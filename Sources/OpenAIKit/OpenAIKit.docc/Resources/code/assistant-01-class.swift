// WeatherAssistant.swift
import Foundation
import OpenAIKit

class WeatherAssistant {
    let openAI: OpenAIKit
    let weatherService = WeatherService.shared
    var messages: [ChatMessage] = []
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
        
        // Set system prompt
        messages.append(ChatMessage(
            role: .system,
            content: "You are a helpful weather assistant. When users ask about weather, use the get_weather function to provide accurate information."
        ))
    }
}