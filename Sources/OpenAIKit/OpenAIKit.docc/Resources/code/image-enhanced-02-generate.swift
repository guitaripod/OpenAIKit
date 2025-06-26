// ImageGenerator.swift
import Foundation
import OpenAIKit

/// Enhanced image generator supporting all three OpenAI image models
class ImageGenerator {
    private let openAI: OpenAIKit
    private(set) var generationStats = GenerationStats()
    
    struct GenerationStats {
        var totalRequests = 0
        var successfulGenerations = 0
        var failedGenerations = 0
        var totalTokensUsed = 0
        var averageGenerationTime: TimeInterval = 0
    }
    
    init(apiKey: String) {
        self.openAI = OpenAIKit(apiKey: apiKey)
    }
    
    /// Generate an image using the specified model with type-safe constants
    func generateImage(
        prompt: String,
        model: String = Models.Images.dallE3,
        options: ImageOptions = ImageOptions()
    ) async throws -> GeneratedImage {
        
        let startTime = Date()
        generationStats.totalRequests += 1
        
        do {
            let result = try await performGeneration(
                prompt: prompt,
                model: model,
                options: options
            )
            
            generationStats.successfulGenerations += 1
            updateAverageTime(Date().timeIntervalSince(startTime))
            
            return result
        } catch {
            generationStats.failedGenerations += 1
            throw error
        }
    }
    
    /// Perform the actual generation with model-specific parameters
    private func performGeneration(
        prompt: String,
        model: String,
        options: ImageOptions
    ) async throws -> GeneratedImage {
        
        let request = buildRequest(
            prompt: prompt,
            model: model,
            options: options
        )
        
        let startTime = Date()
        let response = try await openAI.images.generations(request)
        let generationTime = Date().timeIntervalSince(startTime)
        
        guard let imageData = response.data.first else {
            throw ImageGenerationError.noImageGenerated
        }
        
        // Update token usage if available (gpt-image-1)
        if let usage = response.usage {
            generationStats.totalTokensUsed += usage.totalTokens ?? 0
        }
        
        return GeneratedImage(
            url: imageData.url,
            base64Data: imageData.b64Json,
            revisedPrompt: imageData.revisedPrompt,
            model: model,
            usage: response.usage,
            generationTime: generationTime
        )
    }
    
    /// Build request with model-specific parameters
    private func buildRequest(
        prompt: String,
        model: String,
        options: ImageOptions
    ) -> ImageGenerationRequest {
        
        // Validate parameters based on model
        let validatedOptions = validateOptions(options, for: model)
        
        return ImageGenerationRequest(
            prompt: prompt,
            background: validatedOptions.background,
            model: model,
            n: validatedOptions.n,
            outputCompression: validatedOptions.outputCompression,
            outputFormat: validatedOptions.outputFormat,
            quality: validatedOptions.quality,
            responseFormat: validatedOptions.responseFormat,
            size: validatedOptions.size,
            style: validatedOptions.style,
            user: validatedOptions.user
        )
    }
    
    /// Validate and adjust options based on model capabilities
    private func validateOptions(_ options: ImageOptions, for model: String) -> ImageOptions {
        var validated = options
        
        switch model {
        case Models.Images.dallE2:
            // DALL-E 2 doesn't support quality or style
            validated.quality = nil
            validated.style = nil
            validated.background = nil
            validated.outputCompression = nil
            validated.outputFormat = nil
            // Ensure size is valid for DALL-E 2
            if !["256x256", "512x512", "1024x1024"].contains(options.size) {
                validated.size = "1024x1024"
            }
            
        case Models.Images.dallE3:
            // DALL-E 3 only supports n=1
            validated.n = 1
            validated.background = nil
            validated.outputCompression = nil
            validated.outputFormat = nil
            // Ensure size is valid for DALL-E 3
            if !["1024x1024", "1024x1792", "1792x1024"].contains(options.size) {
                validated.size = "1024x1024"
            }
            
        case Models.Images.gptImage1:
            // gpt-image-1 supports all features
            validated.n = 1 // Currently limited to 1
            
        default:
            break
        }
        
        return validated
    }
    
    private func updateAverageTime(_ newTime: TimeInterval) {
        let totalTime = generationStats.averageGenerationTime * 
            Double(generationStats.successfulGenerations - 1) + newTime
        generationStats.averageGenerationTime = totalTime / 
            Double(generationStats.successfulGenerations)
    }
}

enum ImageGenerationError: LocalizedError {
    case noImageGenerated
    case invalidModel
    case unsupportedFeature(feature: String, model: String)
    
    var errorDescription: String? {
        switch self {
        case .noImageGenerated:
            return "No image was generated from the request"
        case .invalidModel:
            return "Invalid image generation model specified"
        case .unsupportedFeature(let feature, let model):
            return "\(feature) is not supported by \(model)"
        }
    }
}