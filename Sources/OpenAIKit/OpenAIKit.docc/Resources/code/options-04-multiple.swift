// MultipleImageGeneration.swift
import Foundation
import OpenAIKit

class BatchImageGenerator {
    let openAI: OpenAIKit
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
    }
    
    func generateVariations(
        prompt: String,
        count: Int,
        options: ImageGenerationOptions
    ) async throws -> [URL] {
        var urls: [URL] = []
        
        // DALL-E 3 only supports n=1, so we need multiple requests
        await withTaskGroup(of: URL?.self) { group in
            for i in 0..<count {
                group.addTask {
                    do {
                        let modifiedPrompt = "\(prompt), variation \(i + 1)"
                        let request = options.createRequest(prompt: modifiedPrompt)
                        let response = try await self.openAI.images.generations(request)
                        
                        if let urlString = response.data.first?.url,
                           let url = URL(string: urlString) {
                            return url
                        }
                    } catch {
                        print("Failed to generate image \(i + 1): \(error)")
                    }
                    return nil
                }
            }
            
            for await url in group {
                if let url = url {
                    urls.append(url)
                }
            }
        }
        
        return urls
    }
}
