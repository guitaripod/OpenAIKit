// Complete retry implementation
import Foundation
import OpenAIKit

class RetryableOpenAIClient {
    let client: OpenAIKit
    let retryConfig: RetryConfiguration
    
    struct RetryConfiguration {
        let maxAttempts: Int
        let initialDelay: TimeInterval
        let maxDelay: TimeInterval
        let multiplier: Double
        
        static let `default` = RetryConfiguration(
            maxAttempts: 3,
            initialDelay: 1.0,
            maxDelay: 30.0,
            multiplier: 2.0
        )
    }
    
    init(client: OpenAIKit, retryConfig: RetryConfiguration = .default) {
        self.client = client
        self.retryConfig = retryConfig
    }
    
    func completions(_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        var currentDelay = retryConfig.initialDelay
        var lastError: Error?
        var attemptCount = 0
        
        for attempt in 1...retryConfig.maxAttempts {
            attemptCount = attempt
            
            do {
                let response = try await client.chat.completions(request)
                
                // Log success after retry
                if attempt > 1 {
                    print("Request succeeded after \(attempt) attempts")
                }
                
                return response
            } catch {
                lastError = error
                
                // Analyze error
                let errorDetails = ErrorAnalyzer.analyze(error)
                
                // Don't retry non-retryable errors
                guard errorDetails.isRetryable else {
                    throw error
                }
                
                // Don't retry on last attempt
                guard attempt < retryConfig.maxAttempts else {
                    break
                }
                
                // Calculate delay with jitter
                let jitter = Double.random(in: 0.8...1.2)
                let delay = min(currentDelay * jitter, retryConfig.maxDelay)
                
                print("Attempt \(attempt) failed: \(errorDetails.message)")
                print("Retrying in \(String(format: "%.1f", delay)) seconds...")
                
                // Wait before retry
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                // Increase delay for next attempt
                currentDelay = min(currentDelay * retryConfig.multiplier, retryConfig.maxDelay)
            }
        }
        
        // All attempts failed
        throw RetryError.allAttemptsFailed(
            attempts: attemptCount,
            lastError: lastError
        )
    }
}

enum RetryError: LocalizedError {
    case allAttemptsFailed(attempts: Int, lastError: Error?)
    
    var errorDescription: String? {
        switch self {
        case .allAttemptsFailed(let attempts, let error):
            let errorMessage = error?.localizedDescription ?? "Unknown error"
            return "All \(attempts) attempts failed. Last error: \(errorMessage)"
        }
    }
}