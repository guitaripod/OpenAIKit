// ImageFormatOptions.swift
import Foundation
import OpenAIKit

class ImageFormatHandler {
    func generateWithFormat(
        prompt: String,
        format: ImageResponseFormat,
        client: OpenAIKit
    ) async throws -> ImageData {
        let request = ImageGenerationRequest(
            prompt: prompt,
            model: "dall-e-3",
            n: 1,
            quality: .standard,
            responseFormat: format,
            size: .size1024x1024,
            style: .natural,
            user: nil
        )
        
        let response = try await client.images.generations(request)
        
        guard let imageData = response.data.first else {
            throw ImageError.noImageGenerated
        }
        
        switch format {
        case .url:
            if let url = imageData.url {
                return .url(url)
            }
        case .b64Json:
            if let b64 = imageData.b64Json {
                return .base64(b64)
            }
        }
        
        throw ImageError.invalidFormat
    }
}

enum ImageData {
    case url(String)
    case base64(String)
    
    func toData() throws -> Data {
        switch self {
        case .url(let urlString):
            guard let url = URL(string: urlString) else {
                throw ImageError.invalidURL
            }
            return try Data(contentsOf: url)
        case .base64(let base64String):
            guard let data = Data(base64Encoded: base64String) else {
                throw ImageError.invalidBase64
            }
            return data
        }
    }
}

extension ImageError {
    static let invalidFormat = ImageError.noImageGenerated
    static let invalidURL = ImageError.downloadFailed
    static let invalidBase64 = ImageError.invalidImageData
}
