// Parallel function execution
import OpenAIKit

class MultiWeatherAssistant {
    func processToolCalls(_ toolCalls: [ToolCall]) async throws -> [ChatMessage] {
        // Execute all function calls in parallel
        return try await withThrowingTaskGroup(of: ChatMessage?.self) { group in
            for toolCall in toolCalls {
                group.addTask {
                    return try await self.executeFunction(toolCall)
                }
            }
            
            var results: [ChatMessage] = []
            for try await result in group {
                if let message = result {
                    results.append(message)
                }
            }
            
            return results
        }
    }
    
    private func executeFunction(_ toolCall: ToolCall) async throws -> ChatMessage? {
        switch toolCall.function.name {
        case "get_weather":
            let args = try parseArgs(WeatherArgs.self, from: toolCall.function.arguments)
            let data = try await weatherService.getCurrentWeather(
                location: args.location,
                unit: args.unit ?? "celsius"
            )
            return ChatMessage(
                role: .tool,
                content: data.toJSON(),
                toolCallId: toolCall.id
            )
            
        case "get_forecast":
            let args = try parseArgs(ForecastArgs.self, from: toolCall.function.arguments)
            let data = try await weatherService.getForecast(
                location: args.location,
                days: args.days,
                unit: args.unit ?? "celsius"
            )
            return ChatMessage(
                role: .tool,
                content: data.toJSON(),
                toolCallId: toolCall.id
            )
            
        case "get_air_quality":
            let args = try parseArgs(AirQualityArgs.self, from: toolCall.function.arguments)
            let data = try await weatherService.getAirQuality(location: args.location)
            return ChatMessage(
                role: .tool,
                content: data.toJSON(),
                toolCallId: toolCall.id
            )
            
        default:
            return nil
        }
    }
    
    private func parseArgs<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
        guard let data = json.data(using: .utf8) else {
            throw WeatherAssistantError.invalidFunctionArguments
        }
        return try JSONDecoder().decode(type, from: data)
    }
}

// Argument types
struct ForecastArgs: Codable {
    let location: String
    let days: Int
    let unit: String?
}

struct AirQualityArgs: Codable {
    let location: String
}