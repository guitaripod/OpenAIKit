// Complete WeatherAssistant implementation
import Foundation
import OpenAIKit

class WeatherAssistant: ObservableObject {
    let openAI: OpenAIKit
    let weatherService = WeatherService.shared
    @Published var messages: [ChatMessage] = []
    @Published var isProcessing = false
    @Published var error: Error?
    
    private let getWeatherFunction = Function(
        name: "get_weather",
        description: "Get the current weather in a given location",
        parameters: JSONSchema(
            type: .object,
            properties: [
                "location": .init(type: .string, description: "The city and state, e.g. San Francisco, CA"),
                "unit": .init(type: .string, enum: ["celsius", "fahrenheit"], description: "Temperature unit")
            ],
            required: ["location"]
        )
    )
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
        messages.append(ChatMessage(
            role: .system,
            content: "You are a helpful weather assistant. When users ask about weather, use the get_weather function to provide accurate, friendly responses with weather information."
        ))
    }
    
    @MainActor
    func sendMessage(_ content: String) async {
        isProcessing = true
        error = nil
        
        do {
            let response = try await processMessage(content)
            // Response is automatically added to messages in processMessage
        } catch {
            self.error = error
            messages.append(ChatMessage(
                role: .assistant,
                content: "I'm sorry, I encountered an error: \(error.localizedDescription)"
            ))
        }
        
        isProcessing = false
    }
    
    private func processMessage(_ userMessage: String) async throws -> String {
        messages.append(ChatMessage(role: .user, content: userMessage))
        
        let request = ChatCompletionRequest(
            messages: messages,
            model: "gpt-4o-mini",
            tools: [Tool(type: .function, function: getWeatherFunction)],
            toolChoice: "auto"
        )
        
        let response = try await openAI.chat.completions(request)
        
        guard let choice = response.choices.first else {
            throw WeatherAssistantError.noResponse
        }
        
        messages.append(choice.message)
        
        if let toolCalls = choice.message.toolCalls, !toolCalls.isEmpty {
            return try await processFunctionCalls(toolCalls)
        } else {
            return choice.message.content ?? ""
        }
    }
    
    private func processFunctionCalls(_ toolCalls: [ToolCall]) async throws -> String {
        for toolCall in toolCalls {
            if toolCall.function.name == "get_weather" {
                let arguments = toolCall.function.arguments
                let decoder = JSONDecoder()
                
                guard let data = arguments.data(using: .utf8),
                      let args = try? decoder.decode(WeatherArgs.self, from: data) else {
                    throw WeatherAssistantError.invalidFunctionArguments
                }
                
                let weatherData = try await weatherService.getCurrentWeather(
                    location: args.location,
                    unit: args.unit ?? "celsius"
                )
                
                let resultMessage = ChatMessage(
                    role: .tool,
                    content: weatherData.toJSON(),
                    toolCallId: toolCall.id
                )
                messages.append(resultMessage)
            }
        }
        
        return try await getFinalResponse()
    }
    
    private func getFinalResponse() async throws -> String {
        let request = ChatCompletionRequest(
            messages: messages,
            model: "gpt-4o-mini"
        )
        
        let response = try await openAI.chat.completions(request)
        
        guard let choice = response.choices.first,
              let content = choice.message.content else {
            throw WeatherAssistantError.noResponse
        }
        
        messages.append(choice.message)
        return content
    }
}

// Supporting types
struct WeatherArgs: Codable {
    let location: String
    let unit: String?
}

enum WeatherAssistantError: LocalizedError {
    case noResponse
    case invalidFunctionArguments
    case functionExecutionFailed
    
    var errorDescription: String? {
        switch self {
        case .noResponse:
            return "No response from AI assistant"
        case .invalidFunctionArguments:
            return "Invalid function arguments"
        case .functionExecutionFailed:
            return "Failed to execute weather function"
        }
    }
}