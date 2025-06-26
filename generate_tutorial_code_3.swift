#!/usr/bin/env swift

import Foundation

let baseDir = "Sources/OpenAIKit/OpenAIKit.docc/Resources/code"

// Tutorial 5: Building Conversations
let conversationsCode = [
    "conversation-01-manager.swift": """
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
""",
    
    "conversation-02-messages.swift": """
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
""",
    
    "conversation-03-tokens.swift": """
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
""",
    
    "conversation-04-window.swift": """
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
            "\\(message.role.rawValue.uppercased()): \\(message.content)"
        }.joined(separator: "\\n\\n")
    }
}
""",
    
    "conversation-05-summary.swift": """
// ConversationManager.swift - With summarization
import Foundation
import OpenAIKit

class ConversationManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var conversationId = UUID()
    @Published var summary: String?
    @Published var isSummarizing = false
    
    private let openAI: OpenAIKit
    private let summarizationThreshold = 20 // Summarize after N messages
    
    init(openAI: OpenAIKit, systemPrompt: String? = nil) {
        self.openAI = openAI
        if let prompt = systemPrompt {
            messages.append(ChatMessage(role: .system, content: prompt))
        }
    }
    
    func addExchange(userMessage: String, assistantResponse: String) async {
        addUserMessage(userMessage)
        addAssistantMessage(assistantResponse)
        
        // Check if we need to summarize
        if shouldSummarize() {
            await summarizeConversation()
        }
    }
    
    private func addUserMessage(_ content: String) {
        messages.append(ChatMessage(role: .user, content: content))
    }
    
    private func addAssistantMessage(_ content: String) {
        messages.append(ChatMessage(role: .assistant, content: content))
    }
    
    private func shouldSummarize() -> Bool {
        let nonSystemMessages = messages.filter { $0.role != .system }
        return nonSystemMessages.count >= summarizationThreshold && summary == nil
    }
    
    @MainActor
    private func summarizeConversation() async {
        isSummarizing = true
        defer { isSummarizing = false }
        
        // Get messages to summarize (exclude system and very recent)
        let messagesToSummarize = messages
            .filter { $0.role != .system }
            .dropLast(4) // Keep last 2 exchanges verbatim
        
        guard !messagesToSummarize.isEmpty else { return }
        
        // Create summarization request
        let summaryPrompt = ChatMessage(
            role: .system,
            content: "Summarize the following conversation concisely, capturing key points and context:"
        )
        
        let conversationText = messagesToSummarize.map { message in
            "\\(message.role.rawValue): \\(message.content)"
        }.joined(separator: "\\n")
        
        let summaryRequest = ChatCompletionRequest(
            messages: [
                summaryPrompt,
                ChatMessage(role: .user, content: conversationText)
            ],
            model: "gpt-4o-mini",
            maxTokens: 150,
            temperature: 0.5
        )
        
        do {
            let response = try await openAI.chat.completions(summaryRequest)
            if let summaryContent = response.choices.first?.message.content {
                summary = summaryContent
                compactMessages()
            }
        } catch {
            print("Failed to summarize: \\(error)")
        }
    }
    
    private func compactMessages() {
        guard let summary = summary else { return }
        
        // Keep system message, summary, and recent messages
        var compactedMessages: [ChatMessage] = []
        
        if let systemMessage = messages.first(where: { $0.role == .system }) {
            compactedMessages.append(systemMessage)
        }
        
        // Add summary as a system message
        compactedMessages.append(ChatMessage(
            role: .system,
            content: "Previous conversation summary: \\(summary)"
        ))
        
        // Keep recent messages
        let recentMessages = messages.suffix(4)
        compactedMessages.append(contentsOf: recentMessages)
        
        messages = compactedMessages
    }
    
    func getContextForRequest() -> [ChatMessage] {
        return messages
    }
}
""",
    
    // Memory System section
    "memory-01-system.swift": """
// MemorySystem.swift
import Foundation

protocol MemoryStore {
    func store(key: String, value: Any) async
    func retrieve(key: String) async -> Any?
    func search(query: String) async -> [MemoryItem]
    func clear() async
}

struct MemoryItem: Identifiable {
    let id = UUID()
    let key: String
    let value: String
    let timestamp: Date
    let metadata: [String: Any]
    let relevanceScore: Double?
}

class SimpleMemoryStore: MemoryStore {
    private var memories: [String: MemoryItem] = [:]
    
    func store(key: String, value: Any) async {
        let item = MemoryItem(
            key: key,
            value: String(describing: value),
            timestamp: Date(),
            metadata: [:],
            relevanceScore: nil
        )
        memories[key] = item
    }
    
    func retrieve(key: String) async -> Any? {
        memories[key]?.value
    }
    
    func search(query: String) async -> [MemoryItem] {
        memories.values.filter { item in
            item.key.localizedCaseInsensitiveContains(query) ||
            item.value.localizedCaseInsensitiveContains(query)
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    func clear() async {
        memories.removeAll()
    }
}
""",
    
    "memory-02-semantic.swift": """
// SemanticMemory.swift
import Foundation
import OpenAIKit

class SemanticMemory: MemoryStore {
    private let openAI: OpenAIKit
    private var memories: [MemoryItem] = []
    private var embeddings: [UUID: [Float]] = [:]
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
    }
    
    func store(key: String, value: Any) async {
        let valueString = String(describing: value)
        
        // Generate embedding for the value
        let embedding = await generateEmbedding(for: valueString)
        
        let item = MemoryItem(
            key: key,
            value: valueString,
            timestamp: Date(),
            metadata: [:],
            relevanceScore: nil
        )
        
        memories.append(item)
        if let embedding = embedding {
            embeddings[item.id] = embedding
        }
    }
    
    func retrieve(key: String) async -> Any? {
        memories.first { $0.key == key }?.value
    }
    
    func search(query: String) async -> [MemoryItem] {
        // Generate embedding for query
        guard let queryEmbedding = await generateEmbedding(for: query) else {
            // Fallback to text search
            return memories.filter { item in
                item.key.localizedCaseInsensitiveContains(query) ||
                item.value.localizedCaseInsensitiveContains(query)
            }
        }
        
        // Calculate similarity scores
        let scoredMemories = memories.compactMap { item -> (MemoryItem, Double)? in
            guard let itemEmbedding = embeddings[item.id] else { return nil }
            let similarity = cosineSimilarity(queryEmbedding, itemEmbedding)
            return (item, similarity)
        }
        
        // Return top matches
        return scoredMemories
            .sorted { $0.1 > $1.1 }
            .prefix(10)
            .map { $0.0 }
    }
    
    func clear() async {
        memories.removeAll()
        embeddings.removeAll()
    }
    
    private func generateEmbedding(for text: String) async -> [Float]? {
        let request = EmbeddingRequest(
            input: text,
            model: "text-embedding-3-small"
        )
        
        do {
            let response = try await openAI.embeddings.create(request)
            if let embedding = response.data.first?.embedding {
                return embedding.floatValues ?? []
            }
        } catch {
            print("Failed to generate embedding: \\(error)")
        }
        
        return nil
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Double {
        guard a.count == b.count else { return 0 }
        
        var dotProduct: Float = 0
        var normA: Float = 0
        var normB: Float = 0
        
        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        
        guard normA > 0 && normB > 0 else { return 0 }
        return Double(dotProduct / (sqrt(normA) * sqrt(normB)))
    }
}
""",
    
    "memory-03-retrieval.swift": """
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
                .map { "- \\($0.value)" }
                .joined(separator: "\\n")
            
            contextMessages.append(ChatMessage(
                role: .system,
                content: "Relevant context from previous conversations:\\n\\(memoryContext)"
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
        let exchangeSummary = "User asked about: \\(userContent). Assistant responded: \\(assistantContent)"
        
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
""",
    
    "memory-04-persistence.swift": """
// PersistentMemory.swift
import Foundation
import CoreData

class PersistentMemoryStore: MemoryStore {
    private let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "ConversationMemory")
        
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data failed to load: \\(error)")
            }
        }
    }
    
    func store(key: String, value: Any) async {
        let context = container.viewContext
        
        await context.perform {
            let memory = MemoryEntity(context: context)
            memory.id = UUID()
            memory.key = key
            memory.value = String(describing: value)
            memory.timestamp = Date()
            memory.embedding = nil // Store embedding data if needed
            
            do {
                try context.save()
            } catch {
                print("Failed to save memory: \\(error)")
            }
        }
    }
    
    func retrieve(key: String) async -> Any? {
        let context = container.viewContext
        let request = MemoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "key == %@", key)
        request.fetchLimit = 1
        
        return await context.perform {
            do {
                let memories = try context.fetch(request)
                return memories.first?.value
            } catch {
                print("Failed to retrieve memory: \\(error)")
                return nil
            }
        }
    }
    
    func search(query: String) async -> [MemoryItem] {
        let context = container.viewContext
        let request = MemoryEntity.fetchRequest()
        
        // Search in both key and value
        request.predicate = NSPredicate(
            format: "key CONTAINS[cd] %@ OR value CONTAINS[cd] %@",
            query, query
        )
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = 20
        
        return await context.perform {
            do {
                let entities = try context.fetch(request)
                return entities.map { entity in
                    MemoryItem(
                        key: entity.key ?? "",
                        value: entity.value ?? "",
                        timestamp: entity.timestamp ?? Date(),
                        metadata: [:],
                        relevanceScore: nil
                    )
                }
            } catch {
                print("Failed to search memories: \\(error)")
                return []
            }
        }
    }
    
    func clear() async {
        let context = container.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MemoryEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        await context.perform {
            do {
                try context.execute(deleteRequest)
                try context.save()
            } catch {
                print("Failed to clear memories: \\(error)")
            }
        }
    }
}

// Core Data Model (create in .xcdatamodeld file)
/*
Entity: MemoryEntity
Attributes:
- id: UUID
- key: String
- value: String
- timestamp: Date
- embedding: Binary (optional)
- metadata: Binary (optional)
*/
""",
    
    // Personas section
    "persona-01-struct.swift": """
// Persona.swift
import Foundation

struct Persona: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let systemPrompt: String
    let temperature: Double
    let traits: [String]
    let knowledge: [String]
    let examples: [ConversationExample]
    
    static let helpful = Persona(
        name: "Helpful Assistant",
        description: "A friendly and helpful AI assistant",
        systemPrompt: "You are a helpful, friendly, and professional AI assistant. Provide clear and accurate information while being approachable.",
        temperature: 0.7,
        traits: ["friendly", "professional", "clear", "patient"],
        knowledge: [],
        examples: []
    )
    
    static let creative = Persona(
        name: "Creative Writer",
        description: "A creative and imaginative storyteller",
        systemPrompt: "You are a creative writer with a vivid imagination. Help users with creative writing, storytelling, and brainstorming ideas.",
        temperature: 0.9,
        traits: ["imaginative", "descriptive", "engaging", "original"],
        knowledge: ["literature", "storytelling techniques", "creative writing"],
        examples: []
    )
    
    static let technical = Persona(
        name: "Technical Expert",
        description: "A precise technical advisor",
        systemPrompt: "You are a technical expert who provides accurate, detailed technical information. Focus on precision and clarity.",
        temperature: 0.3,
        traits: ["precise", "analytical", "thorough", "logical"],
        knowledge: ["programming", "technology", "engineering", "mathematics"],
        examples: []
    )
}

struct ConversationExample: Codable {
    let userInput: String
    let assistantResponse: String
}
""",
    
    "persona-02-prompts.swift": """
// PersonaManager.swift
import Foundation

class PersonaManager: ObservableObject {
    @Published var currentPersona: Persona = .helpful
    @Published var customPersonas: [Persona] = []
    
    private let userDefaults = UserDefaults.standard
    private let customPersonasKey = "customPersonas"
    
    init() {
        loadCustomPersonas()
    }
    
    func buildSystemPrompt(for persona: Persona) -> String {
        var prompt = persona.systemPrompt
        
        // Add traits
        if !persona.traits.isEmpty {
            prompt += "\\n\\nYour personality traits: \\(persona.traits.joined(separator: ", "))"
        }
        
        // Add knowledge domains
        if !persona.knowledge.isEmpty {
            prompt += "\\n\\nYou have expertise in: \\(persona.knowledge.joined(separator: ", "))"
        }
        
        // Add examples
        if !persona.examples.isEmpty {
            prompt += "\\n\\nExample interactions:"
            for example in persona.examples.prefix(3) {
                prompt += "\\nUser: \\(example.userInput)"
                prompt += "\\nAssistant: \\(example.assistantResponse)"
            }
        }
        
        return prompt
    }
    
    func createCustomPersona(
        name: String,
        description: String,
        basePrompt: String,
        traits: [String],
        temperature: Double = 0.7
    ) {
        let persona = Persona(
            name: name,
            description: description,
            systemPrompt: basePrompt,
            temperature: temperature,
            traits: traits,
            knowledge: [],
            examples: []
        )
        
        customPersonas.append(persona)
        saveCustomPersonas()
    }
    
    private func loadCustomPersonas() {
        guard let data = userDefaults.data(forKey: customPersonasKey),
              let personas = try? JSONDecoder().decode([Persona].self, from: data) else {
            return
        }
        customPersonas = personas
    }
    
    private func saveCustomPersonas() {
        guard let data = try? JSONEncoder().encode(customPersonas) else { return }
        userDefaults.set(data, forKey: customPersonasKey)
    }
}
""",
    
    "persona-03-behaviors.swift": """
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
        // Add user message
        messages.append(ChatMessage(role: .user, content: content))
        
        // Apply persona-specific preprocessing
        let processedMessages = applyPersonaBehaviors(to: messages)
        
        // Create request with persona settings
        let request = ChatCompletionRequest(
            messages: processedMessages,
            model: "gpt-4o-mini",
            temperature: currentPersona.temperature,
            topP: currentPersona.temperature > 0.7 ? 0.9 : 0.8
        )
        
        let response = try await openAI.chat.completions(request)
        guard let assistantContent = response.choices.first?.message.content else {
            throw ChatError.noContent
        }
        
        // Apply persona-specific postprocessing
        let finalContent = applyPersonaPostprocessing(assistantContent)
        
        messages.append(ChatMessage(role: .assistant, content: finalContent))
        
        return finalContent
    }
    
    private func applyPersonaBehaviors(to messages: [ChatMessage]) -> [ChatMessage] {
        var processed = messages
        
        // Add persona-specific context based on traits
        switch currentPersona.name {
        case "Creative Writer":
            // Add creative writing context
            if let lastUserMessage = messages.last(where: { $0.role == .user }) {
                if lastUserMessage.content.contains("story") || 
                   lastUserMessage.content.contains("write") {
                    processed.insert(
                        ChatMessage(
                            role: .system,
                            content: "Remember to use vivid descriptions, engaging narrative, and creative language."
                        ),
                        at: processed.count - 1
                    )
                }
            }
            
        case "Technical Expert":
            // Add technical precision reminder
            processed.insert(
                ChatMessage(
                    role: .system,
                    content: "Provide code examples when relevant. Use precise technical terminology."
                ),
                at: 1
            )
            
        default:
            break
        }
        
        return processed
    }
    
    private func applyPersonaPostprocessing(_ content: String) -> String {
        var processed = content
        
        // Add persona-specific formatting
        switch currentPersona.name {
        case "Creative Writer":
            // Could add creative flourishes
            if !processed.contains("*") && processed.count > 100 {
                // Add emphasis to key phrases
                processed = processed.replacingOccurrences(
                    of: "(\\\\b(wonderful|amazing|beautiful|mysterious)\\\\b)",
                    with: "*$1*",
                    options: .regularExpression
                )
            }
            
        case "Technical Expert":
            // Ensure code blocks are properly formatted
            if processed.contains("```") == false && 
               processed.contains("func ") || processed.contains("class ") {
                // Wrap code in markdown
                processed = processed.replacingOccurrences(
                    of: "(func|class|struct|enum)\\\\s+\\\\w+[^\\\\n]*\\\\{[^}]*\\\\}",
                    with: "```swift\\n$0\\n```",
                    options: .regularExpression
                )
            }
            
        default:
            break
        }
        
        return processed
    }
}
""",
    
    "persona-04-switching.swift": """
// PersonaSwitching.swift
import SwiftUI
import OpenAIKit

struct PersonaChatView: View {
    @StateObject private var chat: PersonaChat
    @State private var inputText = ""
    @State private var showPersonaPicker = false
    
    let availablePersonas: [Persona] = [
        .helpful,
        .creative,
        .technical
    ]
    
    init(openAI: OpenAIKit) {
        _chat = StateObject(wrappedValue: PersonaChat(openAI: openAI))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with persona selector
            HStack {
                Button(action: { showPersonaPicker.toggle() }) {
                    HStack {
                        Image(systemName: personaIcon)
                        Text(chat.currentPersona.name)
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(20)
                }
                
                Spacer()
                
                Text("\\(chat.currentPersona.temperature, specifier: "%.1f") temp")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // Messages
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(chat.messages.filter { $0.role != .system }, id: \\.content) { message in
                        MessageBubble(
                            message: message,
                            persona: chat.currentPersona
                        )
                    }
                }
                .padding()
            }
            
            // Input
            HStack {
                TextField(placeholderText, text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        sendMessage()
                    }
                
                Button("Send", action: sendMessage)
                    .disabled(inputText.isEmpty)
            }
            .padding()
        }
        .sheet(isPresented: $showPersonaPicker) {
            PersonaPicker(
                personas: availablePersonas,
                selected: chat.currentPersona
            ) { persona in
                chat.switchPersona(to: persona)
                showPersonaPicker = false
            }
        }
    }
    
    private var personaIcon: String {
        switch chat.currentPersona.name {
        case "Creative Writer":
            return "pencil.and.scribble"
        case "Technical Expert":
            return "chevron.left.forwardslash.chevron.right"
        default:
            return "person.circle"
        }
    }
    
    private var placeholderText: String {
        switch chat.currentPersona.name {
        case "Creative Writer":
            return "Ask for a story, poem, or creative idea..."
        case "Technical Expert":
            return "Ask a technical question..."
        default:
            return "Ask me anything..."
        }
    }
    
    private func sendMessage() {
        let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        inputText = ""
        Task {
            do {
                _ = try await chat.sendMessage(message)
            } catch {
                print("Error: \\(error)")
            }
        }
    }
}

struct PersonaPicker: View {
    let personas: [Persona]
    let selected: Persona
    let onSelect: (Persona) -> Void
    
    var body: some View {
        NavigationView {
            List(personas) { persona in
                PersonaRow(
                    persona: persona,
                    isSelected: persona.id == selected.id
                ) {
                    onSelect(persona)
                }
            }
            .navigationTitle("Choose Persona")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PersonaRow: View {
    let persona: Persona
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(persona.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(persona.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ForEach(persona.traits.prefix(3), id: \\.self) { trait in
                            Text(trait)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(.systemBlue).opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let persona: Persona
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            Text(message.content)
                .padding(12)
                .background(backgroundColor)
                .foregroundColor(textColor)
                .cornerRadius(16)
                .font(fontForPersona)
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
    
    private var backgroundColor: Color {
        if message.role == .user {
            return .blue
        } else {
            // Persona-specific colors
            switch persona.name {
            case "Creative Writer":
                return Color(.systemPurple).opacity(0.1)
            case "Technical Expert":
                return Color(.systemGreen).opacity(0.1)
            default:
                return Color(.systemGray5)
            }
        }
    }
    
    private var textColor: Color {
        message.role == .user ? .white : .primary
    }
    
    private var fontForPersona: Font {
        if message.role == .assistant {
            switch persona.name {
            case "Creative Writer":
                return .system(.body, design: .serif)
            case "Technical Expert":
                return .system(.body, design: .monospaced)
            default:
                return .body
            }
        }
        return .body
    }
}
""",
    
    // Advanced Patterns section
    "state-01-machine.swift": """
// ConversationStateMachine.swift
import Foundation

enum ConversationState {
    case idle
    case greeting
    case questionAnswering
    case taskExecution
    case clarification
    case farewell
    
    var contextualPrompt: String {
        switch self {
        case .idle:
            return "Ready to help. What can I do for you?"
        case .greeting:
            return "Nice to meet you! How can I assist you today?"
        case .questionAnswering:
            return "I'll do my best to answer your question."
        case .taskExecution:
            return "I'll help you with that task."
        case .clarification:
            return "Let me make sure I understand correctly."
        case .farewell:
            return "Thank you for the conversation. Goodbye!"
        }
    }
}

class ConversationStateMachine {
    @Published private(set) var currentState: ConversationState = .idle
    private var stateHistory: [ConversationState] = []
    
    func transition(to newState: ConversationState) {
        stateHistory.append(currentState)
        currentState = newState
        
        // Keep only last 10 states
        if stateHistory.count > 10 {
            stateHistory.removeFirst()
        }
    }
    
    func determineState(from message: String) -> ConversationState {
        let lowercased = message.lowercased()
        
        // Greeting patterns
        if lowercased.contains("hello") || 
           lowercased.contains("hi") || 
           lowercased.contains("hey") ||
           lowercased.hasPrefix("good ") {
            return .greeting
        }
        
        // Farewell patterns
        if lowercased.contains("goodbye") || 
           lowercased.contains("bye") || 
           lowercased.contains("see you") ||
           lowercased.contains("thanks") && lowercased.contains("that's all") {
            return .farewell
        }
        
        // Question patterns
        if lowercased.contains("?") || 
           lowercased.starts(with: "what") ||
           lowercased.starts(with: "how") ||
           lowercased.starts(with: "why") ||
           lowercased.starts(with: "when") ||
           lowercased.starts(with: "where") ||
           lowercased.starts(with: "who") {
            return .questionAnswering
        }
        
        // Clarification patterns
        if lowercased.contains("what do you mean") ||
           lowercased.contains("can you clarify") ||
           lowercased.contains("i don't understand") ||
           lowercased.contains("explain") {
            return .clarification
        }
        
        // Task patterns
        if lowercased.contains("help me") ||
           lowercased.contains("can you") ||
           lowercased.contains("please") ||
           lowercased.contains("i need") ||
           lowercased.contains("create") ||
           lowercased.contains("write") ||
           lowercased.contains("make") {
            return .taskExecution
        }
        
        // Default to current state or question answering
        return currentState == .idle ? .questionAnswering : currentState
    }
    
    func suggestedResponse(for state: ConversationState) -> String? {
        switch state {
        case .greeting:
            return "Hello! I'm here to help. What would you like to know or do today?"
        case .clarification:
            return "I'd be happy to clarify. Which part would you like me to explain further?"
        case .farewell:
            return "It was great talking with you! Feel free to come back anytime."
        default:
            return nil
        }
    }
}
""",
    
    "state-02-branching.swift": """
// BranchingConversation.swift
import Foundation

struct ConversationNode: Identifiable {
    let id = UUID()
    let content: String
    let speaker: ChatRole
    var children: [ConversationNode] = []
    var metadata: [String: Any] = [:]
}

class BranchingConversationManager: ObservableObject {
    @Published var rootNode: ConversationNode
    @Published var currentPath: [ConversationNode] = []
    @Published var alternativeBranches: [[ConversationNode]] = []
    
    init(systemPrompt: String) {
        self.rootNode = ConversationNode(
            content: systemPrompt,
            speaker: .system
        )
        self.currentPath = [rootNode]
    }
    
    func addMessage(_ content: String, role: ChatRole, to parent: ConversationNode? = nil) {
        let newNode = ConversationNode(content: content, speaker: role)
        
        if let parent = parent ?? currentPath.last {
            // Find parent in tree and add child
            addChild(newNode, to: parent, in: &rootNode)
            currentPath.append(newNode)
        }
    }
    
    private func addChild(_ child: ConversationNode, to parent: ConversationNode, in node: inout ConversationNode) {
        if node.id == parent.id {
            node.children.append(child)
        } else {
            for i in 0..<node.children.count {
                addChild(child, to: parent, in: &node.children[i])
            }
        }
    }
    
    func branch(from node: ConversationNode) {
        // Save current path as alternative
        if currentPath.count > 1 {
            alternativeBranches.append(currentPath)
        }
        
        // Find path to node
        currentPath = findPath(to: node, from: rootNode) ?? [rootNode]
    }
    
    private func findPath(to target: ConversationNode, from node: ConversationNode, 
                         currentPath: [ConversationNode] = []) -> [ConversationNode]? {
        let path = currentPath + [node]
        
        if node.id == target.id {
            return path
        }
        
        for child in node.children {
            if let found = findPath(to: target, from: child, currentPath: path) {
                return found
            }
        }
        
        return nil
    }
    
    func exportCurrentBranch() -> [ChatMessage] {
        currentPath.compactMap { node in
            guard node.speaker != .system || node.id == rootNode.id else { return nil }
            return ChatMessage(role: node.speaker, content: node.content)
        }
    }
    
    func findSimilarBranches(to query: String) -> [ConversationNode] {
        var similar: [ConversationNode] = []
        findSimilarNodes(query: query, in: rootNode, results: &similar)
        
        return similar.sorted { node1, node2 in
            let score1 = similarityScore(node1.content, query)
            let score2 = similarityScore(node2.content, query)
            return score1 > score2
        }
    }
    
    private func findSimilarNodes(query: String, in node: ConversationNode, 
                                 results: inout [ConversationNode]) {
        if node.speaker == .user && similarityScore(node.content, query) > 0.7 {
            results.append(node)
        }
        
        for child in node.children {
            findSimilarNodes(query: query, in: child, results: &results)
        }
    }
    
    private func similarityScore(_ text1: String, _ text2: String) -> Double {
        // Simple word overlap score
        let words1 = Set(text1.lowercased().split(separator: " "))
        let words2 = Set(text2.lowercased().split(separator: " "))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return union.isEmpty ? 0 : Double(intersection.count) / Double(union.count)
    }
}
""",
    
    "state-03-context.swift": """
// ContextManager.swift
import Foundation

struct ConversationContext {
    var topic: String?
    var entities: [String: String] = [:] // Named entities
    var sentiment: Sentiment = .neutral
    var intent: Intent = .unknown
    var languageStyle: LanguageStyle = .casual
    var userPreferences: [String: Any] = [:]
    var timestamp: Date = Date()
    
    enum Sentiment {
        case positive, neutral, negative, mixed
    }
    
    enum Intent {
        case question, request, statement, greeting, farewell, unknown
    }
    
    enum LanguageStyle {
        case formal, casual, technical, creative
    }
}

class ContextManager: ObservableObject {
    @Published private(set) var currentContext = ConversationContext()
    private var contextHistory: [ConversationContext] = []
    
    func updateContext(from message: String, role: ChatRole) {
        var newContext = currentContext
        newContext.timestamp = Date()
        
        if role == .user {
            // Extract topic
            newContext.topic = extractTopic(from: message)
            
            // Extract entities
            newContext.entities = extractEntities(from: message)
            
            // Determine sentiment
            newContext.sentiment = analyzeSentiment(message)
            
            // Determine intent
            newContext.intent = classifyIntent(message)
            
            // Detect language style
            newContext.languageStyle = detectLanguageStyle(message)
        }
        
        // Save to history
        contextHistory.append(currentContext)
        currentContext = newContext
        
        // Limit history
        if contextHistory.count > 20 {
            contextHistory.removeFirst()
        }
    }
    
    private func extractTopic(from text: String) -> String? {
        // Simple topic extraction - look for nouns
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        
        // Common topic indicators
        let topicIndicators = ["about", "regarding", "concerning", "with"]
        
        for (index, word) in words.enumerated() {
            if topicIndicators.contains(word.lowercased()) && index < words.count - 1 {
                return words[index + 1...].joined(separator: " ")
            }
        }
        
        // Fallback: use first noun-like word
        return words.first { word in
            word.count > 3 && 
            !["what", "how", "when", "where", "why", "who"].contains(word.lowercased())
        }
    }
    
    private func extractEntities(from text: String) -> [String: String] {
        var entities: [String: String] = [:]
        
        // Simple pattern matching for common entities
        
        // Names (capitalized words)
        let namePattern = try? NSRegularExpression(pattern: "\\\\b[A-Z][a-z]+(?:\\\\s[A-Z][a-z]+)*\\\\b")
        let names = namePattern?.matches(in: text, range: NSRange(text.startIndex..., in: text))
            .compactMap { Range($0.range, in: text).map { String(text[$0]) } } ?? []
        
        if !names.isEmpty {
            entities["names"] = names.joined(separator: ", ")
        }
        
        // Dates
        let datePattern = try? NSRegularExpression(pattern: "\\\\b\\\\d{1,2}/\\\\d{1,2}/\\\\d{2,4}\\\\b")
        let dates = datePattern?.matches(in: text, range: NSRange(text.startIndex..., in: text))
            .compactMap { Range($0.range, in: text).map { String(text[$0]) } } ?? []
        
        if !dates.isEmpty {
            entities["dates"] = dates.joined(separator: ", ")
        }
        
        // Email addresses
        let emailPattern = try? NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\\\.[A-Za-z]{2,}")
        let emails = emailPattern?.matches(in: text, range: NSRange(text.startIndex..., in: text))
            .compactMap { Range($0.range, in: text).map { String(text[$0]) } } ?? []
        
        if !emails.isEmpty {
            entities["emails"] = emails.joined(separator: ", ")
        }
        
        return entities
    }
    
    private func analyzeSentiment(_ text: String) -> ConversationContext.Sentiment {
        let positive = ["good", "great", "excellent", "happy", "love", "wonderful", "amazing", "fantastic"]
        let negative = ["bad", "terrible", "awful", "hate", "angry", "frustrated", "disappointed"]
        
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        let positiveCount = words.filter { positive.contains($0) }.count
        let negativeCount = words.filter { negative.contains($0) }.count
        
        if positiveCount > negativeCount {
            return .positive
        } else if negativeCount > positiveCount {
            return .negative
        } else if positiveCount > 0 && negativeCount > 0 {
            return .mixed
        } else {
            return .neutral
        }
    }
    
    private func classifyIntent(_ text: String) -> ConversationContext.Intent {
        let lowercased = text.lowercased()
        
        if lowercased.contains("?") || 
           ["what", "how", "when", "where", "why", "who", "is", "are", "can", "could", "would"]
            .contains(where: { lowercased.starts(with: $0) }) {
            return .question
        }
        
        if ["please", "could you", "can you", "help", "need", "want"]
            .contains(where: { lowercased.contains($0) }) {
            return .request
        }
        
        if ["hello", "hi", "hey", "good morning", "good afternoon"]
            .contains(where: { lowercased.contains($0) }) {
            return .greeting
        }
        
        if ["bye", "goodbye", "see you", "farewell", "talk to you later"]
            .contains(where: { lowercased.contains($0) }) {
            return .farewell
        }
        
        return .statement
    }
    
    private func detectLanguageStyle(_ text: String) -> ConversationContext.LanguageStyle {
        let formalIndicators = ["therefore", "furthermore", "moreover", "regarding", "concerning"]
        let technicalIndicators = ["function", "algorithm", "implementation", "system", "process"]
        let creativeIndicators = ["imagine", "story", "creative", "idea", "inspiration"]
        
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        if words.contains(where: { formalIndicators.contains($0) }) {
            return .formal
        } else if words.contains(where: { technicalIndicators.contains($0) }) {
            return .technical
        } else if words.contains(where: { creativeIndicators.contains($0) }) {
            return .creative
        } else {
            return .casual
        }
    }
    
    func contextPrompt() -> String {
        var prompt = ""
        
        if let topic = currentContext.topic {
            prompt += "The current topic is: \\(topic). "
        }
        
        switch currentContext.sentiment {
        case .positive:
            prompt += "The user seems positive. Maintain an upbeat tone. "
        case .negative:
            prompt += "The user might be frustrated. Be extra helpful and patient. "
        case .mixed:
            prompt += "The user has mixed feelings. Be balanced in your response. "
        case .neutral:
            break
        }
        
        switch currentContext.languageStyle {
        case .formal:
            prompt += "Use formal language. "
        case .technical:
            prompt += "Use precise technical language. "
        case .creative:
            prompt += "Be creative and imaginative. "
        case .casual:
            prompt += "Keep the tone conversational. "
        }
        
        return prompt
    }
}
""",
    
    "state-04-analytics.swift": """
// ConversationAnalytics.swift
import Foundation
import Charts
import SwiftUI

struct ConversationMetrics {
    let messageCount: Int
    let averageResponseTime: TimeInterval
    let sentimentDistribution: [ConversationContext.Sentiment: Int]
    let topicFrequency: [String: Int]
    let userEngagement: Double
    let conversationDuration: TimeInterval
}

class ConversationAnalytics: ObservableObject {
    @Published var metrics = ConversationMetrics(
        messageCount: 0,
        averageResponseTime: 0,
        sentimentDistribution: [:],
        topicFrequency: [:],
        userEngagement: 0,
        conversationDuration: 0
    )
    
    private var messageTimes: [(Date, ChatRole)] = []
    private var topics: [String] = []
    private var sentiments: [ConversationContext.Sentiment] = []
    private let startTime = Date()
    
    func trackMessage(role: ChatRole, content: String, context: ConversationContext) {
        messageTimes.append((Date(), role))
        
        if let topic = context.topic {
            topics.append(topic)
        }
        
        sentiments.append(context.sentiment)
        
        updateMetrics()
    }
    
    private func updateMetrics() {
        // Message count
        let messageCount = messageTimes.count
        
        // Average response time
        var responseTimes: [TimeInterval] = []
        for i in 1..<messageTimes.count {
            if messageTimes[i].1 == .assistant && messageTimes[i-1].1 == .user {
                let responseTime = messageTimes[i].0.timeIntervalSince(messageTimes[i-1].0)
                responseTimes.append(responseTime)
            }
        }
        let avgResponseTime = responseTimes.isEmpty ? 0 : 
            responseTimes.reduce(0, +) / Double(responseTimes.count)
        
        // Sentiment distribution
        var sentimentDist: [ConversationContext.Sentiment: Int] = [:]
        for sentiment in sentiments {
            sentimentDist[sentiment, default: 0] += 1
        }
        
        // Topic frequency
        var topicFreq: [String: Int] = [:]
        for topic in topics {
            topicFreq[topic, default: 0] += 1
        }
        
        // User engagement (messages per minute)
        let duration = Date().timeIntervalSince(startTime)
        let userMessages = messageTimes.filter { $0.1 == .user }.count
        let engagement = duration > 0 ? Double(userMessages) / (duration / 60) : 0
        
        metrics = ConversationMetrics(
            messageCount: messageCount,
            averageResponseTime: avgResponseTime,
            sentimentDistribution: sentimentDist,
            topicFrequency: topicFreq,
            userEngagement: engagement,
            conversationDuration: duration
        )
    }
    
    func generateReport() -> String {
        var report = "Conversation Analytics Report\\n"
        report += "===========================\\n\\n"
        
        report += "Total Messages: \\(metrics.messageCount)\\n"
        report += "Duration: \\(formatDuration(metrics.conversationDuration))\\n"
        report += "Avg Response Time: \\(String(format: "%.1f", metrics.averageResponseTime))s\\n"
        report += "User Engagement: \\(String(format: "%.1f", metrics.userEngagement)) messages/min\\n\\n"
        
        report += "Sentiment Distribution:\\n"
        for (sentiment, count) in metrics.sentimentDistribution {
            let percentage = Double(count) / Double(metrics.messageCount) * 100
            report += "  \\(sentiment): \\(count) (\\(String(format: "%.0f", percentage))%)\\n"
        }
        
        report += "\\nTop Topics:\\n"
        for (topic, count) in metrics.topicFrequency.sorted(by: { $0.value > $1.value }).prefix(5) {
            report += "  \\(topic): \\(count) times\\n"
        }
        
        return report
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\\(minutes)m \\(seconds)s"
    }
}

// Analytics Dashboard View
struct AnalyticsDashboard: View {
    @ObservedObject var analytics: ConversationAnalytics
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Conversation Analytics")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Key metrics
                HStack(spacing: 20) {
                    MetricCard(
                        title: "Messages",
                        value: "\\(analytics.metrics.messageCount)",
                        icon: "message"
                    )
                    
                    MetricCard(
                        title: "Avg Response",
                        value: "\\(String(format: "%.1f", analytics.metrics.averageResponseTime))s",
                        icon: "clock"
                    )
                    
                    MetricCard(
                        title: "Engagement",
                        value: "\\(String(format: "%.1f", analytics.metrics.userEngagement))/min",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                
                // Sentiment chart
                if !analytics.metrics.sentimentDistribution.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Sentiment Distribution")
                            .font(.headline)
                        
                        Chart {
                            ForEach(Array(analytics.metrics.sentimentDistribution), id: \\.key) { item in
                                BarMark(
                                    x: .value("Sentiment", String(describing: item.key)),
                                    y: .value("Count", item.value)
                                )
                                .foregroundStyle(colorForSentiment(item.key))
                            }
                        }
                        .frame(height: 200)
                    }
                }
                
                // Topic frequency
                if !analytics.metrics.topicFrequency.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Top Topics")
                            .font(.headline)
                        
                        ForEach(Array(analytics.metrics.topicFrequency.sorted(by: { $0.value > $1.value }).prefix(5)), 
                               id: \\.key) { item in
                            HStack {
                                Text(item.key)
                                    .font(.subheadline)
                                Spacer()
                                Text("\\(item.value)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func colorForSentiment(_ sentiment: ConversationContext.Sentiment) -> Color {
        switch sentiment {
        case .positive:
            return .green
        case .negative:
            return .red
        case .mixed:
            return .orange
        case .neutral:
            return .gray
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
""",
    
    // Complete Chatbot section
    "chatbot-01-class.swift": """
// CompleteChatbot.swift
import Foundation
import OpenAIKit

class CompleteChatbot: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false
    @Published var currentPersona: Persona = .helpful
    @Published var context = ConversationContext()
    
    private let openAI: OpenAIKit
    private let conversationManager: ConversationManager
    private let contextManager = ContextManager()
    private let memory = SemanticMemory(openAI: OpenAIManager.shared.client!)
    private let stateMachine = ConversationStateMachine()
    private let analytics = ConversationAnalytics()
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
        self.conversationManager = ConversationManager(
            openAI: openAI,
            systemPrompt: currentPersona.systemPrompt
        )
    }
}
""",
    
    "chatbot-02-integration.swift": """
// CompleteChatbot.swift - Integration
import Foundation
import OpenAIKit

extension CompleteChatbot {
    func sendMessage(_ content: String) async throws -> String {
        // Update state machine
        let newState = stateMachine.determineState(from: content)
        stateMachine.transition(to: newState)
        
        // Update context
        contextManager.updateContext(from: content, role: .user)
        context = contextManager.currentContext
        
        // Add user message
        conversationManager.addUserMessage(content)
        messages = conversationManager.messages
        
        // Track analytics
        analytics.trackMessage(role: .user, content: content, context: context)
        
        // Search memory for relevant context
        let memories = await memory.search(query: content)
        
        // Build enhanced request
        let request = await buildEnhancedRequest(
            userMessage: content,
            memories: memories,
            state: newState
        )
        
        // Get response
        isTyping = true
        defer { isTyping = false }
        
        let response = try await openAI.chat.completions(request)
        guard let assistantContent = response.choices.first?.message.content else {
            throw ChatError.noContent
        }
        
        // Process and store response
        await processResponse(assistantContent, for: content)
        
        return assistantContent
    }
    
    private func buildEnhancedRequest(
        userMessage: String,
        memories: [MemoryItem],
        state: ConversationState
    ) async -> ChatCompletionRequest {
        var messages = conversationManager.getContextForRequest()
        
        // Insert context-aware system messages
        var contextMessages: [ChatMessage] = []
        
        // Add state context
        contextMessages.append(ChatMessage(
            role: .system,
            content: state.contextualPrompt
        ))
        
        // Add memory context
        if !memories.isEmpty {
            let memoryContext = memories.prefix(3)
                .map { "- \\($0.value)" }
                .joined(separator: "\\n")
            
            contextMessages.append(ChatMessage(
                role: .system,
                content: "Relevant context: \\n\\(memoryContext)"
            ))
        }
        
        // Add persona and context modifiers
        let contextPrompt = contextManager.contextPrompt()
        if !contextPrompt.isEmpty {
            contextMessages.append(ChatMessage(
                role: .system,
                content: contextPrompt
            ))
        }
        
        // Insert context messages after system prompt
        if let systemIndex = messages.firstIndex(where: { $0.role == .system }) {
            messages.insert(contentsOf: contextMessages, at: systemIndex + 1)
        } else {
            messages.insert(contentsOf: contextMessages, at: 0)
        }
        
        return ChatCompletionRequest(
            messages: messages,
            model: "gpt-4o-mini",
            temperature: currentPersona.temperature,
            maxTokens: 500
        )
    }
    
    private func processResponse(_ response: String, for userMessage: String) async {
        // Add to conversation
        conversationManager.addAssistantMessage(response)
        messages = conversationManager.messages
        
        // Update context
        contextManager.updateContext(from: response, role: .assistant)
        
        // Store in memory
        let key = "\\(Date().timeIntervalSince1970)_exchange"
        let value = "User: \\(userMessage)\\nAssistant: \\(response)"
        await memory.store(key: key, value: value)
        
        // Track analytics
        analytics.trackMessage(role: .assistant, content: response, context: context)
    }
}
""",
    
    "chatbot-03-intents.swift": """
// IntentHandler.swift
import Foundation
import OpenAIKit

protocol IntentHandler {
    var supportedIntents: [ConversationContext.Intent] { get }
    func canHandle(intent: ConversationContext.Intent, context: ConversationContext) -> Bool
    func handle(message: String, context: ConversationContext) async throws -> IntentResponse
}

struct IntentResponse {
    let content: String
    let suggestedActions: [String]
    let requiresFollowUp: Bool
    let metadata: [String: Any]
}

class QuestionIntentHandler: IntentHandler {
    let supportedIntents: [ConversationContext.Intent] = [.question]
    private let openAI: OpenAIKit
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
    }
    
    func canHandle(intent: ConversationContext.Intent, context: ConversationContext) -> Bool {
        supportedIntents.contains(intent)
    }
    
    func handle(message: String, context: ConversationContext) async throws -> IntentResponse {
        // Analyze question type
        let questionType = analyzeQuestionType(message)
        
        // Generate appropriate response based on question type
        let systemPrompt = buildQuestionPrompt(type: questionType, context: context)
        
        let request = ChatCompletionRequest(
            messages: [
                ChatMessage(role: .system, content: systemPrompt),
                ChatMessage(role: .user, content: message)
            ],
            model: "gpt-4o-mini",
            temperature: 0.7
        )
        
        let response = try await openAI.chat.completions(request)
        let content = response.choices.first?.message.content ?? ""
        
        // Generate follow-up suggestions
        let suggestions = generateSuggestions(for: questionType, originalQuestion: message)
        
        return IntentResponse(
            content: content,
            suggestedActions: suggestions,
            requiresFollowUp: questionType == .clarification,
            metadata: ["questionType": questionType]
        )
    }
    
    private func analyzeQuestionType(_ message: String) -> QuestionType {
        let lowercased = message.lowercased()
        
        if lowercased.contains("how") && lowercased.contains("work") {
            return .explanation
        } else if lowercased.contains("what") && lowercased.contains("difference") {
            return .comparison
        } else if lowercased.contains("why") {
            return .reasoning
        } else if lowercased.contains("when") || lowercased.contains("where") {
            return .factual
        } else {
            return .general
        }
    }
    
    private func buildQuestionPrompt(type: QuestionType, context: ConversationContext) -> String {
        var prompt = "You are answering a \\(type) question. "
        
        switch type {
        case .explanation:
            prompt += "Provide a clear, step-by-step explanation. Use examples if helpful."
        case .comparison:
            prompt += "Compare and contrast the elements mentioned. Use a structured format."
        case .reasoning:
            prompt += "Explain the reasoning and underlying principles."
        case .factual:
            prompt += "Provide accurate, concise factual information."
        case .clarification:
            prompt += "Ask clarifying questions to better understand what the user needs."
        case .general:
            prompt += "Provide a helpful and informative response."
        }
        
        if let topic = context.topic {
            prompt += " The topic is \\(topic)."
        }
        
        return prompt
    }
    
    private func generateSuggestions(for type: QuestionType, originalQuestion: String) -> [String] {
        switch type {
        case .explanation:
            return [
                "Would you like more details?",
                "Can I provide an example?",
                "Should I explain a specific part?"
            ]
        case .comparison:
            return [
                "Would you like to know more differences?",
                "Should I compare other aspects?",
                "Want me to summarize the key differences?"
            ]
        case .reasoning:
            return [
                "Would you like to explore this further?",
                "Can I explain the implications?",
                "Should I provide counter-arguments?"
            ]
        default:
            return [
                "Do you have a follow-up question?",
                "Would you like more information?",
                "Can I clarify anything?"
            ]
        }
    }
    
    enum QuestionType: String {
        case explanation, comparison, reasoning, factual, clarification, general
    }
}

// Intent Router
class IntentRouter {
    private var handlers: [IntentHandler] = []
    
    func register(_ handler: IntentHandler) {
        handlers.append(handler)
    }
    
    func route(message: String, intent: ConversationContext.Intent, 
               context: ConversationContext) async throws -> IntentResponse? {
        for handler in handlers {
            if handler.canHandle(intent: intent, context: context) {
                return try await handler.handle(message: message, context: context)
            }
        }
        return nil
    }
}
""",
    
    "chatbot-04-flow.swift": """
// ConversationFlow.swift
import Foundation

class ConversationFlowManager {
    private var currentFlow: ConversationFlow?
    private let flows: [String: ConversationFlow] = [
        "onboarding": OnboardingFlow(),
        "support": SupportFlow(),
        "feedback": FeedbackFlow(),
        "general": GeneralFlow()
    ]
    
    func determineFlow(from message: String, context: ConversationContext) -> ConversationFlow {
        // Check if we're in an active flow
        if let current = currentFlow, !current.isComplete {
            return current
        }
        
        // Determine new flow based on message and context
        if context.intent == .greeting && context.entities["names"] == nil {
            return flows["onboarding"]!
        } else if message.lowercased().contains("help") || 
                  message.lowercased().contains("problem") ||
                  message.lowercased().contains("issue") {
            return flows["support"]!
        } else if message.lowercased().contains("feedback") ||
                  message.lowercased().contains("suggestion") {
            return flows["feedback"]!
        } else {
            return flows["general"]!
        }
    }
    
    func processInFlow(message: String, flow: ConversationFlow) -> FlowResponse {
        let response = flow.process(message: message)
        
        if flow.isComplete {
            currentFlow = nil
        } else {
            currentFlow = flow
        }
        
        return response
    }
}

protocol ConversationFlow {
    var name: String { get }
    var currentStep: Int { get }
    var isComplete: Bool { get }
    func process(message: String) -> FlowResponse
    func reset()
}

struct FlowResponse {
    let message: String
    let options: [String]
    let requiresInput: Bool
    let metadata: [String: Any]
}

class OnboardingFlow: ConversationFlow {
    let name = "onboarding"
    private(set) var currentStep = 0
    private var userName: String?
    private var preferences: [String: Any] = [:]
    
    var isComplete: Bool {
        currentStep >= 4
    }
    
    func process(message: String) -> FlowResponse {
        switch currentStep {
        case 0:
            currentStep = 1
            return FlowResponse(
                message: "Welcome! I'm your AI assistant. What's your name?",
                options: [],
                requiresInput: true,
                metadata: ["step": "get_name"]
            )
            
        case 1:
            userName = message
            currentStep = 2
            return FlowResponse(
                message: "Nice to meet you, \\(message)! What would you like help with today?",
                options: [
                    "General questions",
                    "Creative writing",
                    "Technical support",
                    "Just chatting"
                ],
                requiresInput: true,
                metadata: ["step": "get_preference"]
            )
            
        case 2:
            preferences["main_interest"] = message
            currentStep = 3
            return FlowResponse(
                message: "Great! Would you prefer formal or casual conversations?",
                options: ["Formal", "Casual", "Depends on context"],
                requiresInput: true,
                metadata: ["step": "get_style"]
            )
            
        case 3:
            preferences["style"] = message
            currentStep = 4
            return FlowResponse(
                message: "Perfect! I'm all set up. How can I help you today, \\(userName ?? "there")?",
                options: [],
                requiresInput: true,
                metadata: ["step": "complete", "preferences": preferences]
            )
            
        default:
            return FlowResponse(
                message: "How can I help you?",
                options: [],
                requiresInput: true,
                metadata: [:]
            )
        }
    }
    
    func reset() {
        currentStep = 0
        userName = nil
        preferences = [:]
    }
}

class SupportFlow: ConversationFlow {
    let name = "support"
    private(set) var currentStep = 0
    private var issue: String?
    private var category: String?
    private var details: String?
    
    var isComplete: Bool {
        currentStep >= 4
    }
    
    func process(message: String) -> FlowResponse {
        switch currentStep {
        case 0:
            currentStep = 1
            return FlowResponse(
                message: "I'm here to help! What kind of issue are you experiencing?",
                options: [
                    "Technical problem",
                    "Account issue",
                    "Feature question",
                    "Other"
                ],
                requiresInput: true,
                metadata: ["step": "categorize"]
            )
            
        case 1:
            category = message
            currentStep = 2
            return FlowResponse(
                message: "Can you describe the issue in more detail?",
                options: [],
                requiresInput: true,
                metadata: ["step": "get_details"]
            )
            
        case 2:
            issue = message
            currentStep = 3
            return FlowResponse(
                message: "When did this issue start occurring?",
                options: [
                    "Just now",
                    "Today",
                    "This week",
                    "It's been ongoing"
                ],
                requiresInput: true,
                metadata: ["step": "get_timeline"]
            )
            
        case 3:
            details = message
            currentStep = 4
            
            // Generate solution based on collected information
            let solution = generateSolution(category: category, issue: issue)
            
            return FlowResponse(
                message: solution,
                options: [
                    "This solved my problem",
                    "I need more help",
                    "I have a different issue"
                ],
                requiresInput: true,
                metadata: ["step": "resolution", "issue": issue ?? ""]
            )
            
        default:
            return FlowResponse(
                message: "Is there anything else I can help you with?",
                options: [],
                requiresInput: true,
                metadata: [:]
            )
        }
    }
    
    private func generateSolution(category: String?, issue: String?) -> String {
        // In real implementation, this would use AI or a knowledge base
        return """
Based on your \(category ?? "issue"), here's what I suggest:

1. First, try restarting the application
2. Check if you're using the latest version
3. Clear your cache and temporary files

If the issue persists, I can help you file a detailed support ticket.
"""
    }
    
    func reset() {
        currentStep = 0
        issue = nil
        category = nil
        details = nil
    }
}

class FeedbackFlow: ConversationFlow {
    let name = "feedback"
    private(set) var currentStep = 0
    var isComplete: Bool { currentStep >= 3 }
    
    func process(message: String) -> FlowResponse {
        // Similar implementation for feedback collection
        FlowResponse(
            message: "Thank you for your feedback!",
            options: [],
            requiresInput: false,
            metadata: [:]
        )
    }
    
    func reset() {
        currentStep = 0
    }
}

class GeneralFlow: ConversationFlow {
    let name = "general"
    let currentStep = 0
    let isComplete = false
    
    func process(message: String) -> FlowResponse {
        FlowResponse(
            message: "",  // Will be handled by main chat logic
            options: [],
            requiresInput: true,
            metadata: ["type": "general"]
        )
    }
    
    func reset() {}
}
""",
    
    "chatbot-05-ui.swift": """
// CompleteChatbotView.swift
import SwiftUI
import OpenAIKit

struct CompleteChatbotView: View {
    @StateObject private var chatbot: CompleteChatbot
    @State private var inputText = ""
    @State private var showingPersonaPicker = false
    @State private var showingAnalytics = false
    @State private var showingMemory = false
    
    init(openAI: OpenAIKit) {
        _chatbot = StateObject(wrappedValue: CompleteChatbot(openAI: openAI))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ChatHeader(
                persona: chatbot.currentPersona,
                onPersonaTap: { showingPersonaPicker = true },
                onAnalyticsTap: { showingAnalytics = true },
                onMemoryTap: { showingMemory = true }
            )
            
            // State indicator
            if chatbot.context.topic != nil {
                StateIndicator(context: chatbot.context)
            }
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(chatbot.messages.enumerated()), id: \\.offset) { index, message in
                            if message.role != .system {
                                MessageRow(
                                    message: message,
                                    showActions: index == chatbot.messages.count - 1,
                                    onAction: { action in
                                        handleAction(action)
                                    }
                                )
                                .id(index)
                            }
                        }
                        
                        if chatbot.isTyping {
                            TypingIndicator()
                                .id("typing")
                        }
                    }
                    .padding()
                    .onChange(of: chatbot.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(chatbot.isTyping ? "typing" : chatbot.messages.count - 1)
                        }
                    }
                }
            }
            
            // Suggestions
            if let lastMessage = chatbot.messages.last,
               lastMessage.role == .assistant {
                SuggestionBar(
                    suggestions: generateSuggestions(),
                    onSelect: { suggestion in
                        inputText = suggestion
                        sendMessage()
                    }
                )
            }
            
            // Input area
            ChatInputArea(
                text: $inputText,
                isLoading: chatbot.isTyping,
                onSend: sendMessage
            )
        }
        .sheet(isPresented: $showingPersonaPicker) {
            PersonaPicker(
                personas: [.helpful, .creative, .technical],
                selected: chatbot.currentPersona
            ) { persona in
                chatbot.currentPersona = persona
                showingPersonaPicker = false
            }
        }
        .sheet(isPresented: $showingAnalytics) {
            AnalyticsDashboard(analytics: chatbot.analytics)
        }
        .sheet(isPresented: $showingMemory) {
            MemoryBrowser(memory: chatbot.memory)
        }
    }
    
    private func sendMessage() {
        let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        inputText = ""
        
        Task {
            do {
                _ = try await chatbot.sendMessage(message)
            } catch {
                // Handle error
                print("Error: \\(error)")
            }
        }
    }
    
    private func handleAction(_ action: String) {
        // Handle quick actions from messages
        switch action {
        case "copy":
            if let lastMessage = chatbot.messages.last {
                UIPasteboard.general.string = lastMessage.content
            }
        case "regenerate":
            if let lastUserMessage = chatbot.messages.reversed().first(where: { $0.role == .user }) {
                Task {
                    _ = try await chatbot.sendMessage(lastUserMessage.content)
                }
            }
        default:
            break
        }
    }
    
    private func generateSuggestions() -> [String] {
        // Context-aware suggestions
        switch chatbot.context.intent {
        case .question:
            return ["Tell me more", "Can you elaborate?", "Give me an example"]
        case .request:
            return ["Thank you", "That's helpful", "I have another question"]
        case .greeting:
            return ["How are you?", "What can you do?", "Nice to meet you"]
        default:
            return ["Continue", "Tell me more", "Thanks"]
        }
    }
}

// Supporting Views
struct ChatHeader: View {
    let persona: Persona
    let onPersonaTap: () -> Void
    let onAnalyticsTap: () -> Void
    let onMemoryTap: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onPersonaTap) {
                HStack {
                    Image(systemName: "person.circle.fill")
                    Text(persona.name)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            Button(action: onMemoryTap) {
                Image(systemName: "brain")
            }
            
            Button(action: onAnalyticsTap) {
                Image(systemName: "chart.bar")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(radius: 1)
    }
}

struct StateIndicator: View {
    let context: ConversationContext
    
    var body: some View {
        HStack {
            if let topic = context.topic {
                Label(topic, systemImage: "tag")
                    .font(.caption)
            }
            
            Label(String(describing: context.sentiment), 
                  systemImage: sentimentIcon)
                .font(.caption)
                .foregroundColor(sentimentColor)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private var sentimentIcon: String {
        switch context.sentiment {
        case .positive:
            return "face.smiling"
        case .negative:
            return "face.frowning"
        case .mixed:
            return "face.neutral"
        case .neutral:
            return "face"
        }
    }
    
    private var sentimentColor: Color {
        switch context.sentiment {
        case .positive:
            return .green
        case .negative:
            return .red
        case .mixed:
            return .orange
        case .neutral:
            return .gray
        }
    }
}

struct SuggestionBar: View {
    let suggestions: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(suggestions, id: \\.self) { suggestion in
                    Button(action: { onSelect(suggestion) }) {
                        Text(suggestion)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(15)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct ChatInputArea: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack {
            TextField("Type a message...", text: $text)
                .textFieldStyle(.roundedBorder)
                .disabled(isLoading)
                .onSubmit {
                    onSend()
                }
            
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(sendButtonColor)
            }
            .disabled(text.isEmpty || isLoading)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
    
    private var sendButtonColor: Color {
        text.isEmpty || isLoading ? .gray : .blue
    }
}

struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .offset(y: animationOffset)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(index) * 0.1),
                        value: animationOffset
                    )
            }
        }
        .onAppear {
            animationOffset = -10
        }
    }
}

struct MemoryBrowser: View {
    let memory: SemanticMemory
    @State private var searchQuery = ""
    @State private var memories: [MemoryItem] = []
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchQuery, onSearch: search)
                
                List(memories) { memory in
                    VStack(alignment: .leading) {
                        Text(memory.key)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(memory.value)
                            .font(.subheadline)
                        Text(memory.timestamp, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Memory")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            search()
        }
    }
    
    private func search() {
        Task {
            memories = await memory.search(query: searchQuery)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let onSearch: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search memories...", text: $text)
                .textFieldStyle(.plain)
                .onSubmit {
                    onSearch()
                }
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding()
    }
}
""",
    
    "chatbot-06-export.swift": """
// ConversationExporter.swift
import Foundation
import UniformTypeIdentifiers

class ConversationExporter {
    enum ExportFormat {
        case markdown
        case json
        case pdf
        case csv
    }
    
    func export(
        messages: [ChatMessage],
        format: ExportFormat,
        metadata: ConversationMetadata? = nil
    ) -> Data? {
        switch format {
        case .markdown:
            return exportAsMarkdown(messages: messages, metadata: metadata)
        case .json:
            return exportAsJSON(messages: messages, metadata: metadata)
        case .pdf:
            return exportAsPDF(messages: messages, metadata: metadata)
        case .csv:
            return exportAsCSV(messages: messages, metadata: metadata)
        }
    }
    
    private func exportAsMarkdown(messages: [ChatMessage], metadata: ConversationMetadata?) -> Data? {
        var markdown = "# Conversation Export\\n\\n"
        
        if let metadata = metadata {
            markdown += "**Date**: \\(formatDate(metadata.date))\\n"
            markdown += "**Duration**: \\(formatDuration(metadata.duration))\\n"
            markdown += "**Messages**: \\(messages.count)\\n"
            if let topic = metadata.topic {
                markdown += "**Topic**: \\(topic)\\n"
            }
            markdown += "\\n---\\n\\n"
        }
        
        for message in messages {
            switch message.role {
            case .user:
                markdown += "### You\\n\\(message.content)\\n\\n"
            case .assistant:
                markdown += "### Assistant\\n\\(message.content)\\n\\n"
            case .system:
                markdown += "_System: \\(message.content)_\\n\\n"
            case .tool:
                markdown += "```\\n\\(message.content)\\n```\\n\\n"
            }
        }
        
        return markdown.data(using: .utf8)
    }
    
    private func exportAsJSON(messages: [ChatMessage], metadata: ConversationMetadata?) -> Data? {
        let export = ConversationExport(
            metadata: metadata,
            messages: messages.map { message in
                ExportedMessage(
                    role: message.role.rawValue,
                    content: message.content,
                    timestamp: Date()
                )
            }
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        return try? encoder.encode(export)
    }
    
    private func exportAsPDF(messages: [ChatMessage], metadata: ConversationMetadata?) -> Data? {
        // In a real implementation, use PDFKit
        // For now, return markdown converted to data
        return exportAsMarkdown(messages: messages, metadata: metadata)
    }
    
    private func exportAsCSV(messages: [ChatMessage], metadata: ConversationMetadata?) -> Data? {
        var csv = "Timestamp,Role,Content\\n"
        
        let dateFormatter = ISO8601DateFormatter()
        
        for message in messages {
            let timestamp = dateFormatter.string(from: Date())
            let content = message.content.replacingOccurrences(of: "\\"", with: "\\"\\"")
            csv += "\\(timestamp),\\(message.role.rawValue),\\"\\(content)\\"\\n"
        }
        
        return csv.data(using: .utf8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return "\\(hours)h \\(minutes)m"
        } else if minutes > 0 {
            return "\\(minutes)m \\(seconds)s"
        } else {
            return "\\(seconds)s"
        }
    }
}

// Supporting types
struct ConversationMetadata: Codable {
    let date: Date
    let duration: TimeInterval
    let topic: String?
    let participants: [String]
    let summary: String?
}

struct ConversationExport: Codable {
    let metadata: ConversationMetadata?
    let messages: [ExportedMessage]
}

struct ExportedMessage: Codable {
    let role: String
    let content: String
    let timestamp: Date
}

// Export UI
struct ExportView: View {
    let messages: [ChatMessage]
    @State private var selectedFormat: ConversationExporter.ExportFormat = .markdown
    @State private var isExporting = false
    @State private var exportURL: URL?
    @Environment(\\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Conversation")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Format picker
                Picker("Format", selection: $selectedFormat) {
                    Text("Markdown").tag(ConversationExporter.ExportFormat.markdown)
                    Text("JSON").tag(ConversationExporter.ExportFormat.json)
                    Text("PDF").tag(ConversationExporter.ExportFormat.pdf)
                    Text("CSV").tag(ConversationExporter.ExportFormat.csv)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Preview
                GroupBox {
                    ScrollView {
                        Text(previewText)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 200)
                }
                
                Spacer()
                
                // Export button
                Button(action: performExport) {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isExporting)
                
                if isExporting {
                    ProgressView("Exporting...")
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $exportURL) { url in
                ShareSheet(url: url)
            }
        }
    }
    
    private var previewText: String {
        let exporter = ConversationExporter()
        let metadata = ConversationMetadata(
            date: Date(),
            duration: 300,
            topic: "General Chat",
            participants: ["User", "Assistant"],
            summary: nil
        )
        
        guard let data = exporter.export(
            messages: Array(messages.prefix(3)),
            format: selectedFormat,
            metadata: metadata
        ) else {
            return "Preview not available"
        }
        
        return String(data: data, encoding: .utf8) ?? "Preview not available"
    }
    
    private func performExport() {
        isExporting = true
        
        let exporter = ConversationExporter()
        let metadata = ConversationMetadata(
            date: Date(),
            duration: 300,
            topic: nil,
            participants: ["User", "Assistant"],
            summary: nil
        )
        
        guard let data = exporter.export(
            messages: messages,
            format: selectedFormat,
            metadata: metadata
        ) else {
            isExporting = false
            return
        }
        
        // Save to temporary file
        let filename = "conversation_\\(Date().timeIntervalSince1970)"
        let extension = fileExtension(for: selectedFormat)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)
            .appendingPathExtension(extension)
        
        do {
            try data.write(to: url)
            exportURL = url
        } catch {
            print("Export failed: \\(error)")
        }
        
        isExporting = false
    }
    
    private func fileExtension(for format: ConversationExporter.ExportFormat) -> String {
        switch format {
        case .markdown:
            return "md"
        case .json:
            return "json"
        case .pdf:
            return "pdf"
        case .csv:
            return "csv"
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Extension to make URL Identifiable
extension URL: Identifiable {
    public var id: String { absoluteString }
}
"""
]

// Write all files
func writeFiles(_ files: [String: String]) {
    for (filename, content) in files {
        let path = (baseDir as NSString).appendingPathComponent(filename)
        do {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
            print("Created: \(filename)")
        } catch {
            print("Error creating \(filename): \(error)")
        }
    }
}

// Generate all tutorial files
print("Generating tutorial code files for Building Conversations...")
writeFiles(conversationsCode)

print("\nGenerated \(conversationsCode.count) files")
print("Total files created so far: \(70 + conversationsCode.count)")