// ImageErrorHandling.swift
import Foundation
import OpenAIKit

/// Rate limit handler with exponential backoff
class RateLimitHandler {
    private var retryAttempts: [String: Int] = [:]
    private var lastRequestTime: [String: Date] = [:]
    private let maxRetries = 5
    
    /// Handle rate limit errors with intelligent retry
    func handleRateLimit(
        error: Error,
        request: ImageGenerationRequest,
        requestId: String
    ) async throws -> RetryDecision {
        
        // Parse rate limit information
        let rateLimitInfo = parseRateLimitError(error)
        
        // Track retry attempts
        let attempts = retryAttempts[requestId] ?? 0
        retryAttempts[requestId] = attempts + 1
        
        // Check if we should retry
        guard attempts < maxRetries else {
            return .abandon(reason: "Maximum retry attempts reached")
        }
        
        // Calculate backoff delay
        let delay = calculateBackoffDelay(
            attempt: attempts,
            rateLimitInfo: rateLimitInfo
        )
        
        // Check if delay is reasonable
        guard delay < 300 else { // 5 minutes max
            return .abandon(reason: "Retry delay too long: \(Int(delay))s")
        }
        
        return .retry(after: delay, strategy: determineRetryStrategy(rateLimitInfo))
    }
    
    /// Parse rate limit information from error
    private func parseRateLimitError(_ error: Error) -> RateLimitInfo {
        // Default rate limit info
        var info = RateLimitInfo(
            limit: 50,
            remaining: 0,
            reset: Date().addingTimeInterval(60),
            retryAfter: nil
        )
        
        // Parse OpenAI error
        if let apiError = error as? OpenAIError,
           case .requestFailed(let statusCode, let message) = apiError,
           statusCode == 429 {
            
            // Extract retry-after if available
            if let message = message,
               let retryAfter = extractRetryAfter(from: message) {
                info.retryAfter = retryAfter
            }
        }
        
        return info
    }
    
    /// Calculate exponential backoff delay
    private func calculateBackoffDelay(
        attempt: Int,
        rateLimitInfo: RateLimitInfo
    ) -> TimeInterval {
        
        // If server provided retry-after, use it
        if let retryAfter = rateLimitInfo.retryAfter {
            return retryAfter
        }
        
        // Otherwise, use exponential backoff with jitter
        let baseDelay = 1.0
        let maxDelay = 60.0
        
        // Calculate exponential delay
        let exponentialDelay = min(
            baseDelay * pow(2.0, Double(attempt)),
            maxDelay
        )
        
        // Add jitter to prevent thundering herd
        let jitter = Double.random(in: 0...1) * 0.3 * exponentialDelay
        
        return exponentialDelay + jitter
    }
    
    /// Determine retry strategy based on rate limit type
    private func determineRetryStrategy(_ info: RateLimitInfo) -> RetryStrategy {
        // If we're close to limit reset, wait for reset
        if let timeToReset = info.reset?.timeIntervalSinceNow,
           timeToReset < 30 {
            return .waitForReset
        }
        
        // If we have remaining quota, slow down
        if info.remaining > 0 {
            return .slowDown
        }
        
        // Otherwise, use standard backoff
        return .exponentialBackoff
    }
    
