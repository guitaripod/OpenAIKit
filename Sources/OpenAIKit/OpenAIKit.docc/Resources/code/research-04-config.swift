// ResearchAssistant.swift
import Foundation
import OpenAIKit

/// A comprehensive research assistant that leverages DeepResearch capabilities
class ResearchAssistant {
    let openAI: OpenAIKit
    
    /// Configuration for DeepResearch features
    struct ResearchConfig {
        let enableWebSearch: Bool
        let enableCodeInterpreter: Bool
        let maxSearchResults: Int
        
        static let `default` = ResearchConfig(
            enableWebSearch: true,
            enableCodeInterpreter: true,
            maxSearchResults: 10
        )
    }
    
    private var config: ResearchConfig
    
    init(apiKey: String, config: ResearchConfig = .default) {
        self.openAI = OpenAIKit(apiKey: apiKey)
        self.config = config
    }
    
    /// Performs deep research on a given topic
    func performResearch(topic: String) async throws -> String {
        var tools: [ChatRequest.Tool] = []
        
        if config.enableWebSearch {
            tools.append(.webSearchPreview)
        }
        
        if config.enableCodeInterpreter {
            tools.append(.codeInterpreter())
        }
        
        let request = ChatRequest(
            model: .gpt4o,
            messages: [
                .system(content: "You are a comprehensive research assistant. Provide thorough, well-researched responses with citations."),
                .user(content: "Research the following topic: \(topic)")
            ],
            tools: tools
        )
        
        let response = try await openAI.chat.completions(request: request)
        return response.choices.first?.message.content ?? ""
    }
}