// Creating different types of messages
import OpenAIKit

// System message - sets the AI's behavior
let systemMessage = ChatMessage(
    role: .system,
    content: "You are a helpful weather assistant. Always provide temperatures in both Celsius and Fahrenheit."
)

// User message
let userMessage = ChatMessage(
    role: .user, 
    content: "What's the weather like today?"
)