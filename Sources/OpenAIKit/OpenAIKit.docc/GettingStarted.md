# Getting Started with OpenAIKit

Learn how to integrate OpenAIKit into your project and make your first API calls.

@Metadata {
    @PageImage(purpose: icon, source: "openaikit-icon", alt: "OpenAIKit icon")
    @PageColor(blue)
}

## Overview

This guide walks you through setting up OpenAIKit in your Swift project, from installation to making your first API calls. By the end of this guide, you'll be able to:

- Install and configure OpenAIKit
- Authenticate with the OpenAI API
- Generate text completions
- Handle streaming responses
- Implement proper error handling
- Follow best practices for production apps

## Installation

### Requirements

- **Swift**: 5.9 or later
- **Platforms**:
  - iOS 15.0+
  - macOS 12.0+
  - watchOS 8.0+
  - tvOS 15.0+
  - visionOS 1.0+
  - Linux (with Swift 5.9+)
- **Xcode**: 15.0+ (for Apple platforms)

### Swift Package Manager

OpenAIKit is distributed exclusively through Swift Package Manager, Apple's official dependency manager.

#### Installing with Xcode

1. Open your project in Xcode
2. Select **File** → **Add Package Dependencies...**
3. Enter the repository URL:
   ```
   https://github.com/marcusziade/OpenAIKit.git
   ```
4. Choose your version requirements:
   - **Up to Next Major**: `1.0.0` (Recommended)
   - **Branch**: `main` (Latest features)
   - **Exact Version**: `1.0.0` (Specific release)
5. Click **Add Package**
6. Select your target and click **Add Package**

#### Installing with Package.swift

For command-line tools or server-side Swift applications:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15),
        .visionOS(.v1)
    ],
    dependencies: [
        // Add OpenAIKit as a dependency
        .package(
            url: "https://github.com/marcusziade/OpenAIKit.git",
            from: "1.0.0"
        )
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: [
                // Add to your target dependencies
                .product(name: "OpenAIKit", package: "OpenAIKit")
            ]
        ),
        .testTarget(
            name: "MyAppTests",
            dependencies: ["MyApp"]
        )
    ]
)
```

### Verifying Installation

After installation, verify OpenAIKit is properly integrated:

```swift
import OpenAIKit

// This should compile without errors
let _ = OpenAIKit.self
```

## Authentication

### Obtaining an API Key

Before using OpenAIKit, you'll need an API key from OpenAI:

1. **Create an Account**: Visit [platform.openai.com](https://platform.openai.com) and sign up
2. **Navigate to API Keys**: Go to your [API keys page](https://platform.openai.com/api-keys)
3. **Create New Key**: Click **"Create new secret key"**
4. **Name Your Key**: Give it a descriptive name (e.g., "MyApp Production")
5. **Copy Immediately**: Copy the key immediately - you won't be able to see it again
6. **Set Permissions**: Configure the key's permissions based on your needs

> Important: API keys are secret credentials. Treat them like passwords:
> - Never commit them to source control
> - Don't embed them in client-side code
> - Use environment variables or secure key storage
> - Rotate keys regularly
> - Monitor usage for unauthorized access

### Secure Key Storage

#### Environment Variables (Recommended)

```swift
import Foundation
import OpenAIKit

// Store your key in environment variables
// In Terminal: export OPENAI_API_KEY="sk-..."

guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
    fatalError("Missing OPENAI_API_KEY environment variable")
}

let openAI = OpenAIKit(apiKey: apiKey)
```

#### Keychain Storage (iOS/macOS)

```swift
import Security
import OpenAIKit

class SecureKeyStorage {
    static func saveAPIKey(_ key: String) {
        let data = key.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "OpenAIAPIKey",
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary) // Delete existing
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "OpenAIAPIKey",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
}

// Usage
if let apiKey = SecureKeyStorage.getAPIKey() {
    let openAI = OpenAIKit(apiKey: apiKey)
}
```

### Client Initialization

#### Basic Setup

```swift
import OpenAIKit

