// ErrorHandling.swift
import Foundation
import OpenAIKit

func sendChatMessage(_ message: String) async throws -> String {
    let openAI = OpenAIManager.shared.client!
    
    let request = ChatCompletionRequest(
        messages: [ChatMessage(role: .user, content: message)],
        model: "gpt-4o-mini"
    )
    
    let response = try await openAI.chat.completions(request)
    return response.choices.first?.message.content ?? ""
}