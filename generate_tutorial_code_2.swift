#!/usr/bin/env swift

import Foundation

let baseDir = "Sources/OpenAIKit/OpenAIKit.docc/Resources/code"

// Tutorial 3: Working with Functions
let functionsCode = [
    "functions-01-empty.swift": """
// FunctionCalling.swift
""",
    
    "functions-02-args.swift": """
// FunctionCalling.swift
import Foundation
import OpenAIKit

// Define function arguments structure
struct WeatherArgs: Codable {
    let location: String
    let unit: String?
}
""",
    
    "functions-03-definition.swift": """
// FunctionCalling.swift
import Foundation
import OpenAIKit

// Define function arguments structure
struct WeatherArgs: Codable {
    let location: String
    let unit: String?
}

// Create function definition
let getWeatherFunction = Function(
    name: "get_weather",
    description: "Get the current weather in a given location"
)
""",
    
    "functions-04-schema.swift": """
// FunctionCalling.swift
import Foundation
import OpenAIKit

// Define function arguments structure
struct WeatherArgs: Codable {
    let location: String
    let unit: String?
}

// Create function definition with parameter schema
let getWeatherFunction = Function(
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
""",
    
    // Weather Service section
    "weather-01-service.swift": """
// WeatherService.swift
import Foundation

class WeatherService {
    static let shared = WeatherService()
    
    private init() {}
    
    func getCurrentWeather(location: String, unit: String = "celsius") async throws -> WeatherData {
        // Mock implementation
        return WeatherData(
            location: location,
            temperature: 22,
            unit: unit,
            description: "Sunny"
        )
    }
}
""",
    
    "weather-02-models.swift": """
// WeatherService.swift
import Foundation

struct WeatherData: Codable {
    let location: String
    let temperature: Double
    let unit: String
    let description: String
    let humidity: Int?
    let windSpeed: Double?
    
    var formattedTemperature: String {
        let symbol = unit == "celsius" ? "°C" : "°F"
        return "\\(Int(temperature))\\(symbol)"
    }
}

class WeatherService {
    static let shared = WeatherService()
    
    private init() {}
    
    func getCurrentWeather(location: String, unit: String = "celsius") async throws -> WeatherData {
        // Simulate API delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Mock weather data
        let temp = Double.random(in: 15...30)
        let fahrenheit = unit == "fahrenheit" ? (temp * 9/5) + 32 : temp
        
        return WeatherData(
            location: location,
            temperature: unit == "celsius" ? temp : fahrenheit,
            unit: unit,
            description: ["Sunny", "Partly Cloudy", "Cloudy", "Rainy"].randomElement()!,
            humidity: Int.random(in: 40...80),
            windSpeed: Double.random(in: 5...25)
        )
    }
}
""",
    
    "weather-03-fetch.swift": """
// WeatherService.swift with real API integration
import Foundation

class WeatherService {
    static let shared = WeatherService()
    private let apiKey = ProcessInfo.processInfo.environment["WEATHER_API_KEY"] ?? ""
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    
    func getCurrentWeather(location: String, unit: String = "celsius") async throws -> WeatherData {
        guard !apiKey.isEmpty else {
            // Return mock data if no API key
            return mockWeather(for: location, unit: unit)
        }
        
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "q", value: location),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: unit == "celsius" ? "metric" : "imperial")
        ]
        
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let response = try JSONDecoder().decode(WeatherAPIResponse.self, from: data)
        
        return WeatherData(
            location: location,
            temperature: response.main.temp,
            unit: unit,
            description: response.weather.first?.description ?? "Unknown",
            humidity: response.main.humidity,
            windSpeed: response.wind.speed
        )
    }
    
    private func mockWeather(for location: String, unit: String) -> WeatherData {
        WeatherData(
            location: location,
            temperature: 22,
            unit: unit,
            description: "Partly cloudy",
            humidity: 65,
            windSpeed: 12
        )
    }
}

// API Response Models
struct WeatherAPIResponse: Codable {
    let main: MainWeather
    let weather: [Weather]
    let wind: Wind
}

struct MainWeather: Codable {
    let temp: Double
    let humidity: Int
}

struct Weather: Codable {
    let description: String
}

struct Wind: Codable {
    let speed: Double
}
""",
    
    "weather-04-format.swift": """
// WeatherFormatter.swift
import Foundation

extension WeatherData {
    func formatForDisplay() -> String {
        var result = "Weather in \\(location):\\n"
        result += "🌡️ Temperature: \\(formattedTemperature)\\n"
        result += "☁️ Conditions: \\(description)\\n"
        
        if let humidity = humidity {
            result += "💧 Humidity: \\(humidity)%\\n"
        }
        
        if let windSpeed = windSpeed {
            let windUnit = unit == "celsius" ? "km/h" : "mph"
            result += "💨 Wind: \\(Int(windSpeed)) \\(windUnit)"
        }
        
        return result
    }
    
    func toJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        guard let data = try? encoder.encode(self),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        
        return json
    }
}
""",
    
    // Assistant section
    "assistant-01-class.swift": """
// WeatherAssistant.swift
import Foundation
import OpenAIKit

class WeatherAssistant {
    let openAI: OpenAIKit
    let weatherService = WeatherService.shared
    var messages: [ChatMessage] = []
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
        
        // Set system prompt
        messages.append(ChatMessage(
            role: .system,
            content: "You are a helpful weather assistant. When users ask about weather, use the get_weather function to provide accurate information."
        ))
    }
}
""",
    
    "assistant-02-process.swift": """
// WeatherAssistant.swift
import Foundation
import OpenAIKit

class WeatherAssistant {
    let openAI: OpenAIKit
    let weatherService = WeatherService.shared
    var messages: [ChatMessage] = []
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
        
        messages.append(ChatMessage(
            role: .system,
            content: "You are a helpful weather assistant. When users ask about weather, use the get_weather function to provide accurate information."
        ))
    }
    
    func processMessage(_ userMessage: String) async throws -> String {
        // Add user message
        messages.append(ChatMessage(role: .user, content: userMessage))
        
        // Create request with function
        let request = ChatCompletionRequest(
            messages: messages,
            model: "gpt-4o-mini",
            tools: [
                Tool(type: .function, function: getWeatherFunction)
            ]
        )
        
        // Get response
        let response = try await openAI.chat.completions(request)
        
        // Process response
        return ""
    }
}
""",
    
    "assistant-03-request.swift": """
// WeatherAssistant.swift - Making the request
func processMessage(_ userMessage: String) async throws -> String {
    messages.append(ChatMessage(role: .user, content: userMessage))
    
    let request = ChatCompletionRequest(
        messages: messages,
        model: "gpt-4o-mini",
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
""",
    
    "assistant-04-check.swift": """
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
""",
    
    "assistant-05-execute.swift": """
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
""",
    
    "assistant-06-complete.swift": """
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
                content: "I'm sorry, I encountered an error: \\(error.localizedDescription)"
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
""",
    
    // UI section
    "view-01-model.swift": """
// WeatherAssistantView.swift
import SwiftUI

struct WeatherAssistantView: View {
    @StateObject private var assistant: WeatherAssistant
    @State private var inputText = ""
    
    init(openAI: OpenAIKit) {
        _assistant = StateObject(wrappedValue: WeatherAssistant(openAI: openAI))
    }
    
    var body: some View {
        VStack {
            Text("Weather Assistant")
                .font(.title)
        }
    }
}
""",
    
    "view-02-ui.swift": """
// WeatherAssistantView.swift
import SwiftUI

struct WeatherAssistantView: View {
    @StateObject private var assistant: WeatherAssistant
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    
    init(openAI: OpenAIKit) {
        _assistant = StateObject(wrappedValue: WeatherAssistant(openAI: openAI))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Weather Assistant")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .shadow(radius: 1)
            
            // Messages
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(assistant.messages.filter { $0.role != .system }, id: \\.content) { message in
                        MessageRow(message: message)
                    }
                    
                    if assistant.isProcessing {
                        HStack {
                            ProgressView()
                            Text("Getting weather information...")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
                .padding()
            }
            
            // Input
            HStack {
                TextField("Ask about weather...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)
                
                Button("Send") {
                    sendMessage()
                }
                .disabled(inputText.isEmpty || assistant.isProcessing)
            }
            .padding()
        }
    }
    
    private func sendMessage() {
        let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        inputText = ""
        Task {
            await assistant.sendMessage(message)
        }
    }
}
""",
    
    "view-03-examples.swift": """
// WeatherAssistantView.swift - With example queries
struct WeatherAssistantView: View {
    @StateObject private var assistant: WeatherAssistant
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    
    let exampleQueries = [
        "What's the weather in San Francisco?",
        "Is it raining in London?",
        "Temperature in Tokyo in Fahrenheit",
        "How's the weather in Paris today?"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Messages or examples
            if assistant.messages.count <= 1 {  // Only system message
                examplesView
            } else {
                messagesView
            }
            
            // Input
            inputView
        }
    }
    
    private var examplesView: some View {
        VStack(spacing: 20) {
            Text("Try asking:")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                ForEach(exampleQueries, id: \\.self) { query in
                    Button(action: {
                        inputText = query
                        sendMessage()
                    }) {
                        Text(query)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
    }
}
""",
    
    "view-04-card.swift": """
// WeatherCardView.swift
import SwiftUI

struct WeatherCardView: View {
    let weatherData: WeatherData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Location
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                Text(weatherData.location)
                    .font(.headline)
            }
            
            // Temperature
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading) {
                    Text(weatherData.formattedTemperature)
                        .font(.system(size: 48, weight: .light))
                    Text(weatherData.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: weatherIcon)
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
            }
            
            // Additional info
            HStack(spacing: 30) {
                if let humidity = weatherData.humidity {
                    Label("\\(humidity)%", systemImage: "humidity.fill")
                }
                
                if let windSpeed = weatherData.windSpeed {
                    let windUnit = weatherData.unit == "celsius" ? "km/h" : "mph"
                    Label("\\(Int(windSpeed)) \\(windUnit)", systemImage: "wind")
                }
            }
            .font(.footnote)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var weatherIcon: String {
        switch weatherData.description.lowercased() {
        case let desc where desc.contains("sun") || desc.contains("clear"):
            return "sun.max.fill"
        case let desc where desc.contains("cloud"):
            return "cloud.fill"
        case let desc where desc.contains("rain"):
            return "cloud.rain.fill"
        case let desc where desc.contains("snow"):
            return "cloud.snow.fill"
        default:
            return "cloud.sun.fill"
        }
    }
}
""",
    
    "view-05-complete.swift": """
// Complete Weather Assistant UI
import SwiftUI
import OpenAIKit

struct WeatherAssistantView: View {
    @StateObject private var assistant: WeatherAssistant
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    
    let exampleQueries = [
        "What's the weather in San Francisco?",
        "Is it raining in London?",
        "Temperature in Tokyo in Fahrenheit",
        "How's the weather in Paris today?"
    ]
    
    init(openAI: OpenAIKit) {
        _assistant = StateObject(wrappedValue: WeatherAssistant(openAI: openAI))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            if assistant.messages.count <= 1 {
                examplesView
            } else {
                messagesView
            }
            
            if let error = assistant.error {
                errorView(error)
            }
            
            inputView
        }
        .onAppear {
            isInputFocused = true
        }
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: "cloud.sun.fill")
                .font(.title2)
                .foregroundColor(.blue)
            Text("Weather Assistant")
                .font(.title2)
                .fontWeight(.semibold)
            Spacer()
            if assistant.messages.count > 1 {
                Button("Clear") {
                    assistant.clearConversation()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(radius: 1)
    }
    
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(assistant.messages.enumerated()), id: \\.offset) { index, message in
                        if message.role != .system {
                            MessageRow(message: message)
                                .id(index)
                        }
                    }
                    
                    if assistant.isProcessing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Getting weather information...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .id("loading")
                    }
                }
                .padding()
                .onChange(of: assistant.messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(assistant.isProcessing ? "loading" : assistant.messages.count - 1)
                    }
                }
            }
        }
    }
    
    private var examplesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cloud.sun.rain.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding()
            
            Text("Ask me about the weather!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Try one of these:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                ForEach(exampleQueries, id: \\.self) { query in
                    Button(action: {
                        inputText = query
                        sendMessage()
                    }) {
                        HStack {
                            Image(systemName: "text.bubble")
                                .foregroundColor(.blue)
                            Text(query)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 40)
    }
    
    private var inputView: some View {
        HStack(spacing: 12) {
            TextField("Ask about weather...", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)
                .onSubmit {
                    sendMessage()
                }
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(sendButtonColor)
            }
            .disabled(inputText.isEmpty || assistant.isProcessing)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
    
    private func errorView(_ error: Error) -> some View {
        Text("Error: \\(error.localizedDescription)")
            .font(.caption)
            .foregroundColor(.red)
            .padding(.horizontal)
    }
    
    private var sendButtonColor: Color {
        inputText.isEmpty || assistant.isProcessing ? .gray : .blue
    }
    
    private func sendMessage() {
        let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        inputText = ""
        Task {
            await assistant.sendMessage(message)
        }
    }
}

// Message Row View
struct MessageRow: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Image(systemName: avatarIcon)
                .font(.title3)
                .foregroundColor(avatarColor)
                .frame(width: 30, height: 30)
                .background(Circle().fill(avatarColor.opacity(0.1)))
            
            // Message content
            VStack(alignment: .leading, spacing: 4) {
                Text(roleTitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                if message.role == .tool {
                    // Show weather card for function results
                    if let data = message.content.data(using: .utf8),
                       let weatherData = try? JSONDecoder().decode(WeatherData.self, from: data) {
                        WeatherCardView(weatherData: weatherData)
                    } else {
                        Text(message.content)
                            .font(.subheadline)
                    }
                } else {
                    Text(message.content)
                        .font(.subheadline)
                        .textSelection(.enabled)
                }
            }
            
            Spacer()
        }
    }
    
    private var avatarIcon: String {
        switch message.role {
        case .user:
            return "person.circle.fill"
        case .assistant:
            return "cloud.sun.fill"
        case .tool:
            return "function"
        default:
            return "circle.fill"
        }
    }
    
    private var avatarColor: Color {
        switch message.role {
        case .user:
            return .blue
        case .assistant:
            return .green
        case .tool:
            return .orange
        default:
            return .gray
        }
    }
    
    private var roleTitle: String {
        switch message.role {
        case .user:
            return "You"
        case .assistant:
            return "Weather Assistant"
        case .tool:
            return "Weather Data"
        default:
            return "System"
        }
    }
}
""",
    
    // Advanced section
    "advanced-01-multiple.swift": """
// Multiple function support
import OpenAIKit

// Define multiple functions
let functions = [
    Function(
        name: "get_weather",
        description: "Get the current weather in a given location",
        parameters: JSONSchema(
            type: .object,
            properties: [
                "location": .init(type: .string, description: "The city and state"),
                "unit": .init(type: .string, enum: ["celsius", "fahrenheit"])
            ],
            required: ["location"]
        )
    ),
    
    Function(
        name: "get_forecast",
        description: "Get weather forecast for the next few days",
        parameters: JSONSchema(
            type: .object,
            properties: [
                "location": .init(type: .string, description: "The city and state"),
                "days": .init(type: .integer, description: "Number of days (1-7)"),
                "unit": .init(type: .string, enum: ["celsius", "fahrenheit"])
            ],
            required: ["location", "days"]
        )
    ),
    
    Function(
        name: "get_air_quality",
        description: "Get air quality index for a location",
        parameters: JSONSchema(
            type: .object,
            properties: [
                "location": .init(type: .string, description: "The city and state")
            ],
            required: ["location"]
        )
    )
]

// Use in request
let request = ChatCompletionRequest(
    messages: messages,
    model: "gpt-4o-mini",
    tools: functions.map { Tool(type: .function, function: $0) },
    toolChoice: "auto"
)
""",
    
    "advanced-02-parallel.swift": """
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
""",
    
    "advanced-03-cache.swift": """
// Function result caching
import Foundation

class CachedWeatherService {
    private let cache = NSCache<NSString, CacheEntry>()
    private let cacheLifetime: TimeInterval = 300 // 5 minutes
    
    func getCurrentWeather(location: String, unit: String) async throws -> WeatherData {
        let cacheKey = "weather_\\(location)_\\(unit)" as NSString
        
        // Check cache
        if let cached = cache.object(forKey: cacheKey),
           cached.isValid {
            return cached.data as! WeatherData
        }
        
        // Fetch fresh data
        let weatherData = try await fetchWeather(location: location, unit: unit)
        
        // Cache result
        let entry = CacheEntry(data: weatherData, timestamp: Date())
        cache.setObject(entry, forKey: cacheKey)
        
        return weatherData
    }
    
    private func fetchWeather(location: String, unit: String) async throws -> WeatherData {
        // Actual API call here
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate API
        
        return WeatherData(
            location: location,
            temperature: 22,
            unit: unit,
            description: "Partly cloudy",
            humidity: 65,
            windSpeed: 12
        )
    }
}

class CacheEntry: NSObject {
    let data: Any
    let timestamp: Date
    
    init(data: Any, timestamp: Date) {
        self.data = data
        self.timestamp = timestamp
    }
    
    var isValid: Bool {
        Date().timeIntervalSince(timestamp) < 300 // 5 minutes
    }
}
""",
    
    "advanced-04-validation.swift": """
// Function argument validation
import Foundation

struct FunctionValidator {
    static func validateWeatherArgs(_ args: WeatherArgs) throws {
        // Validate location
        guard !args.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyLocation
        }
        
        // Validate unit if provided
        if let unit = args.unit {
            guard ["celsius", "fahrenheit"].contains(unit.lowercased()) else {
                throw ValidationError.invalidUnit(unit)
            }
        }
        
        // Check for common issues
        let location = args.location.lowercased()
        if location.count < 2 {
            throw ValidationError.locationTooShort
        }
        
        // Check for valid characters
        let allowedCharacters = CharacterSet.letters
            .union(.whitespaces)
            .union(.punctuationCharacters)
        
        guard location.rangeOfCharacter(from: allowedCharacters.inverted) == nil else {
            throw ValidationError.invalidCharacters
        }
    }
    
    static func validateForecastArgs(_ args: ForecastArgs) throws {
        // Validate location first
        try validateWeatherArgs(WeatherArgs(location: args.location, unit: args.unit))
        
        // Validate days
        guard (1...7).contains(args.days) else {
            throw ValidationError.invalidDayCount(args.days)
        }
    }
}

enum ValidationError: LocalizedError {
    case emptyLocation
    case locationTooShort
    case invalidCharacters
    case invalidUnit(String)
    case invalidDayCount(Int)
    
    var errorDescription: String? {
        switch self {
        case .emptyLocation:
            return "Location cannot be empty"
        case .locationTooShort:
            return "Location name is too short"
        case .invalidCharacters:
            return "Location contains invalid characters"
        case .invalidUnit(let unit):
            return "Invalid unit '\\(unit)'. Use 'celsius' or 'fahrenheit'"
        case .invalidDayCount(let days):
            return "Invalid day count \\(days). Must be between 1 and 7"
        }
    }
}

// Use in function execution
func executeWeatherFunction(_ args: WeatherArgs) async throws -> WeatherData {
    // Validate first
    try FunctionValidator.validateWeatherArgs(args)
    
    // Then execute
    return try await weatherService.getCurrentWeather(
        location: args.location,
        unit: args.unit ?? "celsius"
    )
}
"""
]

