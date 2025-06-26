// ChatExample.swift
import Foundation
import OpenAIKit

class ChatExample {
    let openAI = OpenAIManager.shared.client
    
    func sendMessage(_ message: String) async throws -> String {
        guard let openAI = openAI else { 
            throw OpenAIError.missingAPIKey 
        }
        
        let chatMessage = ChatMessage(role: .user, content: message)
        
        let request = ChatCompletionRequest(
            messages: [chatMessage],
            model: Models.Chat.gpt4oMini
        )
        
        let response = try await openAI.chat.completions(request)
        
        return response.choices.first?.message.content ?? "No response"
    }
}