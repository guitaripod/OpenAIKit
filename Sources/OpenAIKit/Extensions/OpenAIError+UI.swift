import Foundation

/// UI-friendly extensions for OpenAIError to help with user interface integration.
///
/// These extensions provide ready-to-use properties and methods for displaying
/// errors in user interfaces across iOS, macOS, and other Swift platforms.
///
/// ## Example Usage
///
/// ```swift
/// do {
///     let response = try await openAI.chat.completions(request)
/// } catch let error as OpenAIError {
///     // Show alert to user
///     showAlert(
///         title: error.userFriendlyTitle,
///         message: error.userFriendlyMessage,
///         actions: error.suggestedActions
///     )
///     
///     // Handle retry if applicable
///     if error.isRetryable, let delay = error.suggestedRetryDelay {
///         scheduleRetry(after: delay)
///     }
/// }
/// ```
extension OpenAIError {
    
    /// Suggested user actions for resolving the error.
    public enum UserAction: Sendable {
        case retry
        case checkAPIKey
        case checkInternetConnection
        case reduceRequestSize
        case contactSupport
        case wait(seconds: TimeInterval)
        case checkFileFormat
        case useAlternativeModel
        
        /// A localized title for the action button.
        public var buttonTitle: String {
            switch self {
            case .retry:
                return "Try Again"
            case .checkAPIKey:
                return "Check API Key"
            case .checkInternetConnection:
                return "Check Connection"
            case .reduceRequestSize:
                return "Reduce Size"
            case .contactSupport:
                return "Contact Support"
            case .wait(let seconds):
                return "Wait \(Int(seconds))s"
            case .checkFileFormat:
                return "Check File"
            case .useAlternativeModel:
                return "Try Different Model"
            }
        }
        
        /// A description of what the action does.
        public var description: String {
            switch self {
            case .retry:
                return "Retry the request"
            case .checkAPIKey:
                return "Verify your OpenAI API key in settings"
            case .checkInternetConnection:
                return "Check your internet connection and try again"
            case .reduceRequestSize:
                return "Reduce the size of your request"
            case .contactSupport:
                return "Contact support for assistance"
            case .wait(let seconds):
                return "Wait \(Int(seconds)) seconds before retrying"
            case .checkFileFormat:
                return "Ensure the file format is supported"
            case .useAlternativeModel:
                return "Try using a different model"
            }
        }
    }
    
    /// Suggested actions for the user to resolve the error.
    public var suggestedActions: [UserAction] {
        switch self {
        case .invalidURL, .invalidResponse:
            return [.checkInternetConnection, .retry]
            
        case .authenticationFailed:
            return [.checkAPIKey]
            
        case .rateLimitExceeded:
            if let delay = suggestedRetryDelay {
                return [.wait(seconds: delay), .retry]
            }
            return [.wait(seconds: 60)]
            
        case .apiError(let error):
            return suggestedActionsForAPIError(error)
            
        case .decodingFailed, .encodingFailed:
            return [.retry, .contactSupport]
            
        case .clientError(let statusCode):
            return suggestedActionsForClientError(statusCode)
            
        case .serverError:
            return [.wait(seconds: 5), .retry]
            
        case .unknownError:
            return [.retry, .contactSupport]
            
        case .streamingNotSupported:
            return [] // No action needed, feature not supported
            
        case .invalidFileData:
            return [.checkFileFormat]
        }
    }
    
    /// An icon name suitable for SF Symbols or system images.
    public var iconName: String {
        switch self {
        case .invalidURL, .invalidResponse:
            return "wifi.exclamationmark"
        case .authenticationFailed:
            return "lock.fill"
        case .rateLimitExceeded:
            return "clock.fill"
        case .apiError:
            return "exclamationmark.triangle.fill"
        case .decodingFailed, .encodingFailed:
            return "doc.badge.gearshape"
        case .clientError, .serverError, .unknownError:
            return "exclamationmark.circle.fill"
        case .streamingNotSupported:
            return "antenna.radiowaves.left.and.right.slash"
        case .invalidFileData:
            return "doc.fill.badge.exclamationmark"
        }
    }
    
