import OpenAIKit
import Foundation

// MARK: - Image Variations Request

func createImageVariation(from imageData: Data) async throws -> [URL] {
    let openAI = OpenAIKit(apiKey: "your-api-key")
    
    // Create the variation request
    let variationRequest = ImageVariationRequest(
        image: imageData,
        n: 2,  // Generate 2 variations
        size: .size1024x1024
    )
    
    // Send the request
    let response = try await openAI.createImageVariation(request: variationRequest)
    
    // Extract URLs from the response
    let imageURLs = response.data.compactMap { imageData in
        guard case .url(let urlString) = imageData,
              let url = URL(string: urlString) else {
            return nil
        }
        return url
    }
    
    return imageURLs
}

// MARK: - Usage Example

struct ImageVariationGenerator {
    let openAI: OpenAIKit
    
    func generateVariations(from originalImage: UIImage, count: Int = 3) async throws -> [GeneratedVariation] {
        // Convert UIImage to PNG data
        guard let imageData = originalImage.pngData() else {
            throw ImageError.invalidImageData
        }
        
        // Ensure image size is within limits (max 4MB)
        let maxSize = 4 * 1024 * 1024 // 4MB
        guard imageData.count <= maxSize else {
            throw ImageError.imageTooLarge
        }
        
        // Create variation request
        let request = ImageVariationRequest(
            image: imageData,
            n: count,
            size: .size1024x1024,
            responseFormat: .url
        )
        
        // Get variations
        let response = try await openAI.createImageVariation(request: request)
        
        // Convert to our model
        return response.data.enumerated().compactMap { index, imageData in
            guard case .url(let urlString) = imageData,
                  let url = URL(string: urlString) else {
                return nil
            }
            
            return GeneratedVariation(
                id: UUID(),
                url: url,
                index: index,
                timestamp: Date()
            )
        }
    }
}

// MARK: - Models

struct GeneratedVariation: Identifiable {
    let id: UUID
    let url: URL
    let index: Int
    let timestamp: Date
}

enum ImageError: Error {
    case invalidImageData
    case imageTooLarge
    case processingFailed
}