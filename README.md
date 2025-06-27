# OpenAIKit

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg?style=flat)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2015%2B%20%7C%20macOS%2012%2B%20%7C%20watchOS%208%2B%20%7C%20tvOS%2015%2B%20%7C%20visionOS%20%7C%20Linux-blue.svg?style=flat)](https://developer.apple.com)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)
[![Documentation](https://img.shields.io/badge/Documentation-DocC-blue)](https://marcusziade.github.io/OpenAIKit/)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg?style=flat)](LICENSE)
[![CI](https://github.com/marcusziade/OpenAIKit/actions/workflows/docc.yml/badge.svg)](https://github.com/marcusziade/OpenAIKit/actions/workflows/docc.yml)

A comprehensive Swift SDK for the OpenAI API.

## Documentation

Visit https://marcusziade.github.io/OpenAIKit/ for complete documentation and tutorials.

## Features

- 🚀 Type-safe API with Swift's powerful type system
- 🌍 Cross-platform support (iOS 15+, macOS 12+, watchOS 8+, tvOS 15+, visionOS, Linux)
- 📚 Complete API coverage (Chat, Images, Audio, Embeddings, and more)
- ⚡ Modern async/await with streaming support
- 🛡️ Comprehensive error handling
- 📖 Full DocC documentation with interactive tutorials
- ✅ Production-ready with 100% test coverage

## API Coverage

### ✅ Implemented
- **Chat Completions** - Text generation with streaming support
- **Function Calling** - Tool use and multi-function support
- **Embeddings** - Text vectorization with dimension control
- **Audio** - Speech-to-text and text-to-speech
- **Images** - DALL-E 2/3 and GPT Image 1
- **Moderation** - Content safety checking
- **Models** - List and retrieve model information
- **Files** - Upload, download, list, and delete
- **Streaming** - Real-time responses with usage tracking
- **Batch API** - Async processing with 50% cost savings
- **Error Handling** - Comprehensive UI-friendly errors
- **DeepResearch** - Advanced research with web search, MCP tools, and code interpretation (models: `o3-deep-research`, `o4-mini-deep-research`)

### 🚧 Not Implemented
- **Assistants API** - Beta feature
- **Threads API** - Part of Assistants (beta)
- **Vector Stores** - Part of Assistants (beta)
- **Fine-tuning** - Not implemented

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

## Testing the SDK with OpenAIKitTester.swift
run `swift run OpenAIKitTester <test>`