// Simple initialization with API key
let openAI = OpenAIKit(apiKey: "your-api-key")
```

#### Organization Scoping

If you belong to multiple organizations:

```swift
// Scope requests to a specific organization
let openAI = OpenAIKit(
    apiKey: "your-api-key",
    organization: "org-abc123",
    project: "proj-xyz789"  // Optional project ID
)
```

#### Advanced Configuration

For custom requirements like proxy servers or extended timeouts:

```swift
// Create a custom configuration
let config = Configuration(
    apiKey: "your-api-key",
    organization: "org-abc123",
    project: nil,
    baseURL: URL(string: "https://custom-proxy.com")!,
    timeoutInterval: 120  // 2 minutes for long operations
)

// Initialize with custom configuration
let openAI = OpenAIKit(configuration: config)
```

#### Configuration Options

- **apiKey**: Your OpenAI API key (required)
- **organization**: Organization ID for scoping requests
- **project**: Project ID for further scoping
- **baseURL**: Custom API endpoint (default: `https://api.openai.com`)
- **timeoutInterval**: Request timeout in seconds (default: 60)

## Your First Request

### Chat Completion Basics

The chat completion endpoint is the heart of OpenAIKit. Here's how to make your first request:

```swift
import OpenAIKit

// Initialize the client
let openAI = OpenAIKit(apiKey: "your-api-key")

// Create a simple request
let response = try await openAI.chat.completions(
    ChatCompletionRequest(
        messages: [
            ChatMessage(role: .user, content: "Hello, how are you?")
        ],
        model: Models.Chat.gpt4oMini
    )
)

// Extract and print the response
if let content = response.choices.first?.message.content {
    print("Assistant: \(content)")
}

// Check token usage
if let usage = response.usage {
    print("Tokens used: \(usage.totalTokens)")
}
```

### Understanding the Response

The response contains rich information:

```swift
// Full response structure
let response = try await openAI.chat.completions(request)

// Primary response content
let message = response.choices.first?.message
print("Role: \(message?.role ?? .assistant)")
print("Content: \(message?.content ?? "")")

// Metadata
print("Model used: \(response.model)")
print("Response ID: \(response.id)")
print("Created: \(Date(timeIntervalSince1970: TimeInterval(response.created)))")

// Token usage (important for cost monitoring)
if let usage = response.usage {
    print("Prompt tokens: \(usage.promptTokens)")
    print("Completion tokens: \(usage.completionTokens)")
    print("Total tokens: \(usage.totalTokens)")
}

// Multiple choices (if n > 1 in request)
for (index, choice) in response.choices.enumerated() {
    print("Choice \(index + 1): \(choice.message.content ?? "")")
}
```

### Streaming Responses

Streaming provides a better user experience for longer responses:

```swift
// Create a streaming request
let request = ChatCompletionRequest(
    messages: [
        ChatMessage(role: .user, content: "Write a short story about a robot.")
    ],
    model: Models.Chat.gpt4o
)

// Handle the stream
do {
    var fullResponse = ""
    
    for try await chunk in openAI.chat.completionsStream(request) {
        // Each chunk contains a delta (partial update)
        if let delta = chunk.choices.first?.delta {
            // Append content as it arrives
            if let content = delta.content {
                fullResponse += content
                print(content, terminator: "") // Print without newline
            }
            
            // Handle function calls in streaming
            if let toolCalls = delta.toolCalls {
                // Process streaming tool calls
            }
        }
        
        // Check for completion
        if let finishReason = chunk.choices.first?.finishReason {
            print("\n\nFinished: \(finishReason)")
        }
    }
    
    print("\n\nFull response: \(fullResponse)")
} catch {
    print("Streaming error: \(error)")
}
```

### Streaming in SwiftUI

