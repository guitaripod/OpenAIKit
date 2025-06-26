// ImageGeneration.swift
import Foundation
import OpenAIKit

class ImageGenerator {
    let openAI = OpenAIManager.shared.client
    
    func generateImage(prompt: String) async throws -> URL {
        guard let openAI = openAI else {
            throw OpenAIError.missingAPIKey
        }
        
        let request = ImageGenerationRequest(
            prompt: prompt,
            model: "dall-e-3",
            n: 1,
            quality: .standard,
            responseFormat: .url,
            size: .size1024x1024,
            style: .natural,
            user: nil
        )
        
        let response = try await openAI.images.generations(request)
        
        guard let imageData = response.data.first,
              let urlString = imageData.url,
              let url = URL(string: urlString) else {
            throw ImageError.noImageGenerated
        }
        
        return url
    }
}

enum ImageError: LocalizedError {
    case noImageGenerated
    
    var errorDescription: String? {
        switch self {
        case .noImageGenerated:
            return "No image was generated"
        }
    }
}
