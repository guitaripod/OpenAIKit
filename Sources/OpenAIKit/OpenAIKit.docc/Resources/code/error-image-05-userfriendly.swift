// ImageErrorHandling.swift
import Foundation
import OpenAIKit

/// User-friendly error message generator
class UserFriendlyErrorHandler {
    
    /// Convert technical errors to user-friendly messages
    static func createUserMessage(
        from error: Error,
        context: ErrorContext
    ) -> UserErrorMessage {
        
        // Identify error type and create appropriate message
        if let imageError = error as? ImageGenerationError {
            return handleImageGenerationError(imageError, context: context)
        } else if let apiError = error as? OpenAIError {
            return handleAPIError(apiError, context: context)
        } else {
            return handleGenericError(error, context: context)
        }
    }
    
    /// Handle ImageGenerationError with user-friendly messages
    private static func handleImageGenerationError(
        _ error: ImageGenerationError,
        context: ErrorContext
    ) -> UserErrorMessage {
        
        switch error {
        case .contentPolicyViolation(let reason, let suggestions):
            return UserErrorMessage(
                title: "Content Not Allowed",
                message: "Your image request contains content that isn't permitted.",
                details: reason,
                suggestions: suggestions,
                actions: [
                    .modifyPrompt("Edit Prompt"),
                    .learnMore(url: "https://openai.com/policies/usage-policies")
                ],
                severity: .warning,
                icon: "exclamationmark.triangle"
            )
            
        case .rateLimitExceeded(let retryAfter, _):
            let waitTime = Int(retryAfter)
            return UserErrorMessage(
                title: "Too Many Requests",
                message: "You've made too many image requests. Please wait a moment.",
                details: "You can try again in \(waitTime) seconds",
                suggestions: [
                    "Take a short break",
                    "Your images are being generated as fast as possible"
                ],
                actions: [
                    .wait(seconds: waitTime),
                    .notifyWhenReady
                ],
                severity: .info,
                icon: "clock"
            )
            
        case .quotaExhausted(let resetDate, let currentUsage, let limit):
            let formatter = RelativeDateTimeFormatter()
            let resetTime = formatter.localizedString(for: resetDate, relativeTo: Date())
            
            return UserErrorMessage(
                title: "Monthly Limit Reached",
                message: "You've used all your image generations for this month.",
                details: "Used: \(currentUsage) of \(limit) images",
                suggestions: [
                    "Your limit resets \(resetTime)",
                    "Consider upgrading your plan for more images"
                ],
                actions: [
                    .upgrade("View Plans"),
                    .remindMe(date: resetDate)
                ],
                severity: .warning,
                icon: "chart.bar.fill"
            )
            
        case .modelNotAvailable(let model, let alternatives):
            return UserErrorMessage(
                title: "Model Unavailable",
                message: "The selected image model isn't available right now.",
                details: "\(model) is temporarily unavailable",
                suggestions: alternatives.map { "Try \($0) instead" },
                actions: alternatives.map { .switchModel($0) },
                severity: .info,
                icon: "cpu"
            )
            
        case .unsupportedFeature(let feature, let model, let supportedModels):
            return UserErrorMessage(
                title: "Feature Not Supported",
                message: "\(feature.capitalized) isn't available with \(model).",
                details: "This feature requires a different model",
                suggestions: supportedModels.map { "Use \($0) for \(feature)" },
                actions: [
                    .switchModel(supportedModels.first ?? ""),
                    .removeFeature(feature)
                ],
                severity: .info,
                icon: "questionmark.circle"
            )
            
        case .invalidImageSize(let requested, let validSizes):
            return UserErrorMessage(
                title: "Invalid Image Size",
                message: "The requested size isn't supported.",
                details: "\(requested) is not a valid size",
                suggestions: createSizeSuggestions(from: validSizes),
                actions: validSizes.prefix(3).map { .changeSize($0) },
                severity: .error,
                icon: "photo"
            )
            
        case .downloadFailed(let url, let statusCode):
            return UserErrorMessage(
                title: "Download Failed",
                message: "Couldn't download your generated image.",
                details: "Server returned error \(statusCode)",
                suggestions: [
                    "Check your internet connection",
                    "The image link may have expired"
                ],
                actions: [
                    .retry,
                    .regenerate
                ],
                severity: .error,
                icon: "arrow.down.circle"
            )
            
        case .insufficientCredits(let remaining, let required):
            return UserErrorMessage(
                title: "Insufficient Credits",
                message: "You need more credits to generate this image.",
                details: String(format: "Required: $%.2f, Available: $%.2f", required, remaining),
                suggestions: [
                    "Add credits to your account",
                    "Try a less expensive model or smaller size"
                ],
                actions: [
                    .addCredits,
                    .switchModel(Models.Images.dallE2)
                ],
                severity: .warning,
                icon: "creditcard"
            )
            
        default:
            return createGenericImageError(error)
        }
    }
    