    /// The severity level of the error for logging and UI presentation.
    public enum Severity: Int, Comparable, Sendable {
        case info = 0
        case warning = 1
        case error = 2
        case critical = 3
        
        public static func < (lhs: Severity, rhs: Severity) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    /// The severity level of this error.
    public var severity: Severity {
        switch self {
        case .streamingNotSupported:
            return .info
        case .rateLimitExceeded:
            return .warning
        case .authenticationFailed, .invalidFileData:
            return .error
        case .serverError, .decodingFailed, .encodingFailed:
            return .critical
        default:
            return .error
        }
    }
    
    /// Whether this error should trigger an automatic retry.
    public var shouldAutoRetry: Bool {
        isRetryable && severity != .critical
    }
    
    /// The maximum number of automatic retries recommended.
    public var maxRetryAttempts: Int {
        switch self {
        case .rateLimitExceeded:
            return 1 // Only retry once for rate limits
        case .serverError:
            return 3 // Try up to 3 times for server errors
        case .apiError(let error) where error.error.type == "server_error":
            return 3
        default:
            return 0
        }
    }
    
    // MARK: - Private Helpers
    
    private func suggestedActionsForAPIError(_ error: APIError) -> [UserAction] {
        switch error.error.type {
        case "invalid_request_error":
            if error.error.param != nil {
                return [.reduceRequestSize, .retry]
            }
            return [.retry]
            
        case "authentication_error":
            return [.checkAPIKey]
            
        case "rate_limit_error":
            return [.wait(seconds: 60), .retry]
            
        case "server_error":
            return [.wait(seconds: 5), .retry]
            
        case "engine_error":
            return [.useAlternativeModel, .retry]
            
        default:
            return [.retry, .contactSupport]
        }
    }
    
    private func suggestedActionsForClientError(_ statusCode: Int) -> [UserAction] {
        switch statusCode {
        case 400:
            return [.retry]
        case 403:
            return [.checkAPIKey]
        case 404:
            return [.contactSupport]
        case 413:
            return [.reduceRequestSize]
        default:
            return [.retry, .contactSupport]
        }
    }
}

/// Helper struct for displaying error details in UI.
public struct OpenAIErrorDetails: Sendable {
    public let title: String
    public let message: String
    public let iconName: String
    public let severity: OpenAIError.Severity
    public let actions: [OpenAIError.UserAction]
    public let technicalDetails: String?
    public let isRetryable: Bool
    public let suggestedRetryDelay: TimeInterval?
    
    /// Creates error details from an OpenAIError.
    public init(from error: OpenAIError) {
        self.title = error.userFriendlyTitle
        self.message = error.userFriendlyMessage
        self.iconName = error.iconName
        self.severity = error.severity
        self.actions = error.suggestedActions
        self.technicalDetails = error.errorDescription
        self.isRetryable = error.isRetryable
        self.suggestedRetryDelay = error.suggestedRetryDelay
    }
}

/// A protocol for handling OpenAI errors in UI components.
public protocol OpenAIErrorHandling {
    /// Handles an OpenAI error by displaying appropriate UI.
    func handle(_ error: OpenAIError)
    
    /// Handles an error with a custom completion handler.
    func handle(_ error: OpenAIError, completion: @escaping (OpenAIError.UserAction) -> Void)
}

/// Default implementation for error handling.
public extension OpenAIErrorHandling {
    func handle(_ error: OpenAIError) {
        let details = OpenAIErrorDetails(from: error)
        print("[OpenAIKit Error] \(details.title): \(details.message)")
        
        if let technicalDetails = details.technicalDetails {
            print("[Technical Details] \(technicalDetails)")
        }
    }
}