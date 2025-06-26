// AdvancedFeatures.swift
import Foundation
import OpenAIKit

/// Advanced features unique to gpt-image-1
class AdvancedImageGenerator {
    private let openAI: OpenAIKit
    
    init(apiKey: String) {
        self.openAI = OpenAIKit(apiKey: apiKey)
    }
    
    /// Generate image with transparent background
    func generateTransparentImage(
        subject: String,
        style: String = "photorealistic",
        size: String = "1024x1024"
    ) async throws -> TransparentImageResult {
        
        // Craft prompt for transparent background
        let prompt = craftTransparentPrompt(subject: subject, style: style)
        
        let request = ImageGenerationRequest(
            prompt: prompt,
            background: "transparent", // Key parameter for transparency
            model: Models.Images.gptImage1,
            outputFormat: "png", // PNG supports transparency
            quality: "hd",
            responseFormat: .b64Json, // Get full data for processing
            size: size
        )
        
        let response = try await openAI.images.generations(request)
        
        guard let imageData = response.data.first,
              let base64 = imageData.b64Json else {
            throw AdvancedImageError.generationFailed
        }
        
        // Verify transparency in the image
        let hasTransparency = try verifyTransparency(base64Data: base64)
        
        return TransparentImageResult(
            base64Data: base64,
            hasTransparency: hasTransparency,
            revisedPrompt: imageData.revisedPrompt,
            usage: response.usage
        )
    }
    
    /// Craft optimal prompt for transparent backgrounds
    private func craftTransparentPrompt(subject: String, style: String) -> String {
        """
        \(subject), isolated on transparent background, \
        no background elements, clean edges, \
        \(style) style, studio lighting, \
        professional product photography
        """
    }
    
    /// Verify if image actually has transparency
    private func verifyTransparency(base64Data: String) throws -> Bool {
        guard let data = Data(base64Encoded: base64Data) else {
            throw AdvancedImageError.invalidImageData
        }
        
        // Check PNG signature and look for alpha channel
        guard data.count > 8 else { return false }
        
        // PNG signature
        let pngSignature: [UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
        let headerData = data.prefix(8)
        
        guard headerData.elementsEqual(pngSignature) else {
            return false // Not a PNG
        }
        
        // Look for IHDR chunk to check color type
        // Color type 4 (grayscale + alpha) or 6 (truecolor + alpha) indicates transparency
        var offset = 8
        while offset < data.count - 12 {
            let chunkData = data[offset..<offset+12]
            let chunkType = String(data: chunkData[4..<8], encoding: .ascii)
            
            if chunkType == "IHDR" && data.count > offset + 25 {
                let colorType = data[offset + 25]
                return colorType == 4 || colorType == 6
            }
            
            // Move to next chunk
            let chunkLength = chunkData.prefix(4).withUnsafeBytes { 
                $0.load(as: UInt32.self).bigEndian 
            }
            offset += Int(chunkLength) + 12
        }
        
        return false
    }
    
    /// Generate multiple product images with transparent backgrounds
    func generateProductCatalog(
        products: [ProductDescription],
        options: CatalogOptions = CatalogOptions()
    ) async throws -> [CatalogItem] {
        
        var catalogItems: [CatalogItem] = []
        
        for product in products {
            do {
                let result = try await generateTransparentImage(
                    subject: product.description,
                    style: options.style,
                    size: options.size
                )
                
                let item = CatalogItem(
                    productId: product.id,
                    productName: product.name,
                    imageData: result.base64Data,
                    hasTransparency: result.hasTransparency,
                    generatedPrompt: result.revisedPrompt ?? product.description,
                    tokenUsage: result.usage
                )
                
                catalogItems.append(item)
                
                // Rate limiting
                if product != products.last {
                    try await Task.sleep(nanoseconds: UInt64(options.delayBetweenRequests * 1_000_000_000))
                }
                
            } catch {
                print("Failed to generate image for \(product.name): \(error)")
                if options.stopOnError {
                    throw error
                }
            }
        }
        
        return catalogItems
    }
}

/// Result of transparent image generation
struct TransparentImageResult {
    let base64Data: String
    let hasTransparency: Bool
    let revisedPrompt: String?
    let usage: ImageUsage?
}

/// Product description for catalog generation
struct ProductDescription {
    let id: String
    let name: String
    let description: String
}

/// Options for catalog generation
struct CatalogOptions {
    var style: String = "photorealistic"
    var size: String = "1024x1024"
    var delayBetweenRequests: TimeInterval = 1.0
    var stopOnError: Bool = false
}

/// Generated catalog item
struct CatalogItem {
    let productId: String
    let productName: String
    let imageData: String
    let hasTransparency: Bool
    let generatedPrompt: String
    let tokenUsage: ImageUsage?
}

enum AdvancedImageError: LocalizedError {
    case generationFailed
    case invalidImageData
    case transparencyNotSupported
    
    var errorDescription: String? {
        switch self {
        case .generationFailed:
            return "Failed to generate image"
        case .invalidImageData:
            return "Invalid image data received"
        case .transparencyNotSupported:
            return "Generated image does not have transparency"
        }
    }
}