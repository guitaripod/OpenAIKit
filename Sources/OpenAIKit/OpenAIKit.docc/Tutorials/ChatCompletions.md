# Working with Chat Completions

Master the chat completions API with advanced techniques and best practices.

## Overview

Chat completions are the foundation of conversational AI in OpenAI's API. This guide covers everything from basic usage to advanced features like function calling and streaming.

## Basic Conversations

### Single Turn

The simplest form is a single user message:

```swift
let response = try await openAI.chat.completions(
    ChatCompletionRequest(
        messages: [
            ChatMessage(role: .user, content: "What is the capital of France?")
        ],
        model: "gpt-4o-mini"
    )
)
```

### Multi-Turn Conversations

Build context with conversation history:

```swift
var messages: [ChatMessage] = [
    ChatMessage(
        role: .system,
        content: "You are a helpful geography teacher."
    )
]

// First user message
messages.append(ChatMessage(role: .user, content: "What is the capital of France?"))
let response1 = try await openAI.chat.completions(
    ChatCompletionRequest(messages: messages, model: "gpt-4o")
)
messages.append(response1.choices.first!.message)

// Follow-up question
messages.append(ChatMessage(role: .user, content: "What is its population?"))
let response2 = try await openAI.chat.completions(
    ChatCompletionRequest(messages: messages, model: "gpt-4o")
)
```

## Advanced Parameters

### Temperature and Creativity

Control randomness with temperature:

```swift
// Creative writing (high temperature)
let creative = ChatCompletionRequest(
    messages: messages,
    model: "gpt-4o",
    temperature: 0.8,
    topP: 0.9
)

// Factual responses (low temperature)
let factual = ChatCompletionRequest(
    messages: messages,
    model: "gpt-4o",
    temperature: 0.2,
    topP: 0.1
)
```

### Response Formatting

#### JSON Mode

```swift
let request = ChatCompletionRequest(
    messages: [
        ChatMessage(
            role: .system,
            content: "Extract information and respond in JSON format."
        ),
        ChatMessage(
            role: .user,
            content: "Apple Inc. was founded in 1976 by Steve Jobs and Steve Wozniak."
        )
    ],
    model: "gpt-4o",
    responseFormat: ResponseFormat(type: .jsonObject)
)
```

#### Structured Output

```swift
let schema = JSONSchema(
    name: "CompanyInfo",
    schema: [
        "type": "object",
        "properties": [
            "name": ["type": "string"],
            "founded": ["type": "integer"],
            "founders": [
                "type": "array",
                "items": ["type": "string"]
            ]
        ],
        "required": ["name", "founded", "founders"]
    ],
    strict: true
)

let request = ChatCompletionRequest(
    messages: messages,
    model: "gpt-4o",
    responseFormat: ResponseFormat(type: .jsonSchema, jsonSchema: schema)
)
```

## Function Calling

### Defining Functions

```swift
let getWeatherFunction = Function(
    name: "get_weather",
    description: "Get the current weather in a location",
    parameters: [
        "type": "object",
        "properties": [
            "location": [
                "type": "string",
                "description": "The city and state, e.g. San Francisco, CA"
            ],
            "unit": [
                "type": "string",
                "enum": ["celsius", "fahrenheit"],
                "description": "The temperature unit"
            ]
        ],
        "required": ["location"]
    ]
)

let searchFunction = Function(
    name: "search_web",
    description: "Search the web for information",
    parameters: [
        "type": "object",
        "properties": [
            "query": [
                "type": "string",
                "description": "The search query"
            ]
        ],
        "required": ["query"]
    ]
)
```

### Using Functions

```swift
let request = ChatCompletionRequest(
    messages: [
        ChatMessage(role: .user, content: "What's the weather in Tokyo?")
    ],
    model: "gpt-4o",
    tools: [
        Tool(type: .function, function: getWeatherFunction),
        Tool(type: .function, function: searchFunction)
    ],
    toolChoice: .auto
)

let response = try await openAI.chat.completions(request)

// Check if function was called
if let toolCall = response.choices.first?.message.toolCalls?.first {
    print("Function called: \(toolCall.function?.name ?? "")")
    print("Arguments: \(toolCall.function?.arguments ?? "")")
    
    // Parse arguments and execute function
    if let data = toolCall.function?.arguments.data(using: .utf8),
       let args = try? JSONDecoder().decode([String: String].self, from: data) {
        // Execute the function with arguments
        let weatherData = getWeather(location: args["location"] ?? "")
        
        // Send function result back
        messages.append(ChatMessage(
            role: .tool,
            content: weatherData,
            toolCallId: toolCall.id
        ))
    }
}
```

## Streaming Responses