```swift
import SwiftUI
import OpenAIKit

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentResponse: String = ""
    @Published var isStreaming = false
    
    private let openAI = OpenAIKit(apiKey: "your-api-key")
    
    func sendMessage(_ content: String) {
        // Add user message
        messages.append(ChatMessage(role: .user, content: content))
        
        // Start streaming
        isStreaming = true
        currentResponse = ""
        
        Task {
            do {
                let request = ChatCompletionRequest(
                    messages: messages,
                    model: Models.Chat.gpt4o
                )
                
                for try await chunk in openAI.chat.completionsStream(request) {
                    if let content = chunk.choices.first?.delta.content {
                        currentResponse += content
                    }
                }
                
                // Add complete response as assistant message
                messages.append(
                    ChatMessage(role: .assistant, content: currentResponse)
                )
                currentResponse = ""
            } catch {
                currentResponse = "Error: \(error.localizedDescription)"
            }
            
            isStreaming = false
        }
    }
}

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var inputText = ""
    
    var body: some View {
        VStack {
            ScrollView {
                ForEach(viewModel.messages, id: \.content) { message in
                    MessageBubble(message: message)
                }
                
                if viewModel.isStreaming {
                    MessageBubble(
                        message: ChatMessage(
                            role: .assistant,
                            content: viewModel.currentResponse
                        )
                    )
                }
            }
            
            HStack {
                TextField("Type a message...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Send") {
                    viewModel.sendMessage(inputText)
                    inputText = ""
                }
                .disabled(viewModel.isStreaming || inputText.isEmpty)
            }
            .padding()
        }
    }
}
```

## Common Use Cases

OpenAIKit supports a wide range of AI capabilities. Here are practical examples for the most common scenarios:

### Text Generation

```swift
let response = try await openAI.chat.completions(
    ChatCompletionRequest(
        messages: [
            ChatMessage(
                role: .system,
                content: "You are a creative writing assistant."
            ),
            ChatMessage(
                role: .user,
                content: "Write a haiku about programming."
            )
        ],
        model: Models.Chat.gpt4o,
        temperature: 0.8
    )
)
```

### Code Generation

```swift
let response = try await openAI.chat.completions(
    ChatCompletionRequest(
        messages: [
            ChatMessage(
                role: .system,
                content: "You are a Swift programming expert."
            ),
            ChatMessage(
                role: .user,
                content: "Write a function to validate email addresses."
            )
        ],
        model: Models.Chat.gpt4o,
        temperature: 0.2
    )
)
```

### Image Generation

```swift
let imageResponse = try await openAI.images.generations(
    ImageGenerationRequest(
        prompt: "A futuristic city at sunset, digital art style",
        model: Models.Images.dallE3,
        size: "1024x1024",
        quality: "hd"
    )
)

if let imageURL = imageResponse.data.first?.url {
    // Download and display the image
}
```

### Audio Transcription

```swift
let audioData = try Data(contentsOf: audioFileURL)

let transcription = try await openAI.audio.transcriptions(
    TranscriptionRequest(
        file: audioData,
        fileName: "recording.mp3",
        model: Models.Audio.whisper1
    )
)

print(transcription.text)
```

### Text Embeddings

```swift
let embedding = try await openAI.embeddings.create(
    EmbeddingRequest(
        input: "OpenAI provides powerful AI models.",
        model: Models.Embeddings.textEmbedding3Small
    )
)

let vector = embedding.data.first?.embedding.floatValues ?? []
```

### Conversation with Context

```swift
// Build a conversation with context
var messages: [ChatMessage] = [
    ChatMessage(
        role: .system,
        content: """You are a helpful coding assistant. You provide clear, 
                   concise answers with code examples when appropriate."""
    ),
    ChatMessage(
        role: .user,
        content: "How do I sort an array in Swift?"
    ),
    ChatMessage(
        role: .assistant,
        content: """In Swift, you can sort arrays using several methods:

                   1. `sorted()` - Returns a new sorted array
                   2. `sort()` - Sorts the array in place (for var arrays)

                   Example:
                   ```swift
                   let numbers = [3, 1, 4, 1, 5]
                   let sorted = numbers.sorted() // [1, 1, 3, 4, 5]
                   ```"""
    ),
    ChatMessage(
        role: .user,
        content: "How about sorting in descending order?"
    )
]

// Continue the conversation
let response = try await openAI.chat.completions(
    ChatCompletionRequest(
        messages: messages,
        model: Models.Chat.gpt4o,
        temperature: 0.3  // Lower temperature for more focused responses
    )
)
```

### Function Calling

```swift
// Define a function for structured output
let getWeatherFunction = Function(
    name: "get_weather",
    description: "Get the current weather for a location",
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

// Make a request with function calling
let request = ChatCompletionRequest(
    messages: [
        ChatMessage(
            role: .user,
            content: "What's the weather in Tokyo?"
        )
    ],
    model: Models.Chat.gpt4o,
    tools: [
        Tool(type: .function, function: getWeatherFunction)
    ],
    toolChoice: .auto  // Let the model decide when to call functions
)

let response = try await openAI.chat.completions(request)

// Handle function calls
if let toolCalls = response.choices.first?.message.toolCalls {
    for toolCall in toolCalls {
        if toolCall.type == .function {
            print("Function: \(toolCall.function.name)")
            print("Arguments: \(toolCall.function.arguments)")
            
            // Parse arguments and make actual API call
            // Then send the result back to continue the conversation
        }
    }
}
```

