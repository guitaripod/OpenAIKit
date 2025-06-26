// ChatViewModel.swift
import Foundation
import OpenAIKit

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let openAI = OpenAIManager.shared.client
    
    func sendMessage(_ content: String) {
        messages.append(ChatMessage(role: .user, content: content))
        
        Task {
            await getResponse()
        }
    }
    
    @MainActor
    private func getResponse() async {
        guard let openAI = openAI else {
            errorMessage = "OpenAI client not initialized"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let chatMessages = messages.map { message in
            ChatMessage(role: message.role, content: message.content)
        }
        
        let request = ChatCompletionRequest(
            messages: chatMessages,
            model: "gpt-4o-mini"
        )
        
        do {
            let response = try await openAI.chat.completions(request)
            if let content = response.choices.first?.message.content {
                messages.append(ChatMessage(role: .assistant, content: content))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}