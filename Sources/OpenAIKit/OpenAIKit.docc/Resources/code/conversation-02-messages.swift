// ConversationManager.swift - Message management
import Foundation
import OpenAIKit

class ConversationManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var conversationId = UUID()
    private let maxMessages = 50
    
    init(systemPrompt: String? = nil) {
        if let prompt = systemPrompt {
            messages.append(ChatMessage(role: .system, content: prompt))
        }
    }
    
    func addUserMessage(_ content: String) {
        messages.append(ChatMessage(role: .user, content: content))
        trimMessages()
    }
    
    func addAssistantMessage(_ content: String) {
        messages.append(ChatMessage(role: .assistant, content: content))
        trimMessages()
    }
    
    private func trimMessages() {
        // Keep system message + last N messages
        if messages.count > maxMessages {
            let systemMessage = messages.first { $0.role == .system }
            let recentMessages = messages.suffix(maxMessages - 1)
            
            messages = []
            if let system = systemMessage {
                messages.append(system)
            }
            messages.append(contentsOf: recentMessages)
        }
    }
    
    func clear() {
        let systemMessage = messages.first { $0.role == .system }
        messages = systemMessage != nil ? [systemMessage!] : []
        conversationId = UUID()
    }
}