### Vision Capabilities

```swift
// Analyze images with GPT-4 Vision
let imageURL = "https://example.com/image.jpg"

let request = ChatCompletionRequest(
    messages: [
        ChatMessage(
            role: .user,
            content: [
                .text("What's in this image?"),
                .imageURL(ChatImageURL(
                    url: imageURL,
                    detail: .high  // Use .low for faster, cheaper analysis
                ))
            ]
        )
    ],
    model: Models.Chat.gpt4o  // Vision-capable model
)

let response = try await openAI.chat.completions(request)
```

### JSON Mode and Structured Outputs

OpenAIKit supports two ways to get JSON responses:
- **JSON Mode** (`.jsonObject`): Ensures valid JSON but requires prompt engineering
- **Structured Outputs** (`.jsonSchema`): Guarantees responses match your exact schema

#### JSON Mode Example

```swift
// Request structured JSON output
struct Recipe: Codable {
    let name: String
    let ingredients: [String]
    let instructions: [String]
    let prepTime: Int
    let cookTime: Int
}

let request = ChatCompletionRequest(
    messages: [
        ChatMessage(
            role: .system,
            content: "You are a recipe generator. Always respond with valid JSON."
        ),
        ChatMessage(
            role: .user,
            content: """Generate a recipe for chocolate chip cookies. 
                       Use this JSON structure:
                       {
                         "name": "string",
                         "ingredients": ["string"],
                         "instructions": ["string"],
                         "prepTime": "number (minutes)",
                         "cookTime": "number (minutes)"
                       }"""
        )
    ],
    model: Models.Chat.gpt4o,
    responseFormat: ResponseFormat(type: .jsonObject)
)

let response = try await openAI.chat.completions(request)

if let content = response.choices.first?.message.content,
   let data = content.data(using: .utf8) {
    let recipe = try JSONDecoder().decode(Recipe.self, from: data)
    print("Recipe: \(recipe.name)")
    print("Total time: \(recipe.prepTime + recipe.cookTime) minutes")
}
```

#### Structured Outputs with JSON Schema

For guaranteed schema compliance, use `.jsonSchema`:

```swift
// Define exact schema with JSON Schema
let recipeSchema = JSONSchema(
    name: "recipe_schema",
    schema: [
        "type": "object",
        "properties": [
            "name": ["type": "string", "maxLength": 100],
            "ingredients": [
                "type": "array",
                "items": ["type": "string", "maxLength": 50],
                "maxItems": 20
            ],
            "instructions": [
                "type": "array", 
                "items": ["type": "string", "maxLength": 200],
                "maxItems": 10
            ],
            "prepTime": ["type": "integer", "minimum": 0],
            "cookTime": ["type": "integer", "minimum": 0]
        ],
        "required": ["name", "ingredients", "instructions", "prepTime", "cookTime"]
    ],
    strict: true
)

let request = ChatCompletionRequest(
    messages: [
        ChatMessage(role: .user, content: "Generate a recipe for chocolate chip cookies")
    ],
    model: Models.Chat.gpt4o,
    responseFormat: ResponseFormat(type: .jsonSchema, jsonSchema: recipeSchema)
)

// Response will exactly match the schema
let response = try await openAI.chat.completions(request)
```

> **Important Schema Limits**: OpenAI has increased structured output limits:
> - Object properties: Up to 5,000 per object
> - String length: Up to 120,000 characters
> - Enum values: Up to 1,000 per enum
> - Enum string total: For enums with >250 values, up to 15,000 total characters
>
> See ``JSONSchema`` documentation for complete details.

## Error Handling

Robust error handling is crucial for production applications. OpenAIKit provides detailed error information:

### Basic Error Handling

