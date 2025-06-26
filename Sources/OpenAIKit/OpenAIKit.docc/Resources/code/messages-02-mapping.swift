// Error context and recovery suggestions
import Foundation

struct ErrorContext {
    let error: Error
    let operation: String
    let context: [String: Any]
    
    func userMessage() -> UserErrorMessage {
        let details = ErrorAnalyzer.analyze(error)
        
        return UserErrorMessage(
            title: title(for: details),
            message: message(for: details),
            actions: suggestedActions(for: details),
            icon: icon(for: details)
        )
    }
    
    private func title(for details: ErrorDetails) -> String {
        switch details.type {
        case .api:
            return "Service Error"
        case .network:
            return "Connection Error"
        case .unknown:
            return "Unexpected Error"
        }
    }
    
    private func message(for details: ErrorDetails) -> String {
        switch operation {
        case "chat":
            return "Unable to send your message. \(details.suggestedAction)"
        case "image_generation":
            return "Unable to generate image. \(details.suggestedAction)"
        case "transcription":
            return "Unable to transcribe audio. \(details.suggestedAction)"
        default:
            return ErrorMessageMapper.userFriendlyMessage(for: error)
        }
    }
    
    private func suggestedActions(for details: ErrorDetails) -> [ErrorAction] {
        var actions: [ErrorAction] = []
        
        if details.isRetryable {
            actions.append(.retry)
        }
        
        switch details.code {
        case "invalid_api_key":
            actions.append(.configure)
        case "rate_limit_exceeded":
            actions.append(.wait(seconds: 60))
        case "context_length_exceeded":
            actions.append(.reduce)
        default:
            break
        }
        
        actions.append(.dismiss)
        
        return actions
    }
    
    private func icon(for details: ErrorDetails) -> String {
        switch details.type {
        case .api:
            return "exclamationmark.triangle"
        case .network:
            return "wifi.exclamationmark"
        case .unknown:
            return "questionmark.circle"
        }
    }
}

struct UserErrorMessage {
    let title: String
    let message: String
    let actions: [ErrorAction]
    let icon: String
}

enum ErrorAction {
    case retry
    case dismiss
    case configure
    case wait(seconds: Int)
    case reduce
    case contactSupport
    
    var title: String {
        switch self {
        case .retry:
            return "Try Again"
        case .dismiss:
            return "OK"
        case .configure:
            return "Settings"
        case .wait(let seconds):
            return "Wait \(seconds)s"
        case .reduce:
            return "Shorten Message"
        case .contactSupport:
            return "Get Help"
        }
    }
}