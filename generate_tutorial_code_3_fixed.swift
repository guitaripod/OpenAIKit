#!/usr/bin/env swift

import Foundation

let baseDir = "Sources/OpenAIKit/OpenAIKit.docc/Resources/code"

// Tutorial 5: Building Conversations - Part 1
let conversationsCode1 = [
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
"""
]

// Tutorial 5: Part 2 - Memory and Personas
let conversationsCode2 = [
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
writeFiles(conversationsCode1)
writeFiles(conversationsCode2)

print("\nGenerated \(conversationsCode1.count + conversationsCode2.count) files")
print("Run additional scripts to generate remaining files.")