```swift
do {
    let response = try await openAI.chat.completions(request)
    // Handle success
} catch let error as OpenAIError {
    switch error {
    case .authenticationFailed:
        print("Authentication failed. Check your API key.")
        // Prompt user to update their API key
        
    case .rateLimitExceeded:
        print("Rate limit exceeded. Please wait before retrying.")
        // Implement exponential backoff
        
    case .apiError(let apiError):
        print("API Error: \(apiError.error.message)")
        // Handle specific API errors
        if let errorType = apiError.error.type {
            switch errorType {
            case "invalid_request_error":
                // Fix request parameters
                break
            case "server_error":
                // Retry after delay
                break
            default:
                break
            }
        }
        
    case .invalidURL:
        print("Invalid URL configuration")
        
    case .invalidResponse:
        print("Server returned invalid response")
        
    case .decodingFailed(let decodingError):
        print("Failed to decode response: \(decodingError)")
        
    case .clientError(let statusCode):
        print("Client error: HTTP \(statusCode)")
        
    case .serverError(let statusCode):
        print("Server error: HTTP \(statusCode)")
        
    default:
        print("Error: \(error.localizedDescription)")
    }
} catch {
    print("Unexpected error: \(error)")
}
```

### Advanced Error Recovery

```swift
import Foundation

class APIClient {
    private let openAI: OpenAIKit
    private let maxRetries = 3
    
    init(apiKey: String) {
        self.openAI = OpenAIKit(apiKey: apiKey)
    }
    
    func makeRequestWithRetry<T>(
        _ request: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await request()
            } catch let error as OpenAIError {
                lastError = error
                
                // Check if error is retryable
                if error.isRetryable {
                    let delay = error.suggestedRetryDelay ?? pow(2.0, Double(attempt))
                    print("Attempt \(attempt + 1) failed. Retrying in \(delay)s...")
                    
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                
                // Non-retryable error
                throw error
            } catch {
                // Unknown error
                throw error
            }
        }
        
        throw lastError ?? OpenAIError.unknownError(statusCode: -1)
    }
    
    // Usage example
    func getChatCompletion(_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        return try await makeRequestWithRetry {
            try await self.openAI.chat.completions(request)
        }
    }
}
```

### User-Friendly Error Messages

```swift
import SwiftUI

// Extension for UI-friendly error messages
extension OpenAIError {
    var userMessage: (title: String, message: String, isRetryable: Bool) {
        switch self {
        case .authenticationFailed:
            return (
                "Authentication Error",
                "Please check your API key in settings.",
                false
            )
            
        case .rateLimitExceeded:
            return (
                "Too Many Requests",
                "You've exceeded the rate limit. Please wait a moment.",
                true
            )
            
        case .apiError(let error):
            return (
                "Request Failed",
                error.error.message,
                error.error.type == "server_error"
            )
            
        case .serverError:
            return (
                "Server Error",
                "OpenAI is experiencing issues. Please try again later.",
                true
            )
            
        case .invalidResponse:
            return (
                "Invalid Response",
                "Received an unexpected response. Please try again.",
                true
            )
            
        default:
            return (
                "Error",
                self.localizedDescription,
                false
            )
        }
    }
}

// SwiftUI error alert
struct ContentView: View {
    @State private var showError = false
    @State private var errorInfo: (title: String, message: String, isRetryable: Bool)?
    
    var body: some View {
        // Your view content
        Text("OpenAIKit Demo")
            .alert(isPresented: $showError) {
                Alert(
                    title: Text(errorInfo?.title ?? "Error"),
                    message: Text(errorInfo?.message ?? "An error occurred"),
                    primaryButton: .default(Text("OK")),
                    secondaryButton: errorInfo?.isRetryable == true
                        ? .default(Text("Retry"), action: retry)
                        : .cancel()
                )
            }
    }
    
    func handleError(_ error: Error) {
        if let openAIError = error as? OpenAIError {
            errorInfo = openAIError.userMessage
            showError = true
        }
    }
    
    func retry() {
        // Retry the failed operation
    }
}
```

## Best Practices

Follow these guidelines to build robust, secure, and efficient applications with OpenAIKit:

### API Key Security

