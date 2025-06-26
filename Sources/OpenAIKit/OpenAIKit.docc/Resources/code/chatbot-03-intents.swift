// IntentHandler.swift
import Foundation
import OpenAIKit

protocol IntentHandler {
    var supportedIntents: [ConversationContext.Intent] { get }
    func canHandle(intent: ConversationContext.Intent) -> Bool
    func handle(message: String, context: ConversationContext) async throws -> String
}

class QuestionIntentHandler: IntentHandler {
    let supportedIntents: [ConversationContext.Intent] = [.question]
    private let openAI: OpenAIKit
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
    }
    
    func canHandle(intent: ConversationContext.Intent) -> Bool {
        supportedIntents.contains(intent)
    }
    
    func handle(message: String, context: ConversationContext) async throws -> String {
        let request = ChatCompletionRequest(
            messages: [
                ChatMessage(role: .system, content: "Answer the user's question clearly and helpfully."),
                ChatMessage(role: .user, content: message)
            ],
            model: "gpt-4o-mini"
        )
        
        let response = try await openAI.chat.completions(request)
        return response.choices.first?.message.content ?? ""
    }
}
