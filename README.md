# OpenAIKit

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg?style=flat)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2015%2B%20%7C%20macOS%2012%2B%20%7C%20watchOS%208%2B%20%7C%20tvOS%2015%2B%20%7C%20visionOS%20%7C%20Linux-blue.svg?style=flat)](https://developer.apple.com)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)
[![Documentation](https://img.shields.io/badge/Documentation-DocC-blue)](https://marcusziade.github.io/OpenAIKit/)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg?style=flat)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/marcusziade/OpenAIKit?style=social)](https://github.com/marcusziade/OpenAIKit/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/marcusziade/OpenAIKit?style=social)](https://github.com/marcusziade/OpenAIKit/network/members)
[![CI](https://github.com/marcusziade/OpenAIKit/actions/workflows/docc.yml/badge.svg)](https://github.com/marcusziade/OpenAIKit/actions/workflows/docc.yml)

A comprehensive Swift SDK for the OpenAI API.

## Features

- 🚀 Type-safe API with Swift's powerful type system
- 🌍 Cross-platform support (iOS 15+, macOS 12+, watchOS 8+, tvOS 15+, visionOS, Linux)
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
