// ImageQualityOptions.swift
import Foundation
import OpenAIKit

struct ImageGenerationOptions {
    let size: ImageSize
    let quality: ImageQuality
    let style: ImageStyle
    
    static let standard = ImageGenerationOptions(
        size: .size1024x1024,
        quality: .standard,
        style: .natural
    )
    
    static let highQuality = ImageGenerationOptions(
        size: .size1024x1024,
        quality: .hd,
        style: .natural
    )
    
    static let vivid = ImageGenerationOptions(
        size: .size1024x1024,
        quality: .standard,
        style: .vivid
    )
    
    func createRequest(prompt: String) -> ImageGenerationRequest {
        ImageGenerationRequest(
            prompt: prompt,
            model: "dall-e-3",
            n: 1,
            quality: quality,
            responseFormat: .url,
            size: size,
            style: style,
            user: nil
        )
    }
}
