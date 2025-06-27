// ResearchAssistant.swift
import Foundation
import OpenAIKit

/// A comprehensive research assistant that leverages DeepResearch capabilities
class ResearchAssistant {
    let openAI: OpenAIKit
    
    init(apiKey: String) {
        // Configure with extended timeout for DeepResearch
        let config = Configuration(
            apiKey: apiKey,
            timeoutInterval: 1800  // 30 minutes for DeepResearch
        )
        self.openAI = OpenAIKit(configuration: config)
    }
    
    /// Performs deep research on a given topic using the Responses API
    func performResearch(topic: String) async throws -> String {
        // Create a DeepResearch request with web search capability
        let request = ResponseRequest(
            input: "Research the following topic: \(topic)",
            model: Models.DeepResearch.o4MiniDeepResearch,
            tools: [.webSearchPreview(WebSearchPreviewTool())],
            maxOutputTokens: 10000  // High limit for comprehensive research
        )
        
        let response = try await openAI.responses.create(request)
        
        // Extract message content from output items
        var content = ""
        if let output = response.output {
            for item in output where item.type == "message" {
                content += item.content?.text ?? ""
            }
        }
        
        return content.isEmpty ? "Research incomplete - increase token limit" : content
    }
}