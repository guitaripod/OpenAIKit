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
            "\(message.role.rawValue): \(message.content)"
        }.joined(separator: "\n")
        
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
            print("Failed to summarize: \(error)")
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
            content: "Previous conversation summary: \(summary)"
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