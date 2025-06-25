# ``OpenAIKit``

A powerful, type-safe Swift SDK for the OpenAI API with support for all major endpoints and platforms.

## Overview

OpenAIKit provides a comprehensive, Swift-native interface to OpenAI's API, featuring:

- 🚀 **Modern Swift**: Built with async/await, Sendable conformance, and type safety
- 🌐 **Cross-Platform**: Supports iOS, macOS, watchOS, tvOS, visionOS, and Linux
- 🔐 **Secure**: Built-in authentication and secure API key management
- 📡 **Real-time Streaming**: Server-Sent Events support for streaming responses
- 🎯 **Type-Safe**: Strongly typed requests and responses with comprehensive error handling
- 📦 **Zero Dependencies**: Pure Swift implementation with no external dependencies

## Getting Started

### Installation

Add OpenAIKit to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/marcusziade/OpenAIKit.git", from: "1.0.0")
]
```

### Basic Usage

```swift
import OpenAIKit

// Initialize the client
let openAI = OpenAIKit(apiKey: "your-api-key")

// Make a simple chat completion
let response = try await openAI.chat.completions(
    ChatCompletionRequest(
        messages: [
            ChatMessage(role: .system, content: "You are a helpful assistant."),
            ChatMessage(role: .user, content: "Explain quantum computing in simple terms.")
        ],
        model: "gpt-4o"
    )
)

print(response.choices.first?.message.content ?? "")
```

## Topics

### Essentials

- ``OpenAIKit``
- ``Configuration``

### Chat Completions

- ``ChatEndpoint``
- ``ChatCompletionRequest``
- ``ChatMessage``
- ``ChatCompletionResponse``

### Audio

- ``AudioEndpoint``
- ``SpeechRequest``
- ``TranscriptionRequest``
- ``TranslationRequest``

### Images

- ``ImagesEndpoint``
- ``ImageGenerationRequest``
- ``ImageEditRequest``
- ``ImageVariationRequest``

### Embeddings

- ``EmbeddingsEndpoint``
- ``EmbeddingRequest``
- ``EmbeddingResponse``

### Models & Moderations

- ``ModelsEndpoint``
- ``ModerationsEndpoint``

### File Management

- ``FilesEndpoint``
- ``FileRequest``
- ``FileObject``

### Error Handling

- ``OpenAIError``
- ``APIError``

### Advanced Features

- ``Request``
- ``StreamableRequest``
- ``UploadRequest``
- ``JSONValue``