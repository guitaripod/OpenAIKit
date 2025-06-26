// ImageErrorHandling.swift
import Foundation
import OpenAIKit

/// Model-specific error handler
class ModelSpecificErrorHandler {
    
    /// Handle errors specific to each image model
    func handleModelError(
        _ error: Error,
        model: String,
        request: ImageGenerationRequest
    ) throws -> ModelErrorRecovery {
        
        // Identify the specific issue
        let issue = identifyModelIssue(error, model: model, request: request)
        
        // Generate recovery options based on model
        switch model {
        case Models.Images.dallE2:
            return handleDALLE2Error(issue, request: request)
            
        case Models.Images.dallE3:
            return handleDALLE3Error(issue, request: request)
            
        case Models.Images.gptImage1:
            return handleGPTImageError(issue, request: request)
            
        default:
            return .switchModel(
                to: Models.Images.dallE3,
                reason: "Unknown model, switching to DALL-E 3"
            )
        }
    }
    
    /// Identify the specific model issue
    private func identifyModelIssue(
        _ error: Error,
        model: String,
        request: ImageGenerationRequest
    ) -> ModelIssue {
        
        // Check for parameter issues
        if let paramError = checkParameterCompatibility(request, model: model) {
            return paramError
        }
        
        // Check for feature issues
        if let featureError = checkFeatureSupport(request, model: model) {
            return featureError
        }
        
        // Parse error message
        if let apiError = error as? OpenAIError {
            return parseAPIError(apiError, model: model)
        }
        
        return .unknown(error.localizedDescription)
    }
    
    /// Handle DALL-E 2 specific errors
    private func handleDALLE2Error(
        _ issue: ModelIssue,
        request: ImageGenerationRequest
    ) -> ModelErrorRecovery {
        
        switch issue {
        case .unsupportedSize(let size):
            return .modifyRequest(
                changes: [
                    .size(closestDALLE2Size(to: size)),
                    .removeParameter("quality"),
                    .removeParameter("style")
                ],
                reason: "DALL-E 2 only supports 256x256, 512x512, and 1024x1024"
            )
            
        case .unsupportedFeature(let feature):
            if feature == "quality" || feature == "style" {
                return .modifyRequest(
                    changes: [.removeParameter(feature)],
                    reason: "DALL-E 2 doesn't support \(feature) settings"
                )
            } else if feature == "transparency" {
                return .switchModel(
                    to: Models.Images.gptImage1,
                    reason: "Only gpt-image-1 supports transparent backgrounds"
                )
            }
            
        case .tooManyImages(let requested):
            if requested > 10 {
                return .modifyRequest(
                    changes: [.n(10)],
                    reason: "DALL-E 2 maximum is 10 images per request"
                )
            }
            
        default:
            return .fallbackStrategy(
                "Simplify your request for DALL-E 2 compatibility"
            )
        }
        
        return .fallbackStrategy("Unable to handle DALL-E 2 error")
    }
    
    /// Handle DALL-E 3 specific errors
    private func handleDALLE3Error(
        _ issue: ModelIssue,
        request: ImageGenerationRequest
    ) -> ModelErrorRecovery {
        
        switch issue {
        case .unsupportedSize(let size):
            return .modifyRequest(
                changes: [.size(closestDALLE3Size(to: size))],
                reason: "DALL-E 3 supports 1024x1024, 1024x1792, and 1792x1024"
            )
            
        case .tooManyImages(let requested):
            if requested > 1 {
                return .modifyRequest(
                    changes: [.n(1)],
                    reason: "DALL-E 3 only generates 1 image per request"
                )
            }
            
        case .unsupportedFeature(let feature):
            if feature == "transparency" {
                return .switchModel(
                    to: Models.Images.gptImage1,
                    reason: "Use gpt-image-1 for transparent backgrounds"
                )
            }
            
        case .promptTooComplex:
            return .modifyRequest(
                changes: [.simplifyPrompt],
                reason: "Simplify prompt for better DALL-E 3 results"
            )
            
        default:
            return .retry(
                with: .adjustedParameters,
                reason: "Retry with adjusted parameters"
            )
        }
    }
    
    /// Handle gpt-image-1 specific errors
    private func handleGPTImageError(
        _ issue: ModelIssue,
        request: ImageGenerationRequest
    ) -> ModelErrorRecovery {
        
        switch issue {
        case .organizationNotVerified:
            return .switchModel(
                to: Models.Images.dallE3,
                reason: "Organization needs verification for gpt-image-1. Using DALL-E 3 instead"
            )
            
        case .quotaExceeded:
            return .switchModel(
                to: Models.Images.dallE2,
                reason: "gpt-image-1 quota exceeded. Using DALL-E 2 for lower cost"
            )
            
        case .unsupportedSize(let size):
            // gpt-image-1 supports more sizes, find closest
            return .modifyRequest(
                changes: [.size(closestGPTImageSize(to: size))],
                reason: "Adjusting to nearest supported size"
            )
            
        case .compressionError(let value):
            return .modifyRequest(
                changes: [.outputCompression(clamp(value, min: 0, max: 100))],
                reason: "Compression must be between 0 and 100"
            )
            
        case .outputFormatError(let format):
            let validFormats = ["png", "jpeg", "webp"]
            return .modifyRequest(
                changes: [.outputFormat(validFormats.first!)],
                reason: "Invalid format '\(format)'. Using PNG instead"
            )
            
        default:
            return .fallbackWithDegradation(
                features: [.removeTransparency, .lowerQuality, .smallerSize],
                reason: "Reducing requirements for compatibility"
            )
        }
    }
    
