// PersonaBehavior.swift
import Foundation
import OpenAIKit

class PersonaChat: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentPersona: Persona = .helpful
    
    private let openAI: OpenAIKit
    private let personaManager = PersonaManager()
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
        updateSystemPrompt()
    }
    
    func switchPersona(to persona: Persona) {
        currentPersona = persona
        messages.removeAll()
        updateSystemPrompt()
    }
    
    private func updateSystemPrompt() {
        let systemPrompt = personaManager.buildSystemPrompt(for: currentPersona)
        messages = [ChatMessage(role: .system, content: systemPrompt)]
    }
    
    func sendMessage(_ content: String) async throws -> String {
        messages.append(ChatMessage(role: .user, content: content))
        
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
        return assistantContent
    }
}
