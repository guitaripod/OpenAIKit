// CompleteChatbot.swift - Integration
import Foundation
import OpenAIKit

extension CompleteChatbot {
    func sendMessage(_ content: String) async throws -> String {
        // Update context
        contextManager.updateContext(from: content, role: .user)
        context = contextManager.currentContext
        
        // Add user message
        messages.append(ChatMessage(role: .user, content: content))
        
        // Track analytics
        analytics.trackMessage(role: .user, content: content, context: context)
        
        // Build enhanced request
        let request = buildEnhancedRequest(userMessage: content)
        
        // Get response
        isTyping = true
        defer { isTyping = false }
        
        let response = try await openAI.chat.completions(request)
        guard let assistantContent = response.choices.first?.message.content else {
            throw ChatError.noContent
        }
        
        // Process response
        await processResponse(assistantContent, for: content)
        
        return assistantContent
    }
    
    private func buildEnhancedRequest(userMessage: String) -> ChatCompletionRequest {
        var contextMessages = messages
        
        // Add context-aware system messages based on state
        if context.intent == .greeting {
            contextMessages.insert(
                ChatMessage(role: .system, content: "The user is greeting you. Be friendly and welcoming."),
                at: 1
            )
        }
        
        return ChatCompletionRequest(
            messages: contextMessages,
            model: "gpt-4o-mini",
            temperature: currentPersona.temperature
        )
    }
    
    private func processResponse(_ response: String, for userMessage: String) async {
        messages.append(ChatMessage(role: .assistant, content: response))
        contextManager.updateContext(from: response, role: .assistant)
        analytics.trackMessage(role: .assistant, content: response, context: context)
    }
}