// Tutorial 4: Handling Errors
let errorsCode = [
    "errors-01-empty.swift": """
// ErrorHandling.swift
""",
    
    "errors-02-function.swift": """
// ErrorHandling.swift
import Foundation
import OpenAIKit

func sendChatMessage(_ message: String) async throws -> String {
    let openAI = OpenAIManager.shared.client!
    
    let request = ChatCompletionRequest(
        messages: [ChatMessage(role: .user, content: message)],
        model: "gpt-4o-mini"
    )
    
    let response = try await openAI.chat.completions(request)
    return response.choices.first?.message.content ?? ""
}
""",
    
    "errors-03-catch.swift": """
// ErrorHandling.swift
import Foundation
import OpenAIKit

func sendChatMessage(_ message: String) async -> Result<String, Error> {
    let openAI = OpenAIManager.shared.client!
    
    let request = ChatCompletionRequest(
        messages: [ChatMessage(role: .user, content: message)],
        model: "gpt-4o-mini"
    )
    
    do {
        let response = try await openAI.chat.completions(request)
        let content = response.choices.first?.message.content ?? ""
        return .success(content)
    } catch {
        return .failure(error)
    }
}

// Usage
Task {
    let result = await sendChatMessage("Hello!")
    
    switch result {
    case .success(let response):
        print("Response: \\(response)")
    case .failure(let error):
        print("Error: \\(error)")
    }
}
""",
    
    "errors-04-specific.swift": """
// ErrorHandling.swift - Handling specific errors
import Foundation
import OpenAIKit

func sendChatMessage(_ message: String) async -> Result<String, ChatError> {
    guard let openAI = OpenAIManager.shared.client else {
        return .failure(.clientNotInitialized)
    }
    
    let request = ChatCompletionRequest(
        messages: [ChatMessage(role: .user, content: message)],
        model: "gpt-4o-mini"
    )
    
    do {
        let response = try await openAI.chat.completions(request)
        guard let content = response.choices.first?.message.content else {
            return .failure(.noContent)
        }
        return .success(content)
    } catch let error as APIError {
        // Handle API errors
        return .failure(.apiError(error))
    } catch {
        // Handle other errors
        return .failure(.networkError(error))
    }
}

enum ChatError: LocalizedError {
    case clientNotInitialized
    case noContent
    case apiError(APIError)
    case networkError(Error)
    case rateLimitExceeded
    case invalidRequest(String)
    
    var errorDescription: String? {
        switch self {
        case .clientNotInitialized:
            return "OpenAI client is not initialized"
        case .noContent:
            return "No content in response"
        case .apiError(let error):
            return "API Error: \\(error.error.message)"
        case .networkError(let error):
            return "Network Error: \\(error.localizedDescription)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .invalidRequest(let reason):
            return "Invalid request: \\(reason)"
        }
    }
}
""",
    
    "errors-05-details.swift": """
// ErrorHandling.swift - Extracting error details
import Foundation
import OpenAIKit

class ErrorAnalyzer {
    static func analyze(_ error: Error) -> ErrorDetails {
        if let apiError = error as? APIError {
            return ErrorDetails(
                type: .api,
                code: apiError.error.code ?? "unknown",
                message: apiError.error.message,
                isRetryable: isRetryable(apiError),
                suggestedAction: suggestAction(for: apiError)
            )
        } else if let urlError = error as? URLError {
            return ErrorDetails(
                type: .network,
                code: String(urlError.code.rawValue),
                message: urlError.localizedDescription,
                isRetryable: urlError.code != .cancelled,
                suggestedAction: "Check your internet connection"
            )
        } else {
            return ErrorDetails(
                type: .unknown,
                code: "unknown",
                message: error.localizedDescription,
                isRetryable: false,
                suggestedAction: "Please try again or contact support"
            )
        }
    }
    
    private static func isRetryable(_ error: APIError) -> Bool {
        guard let code = error.error.code else { return false }
        
        switch code {
        case "rate_limit_exceeded", "server_error", "service_unavailable":
            return true
        case "invalid_api_key", "invalid_request", "invalid_model":
            return false
        default:
            return false
        }
    }
    
    private static func suggestAction(for error: APIError) -> String {
        guard let code = error.error.code else {
            return "Please try again"
        }
        
        switch code {
        case "rate_limit_exceeded":
            return "Wait a moment before trying again"
        case "invalid_api_key":
            return "Check your API key configuration"
        case "invalid_model":
            return "Use a valid model name like 'gpt-4o-mini'"
        case "context_length_exceeded":
            return "Reduce the length of your messages"
        case "server_error":
            return "OpenAI is experiencing issues. Try again later"
        default:
            return "Review your request and try again"
        }
    }
}

struct ErrorDetails {
    enum ErrorType {
        case api, network, unknown
    }
    
    let type: ErrorType
    let code: String
    let message: String
    let isRetryable: Bool
    let suggestedAction: String
}
""",
    
    // Retry Logic section
    "retry-01-wrapper.swift": """
// RetryWrapper.swift
import Foundation

class RetryWrapper {
    static func retry<T>(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                if attempt < maxAttempts {
                    // Wait before retrying
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? RetryError.unknownError
    }
}

enum RetryError: LocalizedError {
    case unknownError
    case maxAttemptsExceeded
    
    var errorDescription: String? {
        switch self {
        case .unknownError:
            return "An unknown error occurred"
        case .maxAttemptsExceeded:
            return "Maximum retry attempts exceeded"
        }
    }
}
""",
    
    "retry-02-backoff.swift": """
// Exponential backoff retry
import Foundation

class ExponentialBackoffRetry {
    static func retry<T>(
        maxAttempts: Int = 3,
        initialDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 60.0,
        multiplier: Double = 2.0,
        shouldRetry: @escaping (Error) -> Bool = { _ in true },
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var currentDelay = initialDelay
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Check if we should retry this error
                guard shouldRetry(error) else {
                    throw error
                }
                
                if attempt < maxAttempts {
                    // Add jitter to prevent thundering herd
                    let jitter = Double.random(in: 0.8...1.2)
                    let delay = min(currentDelay * jitter, maxDelay)
                    
                    print("Attempt \\(attempt) failed. Retrying in \\(String(format: "%.1f", delay)) seconds...")
                    
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    
                    // Increase delay for next attempt
                    currentDelay = min(currentDelay * multiplier, maxDelay)
                }
            }
        }
        
        throw RetryError.maxAttemptsExceeded
    }
}

// Usage with OpenAI
func sendMessageWithRetry(_ message: String) async throws -> String {
    try await ExponentialBackoffRetry.retry(
        maxAttempts: 3,
        initialDelay: 1.0,
        shouldRetry: { error in
            // Only retry certain errors
            if let apiError = error as? APIError {
                return ErrorAnalyzer.analyze(apiError).isRetryable
            }
            return error is URLError
        }
    ) {
        try await sendChatMessage(message)
    }
}
""",
    
    "retry-03-implementation.swift": """
// Complete retry implementation
import Foundation
import OpenAIKit

class RetryableOpenAIClient {
    let client: OpenAIKit
    let retryConfig: RetryConfiguration
    
    struct RetryConfiguration {
        let maxAttempts: Int
        let initialDelay: TimeInterval
        let maxDelay: TimeInterval
        let multiplier: Double
        
        static let `default` = RetryConfiguration(
            maxAttempts: 3,
            initialDelay: 1.0,
            maxDelay: 30.0,
            multiplier: 2.0
        )
    }
    
    init(client: OpenAIKit, retryConfig: RetryConfiguration = .default) {
        self.client = client
        self.retryConfig = retryConfig
    }
    
    func completions(_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        var currentDelay = retryConfig.initialDelay
        var lastError: Error?
        var attemptCount = 0
        
        for attempt in 1...retryConfig.maxAttempts {
            attemptCount = attempt
            
            do {
                let response = try await client.chat.completions(request)
                
                // Log success after retry
                if attempt > 1 {
                    print("Request succeeded after \\(attempt) attempts")
                }
                
                return response
            } catch {
                lastError = error
                
                // Analyze error
                let errorDetails = ErrorAnalyzer.analyze(error)
                
                // Don't retry non-retryable errors
                guard errorDetails.isRetryable else {
                    throw error
                }
                
                // Don't retry on last attempt
                guard attempt < retryConfig.maxAttempts else {
                    break
                }
                
                // Calculate delay with jitter
                let jitter = Double.random(in: 0.8...1.2)
                let delay = min(currentDelay * jitter, retryConfig.maxDelay)
                
                print("Attempt \\(attempt) failed: \\(errorDetails.message)")
                print("Retrying in \\(String(format: "%.1f", delay)) seconds...")
                
                // Wait before retry
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                // Increase delay for next attempt
                currentDelay = min(currentDelay * retryConfig.multiplier, retryConfig.maxDelay)
            }
        }
        
        // All attempts failed
        throw RetryError.allAttemptsFailed(
            attempts: attemptCount,
            lastError: lastError
        )
    }
}

enum RetryError: LocalizedError {
    case allAttemptsFailed(attempts: Int, lastError: Error?)
    
    var errorDescription: String? {
        switch self {
        case .allAttemptsFailed(let attempts, let error):
            let errorMessage = error?.localizedDescription ?? "Unknown error"
            return "All \\(attempts) attempts failed. Last error: \\(errorMessage)"
        }
    }
}
""",
    
    "retry-04-circuit.swift": """
// Circuit breaker pattern
import Foundation

actor CircuitBreaker {
    enum State {
        case closed
        case open(until: Date)
        case halfOpen
    }
    
    private var state: State = .closed
    private var failureCount = 0
    private let failureThreshold: Int
    private let timeout: TimeInterval
    private let successThreshold: Int
    private var successCount = 0
    
    init(
        failureThreshold: Int = 5,
        timeout: TimeInterval = 60,
        successThreshold: Int = 2
    ) {
        self.failureThreshold = failureThreshold
        self.timeout = timeout
        self.successThreshold = successThreshold
    }
    
    func canExecute() async -> Bool {
        switch state {
        case .closed:
            return true
            
        case .open(let until):
            if Date() > until {
                state = .halfOpen
                return true
            }
            return false
            
        case .halfOpen:
            return true
        }
    }
    
    func recordSuccess() async {
        switch state {
        case .closed:
            failureCount = 0
            
        case .halfOpen:
            successCount += 1
            if successCount >= successThreshold {
                state = .closed
                failureCount = 0
                successCount = 0
            }
            
        case .open:
            break
        }
    }
    
    func recordFailure() async {
        switch state {
        case .closed:
            failureCount += 1
            if failureCount >= failureThreshold {
                state = .open(until: Date().addingTimeInterval(timeout))
            }
            
        case .halfOpen:
            state = .open(until: Date().addingTimeInterval(timeout))
            successCount = 0
            
        case .open:
            break
        }
    }
    
    func reset() async {
        state = .closed
        failureCount = 0
        successCount = 0
    }
}

// Usage with OpenAI
class ResilientOpenAIClient {
    private let client: OpenAIKit
    private let circuitBreaker = CircuitBreaker()
    
    init(client: OpenAIKit) {
        self.client = client
    }
    
    func completions(_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        // Check circuit breaker
        guard await circuitBreaker.canExecute() else {
            throw CircuitBreakerError.circuitOpen
        }
        
        do {
            let response = try await client.chat.completions(request)
            await circuitBreaker.recordSuccess()
            return response
        } catch {
            await circuitBreaker.recordFailure()
            throw error
        }
    }
}

enum CircuitBreakerError: LocalizedError {
    case circuitOpen
    
    var errorDescription: String? {
        "Service temporarily unavailable. Please try again later."
    }
}
""",
    
    // User-Friendly Messages section
    "messages-01-mapper.swift": """
// ErrorMessageMapper.swift
import Foundation

struct ErrorMessageMapper {
    static func userFriendlyMessage(for error: Error) -> String {
        if let chatError = error as? ChatError {
            return chatError.userMessage
        }
        
        let details = ErrorAnalyzer.analyze(error)
        
        switch details.type {
        case .api:
            return mapAPIError(code: details.code)
        case .network:
            return mapNetworkError(details)
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
    
    private static func mapAPIError(code: String) -> String {
        switch code {
        case "rate_limit_exceeded":
            return "You're sending messages too quickly. Please wait a moment."
        case "invalid_api_key":
            return "Authentication failed. Please check your settings."
        case "context_length_exceeded":
            return "Your message is too long. Please try a shorter message."
        case "model_not_found":
            return "The AI model is not available. Please try again."
        case "server_error":
            return "The service is temporarily unavailable. Please try again."
        default:
            return "Unable to process your request. Please try again."
        }
    }
    
    private static func mapNetworkError(_ details: ErrorDetails) -> String {
        if details.message.contains("offline") || details.message.contains("connection") {
            return "No internet connection. Please check your network."
        } else if details.message.contains("timeout") {
            return "The request took too long. Please try again."
        } else {
            return "Connection error. Please check your internet and try again."
        }
    }
}

extension ChatError {
    var userMessage: String {
        switch self {
        case .clientNotInitialized:
            return "The app isn't ready yet. Please wait a moment."
        case .noContent:
            return "No response received. Please try again."
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment."
        case .invalidRequest(let reason):
            return "Invalid request: \\(reason)"
        default:
            return errorDescription ?? "An error occurred"
        }
    }
}
""",
    
    "messages-02-mapping.swift": """
// Error context and recovery suggestions
import Foundation

struct ErrorContext {
    let error: Error
    let operation: String
    let context: [String: Any]
    
    func userMessage() -> UserErrorMessage {
        let details = ErrorAnalyzer.analyze(error)
        
        return UserErrorMessage(
            title: title(for: details),
            message: message(for: details),
            actions: suggestedActions(for: details),
            icon: icon(for: details)
        )
    }
    
    private func title(for details: ErrorDetails) -> String {
        switch details.type {
        case .api:
            return "Service Error"
        case .network:
            return "Connection Error"
        case .unknown:
            return "Unexpected Error"
        }
    }
    
    private func message(for details: ErrorDetails) -> String {
        switch operation {
        case "chat":
            return "Unable to send your message. \\(details.suggestedAction)"
        case "image_generation":
            return "Unable to generate image. \\(details.suggestedAction)"
        case "transcription":
            return "Unable to transcribe audio. \\(details.suggestedAction)"
        default:
            return ErrorMessageMapper.userFriendlyMessage(for: error)
        }
    }
    
    private func suggestedActions(for details: ErrorDetails) -> [ErrorAction] {
        var actions: [ErrorAction] = []
        
        if details.isRetryable {
            actions.append(.retry)
        }
        
        switch details.code {
        case "invalid_api_key":
            actions.append(.configure)
        case "rate_limit_exceeded":
            actions.append(.wait(seconds: 60))
        case "context_length_exceeded":
            actions.append(.reduce)
        default:
            break
        }
        
        actions.append(.dismiss)
        
        return actions
    }
    
    private func icon(for details: ErrorDetails) -> String {
        switch details.type {
        case .api:
            return "exclamationmark.triangle"
        case .network:
            return "wifi.exclamationmark"
        case .unknown:
            return "questionmark.circle"
        }
    }
}

struct UserErrorMessage {
    let title: String
    let message: String
    let actions: [ErrorAction]
    let icon: String
}

enum ErrorAction {
    case retry
    case dismiss
    case configure
    case wait(seconds: Int)
    case reduce
    case contactSupport
    
    var title: String {
        switch self {
        case .retry:
            return "Try Again"
        case .dismiss:
            return "OK"
        case .configure:
            return "Settings"
        case .wait(let seconds):
            return "Wait \\(seconds)s"
        case .reduce:
            return "Shorten Message"
        case .contactSupport:
            return "Get Help"
        }
    }
}
""",
    
    "messages-03-localized.swift": """
// Localized error messages
import Foundation

class LocalizedErrorHandler {
    static func localizedMessage(for error: Error) -> String {
        let key = errorKey(for: error)
        return NSLocalizedString(key, comment: "")
    }
    
    private static func errorKey(for error: Error) -> String {
        let details = ErrorAnalyzer.analyze(error)
        
        switch details.type {
        case .api:
            return "error.api.\\(details.code)"
        case .network:
            return "error.network.\\(details.code)"
        case .unknown:
            return "error.unknown"
        }
    }
}

// Localizable.strings
/*
"error.api.rate_limit_exceeded" = "You're sending messages too quickly. Please wait a moment before trying again.";
"error.api.invalid_api_key" = "Unable to authenticate. Please check your API key in settings.";
"error.api.context_length_exceeded" = "Your message is too long. Please try sending a shorter message.";
"error.api.server_error" = "The service is temporarily unavailable. Please try again later.";
"error.network.-1009" = "No internet connection. Please check your network settings.";
"error.network.-1001" = "The request timed out. Please check your connection and try again.";
"error.unknown" = "An unexpected error occurred. Please try again.";
*/

// Usage in SwiftUI
struct ErrorAlert: ViewModifier {
    @Binding var error: Error?
    
    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: .constant(error != nil),
                presenting: error
            ) { _ in
                Button("OK") {
                    error = nil
                }
            } message: { error in
                Text(LocalizedErrorHandler.localizedMessage(for: error))
            }
    }
}

extension View {
    func errorAlert(error: Binding<Error?>) -> some View {
        modifier(ErrorAlert(error: error))
    }
}
""",
    
    "messages-04-actionable.swift": """
// Actionable error messages with recovery
import SwiftUI

struct ActionableError: Identifiable {
    let id = UUID()
    let error: Error
    let context: ErrorContext
    let recovery: ErrorRecovery?
    
    var userMessage: UserErrorMessage {
        context.userMessage()
    }
}

protocol ErrorRecovery {
    func attemptRecovery() async -> Bool
}

struct RetryRecovery: ErrorRecovery {
    let action: () async throws -> Void
    
    func attemptRecovery() async -> Bool {
        do {
            try await action()
            return true
        } catch {
            return false
        }
    }
}

struct ConfigurationRecovery: ErrorRecovery {
    let openSettings: () -> Void
    
    func attemptRecovery() async -> Bool {
        openSettings()
        return true
    }
}

// SwiftUI Error Presentation
struct ActionableErrorView: View {
    let error: ActionableError
    @Environment(\\.dismiss) var dismiss
    @State private var isRecovering = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: error.userMessage.icon)
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text(error.userMessage.title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error.userMessage.message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                ForEach(error.userMessage.actions, id: \\.title) { action in
                    Button(action: {
                        handleAction(action)
                    }) {
                        Text(action.title)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(backgroundForAction(action))
                            .foregroundColor(foregroundForAction(action))
                            .cornerRadius(10)
                    }
                    .disabled(isRecovering)
                }
            }
            .padding(.top)
            
            if isRecovering {
                ProgressView("Recovering...")
                    .padding()
            }
        }
        .padding()
        .frame(maxWidth: 400)
    }
    
    private func handleAction(_ action: ErrorAction) {
        switch action {
        case .retry:
            if let recovery = error.recovery {
                Task {
                    isRecovering = true
                    let success = await recovery.attemptRecovery()
                    isRecovering = false
                    if success {
                        dismiss()
                    }
                }
            }
        case .dismiss:
            dismiss()
        case .configure:
            if let recovery = error.recovery as? ConfigurationRecovery {
                Task {
                    _ = await recovery.attemptRecovery()
                    dismiss()
                }
            }
        case .wait:
            dismiss()
        default:
            dismiss()
        }
    }
    
    private func backgroundForAction(_ action: ErrorAction) -> Color {
        switch action {
        case .retry:
            return .blue
        case .dismiss:
            return Color(.systemGray5)
        default:
            return Color(.systemGray6)
        }
    }
    
    private func foregroundForAction(_ action: ErrorAction) -> Color {
        switch action {
        case .retry:
            return .white
        default:
            return .primary
        }
    }
}
""",
    
    // Error Handler section
    "handler-01-class.swift": """
// CentralizedErrorHandler.swift
import Foundation
import Combine

@MainActor
class CentralizedErrorHandler: ObservableObject {
    static let shared = CentralizedErrorHandler()
    
    @Published var currentError: ActionableError?
    @Published var errorHistory: [ErrorRecord] = []
    @Published var isShowingError = false
    
    private init() {}
    
    func handle(
        _ error: Error,
        operation: String,
        context: [String: Any] = [:],
        recovery: ErrorRecovery? = nil
    ) {
        let errorContext = ErrorContext(
            error: error,
            operation: operation,
            context: context
        )
        
        let actionableError = ActionableError(
            error: error,
            context: errorContext,
            recovery: recovery
        )
        
        currentError = actionableError
        isShowingError = true
        
        // Record error
        recordError(error, operation: operation)
    }
    
    private func recordError(_ error: Error, operation: String) {
        let record = ErrorRecord(
            timestamp: Date(),
            error: error,
            operation: operation,
            resolved: false
        )
        
        errorHistory.append(record)
        
        // Keep only last 50 errors
        if errorHistory.count > 50 {
            errorHistory.removeFirst()
        }
    }
}

struct ErrorRecord: Identifiable {
    let id = UUID()
    let timestamp: Date
    let error: Error
    let operation: String
    var resolved: Bool
}
""",
    
    "handler-02-tracking.swift": """
// Error tracking and analytics
import Foundation

class ErrorTracker {
    static let shared = ErrorTracker()
    
    private var errorCounts: [String: Int] = [:]
    private var errorTimestamps: [String: [Date]] = [:]
    private let windowSize: TimeInterval = 3600 // 1 hour
    
    func track(_ error: Error, operation: String) {
        let errorKey = key(for: error)
        
        // Update count
        errorCounts[errorKey, default: 0] += 1
        
        // Track timestamp
        var timestamps = errorTimestamps[errorKey, default: []]
        timestamps.append(Date())
        
        // Remove old timestamps
        let cutoff = Date().addingTimeInterval(-windowSize)
        timestamps.removeAll { $0 < cutoff }
        
        errorTimestamps[errorKey] = timestamps
        
        // Check for error patterns
        checkErrorPatterns(errorKey: errorKey, timestamps: timestamps)
    }
    
    private func key(for error: Error) -> String {
        let details = ErrorAnalyzer.analyze(error)
        return "\\(details.type)_\\(details.code)"
    }
    
    private func checkErrorPatterns(errorKey: String, timestamps: [Date]) {
        // Alert if too many errors in time window
        if timestamps.count > 10 {
            notifyHighErrorRate(errorKey: errorKey, count: timestamps.count)
        }
    }
    
    private func notifyHighErrorRate(errorKey: String, count: Int) {
        print("⚠️ High error rate detected: \\(errorKey) occurred \\(count) times in the last hour")
        
        // Could send to analytics service
        // Analytics.track("high_error_rate", properties: ["error": errorKey, "count": count])
    }
    
    func errorRate(for errorKey: String) -> Double {
        let timestamps = errorTimestamps[errorKey, default: []]
        let recentTimestamps = timestamps.filter { 
            $0 > Date().addingTimeInterval(-windowSize) 
        }
        
        return Double(recentTimestamps.count) / (windowSize / 60) // errors per minute
    }
    
    func mostCommonErrors(limit: Int = 5) -> [(error: String, count: Int)] {
        errorCounts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }
}

// Error Dashboard View
struct ErrorDashboard: View {
    @State private var commonErrors: [(error: String, count: Int)] = []
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Error Analytics")
                .font(.title)
            
            ForEach(commonErrors, id: \\.error) { item in
                HStack {
                    Text(item.error)
                        .font(.caption)
                    Spacer()
                    Text("\\(item.count)")
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 4)
            }
        }
        .onAppear {
            commonErrors = ErrorTracker.shared.mostCommonErrors()
        }
    }
}
""",
    
    "handler-03-recovery.swift": """
// Automatic error recovery strategies
import Foundation

class ErrorRecoveryManager {
    static let shared = ErrorRecoveryManager()
    
    func recoveryStrategy(for error: Error, context: ErrorContext) -> ErrorRecovery? {
        let details = ErrorAnalyzer.analyze(error)
        
        switch details.type {
        case .api:
            return apiRecoveryStrategy(details: details, context: context)
        case .network:
            return networkRecoveryStrategy(details: details, context: context)
        case .unknown:
            return nil
        }
    }
    
    private func apiRecoveryStrategy(details: ErrorDetails, context: ErrorContext) -> ErrorRecovery? {
        switch details.code {
        case "rate_limit_exceeded":
            return DelayedRetryRecovery(delay: 60) {
                // Retry the operation after delay
                try await retryOperation(context)
            }
            
        case "invalid_api_key":
            return ConfigurationRecovery {
                // Open settings
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            
        case "context_length_exceeded":
            return MessageTruncationRecovery(context: context)
            
        default:
            if details.isRetryable {
                return RetryRecovery {
                    try await retryOperation(context)
                }
            }
            return nil
        }
    }
    
    private func networkRecoveryStrategy(details: ErrorDetails, context: ErrorContext) -> ErrorRecovery? {
        return NetworkRecovery {
            // Wait for network
            await waitForNetwork()
            try await retryOperation(context)
        }
    }
    
    private func retryOperation(_ context: ErrorContext) async throws {
        // Re-execute the original operation based on context
        switch context.operation {
        case "chat":
            if let message = context.context["message"] as? String {
                _ = try await sendChatMessage(message)
            }
        default:
            break
        }
    }
    
    private func waitForNetwork() async {
        // Implement network monitoring
        // For now, just wait
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
}

struct DelayedRetryRecovery: ErrorRecovery {
    let delay: TimeInterval
    let action: () async throws -> Void
    
    func attemptRecovery() async -> Bool {
        do {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            try await action()
            return true
        } catch {
            return false
        }
    }
}

struct MessageTruncationRecovery: ErrorRecovery {
    let context: ErrorContext
    
    func attemptRecovery() async -> Bool {
        guard let message = context.context["message"] as? String else {
            return false
        }
        
        // Truncate message to fit context limit
        let truncated = String(message.prefix(2000)) + "..."
        
        do {
            _ = try await sendChatMessage(truncated)
            return true
        } catch {
            return false
        }
    }
}

struct NetworkRecovery: ErrorRecovery {
    let action: () async throws -> Void
    
    func attemptRecovery() async -> Bool {
        // Check network availability first
        // This is simplified - in real app use NWPathMonitor
        do {
            try await action()
            return true
        } catch {
            return false
        }
    }
}
""",
    
    "handler-04-ui.swift": """
// Error UI components
import SwiftUI

struct ErrorBanner: View {
    let error: Error
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                
                Text(ErrorMessageMapper.userFriendlyMessage(for: error))
                    .font(.subheadline)
                    .lineLimit(isExpanded ? nil : 1)
                
                Spacer()
                
                if !isExpanded {
                    Button(action: { isExpanded = true }) {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                }
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let retry = onRetry {
                        Button("Try Again", action: retry)
                            .font(.caption)
                            .padding(.top, 4)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemYellow).opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemYellow).opacity(0.3), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

// Error toast notification
struct ErrorToast: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.red)
        .cornerRadius(8)
        .shadow(radius: 4)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// Error handling view modifier
struct ErrorHandling: ViewModifier {
    @StateObject private var errorHandler = CentralizedErrorHandler.shared
    
    func body(content: Content) -> some View {
        content
            .sheet(item: $errorHandler.currentError) { error in
                ActionableErrorView(error: error)
            }
            .overlay(alignment: .top) {
                if let error = errorHandler.currentError,
                   !errorHandler.isShowingError {
                    ErrorToast(message: error.userMessage.message)
                        .padding(.top)
                        .onTapGesture {
                            errorHandler.isShowingError = true
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                if !errorHandler.isShowingError {
                                    errorHandler.currentError = nil
                                }
                            }
                        }
                }
            }
    }
}

extension View {
    func handlesErrors() -> some View {
        modifier(ErrorHandling())
    }
}
""",
    
    "handler-05-state.swift": """
// Error state management
import SwiftUI
import Combine

@MainActor
class ErrorStateManager: ObservableObject {
    @Published var errors: [UUID: Error] = [:]
    @Published var isRetrying: [UUID: Bool] = [:]
    @Published var errorStates: [UUID: ErrorState] = [:]
    
    enum ErrorState {
        case active
        case recovering
        case resolved
        case dismissed
    }
    
    func setError(_ error: Error, for id: UUID) {
        errors[id] = error
        errorStates[id] = .active
    }
    
    func clearError(for id: UUID) {
        errors.removeValue(forKey: id)
        errorStates.removeValue(forKey: id)
        isRetrying.removeValue(forKey: id)
    }
    
    func startRetry(for id: UUID) {
        isRetrying[id] = true
        errorStates[id] = .recovering
    }
    
    func endRetry(for id: UUID, success: Bool) {
        isRetrying[id] = false
        if success {
            errorStates[id] = .resolved
            // Clear after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.clearError(for: id)
            }
        } else {
            errorStates[id] = .active
        }
    }
}

// Usage in a view
struct ContentViewWithErrors: View {
    @StateObject private var errorManager = ErrorStateManager()
    @State private var taskId = UUID()
    
    var body: some View {
        VStack {
            // Main content
            Button("Perform Task") {
                Task {
                    await performTask()
                }
            }
            
            // Error display
            if let error = errorManager.errors[taskId] {
                ErrorRow(
                    error: error,
                    state: errorManager.errorStates[taskId] ?? .active,
                    isRetrying: errorManager.isRetrying[taskId] ?? false,
                    onRetry: {
                        Task {
                            await retryTask()
                        }
                    },
                    onDismiss: {
                        errorManager.clearError(for: taskId)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(), value: errorManager.errors.count)
    }
    
    private func performTask() async {
        do {
            // Perform operation
            _ = try await sendChatMessage("Hello")
        } catch {
            errorManager.setError(error, for: taskId)
        }
    }
    
    private func retryTask() async {
        errorManager.startRetry(for: taskId)
        
        do {
            // Retry operation
            _ = try await sendChatMessage("Hello")
            errorManager.endRetry(for: taskId, success: true)
        } catch {
            errorManager.setError(error, for: taskId)
            errorManager.endRetry(for: taskId, success: false)
        }
    }
}

struct ErrorRow: View {
    let error: Error
    let state: ErrorStateManager.ErrorState
    let isRetrying: Bool
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .animation(.easeInOut, value: state)
            
            VStack(alignment: .leading) {
                Text(ErrorMessageMapper.userFriendlyMessage(for: error))
                    .font(.subheadline)
                
                if state == .resolved {
                    Text("Resolved")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            if isRetrying {
                ProgressView()
                    .scaleEffect(0.8)
            } else if state == .active {
                Button("Retry", action: onRetry)
                    .font(.caption)
            }
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(8)
    }
    
    private var iconName: String {
        switch state {
        case .active:
            return "exclamationmark.triangle.fill"
        case .recovering:
            return "arrow.clockwise"
        case .resolved:
            return "checkmark.circle.fill"
        case .dismissed:
            return "xmark.circle"
        }
    }
    
    private var iconColor: Color {
        switch state {
        case .active:
            return .red
        case .recovering:
            return .orange
        case .resolved:
            return .green
        case .dismissed:
            return .gray
        }
    }
    
    private var backgroundColor: Color {
        switch state {
        case .active:
            return Color(.systemRed).opacity(0.1)
        case .recovering:
            return Color(.systemOrange).opacity(0.1)
        case .resolved:
            return Color(.systemGreen).opacity(0.1)
        case .dismissed:
            return Color(.systemGray).opacity(0.1)
        }
    }
}
"""
]

// Write all files
func writeFiles(_ files: [String: String]) {
    for (filename, content) in files {
        let path = (baseDir as NSString).appendingPathComponent(filename)
        do {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
            print("Created: \(filename)")
        } catch {
            print("Error creating \(filename): \(error)")
        }
    }
}

// Generate all tutorial files
print("Generating tutorial code files for Functions and Error Handling...")
writeFiles(functionsCode)
writeFiles(errorsCode)

print("\nGenerated \(functionsCode.count + errorsCode.count) files")
print("Total files created so far: \(29 + functionsCode.count + errorsCode.count)")