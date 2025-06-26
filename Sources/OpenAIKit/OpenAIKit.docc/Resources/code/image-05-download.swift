// ImageGeneration.swift - Downloading generated images
import Foundation
import OpenAIKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

class ImageGenerator {
    let openAI = OpenAIManager.shared.client
    
    func generateImage(prompt: String) async throws -> URL {
        guard let openAI = openAI else {
            throw OpenAIError.missingAPIKey
        }
        
        let request = ImageGenerationRequest(
            prompt: prompt,
            model: Models.Images.dallE3,
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
    
    func downloadImage(from url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ImageError.downloadFailed
        }
        
        return data
    }
    
    #if canImport(UIKit)
    func generateAndDownloadImage(prompt: String) async throws -> UIImage {
        let url = try await generateImage(prompt: prompt)
        let data = try await downloadImage(from: url)
        
        guard let image = UIImage(data: data) else {
            throw ImageError.invalidImageData
        }
        
        return image
    }
    #elseif canImport(AppKit)
    func generateAndDownloadImage(prompt: String) async throws -> NSImage {
        let url = try await generateImage(prompt: prompt)
        let data = try await downloadImage(from: url)
        
        guard let image = NSImage(data: data) else {
            throw ImageError.invalidImageData
        }
        
        return image
    }
    #endif
}

extension ImageError {
    case downloadFailed
    case invalidImageData
}