### Basic Streaming

```swift
for try await chunk in openAI.chat.completionsStream(request) {
    if let content = chunk.choices.first?.delta.content {
        print(content, terminator: "")
        // Update UI in real-time
    }
}
```

### Streaming with Function Calls

```swift
var functionName = ""
var functionArguments = ""

for try await chunk in openAI.chat.completionsStream(request) {
    if let toolCall = chunk.choices.first?.delta.toolCalls?.first {
        if let name = toolCall.function?.name {
            functionName = name
        }
        if let args = toolCall.function?.arguments {
            functionArguments += args
        }
    }
    
    if let finishReason = chunk.choices.first?.finishReason {
        if finishReason == .toolCalls {
            print("Function: \(functionName)")
            print("Arguments: \(functionArguments)")
        }
    }
}
```

## Multimodal Conversations

### Text and Images

```swift
let messages = [
    ChatMessage(
        role: .user,
        content: .parts([
            MessagePart(type: .text, text: "What's in this image?"),
            MessagePart(
                type: .imageUrl,
                imageUrl: ImageURL(
                    url: "https://example.com/image.jpg",
                    detail: .high
                )
            )
        ])
    )
]

let response = try await openAI.chat.completions(
    ChatCompletionRequest(
        messages: messages,
        model: "gpt-4o",
        maxCompletionTokens: 300
    )
)
```

### Base64 Images

```swift
let imageData = try Data(contentsOf: imageURL)
let base64String = imageData.base64EncodedString()

let message = ChatMessage(
    role: .user,
    content: .parts([
        MessagePart(type: .text, text: "Describe this image in detail."),
        MessagePart(
            type: .imageUrl,
            imageUrl: ImageURL(
                url: "data:image/jpeg;base64,\(base64String)",
                detail: .high
            )
        )
    ])
)
```

## Token Management

### Limiting Response Length

```swift
let request = ChatCompletionRequest(
    messages: messages,
    model: "gpt-4o",
    maxCompletionTokens: 100,  // Limit response to ~75 words
    stop: ["\n\n", "END"]      // Stop sequences
)
```

### Calculating Costs

```swift
extension ChatCompletionResponse {
    func estimatedCost(model: String) -> Double? {
        guard let usage = usage else { return nil }
        
        // Prices per 1M tokens (example rates)
        let pricing: [String: (input: Double, output: Double)] = [
            "gpt-4o": (5.0, 15.0),
            "gpt-4o-mini": (0.15, 0.6),
            "gpt-3.5-turbo": (0.5, 1.5)
        ]
        
        guard let rate = pricing[model] else { return nil }
        
        let inputCost = Double(usage.promptTokens) / 1_000_000 * rate.input
        let outputCost = Double(usage.completionTokens) / 1_000_000 * rate.output
        
        return inputCost + outputCost
    }
}
```

## Best Practices

### Conversation Management

```swift
class ConversationManager {
    private var messages: [ChatMessage] = []
    private let maxMessages = 20
    private let openAI: OpenAIKit
    
    init(openAI: OpenAIKit, systemPrompt: String) {
        self.openAI = openAI
        self.messages.append(
            ChatMessage(role: .system, content: systemPrompt)
        )
    }
    
    func addUserMessage(_ content: String) {
        messages.append(ChatMessage(role: .user, content: content))
        trimMessages()
    }
    
    func getAssistantResponse() async throws -> String {
        let response = try await openAI.chat.completions(
            ChatCompletionRequest(
                messages: messages,
                model: "gpt-4o"
            )
        )
        
        if let message = response.choices.first?.message {
            messages.append(message)
            trimMessages()
            return message.content.stringValue ?? ""
        }
        
        throw OpenAIError.invalidResponse
    }
    
    private func trimMessages() {
        // Keep system message and recent messages
        if messages.count > maxMessages {
            let systemMessage = messages.first { $0.role == .system }
            let recentMessages = Array(messages.suffix(maxMessages - 1))
            messages = [systemMessage].compactMap { $0 } + recentMessages
        }
    }
}
```

### Error Recovery

```swift
func robustChatCompletion(_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
    var lastError: Error?
    
    for attempt in 1...3 {
        do {
            return try await openAI.chat.completions(request)
        } catch OpenAIError.rateLimitExceeded {
            // Exponential backoff
            let delay = pow(2.0, Double(attempt))
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            lastError = error
        } catch OpenAIError.serverError {
            // Retry server errors
            try await Task.sleep(nanoseconds: 1_000_000_000)
            lastError = error
        } catch {
            // Don't retry other errors
            throw error
        }
    }
    
    throw lastError ?? OpenAIError.unknownError(statusCode: 0)
}
```