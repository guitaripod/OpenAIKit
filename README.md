# OpenAIKit

A comprehensive Swift SDK for the OpenAI API.

## Features

- 🚀 Type-safe API with Swift's powerful type system
- 🌍 Cross-platform support (iOS, macOS, watchOS, tvOS, visionOS, Linux)
- 📚 Complete API coverage (Chat, Images, Audio, Embeddings, and more)
- ⚡ Modern async/await with streaming support
- 🛡️ Comprehensive error handling
- 📖 Full DocC documentation with interactive tutorials

## Documentation

Visit https://marcusziade.github.io/OpenAIKit/ for complete documentation and tutorials.

## Installation

Add OpenAIKit to your Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/marcusziade/OpenAIKit.git", from: "1.0.0")
]
```

## Quick Start

```swift
import OpenAIKit

let openAI = OpenAIKit(configuration: .init(apiKey: "your-api-key"))

let response = try await openAI.chat.completions(
    .init(
        model: .gpt4o,
        messages: [.user("Hello, world\!")]
    )
)

print(response.choices.first?.message.content ?? "")
```
