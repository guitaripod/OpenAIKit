// Different models for different use cases
import OpenAIKit

// Fast, cost-effective model
let quickRequest = ChatCompletionRequest(
    messages: [ChatMessage(role: .user, content: "Hello!")],
    model: Models.Chat.gpt4oMini
)

// More capable model for complex tasks
let complexRequest = ChatCompletionRequest(
    messages: [
        ChatMessage(role: .system, content: "You are an expert programmer."),
        ChatMessage(role: .user, content: "Explain the SOLID principles with code examples")
    ],
    model: Models.Chat.gpt4o,
    temperature: 0.7
)

// Multiple responses
let multipleRequest = ChatCompletionRequest(
    messages: [ChatMessage(role: .user, content: "Suggest a name for my cat")],
    model: Models.Chat.gpt4oMini,
    n: 3,  // Get 3 different suggestions
    temperature: 0.8
)