    /// Handle OpenAI API errors
    private static func handleAPIError(
        _ error: OpenAIError,
        context: ErrorContext
    ) -> UserErrorMessage {
        
        switch error {
        case .invalidAPIKey:
            return UserErrorMessage(
                title: "Authentication Failed",
                message: "Your API key isn't working.",
                details: "Please check your OpenAI API key",
                suggestions: [
                    "Verify your API key in settings",
                    "Make sure your key hasn't expired"
                ],
                actions: [
                    .openSettings,
                    .learnMore(url: "https://platform.openai.com/api-keys")
                ],
                severity: .error,
                icon: "key"
            )
            
        case .requestFailed(let statusCode, let message):
            return handleHTTPError(statusCode: statusCode, message: message)
            
        default:
            return UserErrorMessage(
                title: "Something Went Wrong",
                message: "We encountered an unexpected error.",
                details: error.localizedDescription,
                suggestions: ["Try again in a moment"],
                actions: [.retry, .reportIssue],
                severity: .error,
                icon: "exclamationmark.circle"
            )
        }
    }
    
    /// Handle generic errors
    private static func handleGenericError(
        _ error: Error,
        context: ErrorContext
    ) -> UserErrorMessage {
        
        // Network errors
        if (error as NSError).domain == NSURLErrorDomain {
            return UserErrorMessage(
                title: "Connection Problem",
                message: "We couldn't connect to the image service.",
                details: "Please check your internet connection",
                suggestions: [
                    "Make sure you're connected to the internet",
                    "Try again in a few moments"
                ],
                actions: [.retry, .checkConnection],
                severity: .warning,
                icon: "wifi.exclamationmark"
            )
        }
        
        return UserErrorMessage(
            title: "Unexpected Error",
            message: "Something went wrong while generating your image.",
            details: error.localizedDescription,
            suggestions: ["Please try again"],
            actions: [.retry, .reportIssue],
            severity: .error,
            icon: "exclamationmark.triangle"
        )
    }
    
    /// Handle HTTP status code errors
    private static func handleHTTPError(
        statusCode: Int,
        message: String?
    ) -> UserErrorMessage {
        
        switch statusCode {
        case 400:
            return UserErrorMessage(
                title: "Invalid Request",
                message: "There's a problem with your image request.",
                details: message ?? "Please check your settings",
                suggestions: ["Review your prompt and settings"],
                actions: [.modifyPrompt("Edit Request"), .retry],
                severity: .error,
                icon: "exclamationmark.circle"
            )
            
        case 401:
            return UserErrorMessage(
                title: "Authentication Required",
                message: "You need to sign in to generate images.",
                details: "Your session may have expired",
                suggestions: ["Sign in again to continue"],
                actions: [.signIn, .openSettings],
                severity: .error,
                icon: "person.crop.circle.badge.exclamationmark"
            )
            
        case 403:
            return UserErrorMessage(
                title: "Access Denied",
                message: "You don't have permission to use this feature.",
                details: message ?? "Contact support for access",
                suggestions: ["Your account may need verification"],
                actions: [.contactSupport, .learnMore(url: "")],
                severity: .error,
                icon: "lock"
            )
            
        case 500...599:
            return UserErrorMessage(
                title: "Server Problem",
                message: "The image service is having issues.",
                details: "This is temporary - please try again soon",
                suggestions: ["Wait a few minutes and try again"],
                actions: [.retry, .checkStatus],
                severity: .warning,
                icon: "server.rack"
            )
            
        default:
            return UserErrorMessage(
                title: "Request Failed",
                message: "We couldn't process your image request.",
                details: "Error code: \(statusCode)",
                suggestions: ["Try again or contact support"],
                actions: [.retry, .reportIssue],
                severity: .error,
                icon: "xmark.circle"
            )
        }
    }
    