    /// Check parameter compatibility
    private func checkParameterCompatibility(
        _ request: ImageGenerationRequest,
        model: String
    ) -> ModelIssue? {
        
        switch model {
        case Models.Images.dallE2:
            // Check size
            if let size = request.size,
               !["256x256", "512x512", "1024x1024"].contains(size) {
                return .unsupportedSize(size)
            }
            // Check n parameter
            if let n = request.n, n > 10 {
                return .tooManyImages(n)
            }
            // Check unsupported parameters
            if request.quality != nil || request.style != nil {
                return .unsupportedFeature("quality/style")
            }
            
        case Models.Images.dallE3:
            // Check size
            if let size = request.size,
               !["1024x1024", "1024x1792", "1792x1024"].contains(size) {
                return .unsupportedSize(size)
            }
            // Check n parameter
            if let n = request.n, n > 1 {
                return .tooManyImages(n)
            }
            
        case Models.Images.gptImage1:
            // Check compression
            if let compression = request.outputCompression,
               compression < 0 || compression > 100 {
                return .compressionError(compression)
            }
            // Check format
            if let format = request.outputFormat,
               !["png", "jpeg", "webp"].contains(format.lowercased()) {
                return .outputFormatError(format)
            }
            
        default:
            break
        }
        
        return nil
    }
    
    /// Check feature support
    private func checkFeatureSupport(
        _ request: ImageGenerationRequest,
        model: String
    ) -> ModelIssue? {
        
        // Check transparency support
        if request.background == "transparent" && model != Models.Images.gptImage1 {
            return .unsupportedFeature("transparency")
        }
        
        // Check compression support
        if request.outputCompression != nil && model != Models.Images.gptImage1 {
            return .unsupportedFeature("compression")
        }
        
        return nil
    }
    
    /// Parse API error
    private func parseAPIError(_ error: OpenAIError, model: String) -> ModelIssue {
        switch error {
        case .requestFailed(let code, let message):
            if code == 403 && message?.contains("organization") == true {
                return .organizationNotVerified
            } else if code == 429 && message?.contains("quota") == true {
                return .quotaExceeded
            }
        default:
            break
        }
        
        return .unknown(error.localizedDescription)
    }
    
    // Helper methods for size adjustments
    
    private func closestDALLE2Size(to size: String) -> String {
        let dalle2Sizes = ["256x256", "512x512", "1024x1024"]
        return findClosestSize(to: size, from: dalle2Sizes)
    }
    
    private func closestDALLE3Size(to size: String) -> String {
        let dalle3Sizes = ["1024x1024", "1024x1792", "1792x1024"]
        return findClosestSize(to: size, from: dalle3Sizes)
    }
    
    private func closestGPTImageSize(to size: String) -> String {
        let gptSizes = ["256x256", "512x512", "1024x1024", "2048x2048", "4096x4096"]
        return findClosestSize(to: size, from: gptSizes)
    }
    
    private func findClosestSize(to target: String, from sizes: [String]) -> String {
        // Parse target dimensions
        let targetDimensions = target.split(separator: "x").compactMap { Int($0) }
        guard targetDimensions.count == 2 else { return sizes[0] }
        
        let targetArea = targetDimensions[0] * targetDimensions[1]
        
        // Find size with closest area
        return sizes.min { size1, size2 in
            let dims1 = size1.split(separator: "x").compactMap { Int($0) }
            let dims2 = size2.split(separator: "x").compactMap { Int($0) }
            
            let area1 = dims1[0] * dims1[1]
            let area2 = dims2[0] * dims2[1]
            
            return abs(area1 - targetArea) < abs(area2 - targetArea)
        } ?? sizes[0]
    }
    
    private func clamp(_ value: Int, min: Int, max: Int) -> Int {
        return Swift.max(min, Swift.min(max, value))
    }
}

// Supporting types
enum ModelIssue {
    case unsupportedSize(String)
    case unsupportedFeature(String)
    case tooManyImages(Int)
    case organizationNotVerified
    case quotaExceeded
    case promptTooComplex
    case compressionError(Int)
    case outputFormatError(String)
    case unknown(String)
}

enum ModelErrorRecovery {
    case switchModel(to: String, reason: String)
    case modifyRequest(changes: [RequestChange], reason: String)
    case retry(with: RetryApproach, reason: String)
    case fallbackStrategy(String)
    case fallbackWithDegradation(features: [DegradationOption], reason: String)
    
    var description: String {
        switch self {
        case .switchModel(let model, let reason):
            return "Switch to \(model): \(reason)"
        case .modifyRequest(let changes, let reason):
            return "Modify request: \(reason)\nChanges: \(changes)"
        case .retry(let approach, let reason):
            return "Retry with \(approach): \(reason)"
        case .fallbackStrategy(let strategy):
            return "Fallback: \(strategy)"
        case .fallbackWithDegradation(let features, let reason):
            return "Degrade features: \(reason)\nOptions: \(features)"
        }
    }
}

enum RequestChange {
    case size(String)
    case n(Int)
    case quality(String)
    case style(String)
    case outputCompression(Int)
    case outputFormat(String)
    case removeParameter(String)
    case simplifyPrompt
}

enum RetryApproach {
    case sameParameters
    case adjustedParameters
    case simplifiedPrompt
}

enum DegradationOption {
    case removeTransparency
    case lowerQuality
    case smallerSize
    case removeCompression
}