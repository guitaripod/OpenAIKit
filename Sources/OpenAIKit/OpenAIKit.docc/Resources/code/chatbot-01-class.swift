// CompleteChatbot.swift
import Foundation
import OpenAIKit

class CompleteChatbot: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false
    @Published var currentPersona: Persona = .helpful
    @Published var context = ConversationContext()
    
    private let openAI: OpenAIKit
    private let contextManager = ContextManager()
    private let analytics = ConversationAnalytics()
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
    }
    
    func sendMessage(_ content: String) async throws -> String {
        contextManager.updateContext(from: content, role: .user)
        context = contextManager.currentContext
        
        messages.append(ChatMessage(role: .user, content: content))
        analytics.trackMessage(role: .user, content: content, context: context)
        
        isTyping = true
        defer { isTyping = false }
        
        let request = ChatCompletionRequest(
            messages: messages,
            model: "gpt-4o-mini",
            temperature: currentPersona.temperature
        )
        
        let response = try await openAI.chat.completions(request)
        guard let assistantContent = response.choices.first?.message.content else {
            throw ChatError.noContent
        }
        
        messages.append(ChatMessage(role: .assistant, content: assistantContent))
        analytics.trackMessage(role: .assistant, content: assistantContent, context: context)
        
        return assistantContent
    }
}
