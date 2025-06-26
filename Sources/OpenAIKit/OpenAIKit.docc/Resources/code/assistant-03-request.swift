// WeatherAssistant.swift - Making the request
func processMessage(_ userMessage: String) async throws -> String {
    messages.append(ChatMessage(role: .user, content: userMessage))
    
    let request = ChatCompletionRequest(
        messages: messages,
        model: Models.Chat.gpt4oMini,
        tools: [
            Tool(type: .function, function: getWeatherFunction)
        ],
        toolChoice: "auto"  // Let the model decide when to use the function
    )
    
    let response = try await openAI.chat.completions(request)
    
    guard let choice = response.choices.first else {
        throw WeatherAssistantError.noResponse
    }
    
    // Store assistant's response
    messages.append(choice.message)
    
    // Check if function was called
    if let toolCalls = choice.message.toolCalls,
       !toolCalls.isEmpty {
        // Process function calls
        return try await processFunctionCalls(toolCalls)
    } else {
        // Return regular response
        return choice.message.content ?? ""
    }
}

enum WeatherAssistantError: Error {
    case noResponse
    case invalidFunctionArguments
    case functionExecutionFailed
}