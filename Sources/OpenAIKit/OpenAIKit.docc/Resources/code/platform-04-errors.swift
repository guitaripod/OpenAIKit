// StreamErrorHandling.swift
import Foundation

enum StreamError: LocalizedError {
    case connectionLost
    case timeout
    case invalidResponse
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .connectionLost:
            return "Connection lost during streaming"
        case .timeout:
            return "Stream timed out"
        case .invalidResponse:
            return "Invalid streaming response"
        case .rateLimited:
            return "Rate limit exceeded during streaming"
        }
    }
}

class StreamErrorHandler {
    static func handle(_ error: Error) -> StreamError {
        // Map various errors to stream errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return .timeout
            case .networkConnectionLost:
                return .connectionLost
            default:
                return .connectionLost
            }
        }
        
        return .invalidResponse
    }
}
