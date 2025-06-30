# ``OpenAIKit``

A powerful, type-safe Swift SDK for the OpenAI API with support for all major endpoints and platforms.

@Metadata {
    @DisplayName("OpenAIKit")
    @TitleHeading("Swift SDK")
}

## Overview

OpenAIKit provides a comprehensive, Swift-native interface to OpenAI's API, designed for modern Swift applications. Whether you're building conversational AI, generating images, processing audio, or implementing semantic search, OpenAIKit offers a clean, intuitive API that leverages Swift's strongest features.

### Key Features

- 🚀 **Modern Swift Architecture**: Built from the ground up with async/await, Sendable conformance, and strict type safety
- 🌐 **Universal Platform Support**: Seamlessly runs on iOS 15+, macOS 12+, watchOS 8+, tvOS 15+, visionOS 1+, and Linux
- 🔐 **Enterprise-Grade Security**: Secure API key management with built-in best practices for authentication
- 📡 **Real-time Streaming**: First-class Server-Sent Events support for responsive, streaming completions
- 🎯 **Type-Safe API Design**: Strongly typed requests and responses eliminate runtime errors and improve developer experience
- 📦 **Zero Dependencies**: Pure Swift implementation ensures minimal app size and maximum compatibility
- 🔍 **Advanced Capabilities**: Support for OpenAI's latest features including function calling, vision, and deep research
- ⚡ **Performance Optimized**: Efficient networking layer with automatic retry logic and connection pooling
- 🛡️ **Comprehensive Error Handling**: Rich error types with actionable recovery suggestions
- 📱 **SwiftUI Ready**: Designed to work seamlessly with SwiftUI's reactive programming model

## Getting Started

### Installation

Add OpenAIKit to your project using Swift Package Manager:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/marcusziade/OpenAIKit.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/marcusziade/OpenAIKit.git`
3. Choose your version requirements

### Quick Start

```swift
import OpenAIKit

// Initialize with your API key
let openAI = OpenAIKit(apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "")

// Create a chat completion
let response = try await openAI.chat.completions(
    ChatCompletionRequest(
        messages: [
            ChatMessage(role: .system, content: "You are a helpful assistant."),
            ChatMessage(role: .user, content: "Explain quantum computing in simple terms.")
        ],
        model: Models.Chat.gpt4o
    )
)

// Access the generated response
if let content = response.choices.first?.message.content {
    print(content)
}
```

### Streaming Example

```swift
// Stream responses for real-time output
let request = ChatCompletionRequest(
    messages: [ChatMessage(role: .user, content: "Tell me a story")],
    model: Models.Chat.gpt4o
)

for try await chunk in openAI.chat.completionsStream(request) {
    if let content = chunk.choices.first?.delta.content {
        print(content, terminator: "")
    }
}
```

## Topics

### Getting Started
- <doc:GettingStarted>
- ``OpenAIKit``
- ``Configuration``

### Chat & Conversations
- ``ChatEndpoint``
- ``ChatCompletionRequest``
- ``ChatCompletionResponse``
- ``ChatMessage``
- ``ChatStreamChunk``
- ``Function``
- ``Tool``
- ``ToolChoice``

### Audio Processing
- ``AudioEndpoint``
- ``SpeechRequest``
- ``TranscriptionRequest``
- ``TranslationRequest``
- ``AudioResponse``
- ``TranscriptionResponse``

### Image Generation
- ``ImagesEndpoint``
- ``ImageGenerationRequest``
- ``ImageEditRequest``
- ``ImageVariationRequest``
- ``ImageResponse``

### Embeddings & Search
- ``EmbeddingsEndpoint``
- ``EmbeddingRequest``
- ``EmbeddingResponse``
- ``Embedding``

### Model Management
- ``ModelsEndpoint``
- ``ModerationsEndpoint``
- ``Model``
- ``ModelPermission``

### File Operations
- ``FilesEndpoint``
- ``FileRequest``
- ``FileObject``
- ``FileUploadRequest``

### Assistants API
- ``AssistantsEndpoint``
- ``ThreadsEndpoint``
- ``Assistant``
- ``Thread``
- ``Message``
- ``Run``

### Vector Stores
- ``VectorStoresEndpoint``
- ``VectorStore``
- ``VectorStoreFile``

### Batch Processing
- ``BatchesEndpoint``
- ``BatchEndpoint``
- ``Batch``
- ``BatchRequest``

### Fine-Tuning
- ``FineTuningEndpoint``
- ``FineTuningJob``
- ``FineTuningRequest``

### Error Handling
- ``OpenAIError``
- ``APIError``
- ``APIErrorDetail``
- ``RetryHandler``

### Advanced Features
- ``Request``
- ``StreamableRequest``
- ``UploadRequest``
- ``JSONValue``
- ``ResponseFormat``

### Research & Analysis
- <doc:DeepResearch-Tutorial>
- ``DeepResearchEndpoint``
- ``DeepResearchRequest``
- ``DeepResearchResponse``