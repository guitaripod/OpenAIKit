import Foundation
import OpenAIKit

// MARK: - Chunk Processor

class ChunkProcessor {
    private let openAI: OpenAIKit
    private let processingQueue = DispatchQueue(label: "chunk.processing", attributes: .concurrent)
    private let semaphore: DispatchSemaphore
    
    init(apiKey: String, maxConcurrentRequests: Int = 3) {
        self.openAI = OpenAIKit(apiKey: apiKey)
        self.semaphore = DispatchSemaphore(value: maxConcurrentRequests)
    }
    
    // Process a single chunk
    func processChunk(
        _ chunk: AudioChunker.AudioChunk,
        options: ProcessingOptions = ProcessingOptions()
    ) async throws -> ChunkTranscriptionResult {
        // Wait for available slot
        await withCheckedContinuation { continuation in
            processingQueue.async {
                self.semaphore.wait()
                continuation.resume()
            }
        }
        
        defer {
            semaphore.signal()
        }
        
        let startTime = Date()
        
        // Create transcription request
        let request = AudioTranscriptionRequest(
            file: chunk.data,
            model: "whisper-1",
            prompt: options.prompt,
            responseFormat: options.includeTimestamps ? .verboseJson : .json,
            temperature: options.temperature,
            language: options.language?.rawValue
        )
        
        do {
            let response = try await openAI.createAudioTranscription(request: request)
            let processingTime = Date().timeIntervalSince(startTime)
            
            // Adjust timestamps based on chunk offset
            let adjustedSegments = adjustSegmentTimestamps(
                segments: response.segments,
                offset: chunk.startTime
            )
            
            return ChunkTranscriptionResult(
                chunkId: chunk.id,
                chunkIndex: chunk.index,
                text: response.text,
                segments: adjustedSegments,
                language: response.language,
                processingTime: processingTime,
                confidence: calculateConfidence(response: response)
            )
        } catch {
            return ChunkTranscriptionResult(
                chunkId: chunk.id,
                chunkIndex: chunk.index,
                text: "",
                segments: nil,
                language: nil,
                processingTime: Date().timeIntervalSince(startTime),
                confidence: 0,
                error: error
            )
        }
    }
    
