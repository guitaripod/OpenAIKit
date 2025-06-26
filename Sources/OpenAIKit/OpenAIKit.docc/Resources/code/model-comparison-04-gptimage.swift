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
        supportsTransparency: true,     // Unique feature!
        supportsCompression: true,      // Control output size
        supportsTokenTracking: true,    // Track usage for billing
        averageGenerationTime: 10.0,    // Higher quality takes time
        costPerImage: "Token-based"     // Varies by complexity
    )
    
    /// GPT-Image-1 Use Cases:
    /// - Photorealistic imagery
    /// - Product photography with transparent backgrounds
    /// - Complex scenes with multiple subjects
    /// - When you need fine control over output format
    /// - Enterprise applications with usage tracking
    /// - E-commerce and catalog imagery
    /// - Professional photography alternatives
    
    static let allCapabilities = [
        dalle2Capabilities,
        dalle3Capabilities,
        gptImage1Capabilities
    ]
}