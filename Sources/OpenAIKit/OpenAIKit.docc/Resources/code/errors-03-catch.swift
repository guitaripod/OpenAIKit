// ErrorHandling.swift
import Foundation
import OpenAIKit

func sendChatMessage(_ message: String) async -> Result<String, Error> {
    let openAI = OpenAIManager.shared.client!
    
    let request = ChatCompletionRequest(
        messages: [ChatMessage(role: .user, content: message)],
        model: "gpt-4o-mini"
    )
    
    do {
        let response = try await openAI.chat.completions(request)
        let content = response.choices.first?.message.content ?? ""
        return .success(content)
    } catch {
        return .failure(error)
    }
}

// Usage
Task {
    let result = await sendChatMessage("Hello!")
    
    switch result {
    case .success(let response):
        print("Response: \(response)")
    case .failure(let error):
        print("Error: \(error)")
    }
}