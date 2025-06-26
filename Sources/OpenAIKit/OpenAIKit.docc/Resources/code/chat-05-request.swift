// ChatExample.swift
import Foundation
import OpenAIKit

class ChatExample {
    let openAI = OpenAIManager.shared.client
    
    func sendMessage(_ message: String) async throws -> String {
        let chatMessage = ChatMessage(role: .user, content: message)
        
        let request = ChatCompletionRequest(
            messages: [chatMessage],
            model: "gpt-4o-mini"
        )
        
        // Send request
        return ""
    }
}