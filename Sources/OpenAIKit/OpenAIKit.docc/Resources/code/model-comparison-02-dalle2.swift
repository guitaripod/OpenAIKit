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
        averageGenerationTime: 3.0, // seconds
        costPerImage: "$0.016-$0.020" // varies by size
    )
    
    /// DALL-E 2 Use Cases:
    /// - Quick prototyping and iterations
    /// - Generating multiple variations quickly
    /// - Cost-sensitive applications
    /// - Simple illustrations and icons
    /// - When you need up to 10 images at once
}