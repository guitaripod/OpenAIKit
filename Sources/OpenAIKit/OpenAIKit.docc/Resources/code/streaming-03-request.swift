// StreamingChat.swift
import Foundation
import OpenAIKit

class StreamingChat {
    let openAI = OpenAIManager.shared.client
    
    func streamMessage(_ message: String) async throws {
        guard let openAI = openAI else {
            throw OpenAIError.missingAPIKey
        }
        
        let request = ChatCompletionRequest(
            messages: [
                ChatMessage(role: .user, content: message)
            ],
            model: "gpt-4o-mini",
            stream: true
        )
        
        // Stream will be handled next
    }
}