    // Process multiple chunks with progress tracking
    func processChunks(
        _ chunks: [AudioChunker.AudioChunk],
        options: ProcessingOptions = ProcessingOptions(),
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> [ChunkTranscriptionResult] {
        var results: [ChunkTranscriptionResult] = []
        let totalChunks = chunks.count
        var processedCount = 0
        
        // Process chunks in parallel batches
        await withTaskGroup(of: ChunkTranscriptionResult.self) { group in
            for chunk in chunks {
                group.addTask {
                    try await self.processChunk(chunk, options: options)
                }
            }
            
            for await result in group {
                results.append(result)
                processedCount += 1
                
                let progress = Double(processedCount) / Double(totalChunks)
                await MainActor.run {
                    progressHandler?(progress)
                }
            }
        }
        
        // Sort results by chunk index
        results.sort { $0.chunkIndex < $1.chunkIndex }
        
        return results
    }
    
    // Process with retry logic
    func processChunkWithRetry(
        _ chunk: AudioChunker.AudioChunk,
        options: ProcessingOptions = ProcessingOptions(),
        maxRetries: Int = 3
    ) async throws -> ChunkTranscriptionResult {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                let result = try await processChunk(chunk, options: options)
                
                if result.error == nil {
                    return result
                }
                
                lastError = result.error
                
                // Wait before retry with exponential backoff
                let delay = pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
            } catch {
                lastError = error
                
                if attempt < maxRetries - 1 {
                    let delay = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? ProcessingError.maxRetriesExceeded
    }
    
    // Merge chunk results into final transcription
    func mergeChunkResults(_ results: [ChunkTranscriptionResult]) -> MergedTranscriptionResult {
        let sortedResults = results.sorted { $0.chunkIndex < $1.chunkIndex }
        
        var fullText = ""
        var allSegments: [TranscriptionSegment] = []
        var detectedLanguages: [String: Int] = [:]
        var totalConfidence: Double = 0
        var successfulChunks = 0
        
        for result in sortedResults {
            if result.error == nil {
                // Add text with proper spacing
                if !fullText.isEmpty && !fullText.hasSuffix(" ") && !fullText.hasSuffix("\n") {
                    fullText += " "
                }
                fullText += result.text
                
                // Collect segments
                if let segments = result.segments {
                    allSegments.append(contentsOf: segments)
                }
                
                // Track languages
                if let language = result.language {
                    detectedLanguages[language, default: 0] += 1
                }
                
                totalConfidence += result.confidence
                successfulChunks += 1
            }
        }
        
        // Determine primary language
        let primaryLanguage = detectedLanguages.max { $0.value < $1.value }?.key
        
        // Calculate average confidence
        let averageConfidence = successfulChunks > 0 ? totalConfidence / Double(successfulChunks) : 0
        
        return MergedTranscriptionResult(
            text: fullText.trimmingCharacters(in: .whitespacesAndNewlines),
            segments: allSegments.isEmpty ? nil : allSegments,
            primaryLanguage: primaryLanguage,
            detectedLanguages: detectedLanguages,
            averageConfidence: averageConfidence,
            successfulChunks: successfulChunks,
            totalChunks: results.count
        )
    }
    
    // Helper functions
    
    private func adjustSegmentTimestamps(
        segments: [TranscriptionSegment]?,
        offset: TimeInterval
    ) -> [TranscriptionSegment]? {
        guard let segments = segments else { return nil }
        
        return segments.map { segment in
            var adjusted = segment
            if let start = segment.start {
                adjusted.start = start + offset
            }
            if let end = segment.end {
                adjusted.end = end + offset
            }
            return adjusted
        }
    }
    
    private func calculateConfidence(response: AudioTranscriptionResponse) -> Double {
        guard let segments = response.segments, !segments.isEmpty else { return 0.8 }
        
        let avgLogprobs = segments.compactMap { $0.avgLogprob }
        guard !avgLogprobs.isEmpty else { return 0.8 }
        
        let avgLogprob = avgLogprobs.reduce(0, +) / Double(avgLogprobs.count)
        return min(max(exp(avgLogprob), 0), 1)
    }
}

// MARK: - Models

struct ProcessingOptions {
    var language: WhisperLanguage?
    var prompt: String?
    var temperature: Double = 0
    var includeTimestamps: Bool = false
}

struct ChunkTranscriptionResult {
    let chunkId: UUID
    let chunkIndex: Int
    let text: String
    let segments: [TranscriptionSegment]?
    let language: String?
    let processingTime: TimeInterval
    let confidence: Double
    let error: Error?
    
    var isSuccess: Bool {
        error == nil && !text.isEmpty
    }
}

struct MergedTranscriptionResult {
    let text: String
    let segments: [TranscriptionSegment]?
    let primaryLanguage: String?
    let detectedLanguages: [String: Int]
    let averageConfidence: Double
    let successfulChunks: Int
    let totalChunks: Int
    
    var successRate: Double {
        guard totalChunks > 0 else { return 0 }
        return Double(successfulChunks) / Double(totalChunks)
    }
    
    var duration: TimeInterval? {
        guard let segments = segments,
              let firstStart = segments.first?.start,
              let lastEnd = segments.last?.end else {
            return nil
        }
        return lastEnd - firstStart
    }
}

enum ProcessingError: LocalizedError {
    case maxRetriesExceeded
    case noChunksProcessed
    case partialFailure(successCount: Int, totalCount: Int)
    
    var errorDescription: String? {
        switch self {
        case .maxRetriesExceeded:
            return "Maximum number of retries exceeded"
        case .noChunksProcessed:
            return "No chunks were successfully processed"
        case .partialFailure(let success, let total):
            return "Only \(success) out of \(total) chunks were processed successfully"
        }
    }
}