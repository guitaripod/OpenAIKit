import Foundation
import AVFoundation
import OpenAIKit

// MARK: - Audio Chunker

class AudioChunker {
    private let maxChunkSize: Int = 25 * 1024 * 1024  // 25MB (OpenAI limit)
    private let optimalChunkDuration: TimeInterval = 600  // 10 minutes
    
    struct AudioChunk {
        let id: UUID
        let index: Int
        let data: Data
        let startTime: TimeInterval
        let endTime: TimeInterval
        let duration: TimeInterval
        
        var size: Int {
            data.count
        }
        
        var formattedTimeRange: String {
            let startMinutes = Int(startTime) / 60
            let startSeconds = Int(startTime) % 60
            let endMinutes = Int(endTime) / 60
            let endSeconds = Int(endTime) % 60
            
            return String(format: "%02d:%02d - %02d:%02d", 
                         startMinutes, startSeconds, endMinutes, endSeconds)
        }
    }
    
    // Split audio file into chunks
    func splitAudioFile(at url: URL) async throws -> [AudioChunk] {
        let asset = AVAsset(url: url)
        
        // Check if we need to split
        let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int ?? 0
        if fileSize <= maxChunkSize {
            // File is small enough, return as single chunk
            let data = try Data(contentsOf: url)
            let duration = CMTimeGetSeconds(asset.duration)
            
            return [AudioChunk(
                id: UUID(),
                index: 0,
                data: data,
                startTime: 0,
                endTime: duration,
                duration: duration
            )]
        }
        
        // Split into chunks
        return try await splitLargeAudioFile(asset: asset, url: url)
    }
    
    private func splitLargeAudioFile(asset: AVAsset, url: URL) async throws -> [AudioChunk] {
        var chunks: [AudioChunk] = []
        let totalDuration = CMTimeGetSeconds(asset.duration)
        
        // Calculate chunk duration based on file size and duration
        let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int ?? 0
        let bytesPerSecond = Double(fileSize) / totalDuration
        let maxChunkDuration = Double(maxChunkSize) / bytesPerSecond
        let chunkDuration = min(optimalChunkDuration, maxChunkDuration)
        
        var currentTime: TimeInterval = 0
        var chunkIndex = 0
        
        while currentTime < totalDuration {
            let endTime = min(currentTime + chunkDuration, totalDuration)
            
            // Extract chunk
            let chunkData = try await extractAudioChunk(
                from: asset,
                startTime: currentTime,
                endTime: endTime
            )
            
            let chunk = AudioChunk(
                id: UUID(),
                index: chunkIndex,
                data: chunkData,
                startTime: currentTime,
                endTime: endTime,
                duration: endTime - currentTime
            )
            
            chunks.append(chunk)
            
            currentTime = endTime
            chunkIndex += 1
        }
        
        return chunks
    }
    
    private func extractAudioChunk(
        from asset: AVAsset,
        startTime: TimeInterval,
        endTime: TimeInterval
    ) async throws -> Data {
        // Create composition
        let composition = AVMutableComposition()
        
        guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
            throw ChunkError.noAudioTrack
        }
        
        let compositionTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )
        
        let startCMTime = CMTime(seconds: startTime, preferredTimescale: 1000)
        let endCMTime = CMTime(seconds: endTime, preferredTimescale: 1000)
        let timeRange = CMTimeRange(start: startCMTime, end: endCMTime)
        
        try compositionTrack?.insertTimeRange(
            timeRange,
            of: audioTrack,
            at: .zero
        )
        
        // Export to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetAppleM4A
        )
        
        exportSession?.outputURL = tempURL
        exportSession?.outputFileType = .m4a
        
        await exportSession?.export()
        
        guard exportSession?.status == .completed else {
            throw ChunkError.exportFailed(exportSession?.error)
        }
        
        // Read exported data
        let data = try Data(contentsOf: tempURL)
        
        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
        
        return data
    }
    
    // Estimate number of chunks needed
    func estimateChunkCount(for url: URL) throws -> Int {
        let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int ?? 0
        
        if fileSize <= maxChunkSize {
            return 1
        }
        
        return Int(ceil(Double(fileSize) / Double(maxChunkSize)))
    }
    
    // Calculate optimal chunk size for a given duration
    func calculateOptimalChunkSize(
        totalDuration: TimeInterval,
        fileSize: Int
    ) -> (chunkDuration: TimeInterval, estimatedChunks: Int) {
        let bytesPerSecond = Double(fileSize) / totalDuration
        let maxChunkDuration = Double(maxChunkSize) / bytesPerSecond
        let chunkDuration = min(optimalChunkDuration, maxChunkDuration)
        let estimatedChunks = Int(ceil(totalDuration / chunkDuration))
        
        return (chunkDuration, estimatedChunks)
    }
}

// MARK: - Chunk Manager

class AudioChunkManager {
    private let chunker = AudioChunker()
    private var chunks: [AudioChunker.AudioChunk] = []
    private var processedChunks: Set<UUID> = []
    
    func prepareAudioFile(_ url: URL) async throws -> ChunkingResult {
        let startTime = Date()
        
        // Get file info
        let asset = AVAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int ?? 0
        
        // Split into chunks
        chunks = try await chunker.splitAudioFile(at: url)
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        return ChunkingResult(
            originalFile: url,
            chunks: chunks,
            totalDuration: duration,
            totalSize: fileSize,
            processingTime: processingTime
        )
    }
    
    func getChunk(at index: Int) -> AudioChunker.AudioChunk? {
        guard index >= 0 && index < chunks.count else { return nil }
        return chunks[index]
    }
    
    func markChunkAsProcessed(_ chunkId: UUID) {
        processedChunks.insert(chunkId)
    }
    
    func isChunkProcessed(_ chunkId: UUID) -> Bool {
        processedChunks.contains(chunkId)
    }
    
    func reset() {
        chunks.removeAll()
        processedChunks.removeAll()
    }
    
    var totalChunks: Int {
        chunks.count
    }
    
    var processedCount: Int {
        processedChunks.count
    }
    
    var progress: Double {
        guard totalChunks > 0 else { return 0 }
        return Double(processedCount) / Double(totalChunks)
    }
}

// MARK: - Models

struct ChunkingResult {
    let originalFile: URL
    let chunks: [AudioChunker.AudioChunk]
    let totalDuration: TimeInterval
    let totalSize: Int
    let processingTime: TimeInterval
    
    var averageChunkSize: Int {
        guard !chunks.isEmpty else { return 0 }
        return totalSize / chunks.count
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)
    }
}

enum ChunkError: LocalizedError {
    case noAudioTrack
    case exportFailed(Error?)
    case invalidTimeRange
    
    var errorDescription: String? {
        switch self {
        case .noAudioTrack:
            return "No audio track found in the file"
        case .exportFailed(let error):
            return "Failed to export audio chunk: \(error?.localizedDescription ?? "Unknown error")"
        case .invalidTimeRange:
            return "Invalid time range specified for chunk"
        }
    }
}