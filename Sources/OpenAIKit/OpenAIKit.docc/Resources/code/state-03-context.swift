// ContextManager.swift
import Foundation

struct ConversationContext {
    var topic: String?
    var entities: [String: String] = [:]
    var sentiment: Sentiment = .neutral
    var intent: Intent = .unknown
    
    enum Sentiment {
        case positive, neutral, negative, mixed
    }
    
    enum Intent {
        case question, request, statement, greeting, farewell, unknown
    }
}

class ContextManager: ObservableObject {
    @Published private(set) var currentContext = ConversationContext()
    
    func updateContext(from message: String, role: ChatRole) {
        if role == .user {
            currentContext.topic = extractTopic(from: message)
            currentContext.intent = classifyIntent(message)
            currentContext.sentiment = analyzeSentiment(message)
        }
    }
    
    private func extractTopic(from text: String) -> String? {
        // Simple implementation
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.first { $0.count > 3 }
    }
    
    private func classifyIntent(_ text: String) -> ConversationContext.Intent {
        if text.contains("?") {
            return .question
        } else if text.lowercased().contains("hello") {
            return .greeting
        } else {
            return .statement
        }
    }
    
    private func analyzeSentiment(_ text: String) -> ConversationContext.Sentiment {
        // Simple sentiment analysis
        let positive = ["good", "great", "excellent", "happy"]
        let negative = ["bad", "terrible", "awful", "sad"]
        
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let hasPositive = words.contains { positive.contains($0) }
        let hasNegative = words.contains { negative.contains($0) }
        
        if hasPositive && !hasNegative {
            return .positive
        } else if hasNegative && !hasPositive {
            return .negative
        } else if hasPositive && hasNegative {
            return .mixed
        } else {
            return .neutral
        }
    }
}
