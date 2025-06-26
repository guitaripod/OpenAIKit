import OpenAIKit
import Foundation
import AVFoundation

// MARK: - Language Detection

class AudioLanguageDetector {
    private let openAI: OpenAIKit
    private let sampleDuration: TimeInterval = 10.0  // Use first 10 seconds for detection
    
    init(apiKey: String) {
        self.openAI = OpenAIKit(apiKey: apiKey)
    }
    
    // Detect language from audio file
    func detectLanguage(
        from audioURL: URL,
        useSample: Bool = true
    ) async throws -> LanguageDetectionResult {
        let startTime = Date()
        
        // Extract sample if requested (for large files)
        let audioData: Data
        if useSample {
            audioData = try extractAudioSample(from: audioURL, duration: sampleDuration)
        } else {
            audioData = try Data(contentsOf: audioURL)
        }
        
        // Use transcription to detect language
        let request = AudioTranscriptionRequest(
            file: audioData,
            model: "whisper-1",
            responseFormat: .verboseJson,
            temperature: 0  // Low temperature for accuracy
        )
        
        let response = try await openAI.createAudioTranscription(request: request)
        
        let detectionTime = Date().timeIntervalSince(startTime)
        
        // Parse detected language
        let detectedLanguage = parseLanguage(from: response.language ?? "unknown")
        
        // Calculate confidence based on response
        let confidence = calculateConfidence(
            response: response,
            expectedLanguage: detectedLanguage
        )
        
        return LanguageDetectionResult(
            detectedLanguage: detectedLanguage,
            confidence: confidence,
            alternativeLanguages: findAlternativeLanguages(
                text: response.text,
                primaryLanguage: detectedLanguage
            ),
            sampleText: String(response.text.prefix(200)),
            detectionTime: detectionTime,
            audioFeatures: extractAudioFeatures(from: audioURL)
        )
    }
    
    // Batch language detection for multiple files
    func detectLanguages(
        from audioURLs: [URL]
    ) async throws -> [BatchDetectionResult] {
        var results: [BatchDetectionResult] = []
        
        await withTaskGroup(of: BatchDetectionResult.self) { group in
            for audioURL in audioURLs {
                group.addTask {
                    do {
                        let detection = try await self.detectLanguage(
                            from: audioURL,
                            useSample: true
                        )
                        
                        return BatchDetectionResult(
                            fileURL: audioURL,
                            detection: detection,
                            error: nil
                        )
                    } catch {
                        return BatchDetectionResult(
                            fileURL: audioURL,
                            detection: nil,
                            error: error
                        )
                    }
                }
            }
            
            for await result in group {
                results.append(result)
            }
        }
        
        return results
    }
    
    // Extract audio sample for faster detection
    private func extractAudioSample(
        from url: URL,
        duration: TimeInterval
    ) throws -> Data {
        let asset = AVAsset(url: url)
        
        // Get audio duration
        let assetDuration = CMTimeGetSeconds(asset.duration)
        let sampleDuration = min(duration, assetDuration)
        
        // For now, just read the whole file
        // In production, you'd use AVAssetReader to extract a sample
        let data = try Data(contentsOf: url)
        
        // Rough approximation: take first portion of data
        let sampleSize = Int(Double(data.count) * (sampleDuration / assetDuration))
        return data.prefix(sampleSize)
    }
    
    private func parseLanguage(from detectedString: String) -> WhisperLanguage? {
        // Try to match the detected string to our enum
        let normalized = detectedString.lowercased().trimmingCharacters(in: .whitespaces)
        
        // First try direct code match
        if let language = WhisperLanguage(rawValue: normalized) {
            return language
        }
        
        // Then try matching by display name
        return WhisperLanguage.allCases.first { language in
            language.displayName.lowercased() == normalized
        }
    }
    
    private func calculateConfidence(
        response: AudioTranscriptionResponse,
        expectedLanguage: WhisperLanguage?
    ) -> Double {
        var confidence = 0.8  // Base confidence
        
        // Boost if segments have high log probabilities
        if let segments = response.segments {
            let avgLogprobs = segments.compactMap { $0.avgLogprob }
            if !avgLogprobs.isEmpty {
                let avgLogprob = avgLogprobs.reduce(0, +) / Double(avgLogprobs.count)
                confidence = min(max(exp(avgLogprob), 0.5), 1.0)
            }
        }
        
        // Reduce confidence if no valid language detected
        if expectedLanguage == nil {
            confidence *= 0.7
        }
        
        return confidence
    }
    
    private func findAlternativeLanguages(
        text: String,
        primaryLanguage: WhisperLanguage?
    ) -> [(language: WhisperLanguage, probability: Double)] {
        // Simple heuristic: check for common words/patterns
        var alternatives: [(WhisperLanguage, Double)] = []
        
        for language in WhisperLanguage.allCases {
            if language == primaryLanguage { continue }
            
            if let hints = LanguageDetectionHelper.languageHints[language] {
                let matches = hints.filter { hint in
                    text.localizedCaseInsensitiveContains(hint)
                }.count
                
                if matches > 0 {
                    let probability = Double(matches) / Double(hints.count) * 0.5
                    alternatives.append((language, probability))
                }
            }
        }
        
        return alternatives
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map { ($0.0, $0.1) }
    }
    
