// ImageGenerator.swift
import Foundation
import OpenAIKit

extension ImageGenerator {
    
    /// Handle different response types with model-specific features
    func processImageResponse(
        _ response: ImageResponse,
        model: String,
        startTime: Date
    ) throws -> [ProcessedImage] {
        
        var processedImages: [ProcessedImage] = []
        
        for imageData in response.data {
            let processed = try processImage(
                imageData,
                model: model,
                usage: response.usage
            )
            processedImages.append(processed)
        }
        
        // Log model-specific information
        logGenerationDetails(
            model: model,
            imageCount: processedImages.count,
            usage: response.usage,
            duration: Date().timeIntervalSince(startTime)
        )
        
        return processedImages
    }
    
    /// Process individual image with enhanced metadata
    private func processImage(
        _ imageData: ImageObject,
        model: String,
        usage: ImageUsage?
    ) throws -> ProcessedImage {
        
        var metadata = ImageMetadata(model: model)
        
        // Handle revised prompt (DALL-E 3 feature)
        if let revisedPrompt = imageData.revisedPrompt {
            metadata.revisedPrompt = revisedPrompt
            metadata.promptWasRevised = true
        }
        
        // Extract image location
        if let url = imageData.url {
            metadata.location = .url(url)
        } else if let base64 = imageData.b64Json {
            metadata.location = .base64(base64)
        } else {
            throw ImageGenerationError.noImageData
        }
        
        // Add token usage for gpt-image-1
        if model == Models.Images.gptImage1, let usage = usage {
            metadata.tokenUsage = TokenUsageInfo(
                total: usage.totalTokens ?? 0,
                input: usage.inputTokens ?? 0,
                output: usage.outputTokens ?? 0,
                textTokens: usage.inputTokensDetails?.textTokens ?? 0,
                imageTokens: usage.inputTokensDetails?.imageTokens ?? 0
            )
        }
        
        return ProcessedImage(
            id: UUID().uuidString,
            metadata: metadata,
            generatedAt: Date()
        )
    }
    
    /// Log generation details for analytics
    private func logGenerationDetails(
        model: String,
        imageCount: Int,
        usage: ImageUsage?,
        duration: TimeInterval
    ) {
        print("=== Image Generation Complete ===")
        print("Model: \(model)")
        print("Images Generated: \(imageCount)")
        print("Duration: \(String(format: "%.2f", duration))s")
        
        if let usage = usage {
            print("Token Usage:")
            if let total = usage.totalTokens {
                print("  Total: \(total)")
            }
            if let input = usage.inputTokens {
                print("  Input: \(input)")
            }
            if let output = usage.outputTokens {
                print("  Output: \(output)")
            }
            if let details = usage.inputTokensDetails {
                if let text = details.textTokens {
                    print("  Text Tokens: \(text)")
                }
                if let image = details.imageTokens {
                    print("  Image Tokens: \(image)")
                }
            }
        }
        print("================================")
    }
}

/// Processed image with full metadata
struct ProcessedImage {
    let id: String
    let metadata: ImageMetadata
    let generatedAt: Date
}

/// Image metadata including model-specific features
struct ImageMetadata {
    let model: String
    var location: ImageLocation?
    var revisedPrompt: String?
    var promptWasRevised: Bool = false
    var tokenUsage: TokenUsageInfo?
    
    enum ImageLocation {
        case url(String)
        case base64(String)
    }
}

/// Token usage information for billing
struct TokenUsageInfo {
    let total: Int
    let input: Int
    let output: Int
    let textTokens: Int
    let imageTokens: Int
    
    var estimatedCost: Double {
        // Rough estimation - adjust based on current pricing
        let costPerThousandTokens = 0.002
        return Double(total) / 1000.0 * costPerThousandTokens
    }
}

extension ImageGenerationError {
    static let noImageData = ImageGenerationError.custom("No image data in response")