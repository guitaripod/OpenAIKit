// Exponential backoff retry
import Foundation

class ExponentialBackoffRetry {
    static func retry<T>(
        maxAttempts: Int = 3,
        initialDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 60.0,
        multiplier: Double = 2.0,
        shouldRetry: @escaping (Error) -> Bool = { _ in true },
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var currentDelay = initialDelay
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Check if we should retry this error
                guard shouldRetry(error) else {
                    throw error
                }
                
                if attempt < maxAttempts {
                    // Add jitter to prevent thundering herd
                    let jitter = Double.random(in: 0.8...1.2)
                    let delay = min(currentDelay * jitter, maxDelay)
                    
                    print("Attempt \(attempt) failed. Retrying in \(String(format: "%.1f", delay)) seconds...")
                    
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    
                    // Increase delay for next attempt
                    currentDelay = min(currentDelay * multiplier, maxDelay)
                }
            }
        }
        
        throw RetryError.maxAttemptsExceeded
    }
}

// Usage with OpenAI
func sendMessageWithRetry(_ message: String) async throws -> String {
    try await ExponentialBackoffRetry.retry(
        maxAttempts: 3,
        initialDelay: 1.0,
        shouldRetry: { error in
            // Only retry certain errors
            if let apiError = error as? APIError {
                return ErrorAnalyzer.analyze(apiError).isRetryable
            }
            return error is URLError
        }
    ) {
        try await sendChatMessage(message)
    }
}