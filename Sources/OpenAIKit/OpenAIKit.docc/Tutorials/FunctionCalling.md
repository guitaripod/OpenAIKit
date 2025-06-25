# Function Calling Guide

Learn how to extend GPT models with custom functions for structured data extraction and tool integration.

## Overview

Function calling allows GPT models to generate structured outputs that can trigger actions in your application. This enables building assistants that can:

- Fetch real-time data
- Perform calculations
- Interact with APIs
- Control application features

## Basic Function Definition

### Simple Function

```swift
let getCurrentTimeFunction = Function(
    name: "get_current_time",
    description: "Get the current time in a specific timezone",
    parameters: [
        "type": "object",
        "properties": [
            "timezone": [
                "type": "string",
                "description": "The timezone identifier (e.g., 'America/New_York')"
            ]
        ],
        "required": ["timezone"]
    ]
)
```

### Complex Function

```swift
let createEventFunction = Function(
    name: "create_calendar_event",
    description: "Create a new calendar event",
    parameters: [
        "type": "object",
        "properties": [
            "title": [
                "type": "string",
                "description": "Event title"
            ],
            "start_time": [
                "type": "string",
                "format": "date-time",
                "description": "ISO 8601 formatted start time"
            ],
            "duration_minutes": [
                "type": "integer",
                "description": "Duration in minutes"
            ],
            "attendees": [
                "type": "array",
                "items": ["type": "string"],
                "description": "Email addresses of attendees"
            ],
            "location": [
                "type": "string",
                "description": "Event location (optional)"
            ]
        ],
        "required": ["title", "start_time", "duration_minutes"]
    ]
)
```

## Making Function Calls

### Single Function

```swift
let request = ChatCompletionRequest(
    messages: [
        ChatMessage(
            role: .user,
            content: "What time is it in Tokyo?"
        )
    ],
    model: "gpt-4o",
    tools: [
        Tool(type: .function, function: getCurrentTimeFunction)
    ],
    toolChoice: .auto
)

let response = try await openAI.chat.completions(request)

if let toolCall = response.choices.first?.message.toolCalls?.first,
   let functionCall = toolCall.function {
    print("Function: \(functionCall.name)")
    print("Arguments: \(functionCall.arguments)")
}
```

### Multiple Functions

```swift
let functions = [
    getCurrentTimeFunction,
    createEventFunction,
    // Add more functions...
]

let request = ChatCompletionRequest(
    messages: messages,
    model: "gpt-4o",
    tools: functions.map { Tool(type: .function, function: $0) },
    toolChoice: .auto  // Let the model decide which function to call
)
```

## Parsing Function Arguments

### Define Codable Types

```swift
struct TimeZoneArgs: Codable {
    let timezone: String
}

struct EventArgs: Codable {
    let title: String
    let startTime: String
    let durationMinutes: Int
    let attendees: [String]?
    let location: String?
    
    private enum CodingKeys: String, CodingKey {
        case title
        case startTime = "start_time"
        case durationMinutes = "duration_minutes"
        case attendees
        case location
    }
}
```

### Parse and Execute

```swift
func handleFunctionCall(_ toolCall: ToolCall) async throws -> ChatMessage {
    guard let functionCall = toolCall.function else {
        throw OpenAIError.invalidResponse
    }
    
    let result: String
    
    switch functionCall.name {
    case "get_current_time":
        let args = try JSONDecoder().decode(
            TimeZoneArgs.self,
            from: functionCall.arguments.data(using: .utf8)!
        )
        result = getCurrentTime(timezone: args.timezone)
        
    case "create_calendar_event":
        let args = try JSONDecoder().decode(
            EventArgs.self,
            from: functionCall.arguments.data(using: .utf8)!
        )
        result = try await createEvent(args)
        
    default:
        result = "Unknown function"
    }
    
    // Return the function result
    return ChatMessage(
        role: .tool,
        content: result,
        toolCallId: toolCall.id
    )
}
```

## Complete Function Flow

### Full Implementation

```swift
class FunctionCallingAssistant {
    let openAI: OpenAIKit
    var messages: [ChatMessage] = []
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
        self.messages.append(
            ChatMessage(
                role: .system,
                content: "You are a helpful assistant with access to various tools."
            )
        )
    }
    
    func process(_ userInput: String) async throws -> String {
        // Add user message
        messages.append(ChatMessage(role: .user, content: userInput))
        
        // Get model response
        let response = try await openAI.chat.completions(
            ChatCompletionRequest(
                messages: messages,
                model: "gpt-4o",
                tools: availableTools,
                toolChoice: .auto
            )
        )
        
        guard let choice = response.choices.first else {
            throw OpenAIError.invalidResponse
        }
        
        // Add assistant message
        messages.append(choice.message)
        
        // Check if function was called
        if let toolCalls = choice.message.toolCalls {
            // Execute all function calls
            for toolCall in toolCalls {
                let functionResult = try await handleFunctionCall(toolCall)
                messages.append(functionResult)
            }
            
            // Get final response after function execution
            let finalResponse = try await openAI.chat.completions(
                ChatCompletionRequest(
                    messages: messages,
                    model: "gpt-4o"
                )
            )
            
            if let finalMessage = finalResponse.choices.first?.message {
                messages.append(finalMessage)
                return finalMessage.content.stringValue ?? ""
            }
        }
        
        return choice.message.content.stringValue ?? ""
    }
}
```

