#!/usr/bin/env swift

import Foundation

let baseDir = "Sources/OpenAIKit/OpenAIKit.docc/Resources/code"

// Create directory if it doesn't exist
try FileManager.default.createDirectory(atPath: baseDir, withIntermediateDirectories: true)

// Tutorial 1: Setting Up OpenAIKit
let setupCode = [
    "setup-01-package.swift": """
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyApp",
    products: [
        .library(
            name: "MyApp",
            targets: ["MyApp"]
        )
    ],
    targets: [
        .target(
            name: "MyApp"
        )
    ]
)
""",
    
    "setup-02-package.swift": """
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyApp",
    products: [
        .library(
            name: "MyApp",
            targets: ["MyApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/marcusziade/OpenAIKit.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MyApp"
        )
    ]
)
""",
    
    "setup-03-package.swift": """
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyApp",
    products: [
        .library(
            name: "MyApp",
            targets: ["MyApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/marcusziade/OpenAIKit.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: ["OpenAIKit"]
        )
    ]
)
""",
    
    "setup-04-empty.swift": """
// OpenAIClient.swift
""",
    
    "setup-05-import.swift": """
// OpenAIClient.swift
import OpenAIKit
import Foundation

class OpenAIManager {
    static let shared = OpenAIManager()
    
    private init() {}
}
""",
    
    "setup-06-apikey.swift": """
// OpenAIClient.swift
import OpenAIKit
import Foundation

class OpenAIManager {
    static let shared = OpenAIManager()
    
    private var apiKey: String {
        guard let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            fatalError("Missing OPENAI_API_KEY environment variable")
        }
        return key
    }
    
    private init() {}
}
""",
    
    "setup-07-init.swift": """
// OpenAIClient.swift
import OpenAIKit
import Foundation

class OpenAIManager {
    static let shared = OpenAIManager()
    
    private var apiKey: String {
        guard let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            fatalError("Missing OPENAI_API_KEY environment variable")
        }
        return key
    }
    
    let client: OpenAIKit
    
    private init() {
        let configuration = Configuration(apiKey: apiKey)
        self.client = OpenAIKit(configuration: configuration)
    }
}
""",
    
    "setup-08-complete.swift": """
// OpenAIClient.swift
import OpenAIKit
import Foundation

enum OpenAIError: LocalizedError {
    case missingAPIKey
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key not found. Please set the OPENAI_API_KEY environment variable."
        }
    }
}

class OpenAIManager {
    static let shared = OpenAIManager()
    
    private var apiKey: String? {
        ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
    }
    
    let client: OpenAIKit?
    
    private init() {
        guard let apiKey = apiKey else {
            print("Warning: \\(OpenAIError.missingAPIKey.errorDescription ?? "")")
            self.client = nil
            return
        }
        
        let configuration = Configuration(apiKey: apiKey)
        self.client = OpenAIKit(configuration: configuration)
    }
}
"""
]

