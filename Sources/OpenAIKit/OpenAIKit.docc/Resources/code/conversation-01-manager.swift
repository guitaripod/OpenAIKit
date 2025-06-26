// ConversationManager.swift
import Foundation
import OpenAIKit

class ConversationManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var conversationId = UUID()
    
    init(systemPrompt: String? = nil) {
        if let prompt = systemPrompt {
            messages.append(ChatMessage(role: .system, content: prompt))
        }
    }
}