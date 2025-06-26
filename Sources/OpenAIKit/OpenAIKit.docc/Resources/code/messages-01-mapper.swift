// ErrorMessageMapper.swift
import Foundation

struct ErrorMessageMapper {
    static func userFriendlyMessage(for error: Error) -> String {
        if let chatError = error as? ChatError {
            return chatError.userMessage
        }
        
        let details = ErrorAnalyzer.analyze(error)
        
        switch details.type {
        case .api:
            return mapAPIError(code: details.code)
        case .network:
            return mapNetworkError(details)
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
    
    private static func mapAPIError(code: String) -> String {
        switch code {
        case "rate_limit_exceeded":
            return "You're sending messages too quickly. Please wait a moment."
        case "invalid_api_key":
            return "Authentication failed. Please check your settings."
        case "context_length_exceeded":
            return "Your message is too long. Please try a shorter message."
        case "model_not_found":
            return "The AI model is not available. Please try again."
        case "server_error":
            return "The service is temporarily unavailable. Please try again."
        default:
            return "Unable to process your request. Please try again."
        }
    }
    
    private static func mapNetworkError(_ details: ErrorDetails) -> String {
        if details.message.contains("offline") || details.message.contains("connection") {
            return "No internet connection. Please check your network."
        } else if details.message.contains("timeout") {
            return "The request took too long. Please try again."
        } else {
            return "Connection error. Please check your internet and try again."
        }
    }
}

extension ChatError {
    var userMessage: String {
        switch self {
        case .clientNotInitialized:
            return "The app isn't ready yet. Please wait a moment."
        case .noContent:
            return "No response received. Please try again."
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment."
        case .invalidRequest(let reason):
            return "Invalid request: \(reason)"
        default:
            return errorDescription ?? "An error occurred"
        }
    }
}