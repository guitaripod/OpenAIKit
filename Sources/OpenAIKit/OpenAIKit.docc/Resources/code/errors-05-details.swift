// ErrorHandling.swift - Extracting error details
import Foundation
import OpenAIKit

class ErrorAnalyzer {
    static func analyze(_ error: Error) -> ErrorDetails {
        if let apiError = error as? APIError {
            return ErrorDetails(
                type: .api,
                code: apiError.error.code ?? "unknown",
                message: apiError.error.message,
                isRetryable: isRetryable(apiError),
                suggestedAction: suggestAction(for: apiError)
            )
        } else if let urlError = error as? URLError {
            return ErrorDetails(
                type: .network,
                code: String(urlError.code.rawValue),
                message: urlError.localizedDescription,
                isRetryable: urlError.code != .cancelled,
                suggestedAction: "Check your internet connection"
            )
        } else {
            return ErrorDetails(
                type: .unknown,
                code: "unknown",
                message: error.localizedDescription,
                isRetryable: false,
                suggestedAction: "Please try again or contact support"
            )
        }
    }
    
    private static func isRetryable(_ error: APIError) -> Bool {
        guard let code = error.error.code else { return false }
        
        switch code {
        case "rate_limit_exceeded", "server_error", "service_unavailable":
            return true
        case "invalid_api_key", "invalid_request", "invalid_model":
            return false
        default:
            return false
        }
    }
    
    private static func suggestAction(for error: APIError) -> String {
        guard let code = error.error.code else {
            return "Please try again"
        }
        
        switch code {
        case "rate_limit_exceeded":
            return "Wait a moment before trying again"
        case "invalid_api_key":
            return "Check your API key configuration"
        case "invalid_model":
            return "Use a valid model name like 'gpt-4o-mini'"
        case "context_length_exceeded":
            return "Reduce the length of your messages"
        case "server_error":
            return "OpenAI is experiencing issues. Try again later"
        default:
            return "Review your request and try again"
        }
    }
}

struct ErrorDetails {
    enum ErrorType {
        case api, network, unknown
    }
    
    let type: ErrorType
    let code: String
    let message: String
    let isRetryable: Bool
    let suggestedAction: String
}