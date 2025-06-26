// MemoryRetrieval.swift
import Foundation
import OpenAIKit

class ConversationWithMemory: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var relevantMemories: [MemoryItem] = []
    
    private let openAI: OpenAIKit
    private let memory: SemanticMemory
    private let maxMemoriesToInclude = 3
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
        self.memory = SemanticMemory(openAI: openAI)
    }
    
    func sendMessage(_ content: String) async throws -> String {
        // Search for relevant memories
        relevantMemories = await memory.search(query: content)
        
        // Build context with memories
        var contextMessages: [ChatMessage] = []
        
        // Add system prompt with memories
        if !relevantMemories.isEmpty {
            let memoryContext = relevantMemories
                .prefix(maxMemoriesToInclude)
                .map { "- \($0.value)" }
                .joined(separator: "\n")
            
            contextMessages.append(ChatMessage(
                role: .system,
                content: "Relevant context from previous conversations:\n\(memoryContext)"
            ))
        }
        
        // Add conversation history
        contextMessages.append(contentsOf: messages.suffix(10))
        
        // Add user message
        let userMessage = ChatMessage(role: .user, content: content)
        contextMessages.append(userMessage)
        messages.append(userMessage)
        
        // Get response
        let request = ChatCompletionRequest(
            messages: contextMessages,
            model: "gpt-4o-mini"
        )
        
        let response = try await openAI.chat.completions(request)
        guard let assistantContent = response.choices.first?.message.content else {
            throw ChatError.noContent
        }
        
        // Store exchange in memory
        await storeExchangeInMemory(userContent: content, assistantContent: assistantContent)
        
        // Add assistant message
        let assistantMessage = ChatMessage(role: .assistant, content: assistantContent)
        messages.append(assistantMessage)
        
        return assistantContent
    }
    
    private func storeExchangeInMemory(userContent: String, assistantContent: String) async {
        // Extract key information from the exchange
        let exchangeSummary = "User asked about: \(userContent). Assistant responded: \(assistantContent)"
        
        // Generate a key based on the main topic
        let key = extractKey(from: userContent)
        
        await memory.store(key: key, value: exchangeSummary)
    }
    
    private func extractKey(from text: String) -> String {
        // Simple key extraction - in practice, use NLP
        let words = text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 }
        
        return words.prefix(3).joined(separator: "_").lowercased()
    }
}