```swift
// ❌ NEVER: Hardcode API keys
let openAI = OpenAIKit(apiKey: "sk-abc123...")  // Security vulnerability!

// ❌ NEVER: Store in UserDefaults
UserDefaults.standard.set("sk-abc123...", forKey: "apiKey")  // Not secure!

// ❌ NEVER: Include in Info.plist
// API keys in Info.plist are visible to anyone who inspects your app

// ✅ DO: Use environment variables
if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
    let openAI = OpenAIKit(apiKey: apiKey)
} else {
    // Handle missing key appropriately
    fatalError("Set OPENAI_API_KEY environment variable")
}

// ✅ DO: Use Keychain (iOS/macOS)
import KeychainAccess

let keychain = Keychain(service: "com.yourapp.openai")
    .accessibility(.whenUnlockedThisDeviceOnly)  // Device-specific
    .synchronizable(false)  // Don't sync across devices

// Save key (one-time setup)
try keychain.set("your-api-key", key: "openai_api_key")

// Retrieve key
if let apiKey = try? keychain.getString("openai_api_key") {
    let openAI = OpenAIKit(apiKey: apiKey)
}

// ✅ DO: Use server proxy for production
// Instead of exposing API keys in client apps, use a backend service
class APIProxy {
    func makeOpenAIRequest(_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        // Forward request to your backend
        // Backend handles OpenAI communication with server-side API key
    }
}
```

### Rate Limiting & Retry Logic

```swift
import Foundation

// Sophisticated retry handler with exponential backoff
actor RateLimitHandler {
    private var requestTimes: [Date] = []
    private let maxRequestsPerMinute = 20  // Adjust based on your tier
    
    func canMakeRequest() -> Bool {
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)
        
        // Remove old timestamps
        requestTimes.removeAll { $0 < oneMinuteAgo }
        
        return requestTimes.count < maxRequestsPerMinute
    }
    
    func recordRequest() {
        requestTimes.append(Date())
    }
    
    func waitTime() -> TimeInterval? {
        guard !canMakeRequest() else { return nil }
        
        // Calculate time until oldest request expires
        if let oldestRequest = requestTimes.first {
            let timeSinceOldest = Date().timeIntervalSince(oldestRequest)
            return max(0, 60 - timeSinceOldest)
        }
        
        return nil
    }
}

// Retry with circuit breaker pattern
class SmartRetryHandler {
    private let rateLimiter = RateLimitHandler()
    private var consecutiveFailures = 0
    private let maxConsecutiveFailures = 5
    private var circuitOpenUntil: Date?
    
    enum RetryError: Error {
        case circuitOpen
        case maxRetriesExceeded
    }
    
    func executeWithRetry<T>(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 60.0,
        _ operation: () async throws -> T
    ) async throws -> T {
        // Check circuit breaker
        if let openUntil = circuitOpenUntil, Date() < openUntil {
            throw RetryError.circuitOpen
        }
        
        // Check rate limit
        if let waitTime = await rateLimiter.waitTime() {
            try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                await rateLimiter.recordRequest()
                
                let result = try await operation()
                
                // Success - reset failure counter
                consecutiveFailures = 0
                circuitOpenUntil = nil
                
                return result
                
            } catch let error as OpenAIError {
                lastError = error
                
                if error.isRetryable {
                    consecutiveFailures += 1
                    
                    // Open circuit if too many failures
                    if consecutiveFailures >= maxConsecutiveFailures {
                        circuitOpenUntil = Date().addingTimeInterval(300)  // 5 minutes
                        throw RetryError.circuitOpen
                    }
                    
                    // Calculate delay with jitter
                    let baseDelay = min(baseDelay * pow(2.0, Double(attempt)), maxDelay)
                    let jitter = Double.random(in: 0.0...0.1) * baseDelay
                    let delay = baseDelay + jitter
                    
                    print("Retry \(attempt + 1)/\(maxRetries) after \(delay)s")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    
                } else {
                    // Non-retryable error
                    throw error
                }
                
            } catch {
                // Unknown error
                throw error
            }
        }
        
        throw lastError ?? RetryError.maxRetriesExceeded
    }
}

// Usage
let retryHandler = SmartRetryHandler()

do {
    let response = try await retryHandler.executeWithRetry {
        try await openAI.chat.completions(request)
    }
} catch SmartRetryHandler.RetryError.circuitOpen {
    print("Service temporarily unavailable. Too many failures.")
} catch {
    print("Request failed: \(error)")
}
```

### Token Management & Cost Control

