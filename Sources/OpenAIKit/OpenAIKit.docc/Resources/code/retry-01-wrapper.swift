// RetryWrapper.swift
import Foundation

class RetryWrapper {
    static func retry<T>(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                if attempt < maxAttempts {
                    // Wait before retrying
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? RetryError.unknownError
    }
}

enum RetryError: LocalizedError {
    case unknownError
    case maxAttemptsExceeded
    
    var errorDescription: String? {
        switch self {
        case .unknownError:
            return "An unknown error occurred"
        case .maxAttemptsExceeded:
            return "Maximum retry attempts exceeded"
        }
    }
}