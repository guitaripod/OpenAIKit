// Controlling response length with max tokens
import OpenAIKit

// Short response
let shortRequest = ChatCompletionRequest(
    messages: [
        ChatMessage(role: .user, content: "Explain quantum physics")
    ],
    model: "gpt-4o-mini",
    maxTokens: 50  // Limit to ~40 words
)

// Longer response
let detailedRequest = ChatCompletionRequest(
    messages: [
        ChatMessage(role: .user, content: "Explain quantum physics")
    ],
    model: "gpt-4o-mini",
    maxTokens: 500  // Allow for detailed explanation
)

// With stop sequences
let listRequest = ChatCompletionRequest(
    messages: [
        ChatMessage(role: .user, content: "List 3 benefits of exercise:")
    ],
    model: "gpt-4o-mini",
    stop: ["4.", "\n\n"],  // Stop at "4." or double newline
    temperature: 0.3
)