```swift
import Foundation

// Token counter and cost calculator
class TokenManager {
    // Approximate token costs (check OpenAI pricing for current rates)
    private let pricing: [String: (input: Double, output: Double)] = [
        "gpt-4o": (0.005, 0.015),          // $5/$15 per 1M tokens
        "gpt-4o-mini": (0.00015, 0.0006),  // $0.15/$0.60 per 1M tokens
        "gpt-3.5-turbo": (0.0005, 0.0015)  // $0.50/$1.50 per 1M tokens
    ]
    
    private var totalTokensUsed = 0
    private var totalCost: Double = 0
    
    // Estimate tokens before making request (rough approximation)
    func estimateTokens(for text: String) -> Int {
        // Rough estimate: 1 token ≈ 4 characters or 0.75 words
        let words = text.components(separatedBy: .whitespacesAndNewlines).count
        return Int(Double(words) / 0.75)
    }
    
    func trackUsage(_ response: ChatCompletionResponse) {
        guard let usage = response.usage else { return }
        
        totalTokensUsed += usage.totalTokens
        
        // Calculate cost
        if let modelPricing = pricing[response.model] {
            let inputCost = Double(usage.promptTokens) / 1_000_000 * modelPricing.input
            let outputCost = Double(usage.completionTokens) / 1_000_000 * modelPricing.output
            let requestCost = inputCost + outputCost
            
            totalCost += requestCost
            
            print("💰 Request cost: $\(String(format: "%.4f", requestCost))")
            print("📊 Total session cost: $\(String(format: "%.4f", totalCost))")
        }
    }
    
    func getCurrentStats() -> (tokens: Int, cost: Double) {
        return (totalTokensUsed, totalCost)
    }
}

// Token-aware request builder
class SmartRequestBuilder {
    private let tokenManager = TokenManager()
    
    func buildOptimizedRequest(
        messages: [ChatMessage],
        maxTokenBudget: Int = 4000,
        preserveSystemMessage: Bool = true
    ) -> ChatCompletionRequest {
        var optimizedMessages = messages
        var estimatedTokens = 0
        
        // Calculate token usage
        for message in messages {
            estimatedTokens += tokenManager.estimateTokens(
                for: message.content ?? ""
            )
        }
        
        // Trim conversation if needed
        if estimatedTokens > maxTokenBudget {
            optimizedMessages = trimConversation(
                messages: messages,
                targetTokens: maxTokenBudget,
                preserveSystemMessage: preserveSystemMessage
            )
        }
        
        return ChatCompletionRequest(
            messages: optimizedMessages,
            model: Models.Chat.gpt4oMini,  // Use cheaper model for long conversations
            maxTokens: min(1000, maxTokenBudget - estimatedTokens)  // Leave room for response
        )
    }
    
    private func trimConversation(
        messages: [ChatMessage],
        targetTokens: Int,
        preserveSystemMessage: Bool
    ) -> [ChatMessage] {
        var result: [ChatMessage] = []
        var currentTokens = 0
        
        // Always keep system message if requested
        if preserveSystemMessage,
           let systemMessage = messages.first(where: { $0.role == .system }) {
            result.append(systemMessage)
            currentTokens += tokenManager.estimateTokens(
                for: systemMessage.content ?? ""
            )
        }
        
        // Add most recent messages within budget
        for message in messages.reversed() {
            if message.role == .system && preserveSystemMessage { continue }
            
            let messageTokens = tokenManager.estimateTokens(
                for: message.content ?? ""
            )
            
            if currentTokens + messageTokens <= targetTokens {
                result.insert(message, at: result.count)  // Maintain order
                currentTokens += messageTokens
            } else {
                break
            }
        }
        
        return result
    }
}

// Usage with monitoring
let tokenManager = TokenManager()
let requestBuilder = SmartRequestBuilder()

// Build optimized request
let request = requestBuilder.buildOptimizedRequest(
    messages: conversationHistory,
    maxTokenBudget: 3000
)

// Make request and track usage
let response = try await openAI.chat.completions(request)
tokenManager.trackUsage(response)

// Get session stats
let (totalTokens, totalCost) = tokenManager.getCurrentStats()
print("Session summary: \(totalTokens) tokens, $\(String(format: "%.2f", totalCost))")
```