    // Helper methods
    
    private static func createSizeSuggestions(from sizes: [String]) -> [String] {
        return sizes.prefix(3).map { size in
            let dimensions = size.split(separator: "x")
            if dimensions.count == 2 {
                return "Try \(size) (\(aspectRatio(for: size)))"
            }
            return "Try \(size)"
        }
    }
    
    private static func aspectRatio(for size: String) -> String {
        switch size {
        case "1024x1024", "512x512", "256x256":
            return "Square"
        case "1792x1024":
            return "Landscape"
        case "1024x1792":
            return "Portrait"
        default:
            return "Custom"
        }
    }
    
    private static func createGenericImageError(_ error: ImageGenerationError) -> UserErrorMessage {
        UserErrorMessage(
            title: "Image Generation Failed",
            message: error.errorDescription ?? "Unable to generate image",
            details: nil,
            suggestions: error.recoverySuggestion.map { [$0] } ?? [],
            actions: [.retry],
            severity: .error,
            icon: "photo"
        )
    }
}

/// User-friendly error message structure
struct UserErrorMessage {
    let title: String
    let message: String
    let details: String?
    let suggestions: [String]
    let actions: [ErrorAction]
    let severity: ErrorSeverity
    let icon: String
    
    /// Format for display
    var formattedMessage: String {
        var parts = [title, message]
        if let details = details {
            parts.append(details)
        }
        if !suggestions.isEmpty {
            parts.append("\n" + suggestions.map { "• \($0)" }.joined(separator: "\n"))
        }
        return parts.joined(separator: "\n\n")
    }
}

/// Possible error actions
enum ErrorAction {
    case retry
    case modifyPrompt(String)
    case switchModel(String)
    case changeSize(String)
    case removeFeature(String)
    case wait(seconds: Int)
    case notifyWhenReady
    case upgrade(String)
    case remindMe(date: Date)
    case addCredits
    case openSettings
    case signIn
    case contactSupport
    case reportIssue
    case checkStatus
    case checkConnection
    case regenerate
    case learnMore(url: String)
    
    var label: String {
        switch self {
        case .retry: return "Try Again"
        case .modifyPrompt(let label): return label
        case .switchModel(let model): return "Use \(model)"
        case .changeSize(let size): return "Change to \(size)"
        case .removeFeature(let feature): return "Remove \(feature)"
        case .wait(let seconds): return "Wait \(seconds)s"
        case .notifyWhenReady: return "Notify Me"
        case .upgrade(let label): return label
        case .remindMe: return "Set Reminder"
        case .addCredits: return "Add Credits"
        case .openSettings: return "Open Settings"
        case .signIn: return "Sign In"
        case .contactSupport: return "Contact Support"
        case .reportIssue: return "Report Issue"
        case .checkStatus: return "Check Status"
        case .checkConnection: return "Check Connection"
        case .regenerate: return "Generate New"
        case .learnMore: return "Learn More"
        }
    }
}

/// Error severity levels
enum ErrorSeverity {
    case info
    case warning
    case error
    case critical
    
    var color: String {
        switch self {
        case .info: return "blue"
        case .warning: return "orange"
        case .error: return "red"
        case .critical: return "red"
        }
    }
}