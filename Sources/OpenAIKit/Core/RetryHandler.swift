import Foundation

/// A configurable retry handler for OpenAI API requests.
///
/// This handler implements exponential backoff with jitter for retrying failed requests,
/// particularly useful for handling rate limits and transient server errors.
///
/// ## Example Usage
///
/// ```swift
/// let retryHandler = RetryHandler()
/// 
/// do {
///     let result = try await retryHandler.perform {
///         try await openAI.chat.completions(request)
///     }
/// } catch {
///     // All retries exhausted
///     print("Failed after \(retryHandler.configuration.maxAttempts) attempts")
/// }
/// ```
public final class RetryHandler: Sendable {
    
    /// Configuration for the retry handler.
    public struct Configuration: Sendable {
        /// Maximum number of retry attempts.
        public let maxAttempts: Int
        
        /// Base delay in seconds for exponential backoff.
        public let baseDelay: TimeInterval
        
        /// Maximum delay in seconds between retries.
        public let maxDelay: TimeInterval
        
        /// Jitter factor (0.0-1.0) to randomize delays.
        public let jitterFactor: Double
        
        /// Whether to use exponential backoff.
        public let useExponentialBackoff: Bool
        
        /// Custom delay calculator for specific errors.
        public let customDelayCalculator: (@Sendable (OpenAIError, Int) -> TimeInterval?)?
        
        /// Default configuration with sensible defaults.
        public static let `default` = Configuration(
            maxAttempts: 3,
            baseDelay: 1.0,
            maxDelay: 60.0,
            jitterFactor: 0.1,
            useExponentialBackoff: true,
            customDelayCalculator: nil
        )
        
        /// Configuration optimized for rate limit handling.
        public static let rateLimitOptimized = Configuration(
            maxAttempts: 5,
            baseDelay: 2.0,
            maxDelay: 120.0,
            jitterFactor: 0.2,
            useExponentialBackoff: true,
            customDelayCalculator: { error, _ in
                error.suggestedRetryDelay
            }
        )
        
        /// Creates a custom configuration.
        public init(
            maxAttempts: Int = 3,
            baseDelay: TimeInterval = 1.0,
            maxDelay: TimeInterval = 60.0,
            jitterFactor: Double = 0.1,
            useExponentialBackoff: Bool = true,
            customDelayCalculator: (@Sendable (OpenAIError, Int) -> TimeInterval?)? = nil
        ) {
            self.maxAttempts = max(1, maxAttempts)
            self.baseDelay = max(0.1, baseDelay)
            self.maxDelay = max(baseDelay, maxDelay)
            self.jitterFactor = min(max(0.0, jitterFactor), 1.0)
            self.useExponentialBackoff = useExponentialBackoff
            self.customDelayCalculator = customDelayCalculator
        }
    }
    
    /// The configuration for this retry handler.
    public let configuration: Configuration
    
    /// Creates a retry handler with the specified configuration.
    public init(configuration: Configuration = .default) {
        self.configuration = configuration
    }
    
    /// Performs an async operation with automatic retry on failure.
    ///
    /// - Parameter operation: The async throwing operation to perform.
    /// - Returns: The result of the operation if successful.
    /// - Throws: The last error if all retry attempts are exhausted.
    public func perform<T>(
        _ operation: @Sendable () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<configuration.maxAttempts {
            do {
                return try await operation()
            } catch let error as OpenAIError {
                lastError = error
                
                // Check if error is retryable
                guard error.isRetryable, attempt < configuration.maxAttempts - 1 else {
                    throw error
                }
                
                // Calculate delay
                let delay = calculateDelay(for: error, attempt: attempt)
                
                // Wait before retrying
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
            } catch {
                // Non-OpenAI errors are not retried
                throw error
            }
        }
        
        // All retries exhausted
        throw lastError ?? OpenAIError.unknownError(statusCode: -1)
    }
    
    /// Performs an operation with progress callback.
    public func perform<T>(
        _ operation: @Sendable () async throws -> T,
        onRetry: @Sendable (Int, TimeInterval) async -> Void
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<configuration.maxAttempts {
            do {
                return try await operation()
            } catch let error as OpenAIError {
                lastError = error
                
                guard error.isRetryable, attempt < configuration.maxAttempts - 1 else {
                    throw error
                }
                
                let delay = calculateDelay(for: error, attempt: attempt)
                await onRetry(attempt + 1, delay)
                
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
            } catch {
                throw error
            }
        }
        
        throw lastError ?? OpenAIError.unknownError(statusCode: -1)
    }
    
    // MARK: - Private Methods
    
    private func calculateDelay(for error: OpenAIError, attempt: Int) -> TimeInterval {
        // Check for custom delay
        if let customDelay = configuration.customDelayCalculator?(error, attempt) {
            return min(customDelay, configuration.maxDelay)
        }
        
        // Use error's suggested delay if available
        if let suggestedDelay = error.suggestedRetryDelay {
            return min(suggestedDelay, configuration.maxDelay)
        }
        
        // Calculate delay based on configuration
        var delay = configuration.baseDelay
        
        if configuration.useExponentialBackoff {
            delay = configuration.baseDelay * pow(2.0, Double(attempt))
        }
        
        // Apply jitter
        let jitter = delay * configuration.jitterFactor * Double.random(in: -1...1)
        delay += jitter
        
        // Ensure delay is within bounds
        return min(max(0.1, delay), configuration.maxDelay)
    }
}

/// A convenience extension for retrying OpenAI operations.
public extension OpenAIKit {
    /// Performs an operation with automatic retry handling.
    ///
    /// ```swift
    /// let response = try await openAI.withRetry {
    ///     try await openAI.chat.completions(request)
    /// }
    /// ```
    func withRetry<T>(
        configuration: RetryHandler.Configuration = .default,
        _ operation: @Sendable () async throws -> T
    ) async throws -> T {
        let handler = RetryHandler(configuration: configuration)
        return try await handler.perform(operation)
    }
    
    /// Performs an operation with retry handling and progress updates.
    func withRetry<T>(
        configuration: RetryHandler.Configuration = .default,
        onRetry: @Sendable (Int, TimeInterval) async -> Void,
        _ operation: @Sendable () async throws -> T
    ) async throws -> T {
        let handler = RetryHandler(configuration: configuration)
        return try await handler.perform(operation, onRetry: onRetry)
    }
}