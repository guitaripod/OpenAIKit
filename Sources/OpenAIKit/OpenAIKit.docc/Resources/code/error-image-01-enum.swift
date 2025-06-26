// ImageErrorHandling.swift
import Foundation
import OpenAIKit

/// Comprehensive error types for image generation
enum ImageGenerationError: LocalizedError {
    // Content policy errors
    case contentPolicyViolation(reason: String, suggestions: [String])
    case unsafeContent(categories: [String])
    case copyrightConcern(details: String)
    
    // Rate limiting errors
    case rateLimitExceeded(retryAfter: TimeInterval, limit: RateLimit)
    case quotaExhausted(resetDate: Date, currentUsage: Int, limit: Int)
    case tooManyRequests(message: String)
    
    // Model-specific errors
    case modelNotAvailable(model: String, alternatives: [String])
    case unsupportedFeature(feature: String, model: String, supportedModels: [String])
    case invalidParameter(parameter: String, value: Any, validValues: [String])
    
    // Input validation errors
    case promptTooLong(current: Int, maximum: Int)
    case promptTooShort(current: Int, minimum: Int)
    case invalidImageSize(requested: String, validSizes: [String])
    case invalidImageFormat(requested: String, validFormats: [String])
    
    // Response errors
    case noImageGenerated
    case invalidImageData(reason: String)
    case downloadFailed(url: String, statusCode: Int)
    case base64DecodingFailed
    
    // Network errors
    case networkError(underlying: Error)
    case timeout(duration: TimeInterval)
    case serverError(statusCode: Int, message: String?)
    
    // API errors
    case invalidAPIKey
    case insufficientCredits(remaining: Double, required: Double)
    case organizationNotVerified(model: String)
    
    // File errors
    case fileTooLarge(size: Int, maxSize: Int)
    case unsupportedFileType(type: String, supported: [String])
    case corruptedImageData
    
