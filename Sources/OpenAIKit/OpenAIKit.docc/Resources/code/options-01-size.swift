// ImageSizeOptions.swift
import Foundation
import OpenAIKit

extension ImageGenerationRequest {
    static func withSize(_ size: ImageSize, prompt: String) -> ImageGenerationRequest {
        ImageGenerationRequest(
            prompt: prompt,
            model: "dall-e-3",
            n: 1,
            quality: .standard,
            responseFormat: .url,
            size: size,
            style: .natural,
            user: nil
        )
    }
}

enum ImageSizePreset {
    case square
    case landscape
    case portrait
    
    var size: ImageSize {
        switch self {
        case .square:
            return .size1024x1024
        case .landscape:
            return .size1792x1024
        case .portrait:
            return .size1024x1792
        }
    }
}
