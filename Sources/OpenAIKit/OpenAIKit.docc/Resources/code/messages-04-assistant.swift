// Complete conversation management
import OpenAIKit

class ConversationManager {
    var messages: [ChatMessage] = []
    
    init(systemPrompt: String? = nil) {
        if let prompt = systemPrompt {
            messages.append(ChatMessage(role: .system, content: prompt))
        }
    }
    
    func addUserMessage(_ content: String) {
        messages.append(ChatMessage(role: .user, content: content))
    }
    
    func addAssistantMessage(_ content: String) {
        messages.append(ChatMessage(role: .assistant, content: content))
    }
    
    func createRequest(model: String = "gpt-4o-mini") -> ChatCompletionRequest {
        ChatCompletionRequest(messages: messages, model: model)
    }
}