// Controlling response creativity with temperature
import OpenAIKit

// Low temperature (0.2) - More focused and deterministic
let preciseRequest = ChatCompletionRequest(
    messages: [
        ChatMessage(role: .user, content: "What is 2+2?")
    ],
    model: "gpt-4o-mini",
    temperature: 0.2
)

// High temperature (0.9) - More creative and varied
let creativeRequest = ChatCompletionRequest(
    messages: [
        ChatMessage(role: .user, content: "Write a creative story opening")
    ],
    model: "gpt-4o-mini",
    temperature: 0.9
)