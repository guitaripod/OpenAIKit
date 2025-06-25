# Getting Started with OpenAIKit

Learn how to integrate OpenAIKit into your project and make your first API calls.

## Installation

### Swift Package Manager

OpenAIKit can be easily integrated into your project using Swift Package Manager.

#### Xcode

1. In Xcode, select **File** → **Add Package Dependencies**
2. Enter the repository URL: `https://github.com/yourusername/OpenAIKit.git`
3. Select the version rule and click **Add Package**

#### Package.swift

Add OpenAIKit to your `Package.swift` file:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/yourusername/OpenAIKit.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: ["OpenAIKit"]
        )
    ]
)
```

## Authentication

### Obtaining an API Key

1. Sign up or log in at [platform.openai.com](https://platform.openai.com)
2. Navigate to **API Keys** in your account settings
3. Click **Create new secret key**
4. Copy and securely store your API key

> Important: Never commit API keys to source control. Use environment variables or secure storage.

### Initializing the Client

```swift
import OpenAIKit

// Basic initialization
let openAI = OpenAIKit(apiKey: "your-api-key")

// With organization
let openAI = OpenAIKit(
    apiKey: "your-api-key",
    organization: "org-id"
)

// With custom configuration
let config = Configuration(
    apiKey: "your-api-key",
    baseURL: URL(string: "https://custom-proxy.com")!,
    timeoutInterval: 120
)
let openAI = OpenAIKit(configuration: config)
```

## Your First Request

### Chat Completion

The most common use case is generating text with chat completions:

```swift
// Simple conversation
let response = try await openAI.chat.completions(
    ChatCompletionRequest(
        messages: [
            ChatMessage(role: .user, content: "Hello, how are you?")
        ],
        model: "gpt-4o-mini"
    )
)

print(response.choices.first?.message.content ?? "")
```

### Streaming Responses

For real-time output, use streaming:

```swift
let request = ChatCompletionRequest(
    messages: [
        ChatMessage(role: .user, content: "Write a short story about a robot.")
    ],
    model: "gpt-4o",
    stream: true
)

for try await chunk in openAI.chat.completionsStream(request) {
    if let content = chunk.choices.first?.delta.content {
        print(content, terminator: "")
    }
}
```

## Common Use Cases

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
        model: "gpt-4o",
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
        model: "gpt-4o",
        temperature: 0.2
    )
)
```

### Image Generation

```swift
let imageResponse = try await openAI.images.generations(
    ImageGenerationRequest(
        prompt: "A futuristic city at sunset, digital art style",
        model: "dall-e-3",
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
        model: "whisper-1"
    )
)

print(transcription.text)
```

### Text Embeddings

```swift
let embedding = try await openAI.embeddings.create(
    EmbeddingRequest(
        input: "OpenAI provides powerful AI models.",
        model: "text-embedding-3-small"
    )
)

let vector = embedding.data.first?.embedding.floatValues ?? []
```

## Error Handling

Always handle potential errors:

```swift
do {
    let response = try await openAI.chat.completions(request)
    // Handle success
} catch let error as OpenAIError {
    switch error {
    case .authenticationFailed:
        print("Check your API key")
    case .rateLimitExceeded:
        print("Too many requests, please wait")
    case .apiError(let apiError):
        print("API Error: \(apiError.error.message)")
    default:
        print("Error: \(error.localizedDescription)")
    }
} catch {
    print("Unexpected error: \(error)")
}
```

## Best Practices

### API Key Security

```swift
// ❌ Don't hardcode API keys
let openAI = OpenAIKit(apiKey: "sk-abc123...")

// ✅ Use environment variables
if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
    let openAI = OpenAIKit(apiKey: apiKey)
}

// ✅ Or use secure storage (iOS/macOS)
let keychain = Keychain(service: "com.myapp.openai")
if let apiKey = keychain["api_key"] {
    let openAI = OpenAIKit(apiKey: apiKey)
}
```

### Rate Limiting

Implement exponential backoff for rate limits:

```swift
func makeRequestWithRetry<T>(_ request: () async throws -> T) async throws -> T {
    var retries = 0
    let maxRetries = 3
    
    while retries < maxRetries {
        do {
            return try await request()
        } catch OpenAIError.rateLimitExceeded {
            retries += 1
            let delay = pow(2.0, Double(retries))
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }
    
    return try await request()
}
```

### Token Management

Monitor token usage to control costs:

```swift
let response = try await openAI.chat.completions(request)

if let usage = response.usage {
    print("Prompt tokens: \(usage.promptTokens)")
    print("Completion tokens: \(usage.completionTokens)")
    print("Total tokens: \(usage.totalTokens)")
}
```

## Next Steps

- Explore the ``ChatEndpoint`` for advanced chat features
- Learn about ``Function`` calling for structured outputs
- Try ``AudioEndpoint`` for speech synthesis and transcription
- Generate images with ``ImagesEndpoint``
- Build semantic search with ``EmbeddingsEndpoint``