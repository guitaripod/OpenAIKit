// WeatherAssistant.swift - Complete execution flow
private func getFinalResponse() async throws -> String {
    // Create new request with function results
    let request = ChatCompletionRequest(
        messages: messages,
        model: "gpt-4o-mini"
    )
    
    let response = try await openAI.chat.completions(request)
    
    guard let choice = response.choices.first,
          let content = choice.message.content else {
        throw WeatherAssistantError.noResponse
    }
    
    // Store final response
    messages.append(choice.message)
    
    return content
}

// Public method to get conversation history
func getConversationHistory() -> [ChatMessage] {
    messages
}

// Clear conversation
func clearConversation() {
    messages = [messages.first!]  // Keep system prompt
}