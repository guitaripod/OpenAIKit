// ChatExample.swift
import Foundation
import OpenAIKit

class ChatExample {
    let openAI = OpenAIManager.shared.client
    
    func sendMessage(_ message: String) async throws -> String {
        let chatMessage = ChatMessage(role: .user, content: message)
        
        let request = ChatCompletionRequest(
            messages: [chatMessage],
            model: Models.Chat.gpt4oMini
        )
        
        // Send request
        return ""
    }
}