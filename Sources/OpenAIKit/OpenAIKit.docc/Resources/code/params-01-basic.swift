// Basic parameters for chat completion
import OpenAIKit

let request = ChatCompletionRequest(
    messages: [
        ChatMessage(role: .user, content: "Tell me a joke")
    ],
    model: "gpt-4o-mini"
)