## Advanced Patterns

### Parallel Function Calls

GPT-4 can call multiple functions in parallel:

```swift
// User: "What's the weather in Tokyo and New York?"
// The model might call get_weather twice in one response

if let toolCalls = response.choices.first?.message.toolCalls {
    // Execute functions concurrently
    let results = try await withThrowingTaskGroup(of: ChatMessage.self) { group in
        for toolCall in toolCalls {
            group.addTask {
                try await self.handleFunctionCall(toolCall)
            }
        }
        
        var messages: [ChatMessage] = []
        for try await result in group {
            messages.append(result)
        }
        return messages
    }
    
    // Add all results to conversation
    messages.append(contentsOf: results)
}
```

### Forced Function Calling

```swift
// Force a specific function
let request = ChatCompletionRequest(
    messages: messages,
    model: "gpt-4o",
    tools: tools,
    toolChoice: .function(name: "get_weather")
)

// Force any function (not normal chat)
let request = ChatCompletionRequest(
    messages: messages,
    model: "gpt-4o",
    tools: tools,
    toolChoice: .required
)
```

### Function Validation

```swift
struct FunctionValidator {
    static func validateArguments<T: Decodable>(
        _ arguments: String,
        as type: T.Type
    ) throws -> T {
        guard let data = arguments.data(using: .utf8) else {
            throw ValidationError.invalidJSON
        }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Validation failed: \(arguments)")
            throw ValidationError.invalidArguments(error)
        }
    }
}
```

## Real-World Examples

### Weather Assistant

```swift
let getWeatherFunction = Function(
    name: "get_weather",
    description: "Get current weather for a location",
    parameters: [
        "type": "object",
        "properties": [
            "location": [
                "type": "string",
                "description": "City and state/country"
            ],
            "unit": [
                "type": "string",
                "enum": ["celsius", "fahrenheit"],
                "default": "celsius"
            ]
        ],
        "required": ["location"]
    ]
)

func getWeather(location: String, unit: String = "celsius") async throws -> String {
    // Call weather API
    let weather = try await weatherAPI.fetch(location: location)
    let temp = unit == "celsius" ? weather.tempC : weather.tempF
    return """
    Weather in \(location):
    Temperature: \(temp)°\(unit == "celsius" ? "C" : "F")
    Condition: \(weather.condition)
    Humidity: \(weather.humidity)%
    """
}
```

### Database Query Assistant

```swift
let queryDatabaseFunction = Function(
    name: "query_database",
    description: "Execute a database query",
    parameters: [
        "type": "object",
        "properties": [
            "table": [
                "type": "string",
                "enum": ["users", "orders", "products"],
                "description": "Database table to query"
            ],
            "filters": [
                "type": "object",
                "description": "Query filters",
                "additionalProperties": true
            ],
            "limit": [
                "type": "integer",
                "description": "Maximum results to return",
                "default": 10
            ]
        ],
        "required": ["table"]
    ]
)
```

### Math Calculator

```swift
let calculateFunction = Function(
    name: "calculate",
    description: "Perform mathematical calculations",
    parameters: [
        "type": "object",
        "properties": [
            "expression": [
                "type": "string",
                "description": "Mathematical expression to evaluate"
            ]
        ],
        "required": ["expression"]
    ]
)

func calculate(expression: String) throws -> String {
    let expression = NSExpression(format: expression)
    if let result = expression.expressionValue(with: nil, context: nil) {
        return "Result: \(result)"
    }
    throw CalculationError.invalidExpression
}
```

## Best Practices

### 1. Clear Function Descriptions

```swift
// ❌ Vague description
Function(name: "search", description: "Search for something")

// ✅ Clear and specific
Function(
    name: "search_products",
    description: "Search for products in the catalog by name, category, or price range"
)
```

### 2. Validate Required Fields

```swift
func validateEventArgs(_ args: EventArgs) throws {
    if args.title.isEmpty {
        throw ValidationError.emptyTitle
    }
    
    if args.durationMinutes < 1 {
        throw ValidationError.invalidDuration
    }
    
    // Validate datetime format
    let formatter = ISO8601DateFormatter()
    guard formatter.date(from: args.startTime) != nil else {
        throw ValidationError.invalidDateFormat
    }
}
```

### 3. Handle Errors Gracefully

```swift
func handleFunctionCall(_ toolCall: ToolCall) async -> ChatMessage {
    do {
        let result = try await executeFunctionCall(toolCall)
        return ChatMessage(
            role: .tool,
            content: result,
            toolCallId: toolCall.id
        )
    } catch {
        // Return error to model so it can inform the user
        return ChatMessage(
            role: .tool,
            content: "Error: \(error.localizedDescription)",
            toolCallId: toolCall.id
        )
    }
}
```

### 4. Rate Limiting for External APIs

```swift
actor RateLimiter {
    private var lastCallTime: Date?
    private let minimumInterval: TimeInterval
    
    init(requestsPerSecond: Double) {
        self.minimumInterval = 1.0 / requestsPerSecond
    }
    
    func throttle() async {
        if let lastTime = lastCallTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < minimumInterval {
                try? await Task.sleep(
                    nanoseconds: UInt64((minimumInterval - elapsed) * 1_000_000_000)
                )
            }
        }
        lastCallTime = Date()
    }
}
```