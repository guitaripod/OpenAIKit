// ConversationManager.swift - Token counting
import Foundation
import OpenAIKit

class ConversationManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var conversationId = UUID()
    @Published var estimatedTokens = 0
    
    private let maxTokens = 4000 // Leave room for response
    private let tokenEstimator = TokenEstimator()
    
    init(systemPrompt: String? = nil) {
        if let prompt = systemPrompt {
            messages.append(ChatMessage(role: .system, content: prompt))
            updateTokenCount()
        }
    }
    
    func addUserMessage(_ content: String) {
        messages.append(ChatMessage(role: .user, content: content))
        updateTokenCount()
        trimToTokenLimit()
    }
    
    func addAssistantMessage(_ content: String) {
        messages.append(ChatMessage(role: .assistant, content: content))
        updateTokenCount()
        trimToTokenLimit()
    }
    
    private func updateTokenCount() {
        estimatedTokens = messages.reduce(0) { total, message in
            total + tokenEstimator.estimate(message.content) + 4 // Role tokens
        }
    }
    
    private func trimToTokenLimit() {
        guard estimatedTokens > maxTokens else { return }
        
        // Keep system message and trim from the middle
        let systemMessage = messages.first { $0.role == .system }
        var trimmedMessages: [ChatMessage] = []
        
        if let system = systemMessage {
            trimmedMessages.append(system)
        }
        
        // Keep most recent messages that fit
        var currentTokens = systemMessage != nil ? tokenEstimator.estimate(systemMessage!.content) : 0
        
        for message in messages.reversed() {
            let messageTokens = tokenEstimator.estimate(message.content) + 4
            if currentTokens + messageTokens < maxTokens {
                trimmedMessages.insert(message, at: trimmedMessages.count)
                currentTokens += messageTokens
            } else {
                break
            }
        }
        
        messages = trimmedMessages
        updateTokenCount()
    }
}

// Simple token estimator (rough approximation)
struct TokenEstimator {
    func estimate(_ text: String) -> Int {
        // Rough estimate: ~4 characters per token
        let words = text.split(separator: " ").count
        return max(1, words * 4 / 3)
    }
}