    private func extractAudioFeatures(from url: URL) -> AudioFeatures {
        // Extract basic audio features
        let asset = AVAsset(url: url)
        
        var duration: TimeInterval = 0
        var bitRate: Int = 0
        var sampleRate: Double = 0
        var channels: Int = 0
        
        if let track = asset.tracks(withMediaType: .audio).first {
            duration = CMTimeGetSeconds(asset.duration)
            bitRate = Int(track.estimatedDataRate)
            
            if let formatDescriptions = track.formatDescriptions as? [CMFormatDescription],
               let formatDescription = formatDescriptions.first {
                if let streamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) {
                    sampleRate = streamBasicDescription.pointee.mSampleRate
                    channels = Int(streamBasicDescription.pointee.mChannelsPerFrame)
                }
            }
        }
        
        return AudioFeatures(
            duration: duration,
            bitRate: bitRate,
            sampleRate: sampleRate,
            channels: channels
        )
    }
}

// MARK: - Models

struct LanguageDetectionResult {
    let detectedLanguage: WhisperLanguage?
    let confidence: Double
    let alternativeLanguages: [(language: WhisperLanguage, probability: Double)]
    let sampleText: String
    let detectionTime: TimeInterval
    let audioFeatures: AudioFeatures
    
    var isReliable: Bool {
        confidence > 0.8
    }
}

struct BatchDetectionResult {
    let fileURL: URL
    let detection: LanguageDetectionResult?
    let error: Error?
    
    var isSuccess: Bool {
        detection != nil && error == nil
    }
}

struct AudioFeatures {
    let duration: TimeInterval
    let bitRate: Int
    let sampleRate: Double
    let channels: Int
    
    var quality: AudioQuality {
        if sampleRate >= 44100 && bitRate >= 128000 {
            return .high
        } else if sampleRate >= 22050 && bitRate >= 64000 {
            return .medium
        } else {
            return .low
        }
    }
    
    enum AudioQuality {
        case high
        case medium
        case low
    }
}

// MARK: - Language Detection Cache

class LanguageDetectionCache {
    private var cache: [URL: CachedDetection] = [:]
    private let maxCacheSize = 100
    private let cacheExpiration: TimeInterval = 3600  // 1 hour
    
    struct CachedDetection {
        let result: LanguageDetectionResult
        let timestamp: Date
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 3600
        }
    }
    
    func get(for url: URL) -> LanguageDetectionResult? {
        guard let cached = cache[url],
              !cached.isExpired else {
            return nil
        }
        return cached.result
    }
    
    func set(_ result: LanguageDetectionResult, for url: URL) {
        cache[url] = CachedDetection(result: result, timestamp: Date())
        
        // Maintain cache size
        if cache.count > maxCacheSize {
            removeOldestEntries()
        }
    }
    
    private func removeOldestEntries() {
        let sorted = cache.sorted { $0.value.timestamp < $1.value.timestamp }
        let toRemove = sorted.prefix(cache.count - maxCacheSize)
        
        for (url, _) in toRemove {
            cache.removeValue(forKey: url)
        }
    }
    
    func clear() {
        cache.removeAll()
    }
}

// MARK: - Multi-Language Detection

class MultiLanguageDetector {
    private let detector: AudioLanguageDetector
    private let cache = LanguageDetectionCache()
    
    init(apiKey: String) {
        self.detector = AudioLanguageDetector(apiKey: apiKey)
    }
    
    // Detect if audio contains multiple languages
    func detectMultipleLanguages(
        from audioURL: URL,
        segmentDuration: TimeInterval = 30.0
    ) async throws -> MultiLanguageDetectionResult {
        // This is a simplified version
        // In production, you'd segment the audio and detect each segment
        
        let primaryDetection = try await detector.detectLanguage(from: audioURL)
        
        // For now, return a simple result
        return MultiLanguageDetectionResult(
            primaryLanguage: primaryDetection.detectedLanguage,
            segments: [
                LanguageSegment(
                    startTime: 0,
                    endTime: primaryDetection.audioFeatures.duration,
                    language: primaryDetection.detectedLanguage,
                    confidence: primaryDetection.confidence
                )
            ],
            hasMultipleLanguages: false
        )
    }
}

struct MultiLanguageDetectionResult {
    let primaryLanguage: WhisperLanguage?
    let segments: [LanguageSegment]
    let hasMultipleLanguages: Bool
}

struct LanguageSegment {
    let startTime: TimeInterval
    let endTime: TimeInterval
    let language: WhisperLanguage?
    let confidence: Double
}