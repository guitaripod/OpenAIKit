// Building a conversation with message history
import OpenAIKit

var messages: [ChatMessage] = []

// System prompt
messages.append(ChatMessage(
    role: .system,
    content: "You are a helpful weather assistant."
))

// User question
messages.append(ChatMessage(
    role: .user,
    content: "What's the weather in New York?"
))

// Assistant response (from previous API call)
messages.append(ChatMessage(
    role: .assistant,
    content: "The weather in New York is currently 72°F (22°C) with partly cloudy skies."
))

// Follow-up question
messages.append(ChatMessage(
    role: .user,
    content: "What about tomorrow?"
))

// Create request with full conversation
let request = ChatCompletionRequest(
    messages: messages,
    model: "gpt-4o-mini"
)