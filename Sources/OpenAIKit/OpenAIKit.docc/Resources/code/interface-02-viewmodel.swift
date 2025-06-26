// ChatViewModel.swift
import Foundation
import OpenAIKit

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    let content: String
    let timestamp = Date()
}

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let openAI = OpenAIManager.shared.client
    
    func sendMessage(_ content: String) {
        // Add user message
        messages.append(ChatMessage(role: .user, content: content))
        
        Task {
            await getResponse()
        }
    }
    
    @MainActor
    private func getResponse() async {
        isLoading = true
        defer { isLoading = false }
        
        // Implementation coming next
    }
}