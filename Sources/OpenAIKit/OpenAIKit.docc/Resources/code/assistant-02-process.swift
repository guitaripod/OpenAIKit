// WeatherAssistant.swift
import Foundation
import OpenAIKit

class WeatherAssistant {
    let openAI: OpenAIKit
    let weatherService = WeatherService.shared
    var messages: [ChatMessage] = []
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
        
        messages.append(ChatMessage(
            role: .system,
            content: "You are a helpful weather assistant. When users ask about weather, use the get_weather function to provide accurate information."
        ))
    }
    
    func processMessage(_ userMessage: String) async throws -> String {
        // Add user message
        messages.append(ChatMessage(role: .user, content: userMessage))
        
        // Create request with function
        let request = ChatCompletionRequest(
            messages: messages,
            model: "gpt-4o-mini",
            tools: [
                Tool(type: .function, function: getWeatherFunction)
            ]
        )
        
        // Get response
        let response = try await openAI.chat.completions(request)
        
        // Process response
        return ""
    }
}