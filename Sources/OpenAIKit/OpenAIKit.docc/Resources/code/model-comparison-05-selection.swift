// ModelComparison.swift
import Foundation
import OpenAIKit

/// Helps developers choose the right image generation model for their needs
struct ImageModelComparison {
    
    enum ImageModel: String, CaseIterable {
        case dalle2 = "DALL-E 2"
        case dalle3 = "DALL-E 3"
        case gptImage1 = "GPT-Image-1"
        
        var modelIdentifier: String {
            switch self {
            case .dalle2: return Models.Images.dallE2
            case .dalle3: return Models.Images.dallE3
            case .gptImage1: return Models.Images.gptImage1
            }
        }
    }
    
    struct ModelCapabilities {
        let model: ImageModel
        let supportedSizes: [String]
        let maxImagesPerRequest: Int
        let supportsQualitySettings: Bool
        let supportsStyleSettings: Bool
        let supportsTransparency: Bool
        let supportsCompression: Bool
        let supportsTokenTracking: Bool
        let averageGenerationTime: TimeInterval
        let costPerImage: String
    }
    
    static let dalle2Capabilities = ModelCapabilities(
        model: .dalle2,
        supportedSizes: ["256x256", "512x512", "1024x1024"],
        maxImagesPerRequest: 10,
        supportsQualitySettings: false,
        supportsStyleSettings: false,
        supportsTransparency: false,
        supportsCompression: false,
        supportsTokenTracking: false,
        averageGenerationTime: 3.0,
        costPerImage: "$0.016-$0.020"
    )
    
    static let dalle3Capabilities = ModelCapabilities(
        model: .dalle3,
        supportedSizes: ["1024x1024", "1024x1792", "1792x1024"],
        maxImagesPerRequest: 1,
        supportsQualitySettings: true,
        supportsStyleSettings: true,
        supportsTransparency: false,
        supportsCompression: false,
        supportsTokenTracking: false,
        averageGenerationTime: 7.0,
        costPerImage: "$0.040-$0.120"
    )
    
    static let gptImage1Capabilities = ModelCapabilities(
        model: .gptImage1,
        supportedSizes: ["256x256", "512x512", "1024x1024", "2048x2048", "4096x4096"],
        maxImagesPerRequest: 1,
        supportsQualitySettings: true,
        supportsStyleSettings: true,
        supportsTransparency: true,
        supportsCompression: true,
        supportsTokenTracking: true,
        averageGenerationTime: 10.0,
        costPerImage: "Token-based"
    )
    
    static let allCapabilities = [
        dalle2Capabilities,
        dalle3Capabilities,
        gptImage1Capabilities
    ]
    
    /// Recommends the best model based on requirements
    static func recommendModel(
        needsTransparency: Bool = false,
        needsMultipleImages: Bool = false,
        preferredQuality: ImageQuality = .standard,
        budget: Budget = .moderate,
        size: String? = nil
    ) -> ImageModel {
        
        // Transparent backgrounds are only supported by gpt-image-1
        if needsTransparency {
            return .gptImage1
        }
        
        // Multiple images per request only supported by DALL-E 2
        if needsMultipleImages {
            return .dalle2
        }
        
        // For highest quality or specific styles, use DALL-E 3 or gpt-image-1
        if preferredQuality == .premium {
            return budget == .premium ? .gptImage1 : .dalle3
        }
        
        // For landscape/portrait orientations, DALL-E 3 is optimal
        if let requestedSize = size,
           ["1024x1792", "1792x1024"].contains(requestedSize) {
            return .dalle3
        }
        
        // For cost-sensitive applications, use DALL-E 2
        if budget == .minimal {
            return .dalle2
        }
        
        // Default recommendation: DALL-E 3 for balance of quality and features
        return .dalle3
    }
    
    enum ImageQuality {
        case standard, premium
    }
    
    enum Budget {
        case minimal, moderate, premium
    }
}