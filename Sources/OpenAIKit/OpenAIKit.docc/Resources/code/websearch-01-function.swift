// websearch-01-function.swift
// Basic market research function setup

import Foundation
import OpenAIKit

/// Basic market research assistant setup
class MarketResearchAssistant {
    let openAI = OpenAIManager.shared.client
    
    /// Performs basic market research using web search
    func researchMarket(industry: String) async throws -> String {
        // Create a simple chat request with web search capability
        let request = ChatRequest(
            model: .gpt4o,
            messages: [
                .system(content: "You are a market research analyst. Use web search to find current market information."),
                .user(content: "Research the \(industry) industry. Find market size, growth trends, and key players.")
            ],
            temperature: 0.3,
            tools: [createWebSearchTool()]
        )
        
        // Execute the research request
        let response = try await openAI.chat.completions(request: request)
        
        // Return the raw response content
        return response.choices.first?.message.content ?? "No research data found"
    }
    
    /// Creates a basic web search tool definition
    private func createWebSearchTool() -> ChatRequest.Tool {
        return ChatRequest.Tool(
            type: .function,
            function: .init(
                name: "web_search",
                description: "Search the web for current market information",
                parameters: [
                    "query": [
                        "type": "string",
                        "description": "The search query for market research"
                    ]
                ]
            )
        )
    }
}

// MARK: - Usage Example

func performBasicMarketResearch() async throws {
    let assistant = MarketResearchAssistant()
    
    // Research a specific industry
    let research = try await assistant.researchMarket(industry: "electric vehicles")
    
    print("Market Research Results:")
    print(research)
}

// Example usage:
// Task {
//     try await performBasicMarketResearch()
// }