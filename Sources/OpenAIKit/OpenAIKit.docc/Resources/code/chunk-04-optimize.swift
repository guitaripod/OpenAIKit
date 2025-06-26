import Foundation
import AVFoundation
import OpenAIKit

// MARK: - Chunk Optimizer

class ChunkOptimizer {
    
    // Optimize chunk boundaries for better transcription
    func optimizeChunkBoundaries(
        asset: AVAsset,
        targetChunkDuration: TimeInterval
    ) async throws -> [OptimizedChunk] {
        // Analyze audio for silence periods
        let silencePeriods = try await detectSilencePeriods(in: asset)
        
        // Create chunks at natural boundaries
        return createOptimizedChunks(
            duration: CMTimeGetSeconds(asset.duration),
            targetDuration: targetChunkDuration,
            silencePeriods: silencePeriods
        )
    }
    
    // Detect silence periods in audio
    private func detectSilencePeriods(
        in asset: AVAsset,
        threshold: Float = -40.0  // dB
    ) async throws -> [SilencePeriod] {
        guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
            throw OptimizationError.noAudioTrack
        }
        
        // Create reader
        let reader = try AVAssetReader(asset: asset)
        
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        let output = AVAssetReaderTrackOutput(
            track: audioTrack,
            outputSettings: outputSettings
        )
        
        reader.add(output)
        reader.startReading()
        
        var silencePeriods: [SilencePeriod] = []
        var currentSilenceStart: TimeInterval?
        var currentTime: TimeInterval = 0
        let sampleRate = 44100.0
        
        while reader.status == .reading {
            guard let sampleBuffer = output.copyNextSampleBuffer() else { break }
            
            // Analyze audio levels
            let duration = CMSampleBufferGetDuration(sampleBuffer)
            let durationSeconds = CMTimeGetSeconds(duration)
            
            if let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                let length = CMBlockBufferGetDataLength(blockBuffer)
                let sampleCount = length / 2  // 16-bit samples
                
                var data = Data(count: length)
                data.withUnsafeMutableBytes { bytes in
                    CMBlockBufferCopyDataBytes(
                        blockBuffer,
                        atOffset: 0,
                        dataLength: length,
                        destination: bytes.baseAddress!
                    )
                }
                
                // Calculate RMS level
                let rmsLevel = calculateRMSLevel(data: data, sampleCount: sampleCount)
                let dBLevel = 20 * log10(rmsLevel)
                
                if dBLevel < threshold {
                    // Silence detected
                    if currentSilenceStart == nil {
                        currentSilenceStart = currentTime
                    }
                } else {
                    // Sound detected
                    if let start = currentSilenceStart {
                        let period = SilencePeriod(
                            startTime: start,
                            endTime: currentTime,
                            duration: currentTime - start
                        )
                        
                        // Only keep significant silence periods (> 0.5 seconds)
                        if period.duration > 0.5 {
                            silencePeriods.append(period)
                        }
                        
                        currentSilenceStart = nil
                    }
                }
            }
            
            currentTime += durationSeconds
        }
        
        // Handle final silence period
        if let start = currentSilenceStart {
            let period = SilencePeriod(
                startTime: start,
                endTime: currentTime,
                duration: currentTime - start
            )
            if period.duration > 0.5 {
                silencePeriods.append(period)
            }
        }
        
        return silencePeriods
    }
    
    // Calculate RMS level from audio data
    private func calculateRMSLevel(data: Data, sampleCount: Int) -> Float {
        var sum: Float = 0
        
        data.withUnsafeBytes { bytes in
            let samples = bytes.bindMemory(to: Int16.self)
            
            for i in 0..<sampleCount {
                let sample = Float(samples[i]) / Float(Int16.max)
                sum += sample * sample
            }
        }
        
        return sqrt(sum / Float(sampleCount))
    }
    
    // Create optimized chunks based on silence periods
    private func createOptimizedChunks(
        duration: TimeInterval,
        targetDuration: TimeInterval,
        silencePeriods: [SilencePeriod]
    ) -> [OptimizedChunk] {
        var chunks: [OptimizedChunk] = []
        var currentStart: TimeInterval = 0
        var chunkIndex = 0
        
        while currentStart < duration {
            let idealEnd = currentStart + targetDuration
            
            // Find best split point near ideal end
            let splitPoint = findBestSplitPoint(
                idealTime: idealEnd,
                silencePeriods: silencePeriods,
                maxTime: duration,
                tolerance: targetDuration * 0.2  // 20% tolerance
            )
            
            let chunk = OptimizedChunk(
                index: chunkIndex,
                startTime: currentStart,
                endTime: splitPoint,
                duration: splitPoint - currentStart,
                startsAtSilence: isNearSilence(time: currentStart, silencePeriods: silencePeriods),
                endsAtSilence: isNearSilence(time: splitPoint, silencePeriods: silencePeriods)
            )
            
            chunks.append(chunk)
            
            currentStart = splitPoint
            chunkIndex += 1
        }
        
        return chunks
    }
    
    // Find best split point near target time
    private func findBestSplitPoint(
        idealTime: TimeInterval,
        silencePeriods: [SilencePeriod],
        maxTime: TimeInterval,
        tolerance: TimeInterval
    ) -> TimeInterval {
        // If ideal time exceeds max, return max
        if idealTime >= maxTime {
            return maxTime
        }
        
        // Search for silence period near ideal time
        let searchStart = max(0, idealTime - tolerance)
        let searchEnd = min(maxTime, idealTime + tolerance)
        
        // Find silence periods in search range
        let candidatePeriods = silencePeriods.filter { period in
            period.startTime >= searchStart && period.startTime <= searchEnd
        }
        
        if let nearestSilence = candidatePeriods.min(by: { 
            abs($0.startTime - idealTime) < abs($1.startTime - idealTime)
        }) {
            // Split at the middle of the silence period
            return nearestSilence.startTime + (nearestSilence.duration / 2)
        }
        
        // No silence found, use ideal time
        return min(idealTime, maxTime)
    }
    
    // Check if time is near a silence period
    private func isNearSilence(
        time: TimeInterval,
        silencePeriods: [SilencePeriod],
        threshold: TimeInterval = 0.5
    ) -> Bool {
        return silencePeriods.contains { period in
            abs(time - period.startTime) < threshold ||
            abs(time - period.endTime) < threshold ||
            (time >= period.startTime && time <= period.endTime)
        }
    }
}

