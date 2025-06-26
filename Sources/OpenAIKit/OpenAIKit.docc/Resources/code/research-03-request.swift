// ResearchAssistant.swift
import Foundation
import OpenAIKit

/// A comprehensive research assistant that leverages DeepResearch capabilities
class ResearchAssistant {
    let openAI: OpenAIKit
    
    init(apiKey: String) {
        self.openAI = OpenAIKit(apiKey: apiKey)
    }
    
    /// Performs deep research on a given topic
    func performResearch(topic: String) async throws -> String {
        let request = ChatRequest(
            model: .gpt4o,
            messages: [
                .user(content: "Research the following topic: \(topic)")
            ]
        )
        
        let response = try await openAI.chat.completions(request: request)
        return response.choices.first?.message.content ?? ""
    }
}