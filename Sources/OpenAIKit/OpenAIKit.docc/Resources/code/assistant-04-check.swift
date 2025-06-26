// WeatherAssistant.swift - Processing function calls
private func processFunctionCalls(_ toolCalls: [ToolCall]) async throws -> String {
    var functionResults: [ChatMessage] = []
    
    for toolCall in toolCalls {
        if toolCall.function.name == "get_weather" {
            // Parse arguments
            let arguments = toolCall.function.arguments
            let decoder = JSONDecoder()
            
            guard let data = arguments.data(using: .utf8),
                  let args = try? decoder.decode(WeatherArgs.self, from: data) else {
                throw WeatherAssistantError.invalidFunctionArguments
            }
            
            // Execute function
            let weatherData = try await weatherService.getCurrentWeather(
                location: args.location,
                unit: args.unit ?? "celsius"
            )
            
            // Add function result as message
            let resultMessage = ChatMessage(
                role: .tool,
                content: weatherData.toJSON(),
                toolCallId: toolCall.id
            )
            functionResults.append(resultMessage)
            messages.append(resultMessage)
        }
    }
    
    // Get final response with function results
    return try await getFinalResponse()
}