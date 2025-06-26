// ChatExample.swift
import Foundation
import OpenAIKit

class ChatExample: ObservableObject {
    let openAI = OpenAIManager.shared.client
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func sendMessage(_ message: String) async throws -> String {
        guard let openAI = openAI else { 
            throw OpenAIError.missingAPIKey 
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let chatMessage = ChatMessage(role: .user, content: message)
        
        let request = ChatCompletionRequest(
            messages: [chatMessage],
            model: Models.Chat.gpt4oMini
        )
        
        do {
            let response = try await openAI.chat.completions(request)
            return response.choices.first?.message.content ?? "No response"
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
}