### Performance Optimization

```swift
// Concurrent request handling
actor ConcurrentRequestManager {
    private let openAI: OpenAIKit
    private let maxConcurrent = 5
    private var activeTasks = 0
    
    init(apiKey: String) {
        self.openAI = OpenAIKit(apiKey: apiKey)
    }
    
    func processBatch<T>(
        requests: [ChatCompletionRequest],
        processor: @escaping (ChatCompletionResponse) async throws -> T
    ) async throws -> [T] {
        try await withThrowingTaskGroup(of: T.self) { group in
            var results: [T] = []
            
            for request in requests {
                // Wait if at capacity
                while activeTasks >= maxConcurrent {
                    try await Task.sleep(nanoseconds: 100_000_000)  // 0.1s
                }
                
                activeTasks += 1
                
                group.addTask {
                    defer { Task { await self.decrementActiveTasks() } }
                    
                    let response = try await self.openAI.chat.completions(request)
                    return try await processor(response)
                }
            }
            
            // Collect results
            for try await result in group {
                results.append(result)
            }
            
            return results
        }
    }
    
    private func decrementActiveTasks() {
        activeTasks -= 1
    }
}

// Response caching
actor ResponseCache {
    private var cache: [String: (response: ChatCompletionResponse, timestamp: Date)] = [:]
    private let ttl: TimeInterval = 3600  // 1 hour
    
    func getCachedResponse(for request: ChatCompletionRequest) -> ChatCompletionResponse? {
        let key = cacheKey(for: request)
        
        if let cached = cache[key] {
            let age = Date().timeIntervalSince(cached.timestamp)
            if age < ttl {
                return cached.response
            } else {
                // Expired
                cache.removeValue(forKey: key)
            }
        }
        
        return nil
    }
    
    func cacheResponse(_ response: ChatCompletionResponse, for request: ChatCompletionRequest) {
        let key = cacheKey(for: request)
        cache[key] = (response, Date())
        
        // Limit cache size
        if cache.count > 100 {
            cleanOldEntries()
        }
    }
    
    private func cacheKey(for request: ChatCompletionRequest) -> String {
        // Create unique key from request parameters
        let messageContent = request.messages.map { $0.content ?? "" }.joined()
        let params = "\(request.model)-\(request.temperature ?? 1.0)-\(request.maxTokens ?? 0)"
        return "\(messageContent.hashValue)-\(params)"
    }
    
    private func cleanOldEntries() {
        let now = Date()
        cache = cache.filter { _, value in
            now.timeIntervalSince(value.timestamp) < ttl
        }
    }
}
```

## Next Steps

Now that you've mastered the basics, explore these advanced topics:

### Advanced Chat Features
- **Function Calling**: Learn to use ``Function`` and ``Tool`` for structured outputs
- **Vision Models**: Process images with multimodal capabilities
- **JSON Mode**: Get guaranteed valid JSON responses with ``ResponseFormat``
- **Streaming**: Master real-time responses with ``ChatStreamChunk``

### Other Endpoints
- **Audio Processing**: Convert text to speech and transcribe audio with ``AudioEndpoint``
- **Image Generation**: Create and edit images with ``ImagesEndpoint`` and DALL-E
- **Embeddings**: Build semantic search with ``EmbeddingsEndpoint``
- **Assistants**: Create persistent AI assistants with ``AssistantsEndpoint``
- **Fine-Tuning**: Customize models with ``FineTuningEndpoint``

### Production Topics
- **Error Recovery**: Implement robust error handling with ``OpenAIError``
- **Rate Limiting**: Use ``RetryHandler`` for automatic retries
- **Cost Management**: Track and optimize token usage
- **Security**: Best practices for API key management
- **Performance**: Optimize for speed and efficiency

### Resources
- [API Reference](https://platform.openai.com/docs/api-reference)
- [Model Documentation](https://platform.openai.com/docs/models)
- [Pricing Calculator](https://openai.com/pricing)
- [Usage Dashboard](https://platform.openai.com/usage)

### Community
- [GitHub Issues](https://github.com/marcusziade/OpenAIKit/issues)
- [Discussions](https://github.com/marcusziade/OpenAIKit/discussions)
- [Examples](https://github.com/marcusziade/OpenAIKit/tree/main/Examples)