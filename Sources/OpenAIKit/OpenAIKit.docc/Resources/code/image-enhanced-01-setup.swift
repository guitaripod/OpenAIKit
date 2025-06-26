// ImageGenerator.swift
import Foundation
import OpenAIKit

/// Enhanced image generator supporting all three OpenAI image models
class ImageGenerator {
    private let openAI: OpenAIKit
    
    /// Track generation metrics
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
    
    private func updateAverageTime(_ newTime: TimeInterval) {
        let totalTime = generationStats.averageGenerationTime * 
            Double(generationStats.successfulGenerations - 1) + newTime
        generationStats.averageGenerationTime = totalTime / 
            Double(generationStats.successfulGenerations)
    }
}

/// Options for image generation
struct ImageOptions {
    var size: String = "1024x1024"
    var quality: String = "standard"
    var style: String = "vivid"
    var n: Int = 1
    var responseFormat: ImageResponseFormat = .url
    var user: String? = nil
    
    // gpt-image-1 specific options
    var background: String? = nil
    var outputCompression: Int? = nil
    var outputFormat: String? = nil
}

/// Result of image generation
struct GeneratedImage {
    let url: String?
    let base64Data: String?
    let revisedPrompt: String?
    let model: String
    let usage: ImageUsage?
    let generationTime: TimeInterval
}