    /// Execute request with rate limit handling
    func executeWithRateLimitHandling<T>(
        request: @escaping () async throws -> T,
        requestId: String = UUID().uuidString
    ) async throws -> T {
        
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                // Check if we need to throttle
                if let throttleDelay = getThrottleDelay(for: requestId) {
                    try await Task.sleep(nanoseconds: UInt64(throttleDelay * 1_000_000_000))
                }
                
                // Record request time
                lastRequestTime[requestId] = Date()
                
                // Execute request
                let result = try await request()
                
                // Reset retry count on success
                retryAttempts.removeValue(forKey: requestId)
                
                return result
                
            } catch {
                lastError = error
                
                // Check if it's a rate limit error
                if isRateLimitError(error) {
                    let decision = try await handleRateLimit(
                        error: error,
                        request: ImageGenerationRequest(prompt: ""), // Placeholder
                        requestId: requestId
                    )
                    
                    switch decision {
                    case .retry(let delay, _):
                        print("Rate limited. Retrying after \(Int(delay))s...")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                        
                    case .abandon(let reason):
                        throw ImageGenerationError.rateLimitExceeded(
                            retryAfter: 0,
                            limit: RateLimit(
                                requestsPerMinute: 50,
                                requestsPerDay: 1000,
                                tokensPerMinute: 150000,
                                imagesPerMinute: 50
                            )
                        )
                    }
                } else {
                    // Not a rate limit error, propagate
                    throw error
                }
            }
        }
        
        throw lastError ?? ImageGenerationError.tooManyRequests(
            message: "Failed after \(maxRetries) attempts"
        )
    }
    
    /// Get throttle delay for request
    private func getThrottleDelay(for requestId: String) -> TimeInterval? {
        guard let lastTime = lastRequestTime[requestId] else {
            return nil
        }
        
        let timeSinceLastRequest = Date().timeIntervalSince(lastTime)
        let minimumInterval = 1.2 // 50 requests per minute = 1.2s between requests
        
        if timeSinceLastRequest < minimumInterval {
            return minimumInterval - timeSinceLastRequest
        }
        
        return nil
    }
    
    /// Check if error is rate limit related
    private func isRateLimitError(_ error: Error) -> Bool {
        if let apiError = error as? OpenAIError,
           case .requestFailed(let statusCode, _) = apiError {
            return statusCode == 429
        }
        return false
    }
    
    /// Extract retry-after value from error message
    private func extractRetryAfter(from message: String) -> TimeInterval? {
        // Look for patterns like "retry after X seconds"
        let pattern = #"retry.{0,10}after.{0,10}(\d+)"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(
            in: message,
            range: NSRange(message.startIndex..., in: message)
           ),
           let secondsRange = Range(match.range(at: 1), in: message),
           let seconds = Int(message[secondsRange]) {
            return TimeInterval(seconds)
        }
        
        return nil
    }
}

/// Batch rate limit handler for multiple requests
extension RateLimitHandler {
    
    /// Process batch with rate limit awareness
    func processBatchWithRateLimits(
        items: [String],
        processItem: @escaping (String) async throws -> GeneratedImage
    ) async throws -> [BatchProcessResult] {
        
        var results: [BatchProcessResult] = []
        let batchId = UUID().uuidString
        
        // Calculate safe batch size based on rate limits
        let safeBatchSize = calculateSafeBatchSize()
        
        // Process in chunks
        for chunk in items.chunked(into: safeBatchSize) {
            let chunkResults = await processChunk(
                chunk,
                batchId: batchId,
                processItem: processItem
            )
            results.append(contentsOf: chunkResults)
            
            // Delay between chunks
            if chunk != items.chunked(into: safeBatchSize).last {
                try await Task.sleep(nanoseconds: 60_000_000_000) // 60s between chunks
            }
        }
        
        return results
    }
    
    /// Calculate safe batch size based on current rate limits
    private func calculateSafeBatchSize() -> Int {
        // Conservative approach: 80% of rate limit
        let rateLimit = 50 // requests per minute
        let safetyFactor = 0.8
        return Int(Double(rateLimit) * safetyFactor)
    }
    
    /// Process a chunk of items
    private func processChunk(
        _ items: [String],
        batchId: String,
        processItem: @escaping (String) async throws -> GeneratedImage
    ) async -> [BatchProcessResult] {
        
        await withTaskGroup(of: BatchProcessResult.self) { group in
            var results: [BatchProcessResult] = []
            
            for (index, item) in items.enumerated() {
                group.addTask {
                    do {
                        // Add delay between items in chunk
                        let itemDelay = Double(index) * 1.5 // 1.5s between items
                        try await Task.sleep(nanoseconds: UInt64(itemDelay * 1_000_000_000))
                        
                        let image = try await self.executeWithRateLimitHandling(
                            request: { try await processItem(item) },
                            requestId: "\(batchId)_\(index)"
                        )
                        
                        return BatchProcessResult(
                            item: item,
                            success: true,
                            result: .success(image),
                            attempts: self.retryAttempts["\(batchId)_\(index)"] ?? 1
                        )
                    } catch {
                        return BatchProcessResult(
                            item: item,
                            success: false,
                            result: .failure(error),
                            attempts: self.retryAttempts["\(batchId)_\(index)"] ?? 1
                        )
                    }
                }
            }
            
            for await result in group {
                results.append(result)
            }
            
            return results
        }
    }
}

// Supporting types
struct RateLimitInfo {
    let limit: Int
    let remaining: Int
    let reset: Date?
    let retryAfter: TimeInterval?
}

enum RetryDecision {
    case retry(after: TimeInterval, strategy: RetryStrategy)
    case abandon(reason: String)
}

enum RetryStrategy {
    case exponentialBackoff
    case waitForReset
    case slowDown
}

struct BatchProcessResult {
    let item: String
    let success: Bool
    let result: Result<GeneratedImage, Error>
    let attempts: Int
}

// Array extension for chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}