// Tutorial 2: Your First Chat Completion
let chatCode = [
    "chat-01-empty.swift": """
// ChatExample.swift
""",
    
    "chat-02-imports.swift": """
// ChatExample.swift
import Foundation
import OpenAIKit

class ChatExample {
    let openAI = OpenAIManager.shared.client
}
""",
    
    "chat-03-ui.swift": """
// ChatExample.swift
import Foundation
import OpenAIKit
import SwiftUI

struct ChatView: View {
    @State private var userMessage = ""
    @State private var messages: [String] = []
    
    var body: some View {
        VStack {
            ScrollView {
                ForEach(messages, id: \\.self) { message in
                    Text(message)
                        .padding()
                }
            }
            
            HStack {
                TextField("Type a message", text: $userMessage)
                Button("Send") {
                    // Send message
                }
            }
            .padding()
        }
    }
}
""",
    
    "chat-04-function.swift": """
// ChatExample.swift
import Foundation
import OpenAIKit

class ChatExample {
    let openAI = OpenAIManager.shared.client
    
    func sendMessage(_ message: String) async throws -> String {
        // Implementation here
        return ""
    }
}
""",
    
    "chat-05-request.swift": """
// ChatExample.swift
import Foundation
import OpenAIKit

class ChatExample {
    let openAI = OpenAIManager.shared.client
    
    func sendMessage(_ message: String) async throws -> String {
        let chatMessage = ChatMessage(role: .user, content: message)
        
        let request = ChatCompletionRequest(
            messages: [chatMessage],
            model: "gpt-4o-mini"
        )
        
        // Send request
        return ""
    }
}
""",
    
    "chat-06-response.swift": """
// ChatExample.swift
import Foundation
import OpenAIKit

class ChatExample {
    let openAI = OpenAIManager.shared.client
    
    func sendMessage(_ message: String) async throws -> String {
        guard let openAI = openAI else { 
            throw OpenAIError.missingAPIKey 
        }
        
        let chatMessage = ChatMessage(role: .user, content: message)
        
        let request = ChatCompletionRequest(
            messages: [chatMessage],
            model: "gpt-4o-mini"
        )
        
        let response = try await openAI.chat.completions(request)
        
        return response.choices.first?.message.content ?? "No response"
    }
}
""",
    
    "chat-07-complete.swift": """
// ChatExample.swift
import Foundation
import OpenAIKit

class ChatExample: ObservableObject {
    let openAI = OpenAIManager.shared.client
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func sendMessage(_ message: String) async throws -> String {
        guard let openAI = openAI else { 
            throw OpenAIError.missingAPIKey 
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let chatMessage = ChatMessage(role: .user, content: message)
        
        let request = ChatCompletionRequest(
            messages: [chatMessage],
            model: "gpt-4o-mini"
        )
        
        do {
            let response = try await openAI.chat.completions(request)
            return response.choices.first?.message.content ?? "No response"
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
}
""",
    
    // Message Roles section
    "messages-01-user.swift": """
// Creating different types of messages
import OpenAIKit

// User message - represents input from the user
let userMessage = ChatMessage(
    role: .user, 
    content: "What's the weather like today?"
)
""",
    
    "messages-02-system.swift": """
// Creating different types of messages
import OpenAIKit

// System message - sets the AI's behavior
let systemMessage = ChatMessage(
    role: .system,
    content: "You are a helpful weather assistant. Always provide temperatures in both Celsius and Fahrenheit."
)

// User message
let userMessage = ChatMessage(
    role: .user, 
    content: "What's the weather like today?"
)
""",
    
    "messages-03-conversation.swift": """
// Building a conversation with message history
import OpenAIKit

var messages: [ChatMessage] = []

// System prompt
messages.append(ChatMessage(
    role: .system,
    content: "You are a helpful weather assistant."
))

// User question
messages.append(ChatMessage(
    role: .user,
    content: "What's the weather in New York?"
))

// Assistant response (from previous API call)
messages.append(ChatMessage(
    role: .assistant,
    content: "The weather in New York is currently 72°F (22°C) with partly cloudy skies."
))

// Follow-up question
messages.append(ChatMessage(
    role: .user,
    content: "What about tomorrow?"
))

// Create request with full conversation
let request = ChatCompletionRequest(
    messages: messages,
    model: "gpt-4o-mini"
)
""",
    
    "messages-04-assistant.swift": """
// Complete conversation management
import OpenAIKit

class ConversationManager {
    var messages: [ChatMessage] = []
    
    init(systemPrompt: String? = nil) {
        if let prompt = systemPrompt {
            messages.append(ChatMessage(role: .system, content: prompt))
        }
    }
    
    func addUserMessage(_ content: String) {
        messages.append(ChatMessage(role: .user, content: content))
    }
    
    func addAssistantMessage(_ content: String) {
        messages.append(ChatMessage(role: .assistant, content: content))
    }
    
    func createRequest(model: String = "gpt-4o-mini") -> ChatCompletionRequest {
        ChatCompletionRequest(messages: messages, model: model)
    }
}
""",
    
    // Parameters section
    "params-01-basic.swift": """
// Basic parameters for chat completion
import OpenAIKit

let request = ChatCompletionRequest(
    messages: [
        ChatMessage(role: .user, content: "Tell me a joke")
    ],
    model: "gpt-4o-mini"
)
""",
    
    "params-02-temperature.swift": """
// Controlling response creativity with temperature
import OpenAIKit

// Low temperature (0.2) - More focused and deterministic
let preciseRequest = ChatCompletionRequest(
    messages: [
        ChatMessage(role: .user, content: "What is 2+2?")
    ],
    model: "gpt-4o-mini",
    temperature: 0.2
)

// High temperature (0.9) - More creative and varied
let creativeRequest = ChatCompletionRequest(
    messages: [
        ChatMessage(role: .user, content: "Write a creative story opening")
    ],
    model: "gpt-4o-mini",
    temperature: 0.9
)
""",
    
    "params-03-tokens.swift": """
// Controlling response length with max tokens
import OpenAIKit

// Short response
let shortRequest = ChatCompletionRequest(
    messages: [
        ChatMessage(role: .user, content: "Explain quantum physics")
    ],
    model: "gpt-4o-mini",
    maxTokens: 50  // Limit to ~40 words
)

// Longer response
let detailedRequest = ChatCompletionRequest(
    messages: [
        ChatMessage(role: .user, content: "Explain quantum physics")
    ],
    model: "gpt-4o-mini",
    maxTokens: 500  // Allow for detailed explanation
)

// With stop sequences
let listRequest = ChatCompletionRequest(
    messages: [
        ChatMessage(role: .user, content: "List 3 benefits of exercise:")
    ],
    model: "gpt-4o-mini",
    stop: ["4.", "\\n\\n"],  // Stop at "4." or double newline
    temperature: 0.3
)
""",
    
    "params-04-models.swift": """
// Different models for different use cases
import OpenAIKit

// Fast, cost-effective model
let quickRequest = ChatCompletionRequest(
    messages: [ChatMessage(role: .user, content: "Hello!")],
    model: "gpt-4o-mini"
)

// More capable model for complex tasks
let complexRequest = ChatCompletionRequest(
    messages: [
        ChatMessage(role: .system, content: "You are an expert programmer."),
        ChatMessage(role: .user, content: "Explain the SOLID principles with code examples")
    ],
    model: "gpt-4o",
    temperature: 0.7
)

// Multiple responses
let multipleRequest = ChatCompletionRequest(
    messages: [ChatMessage(role: .user, content: "Suggest a name for my cat")],
    model: "gpt-4o-mini",
    n: 3,  // Get 3 different suggestions
    temperature: 0.8
)
""",
    
    // Interface section
    "interface-01-model.swift": """
// ChatViewModel.swift
import Foundation
import OpenAIKit

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    let content: String
    let timestamp = Date()
}

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    
    private let openAI = OpenAIManager.shared.client
}
""",
    
    "interface-02-viewmodel.swift": """
// ChatViewModel.swift
import Foundation
import OpenAIKit

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    let content: String
    let timestamp = Date()
}

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let openAI = OpenAIManager.shared.client
    
    func sendMessage(_ content: String) {
        // Add user message
        messages.append(ChatMessage(role: .user, content: content))
        
        Task {
            await getResponse()
        }
    }
    
    @MainActor
    private func getResponse() async {
        isLoading = true
        defer { isLoading = false }
        
        // Implementation coming next
    }
}
""",
    
    "interface-03-send.swift": """
// ChatViewModel.swift
import Foundation
import OpenAIKit

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let openAI = OpenAIManager.shared.client
    
    func sendMessage(_ content: String) {
        messages.append(ChatMessage(role: .user, content: content))
        
        Task {
            await getResponse()
        }
    }
    
    @MainActor
    private func getResponse() async {
        guard let openAI = openAI else {
            errorMessage = "OpenAI client not initialized"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let chatMessages = messages.map { message in
            ChatMessage(role: message.role, content: message.content)
        }
        
        let request = ChatCompletionRequest(
            messages: chatMessages,
            model: "gpt-4o-mini"
        )
        
        do {
            let response = try await openAI.chat.completions(request)
            if let content = response.choices.first?.message.content {
                messages.append(ChatMessage(role: .assistant, content: content))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
""",
    
    "interface-04-view.swift": """
// ChatView.swift
import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var inputText = ""
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                        }
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .padding()
                }
            }
            
            HStack {
                TextField("Type a message...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                
                Button("Send") {
                    guard !inputText.isEmpty else { return }
                    viewModel.sendMessage(inputText)
                    inputText = ""
                }
                .disabled(viewModel.isLoading || inputText.isEmpty)
            }
            .padding()
        }
    }
}
""",
    
    "interface-05-bubbles.swift": """
// MessageBubble.swift
import SwiftUI
import OpenAIKit

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading) {
                Text(message.content)
                    .padding(12)
                    .background(backgroundColor)
                    .foregroundColor(textColor)
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
    
    private var backgroundColor: Color {
        switch message.role {
        case .user:
            return .blue
        case .assistant:
            return Color(.systemGray5)
        case .system:
            return .orange
        case .tool:
            return .purple
        }
    }
    
    private var textColor: Color {
        message.role == .user ? .white : .primary
    }
}
""",
    
    "interface-06-complete.swift": """
// Complete Chat Interface
import SwiftUI
import OpenAIKit

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("OpenAI Chat")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    viewModel.messages.removeAll()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(radius: 1)
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                Text("Thinking...")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                    }
                    .padding()
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(viewModel.messages.last?.id)
                        }
                    }
                }
            }
            
            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            // Input area
            HStack(spacing: 12) {
                TextField("Type a message...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)
                    .onSubmit {
                        sendMessage()
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.blue))
                }
                .disabled(viewModel.isLoading || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
        }
        .onAppear {
            isInputFocused = true
        }
    }
    
    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        viewModel.sendMessage(trimmedText)
        inputText = ""
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
print("Generating tutorial code files...")
writeFiles(setupCode)
writeFiles(chatCode)

// Continue with more tutorials...
print("\nGenerated \(setupCode.count + chatCode.count) files so far...")
print("Run this script again with more tutorial content to generate the remaining files.")