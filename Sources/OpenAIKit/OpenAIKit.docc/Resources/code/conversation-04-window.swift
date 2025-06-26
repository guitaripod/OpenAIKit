// ConversationManager.swift - Sliding window context
import Foundation
import OpenAIKit

class ConversationManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var conversationId = UUID()
    @Published var contextWindow: [ChatMessage] = []
    
    private let windowSize = 10 // Number of messages to keep in context
    private let systemPrompt: String?
    
    init(systemPrompt: String? = nil) {
        self.systemPrompt = systemPrompt
        if let prompt = systemPrompt {
            let systemMessage = ChatMessage(role: .system, content: prompt)
            messages.append(systemMessage)
            contextWindow.append(systemMessage)
        }
    }
    
    func addUserMessage(_ content: String) {
        let message = ChatMessage(role: .user, content: content)
        messages.append(message)
        updateContextWindow()
    }
    
    func addAssistantMessage(_ content: String) {
        let message = ChatMessage(role: .assistant, content: content)
        messages.append(message)
        updateContextWindow()
    }
    
    private func updateContextWindow() {
        contextWindow = []
        
        // Always include system prompt
        if let systemMessage = messages.first(where: { $0.role == .system }) {
            contextWindow.append(systemMessage)
        }
        
        // Add recent messages
        let recentMessages = messages.filter { $0.role != .system }.suffix(windowSize)
        contextWindow.append(contentsOf: recentMessages)
    }
    
    func getContextForRequest() -> [ChatMessage] {
        return contextWindow
    }
    
    func searchMessages(query: String) -> [ChatMessage] {
        messages.filter { message in
            message.content.localizedCaseInsensitiveContains(query)
        }
    }
    
    // Export conversation
    func exportConversation() -> String {
        messages.map { message in
            "\(message.role.rawValue.uppercased()): \(message.content)"
        }.joined(separator: "\n\n")
    }
}