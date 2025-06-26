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
        supportsQualitySettings: true, // standard, hd
        supportsStyleSettings: true,   // vivid, natural
        supportsTransparency: false,
        supportsCompression: false,
        supportsTokenTracking: false,
        averageGenerationTime: 7.0, // seconds (HD takes longer)
        costPerImage: "$0.040-$0.120" // varies by quality and size
    )
    
    /// DALL-E 3 Use Cases:
    /// - High-quality artwork and illustrations
    /// - Marketing materials and hero images
    /// - When prompt adherence is critical
    /// - Landscape and portrait orientations
    /// - Professional presentations
    /// - Creative projects requiring specific styles
}