// MARK: - Adaptive Chunk Size

class AdaptiveChunkSizer {
    
    // Calculate optimal chunk size based on audio characteristics
    func calculateOptimalChunkSize(
        fileSize: Int,
        duration: TimeInterval,
        complexity: AudioComplexity
    ) -> ChunkSizeRecommendation {
        let maxChunkSize = 25 * 1024 * 1024  // 25MB limit
        let bytesPerSecond = Double(fileSize) / duration
        
        // Adjust based on complexity
        let complexityFactor: Double
        switch complexity {
        case .simple:
            complexityFactor = 1.2  // Can use larger chunks
        case .moderate:
            complexityFactor = 1.0
        case .complex:
            complexityFactor = 0.8  // Use smaller chunks for better accuracy
        }
        
        // Calculate recommended chunk duration
        let baseChunkDuration = Double(maxChunkSize) / bytesPerSecond
        let adjustedDuration = baseChunkDuration * complexityFactor
        
        // Apply constraints
        let minDuration: TimeInterval = 60  // 1 minute minimum
        let maxDuration: TimeInterval = 600  // 10 minutes maximum
        let optimalDuration = max(minDuration, min(maxDuration, adjustedDuration))
        
        let chunkCount = Int(ceil(duration / optimalDuration))
        
        return ChunkSizeRecommendation(
            optimalDuration: optimalDuration,
            estimatedChunkCount: chunkCount,
            estimatedChunkSize: Int(bytesPerSecond * optimalDuration),
            complexity: complexity
        )
    }
    
    // Analyze audio complexity
    func analyzeAudioComplexity(asset: AVAsset) async throws -> AudioComplexity {
        // Analyze various factors
        let channelCount = getChannelCount(from: asset)
        let hasMusic = try await detectMusic(in: asset)
        let speakerCount = try await estimateSpeakerCount(in: asset)
        let noiseLevel = try await estimateNoiseLevel(in: asset)
        
        // Determine complexity
        if channelCount > 2 || hasMusic || speakerCount > 2 || noiseLevel > 0.5 {
            return .complex
        } else if speakerCount > 1 || noiseLevel > 0.3 {
            return .moderate
        } else {
            return .simple
        }
    }
    
    private func getChannelCount(from asset: AVAsset) -> Int {
        guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
            return 0
        }
        
        if let formatDescriptions = audioTrack.formatDescriptions as? [CMFormatDescription],
           let formatDescription = formatDescriptions.first,
           let streamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) {
            return Int(streamBasicDescription.pointee.mChannelsPerFrame)
        }
        
        return 0
    }
    
    private func detectMusic(in asset: AVAsset) async throws -> Bool {
        // Simplified - in production would use more sophisticated analysis
        return false
    }
    
    private func estimateSpeakerCount(in asset: AVAsset) async throws -> Int {
        // Simplified - in production would use speaker diarization
        return 1
    }
    
    private func estimateNoiseLevel(in asset: AVAsset) async throws -> Double {
        // Simplified - in production would analyze signal-to-noise ratio
        return 0.2
    }
}

// MARK: - Models

struct OptimizedChunk {
    let index: Int
    let startTime: TimeInterval
    let endTime: TimeInterval
    let duration: TimeInterval
    let startsAtSilence: Bool
    let endsAtSilence: Bool
    
    var quality: ChunkQuality {
        if startsAtSilence && endsAtSilence {
            return .excellent
        } else if startsAtSilence || endsAtSilence {
            return .good
        } else {
            return .fair
        }
    }
    
    enum ChunkQuality {
        case excellent  // Starts and ends at silence
        case good      // Starts or ends at silence
        case fair      // No silence boundaries
    }
}

struct SilencePeriod {
    let startTime: TimeInterval
    let endTime: TimeInterval
    let duration: TimeInterval
}

enum AudioComplexity {
    case simple    // Single speaker, quiet environment
    case moderate  // Multiple speakers or some background noise
    case complex   // Music, many speakers, or high noise
}

struct ChunkSizeRecommendation {
    let optimalDuration: TimeInterval
    let estimatedChunkCount: Int
    let estimatedChunkSize: Int
    let complexity: AudioComplexity
    
    var description: String {
        let minutes = Int(optimalDuration) / 60
        let seconds = Int(optimalDuration) % 60
        let sizeInMB = estimatedChunkSize / (1024 * 1024)
        
        return """
        Recommended chunk duration: \(minutes)m \(seconds)s
        Estimated chunks: \(estimatedChunkCount)
        Estimated size per chunk: ~\(sizeInMB)MB
        Audio complexity: \(complexity)
        """
    }
}

enum OptimizationError: LocalizedError {
    case noAudioTrack
    case analysisFailure
    
    var errorDescription: String? {
        switch self {
        case .noAudioTrack:
            return "No audio track found in the file"
        case .analysisFailure:
            return "Failed to analyze audio characteristics"
        }
    }
}