    var errorDescription: String? {
        switch self {
        case .contentPolicyViolation(let reason, _):
            return "Content policy violation: \(reason)"
            
        case .unsafeContent(let categories):
            return "Unsafe content detected in categories: \(categories.joined(separator: ", "))"
            
        case .copyrightConcern(let details):
            return "Copyright concern: \(details)"
            
        case .rateLimitExceeded(let retryAfter, let limit):
            return "Rate limit exceeded. Retry after \(Int(retryAfter)) seconds. Limit: \(limit.description)"
            
        case .quotaExhausted(let resetDate, let currentUsage, let limit):
            return "Quota exhausted. Used \(currentUsage)/\(limit). Resets: \(resetDate)"
            
        case .tooManyRequests(let message):
            return "Too many requests: \(message)"
            
        case .modelNotAvailable(let model, let alternatives):
            return "Model '\(model)' not available. Try: \(alternatives.joined(separator: ", "))"
            
        case .unsupportedFeature(let feature, let model, let supportedModels):
            return "'\(feature)' not supported by \(model). Supported by: \(supportedModels.joined(separator: ", "))"
            
        case .invalidParameter(let parameter, let value, let validValues):
            return "Invalid \(parameter): \(value). Valid values: \(validValues.joined(separator: ", "))"
            
        case .promptTooLong(let current, let maximum):
            return "Prompt too long: \(current) characters (max: \(maximum))"
            
        case .promptTooShort(let current, let minimum):
            return "Prompt too short: \(current) characters (min: \(minimum))"
            
        case .invalidImageSize(let requested, let validSizes):
            return "Invalid size '\(requested)'. Valid sizes: \(validSizes.joined(separator: ", "))"
            
        case .invalidImageFormat(let requested, let validFormats):
            return "Invalid format '\(requested)'. Valid formats: \(validFormats.joined(separator: ", "))"
            
        case .noImageGenerated:
            return "No image was generated from the request"
            
        case .invalidImageData(let reason):
            return "Invalid image data: \(reason)"
            
        case .downloadFailed(let url, let statusCode):
            return "Failed to download image from \(url). Status: \(statusCode)"
            
        case .base64DecodingFailed:
            return "Failed to decode base64 image data"
            
        case .networkError(let underlying):
            return "Network error: \(underlying.localizedDescription)"
            
        case .timeout(let duration):
            return "Request timed out after \(Int(duration)) seconds"
            
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message ?? "Unknown error")"
            
        case .invalidAPIKey:
            return "Invalid API key. Please check your OpenAI API key"
            
        case .insufficientCredits(let remaining, let required):
            return "Insufficient credits. Have: $\(remaining), Need: $\(required)"
            
        case .organizationNotVerified(let model):
            return "Organization not verified for \(model). Contact OpenAI support"
            
        case .fileTooLarge(let size, let maxSize):
            return "File too large: \(size) bytes (max: \(maxSize) bytes)"
            
        case .unsupportedFileType(let type, let supported):
            return "Unsupported file type '\(type)'. Supported: \(supported.joined(separator: ", "))"
            
        case .corruptedImageData:
            return "Image data is corrupted or invalid"
        }
    }
    
    /// User-friendly recovery suggestions
    var recoverySuggestion: String? {
        switch self {
        case .contentPolicyViolation(_, let suggestions):
            return "Try: " + suggestions.joined(separator: " or ")
            
        case .unsafeContent:
            return "Modify your prompt to avoid unsafe content"
            
        case .copyrightConcern:
            return "Avoid using copyrighted names, brands, or characters"
            
        case .rateLimitExceeded(let retryAfter, _):
            return "Wait \(Int(retryAfter)) seconds before retrying"
            
        case .quotaExhausted(let resetDate, _, _):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "Quota resets on \(formatter.string(from: resetDate))"
            
        case .promptTooLong:
            return "Shorten your prompt to fit within the limit"
            
        case .promptTooShort:
            return "Add more detail to your prompt"
            
        case .invalidImageSize(_, let validSizes):
            return "Use one of these sizes: \(validSizes.joined(separator: ", "))"
            
        case .modelNotAvailable(_, let alternatives):
            return "Switch to: \(alternatives.first ?? "another model")"
            
        case .unsupportedFeature(let feature, _, let supportedModels):
            return "Use \(supportedModels.first ?? "a different model") for \(feature)"
            
        case .networkError:
            return "Check your internet connection and try again"
            
        case .timeout:
            return "Try again with a simpler prompt or smaller image size"
            
        case .invalidAPIKey:
            return "Check your API key in the OpenAI dashboard"
            
        case .insufficientCredits:
            return "Add credits to your OpenAI account"
            
        default:
            return nil
        }
    }
    
    /// Whether the error is retryable
    var isRetryable: Bool {
        switch self {
        case .rateLimitExceeded, .tooManyRequests, .networkError, .timeout, .serverError:
            return true
        default:
            return false
        }
    }
    
    /// Suggested retry delay
    var suggestedRetryDelay: TimeInterval? {
        switch self {
        case .rateLimitExceeded(let retryAfter, _):
            return retryAfter
        case .tooManyRequests:
            return 5.0
        case .networkError, .timeout:
            return 2.0
        case .serverError:
            return 10.0
        default:
            return nil
        }
    }
}

/// Rate limit information
struct RateLimit {
    let requestsPerMinute: Int
    let requestsPerDay: Int
    let tokensPerMinute: Int
    let imagesPerMinute: Int
    
    var description: String {
        "\(requestsPerMinute) req/min, \(imagesPerMinute) img/min"
    }
}

/// Error context for debugging
struct ErrorContext {
    let timestamp: Date
    let model: String
    let prompt: String?
    let parameters: [String: Any]
    let requestId: String?
    
    var debugDescription: String {
        """
        Error at: \(timestamp)
        Model: \(model)
        Prompt: \(prompt ?? "N/A")
        Parameters: \(parameters)
        Request ID: \(requestId ?? "N/A")
        """
    }
}