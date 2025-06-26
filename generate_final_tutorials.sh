#!/bin/bash

cd Sources/OpenAIKit/OpenAIKit.docc/Resources/code

# Create all remaining missing tutorial files

# Persona files (remaining)
cat > "persona-03-behaviors.swift" << 'EOF'
// PersonaBehavior.swift
import Foundation
import OpenAIKit

class PersonaChat: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentPersona: Persona = .helpful
    
    private let openAI: OpenAIKit
    private let personaManager = PersonaManager()
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
        updateSystemPrompt()
    }
    
    func switchPersona(to persona: Persona) {
        currentPersona = persona
        messages.removeAll()
        updateSystemPrompt()
    }
    
    private func updateSystemPrompt() {
        let systemPrompt = personaManager.buildSystemPrompt(for: currentPersona)
        messages = [ChatMessage(role: .system, content: systemPrompt)]
    }
    
    func sendMessage(_ content: String) async throws -> String {
        messages.append(ChatMessage(role: .user, content: content))
        
        let request = ChatCompletionRequest(
            messages: messages,
            model: "gpt-4o-mini",
            temperature: currentPersona.temperature
        )
        
        let response = try await openAI.chat.completions(request)
        guard let assistantContent = response.choices.first?.message.content else {
            throw ChatError.noContent
        }
        
        messages.append(ChatMessage(role: .assistant, content: assistantContent))
        return assistantContent
    }
}
EOF

cat > "persona-04-switching.swift" << 'EOF'
// PersonaSwitching.swift
import SwiftUI
import OpenAIKit

struct PersonaChatView: View {
    @StateObject private var chat: PersonaChat
    @State private var inputText = ""
    @State private var showPersonaPicker = false
    
    let availablePersonas: [Persona] = [.helpful, .creative, .technical]
    
    init(openAI: OpenAIKit) {
        _chat = StateObject(wrappedValue: PersonaChat(openAI: openAI))
    }
    
    var body: some View {
        VStack {
            // Header with persona selector
            HStack {
                Button(action: { showPersonaPicker.toggle() }) {
                    HStack {
                        Image(systemName: "person.circle")
                        Text(chat.currentPersona.name)
                    }
                }
                Spacer()
            }
            .padding()
            
            // Messages
            ScrollView {
                ForEach(chat.messages.filter { $0.role != .system }, id: \.content) { message in
                    MessageBubble(message: message)
                }
            }
            
            // Input
            HStack {
                TextField("Type a message...", text: $inputText)
                Button("Send") {
                    Task {
                        _ = try await chat.sendMessage(inputText)
                        inputText = ""
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showPersonaPicker) {
            PersonaPicker(
                personas: availablePersonas,
                selected: chat.currentPersona
            ) { persona in
                chat.switchPersona(to: persona)
                showPersonaPicker = false
            }
        }
    }
}

struct PersonaPicker: View {
    let personas: [Persona]
    let selected: Persona
    let onSelect: (Persona) -> Void
    
    var body: some View {
        NavigationView {
            List(personas) { persona in
                Button(action: { onSelect(persona) }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(persona.name)
                                .font(.headline)
                            Text(persona.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if persona.id == selected.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .navigationTitle("Choose Persona")
        }
    }
}
EOF

# State machine files
cat > "state-01-machine.swift" << 'EOF'
// ConversationStateMachine.swift
import Foundation

enum ConversationState {
    case idle
    case greeting
    case questionAnswering
    case taskExecution
    case clarification
    case farewell
}

class ConversationStateMachine {
    @Published private(set) var currentState: ConversationState = .idle
    
    func transition(to newState: ConversationState) {
        currentState = newState
    }
    
    func determineState(from message: String) -> ConversationState {
        let lowercased = message.lowercased()
        
        if lowercased.contains("hello") || lowercased.contains("hi") {
            return .greeting
        } else if lowercased.contains("?") {
            return .questionAnswering
        } else if lowercased.contains("bye") || lowercased.contains("goodbye") {
            return .farewell
        } else {
            return .taskExecution
        }
    }
}
EOF

cat > "state-02-branching.swift" << 'EOF'
// BranchingConversation.swift
import Foundation

struct ConversationNode: Identifiable {
    let id = UUID()
    let content: String
    let speaker: ChatRole
    var children: [ConversationNode] = []
}

class BranchingConversationManager: ObservableObject {
    @Published var rootNode: ConversationNode
    @Published var currentPath: [ConversationNode] = []
    
    init(systemPrompt: String) {
        self.rootNode = ConversationNode(
            content: systemPrompt,
            speaker: .system
        )
        self.currentPath = [rootNode]
    }
    
    func addMessage(_ content: String, role: ChatRole) {
        let newNode = ConversationNode(content: content, speaker: role)
        if let parent = currentPath.last {
            // In real implementation, would update tree structure
            currentPath.append(newNode)
        }
    }
    
    func branch(from node: ConversationNode) {
        // Create new branch from node
        currentPath = [rootNode, node]
    }
}
EOF

cat > "state-03-context.swift" << 'EOF'
// ContextManager.swift
import Foundation

struct ConversationContext {
    var topic: String?
    var entities: [String: String] = [:]
    var sentiment: Sentiment = .neutral
    var intent: Intent = .unknown
    
    enum Sentiment {
        case positive, neutral, negative, mixed
    }
    
    enum Intent {
        case question, request, statement, greeting, farewell, unknown
    }
}

class ContextManager: ObservableObject {
    @Published private(set) var currentContext = ConversationContext()
    
    func updateContext(from message: String, role: ChatRole) {
        if role == .user {
            currentContext.topic = extractTopic(from: message)
            currentContext.intent = classifyIntent(message)
            currentContext.sentiment = analyzeSentiment(message)
        }
    }
    
    private func extractTopic(from text: String) -> String? {
        // Simple implementation
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.first { $0.count > 3 }
    }
    
    private func classifyIntent(_ text: String) -> ConversationContext.Intent {
        if text.contains("?") {
            return .question
        } else if text.lowercased().contains("hello") {
            return .greeting
        } else {
            return .statement
        }
    }
    
    private func analyzeSentiment(_ text: String) -> ConversationContext.Sentiment {
        // Simple sentiment analysis
        let positive = ["good", "great", "excellent", "happy"]
        let negative = ["bad", "terrible", "awful", "sad"]
        
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let hasPositive = words.contains { positive.contains($0) }
        let hasNegative = words.contains { negative.contains($0) }
        
        if hasPositive && !hasNegative {
            return .positive
        } else if hasNegative && !hasPositive {
            return .negative
        } else if hasPositive && hasNegative {
            return .mixed
        } else {
            return .neutral
        }
    }
}
EOF

cat > "state-04-analytics.swift" << 'EOF'
// ConversationAnalytics.swift
import Foundation
import SwiftUI

struct ConversationMetrics {
    let messageCount: Int
    let averageResponseTime: TimeInterval
    let topicFrequency: [String: Int]
    let userEngagement: Double
}

class ConversationAnalytics: ObservableObject {
    @Published var metrics = ConversationMetrics(
        messageCount: 0,
        averageResponseTime: 0,
        topicFrequency: [:],
        userEngagement: 0
    )
    
    private var messageTimes: [(Date, ChatRole)] = []
    private var topics: [String] = []
    
    func trackMessage(role: ChatRole, content: String, context: ConversationContext) {
        messageTimes.append((Date(), role))
        if let topic = context.topic {
            topics.append(topic)
        }
        updateMetrics()
    }
    
    private func updateMetrics() {
        let messageCount = messageTimes.count
        
        // Calculate average response time
        var responseTimes: [TimeInterval] = []
        for i in 1..<messageTimes.count {
            if messageTimes[i].1 == .assistant && messageTimes[i-1].1 == .user {
                responseTimes.append(messageTimes[i].0.timeIntervalSince(messageTimes[i-1].0))
            }
        }
        let avgResponseTime = responseTimes.isEmpty ? 0 : responseTimes.reduce(0, +) / Double(responseTimes.count)
        
        // Topic frequency
        var topicFreq: [String: Int] = [:]
        for topic in topics {
            topicFreq[topic, default: 0] += 1
        }
        
        metrics = ConversationMetrics(
            messageCount: messageCount,
            averageResponseTime: avgResponseTime,
            topicFrequency: topicFreq,
            userEngagement: Double(messageCount) / max(1, messageTimes.first?.0.timeIntervalSinceNow ?? 1)
        )
    }
}
EOF

# Chatbot files
cat > "chatbot-01-class.swift" << 'EOF'
// CompleteChatbot.swift
import Foundation
import OpenAIKit

class CompleteChatbot: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false
    @Published var currentPersona: Persona = .helpful
    @Published var context = ConversationContext()
    
    private let openAI: OpenAIKit
    private let contextManager = ContextManager()
    private let analytics = ConversationAnalytics()
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
    }
    
    func sendMessage(_ content: String) async throws -> String {
        contextManager.updateContext(from: content, role: .user)
        context = contextManager.currentContext
        
        messages.append(ChatMessage(role: .user, content: content))
        analytics.trackMessage(role: .user, content: content, context: context)
        
        isTyping = true
        defer { isTyping = false }
        
        let request = ChatCompletionRequest(
            messages: messages,
            model: "gpt-4o-mini",
            temperature: currentPersona.temperature
        )
        
        let response = try await openAI.chat.completions(request)
        guard let assistantContent = response.choices.first?.message.content else {
            throw ChatError.noContent
        }
        
        messages.append(ChatMessage(role: .assistant, content: assistantContent))
        analytics.trackMessage(role: .assistant, content: assistantContent, context: context)
        
        return assistantContent
    }
}
EOF

cat > "chatbot-02-integration.swift" << 'EOF'
// CompleteChatbot.swift - Integration
import Foundation
import OpenAIKit

extension CompleteChatbot {
    func sendMessage(_ content: String) async throws -> String {
        // Update context
        contextManager.updateContext(from: content, role: .user)
        context = contextManager.currentContext
        
        // Add user message
        messages.append(ChatMessage(role: .user, content: content))
        
        // Track analytics
        analytics.trackMessage(role: .user, content: content, context: context)
        
        // Build enhanced request
        let request = buildEnhancedRequest(userMessage: content)
        
        // Get response
        isTyping = true
        defer { isTyping = false }
        
        let response = try await openAI.chat.completions(request)
        guard let assistantContent = response.choices.first?.message.content else {
            throw ChatError.noContent
        }
        
        // Process response
        await processResponse(assistantContent, for: content)
        
        return assistantContent
    }
    
    private func buildEnhancedRequest(userMessage: String) -> ChatCompletionRequest {
        var contextMessages = messages
        
        // Add context-aware system messages based on state
        if context.intent == .greeting {
            contextMessages.insert(
                ChatMessage(role: .system, content: "The user is greeting you. Be friendly and welcoming."),
                at: 1
            )
        }
        
        return ChatCompletionRequest(
            messages: contextMessages,
            model: "gpt-4o-mini",
            temperature: currentPersona.temperature
        )
    }
    
    private func processResponse(_ response: String, for userMessage: String) async {
        messages.append(ChatMessage(role: .assistant, content: response))
        contextManager.updateContext(from: response, role: .assistant)
        analytics.trackMessage(role: .assistant, content: response, context: context)
    }
}
EOF

# Continue with remaining files...
# Intent handling
cat > "chatbot-03-intents.swift" << 'EOF'
// IntentHandler.swift
import Foundation
import OpenAIKit

protocol IntentHandler {
    var supportedIntents: [ConversationContext.Intent] { get }
    func canHandle(intent: ConversationContext.Intent) -> Bool
    func handle(message: String, context: ConversationContext) async throws -> String
}

class QuestionIntentHandler: IntentHandler {
    let supportedIntents: [ConversationContext.Intent] = [.question]
    private let openAI: OpenAIKit
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
    }
    
    func canHandle(intent: ConversationContext.Intent) -> Bool {
        supportedIntents.contains(intent)
    }
    
    func handle(message: String, context: ConversationContext) async throws -> String {
        let request = ChatCompletionRequest(
            messages: [
                ChatMessage(role: .system, content: "Answer the user's question clearly and helpfully."),
                ChatMessage(role: .user, content: message)
            ],
            model: "gpt-4o-mini"
        )
        
        let response = try await openAI.chat.completions(request)
        return response.choices.first?.message.content ?? ""
    }
}
EOF

cat > "chatbot-04-flow.swift" << 'EOF'
// ConversationFlow.swift
import Foundation

protocol ConversationFlow {
    var name: String { get }
    var currentStep: Int { get }
    var isComplete: Bool { get }
    func process(message: String) -> FlowResponse
}

struct FlowResponse {
    let message: String
    let options: [String]
    let requiresInput: Bool
}

class OnboardingFlow: ConversationFlow {
    let name = "onboarding"
    private(set) var currentStep = 0
    
    var isComplete: Bool {
        currentStep >= 3
    }
    
    func process(message: String) -> FlowResponse {
        defer { currentStep += 1 }
        
        switch currentStep {
        case 0:
            return FlowResponse(
                message: "Welcome! What's your name?",
                options: [],
                requiresInput: true
            )
        case 1:
            return FlowResponse(
                message: "Nice to meet you, \(message)! What brings you here today?",
                options: ["Just exploring", "I have a question", "Need help with something"],
                requiresInput: true
            )
        case 2:
            return FlowResponse(
                message: "Great! I'm here to help. How can I assist you?",
                options: [],
                requiresInput: true
            )
        default:
            return FlowResponse(
                message: "How can I help you?",
                options: [],
                requiresInput: true
            )
        }
    }
}
EOF

cat > "chatbot-05-ui.swift" << 'EOF'
// CompleteChatbotView.swift
import SwiftUI
import OpenAIKit

struct CompleteChatbotView: View {
    @StateObject private var chatbot: CompleteChatbot
    @State private var inputText = ""
    
    init(openAI: OpenAIKit) {
        _chatbot = StateObject(wrappedValue: CompleteChatbot(openAI: openAI))
    }
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("AI Assistant")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Text(chatbot.currentPersona.name)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding()
            
            // Messages
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(chatbot.messages.filter { $0.role != .system }, id: \.content) { message in
                        MessageRow(message: message)
                    }
                    
                    if chatbot.isTyping {
                        TypingIndicator()
                    }
                }
                .padding()
            }
            
            // Input
            HStack {
                TextField("Type a message...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                
                Button("Send") {
                    Task {
                        _ = try? await chatbot.sendMessage(inputText)
                        inputText = ""
                    }
                }
                .disabled(inputText.isEmpty || chatbot.isTyping)
            }
            .padding()
        }
    }
}

struct MessageRow: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            Text(message.content)
                .padding()
                .background(message.role == .user ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(message.role == .user ? .white : .primary)
                .cornerRadius(16)
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

struct TypingIndicator: View {
    var body: some View {
        HStack {
            ForEach(0..<3) { _ in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
    }
}
EOF

cat > "chatbot-06-export.swift" << 'EOF'
// ConversationExporter.swift
import Foundation

class ConversationExporter {
    enum ExportFormat {
        case markdown
        case json
        case csv
    }
    
    func export(messages: [ChatMessage], format: ExportFormat) -> Data? {
        switch format {
        case .markdown:
            return exportAsMarkdown(messages: messages)
        case .json:
            return exportAsJSON(messages: messages)
        case .csv:
            return exportAsCSV(messages: messages)
        }
    }
    
    private func exportAsMarkdown(messages: [ChatMessage]) -> Data? {
        var markdown = "# Conversation Export\n\n"
        
        for message in messages {
            switch message.role {
            case .user:
                markdown += "**You**: \(message.content)\n\n"
            case .assistant:
                markdown += "**Assistant**: \(message.content)\n\n"
            default:
                break
            }
        }
        
        return markdown.data(using: .utf8)
    }
    
    private func exportAsJSON(messages: [ChatMessage]) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(messages)
    }
    
    private func exportAsCSV(messages: [ChatMessage]) -> Data? {
        var csv = "Role,Content\n"
        
        for message in messages {
            let content = message.content.replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\"\(message.role.rawValue)\",\"\(content)\"\n"
        }
        
        return csv.data(using: .utf8)
    }
}
EOF

# Remaining streaming files
cat > "ui-03-send.swift" << 'EOF'
// StreamingViewModel.swift - Sending messages
import Foundation
import OpenAIKit
import SwiftUI

extension StreamingViewModel {
    func sendMessage(_ text: String) {
        // Add user message
        messages.append(StreamMessage(
            role: .user,
            content: text,
            isComplete: true
        ))
        
        // Start streaming response
        streamResponse(for: text)
    }
    
    private func streamResponse(for prompt: String) {
        streamTask?.cancel()
        currentStreamText = ""
        isStreaming = true
        error = nil
        
        // Add placeholder for assistant message
        let assistantMessageIndex = messages.count
        messages.append(StreamMessage(
            role: .assistant,
            content: "",
            isComplete: false
        ))
        
        streamTask = Task {
            do {
                guard let openAI = openAI else {
                    throw OpenAIError.missingAPIKey
                }
                
                let request = ChatCompletionRequest(
                    messages: messages.map { ChatMessage(role: $0.role, content: $0.content) },
                    model: "gpt-4o-mini",
                    stream: true
                )
                
                let stream = try await openAI.chat.completionsStream(request)
                
                for try await chunk in stream {
                    guard !Task.isCancelled else { break }
                    
                    if let content = chunk.choices.first?.delta.content {
                        await MainActor.run {
                            currentStreamText += content
                            messages[assistantMessageIndex].content = currentStreamText
                        }
                    }
                }
                
                await MainActor.run {
                    messages[assistantMessageIndex].isComplete = true
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
            
            await MainActor.run {
                isStreaming = false
            }
        }
    }
}
EOF

cat > "ui-04-view.swift" << 'EOF'
// StreamingChatView.swift
import SwiftUI
import OpenAIKit

struct StreamingChatView: View {
    @StateObject private var viewModel = StreamingViewModel()
    @State private var inputText = ""
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        StreamMessageRow(message: message)
                    }
                }
                .padding()
            }
            
            HStack {
                TextField("Type a message...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.isStreaming)
                
                Button("Send") {
                    viewModel.sendMessage(inputText)
                    inputText = ""
                }
                .disabled(inputText.isEmpty || viewModel.isStreaming)
            }
            .padding()
        }
    }
}

struct StreamMessageRow: View {
    let message: StreamingViewModel.StreamMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading) {
                Text(message.content)
                    .padding()
                    .background(message.role == .user ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(16)
                
                if !message.isComplete {
                    ProgressView()
                        .scaleEffect(0.6)
                }
            }
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
}
EOF

cat > "ui-05-animation.swift" << 'EOF'
// StreamingAnimation.swift
import SwiftUI

struct AnimatedStreamText: View {
    let text: String
    @State private var visibleCharacters = 0
    
    var body: some View {
        Text(String(text.prefix(visibleCharacters)))
            .onAppear {
                animateText()
            }
            .onChange(of: text) { _ in
                animateText()
            }
    }
    
    private func animateText() {
        visibleCharacters = 0
        
        for (index, _) in text.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.02) {
                if index < text.count {
                    visibleCharacters = index + 1
                }
            }
        }
    }
}

struct StreamingTextView: View {
    @Binding var text: String
    let isComplete: Bool
    
    var body: some View {
        HStack(alignment: .bottom) {
            if isComplete {
                Text(text)
            } else {
                AnimatedStreamText(text: text)
                
                // Blinking cursor
                Text("|")
                    .opacity(isComplete ? 0 : 1)
                    .animation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true))
            }
        }
    }
}
EOF

# Stream management files
cat > "stream-01-manager.swift" << 'EOF'
// StreamManager.swift
import Foundation
import OpenAIKit

class StreamManager {
    private var activeStreams: [UUID: Task<Void, Error>] = [:]
    
    func startStream(
        id: UUID,
        request: ChatCompletionRequest,
        client: OpenAIKit,
        onChunk: @escaping (ChatStreamChunk) -> Void,
        onComplete: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        // Cancel existing stream if any
        cancelStream(id: id)
        
        let task = Task {
            do {
                let stream = try await client.chat.completionsStream(request)
                
                for try await chunk in stream {
                    if Task.isCancelled { break }
                    onChunk(chunk)
                }
                
                onComplete()
            } catch {
                if !Task.isCancelled {
                    onError(error)
                }
            }
        }
        
        activeStreams[id] = task
    }
    
    func cancelStream(id: UUID) {
        activeStreams[id]?.cancel()
        activeStreams.removeValue(forKey: id)
    }
    
    func cancelAllStreams() {
        activeStreams.values.forEach { $0.cancel() }
        activeStreams.removeAll()
    }
}
EOF

cat > "stream-02-cancel.swift" << 'EOF'
// StreamCancellation.swift
import Foundation
import OpenAIKit

class CancellableStreamViewModel: ObservableObject {
    @Published var streamText = ""
    @Published var isStreaming = false
    
    private let streamManager = StreamManager()
    private let streamId = UUID()
    private let openAI: OpenAIKit
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
    }
    
    func startStreaming(prompt: String) {
        streamText = ""
        isStreaming = true
        
        let request = ChatCompletionRequest(
            messages: [ChatMessage(role: .user, content: prompt)],
            model: "gpt-4o-mini",
            stream: true
        )
        
        streamManager.startStream(
            id: streamId,
            request: request,
            client: openAI,
            onChunk: { [weak self] chunk in
                DispatchQueue.main.async {
                    if let content = chunk.choices.first?.delta.content {
                        self?.streamText += content
                    }
                }
            },
            onComplete: { [weak self] in
                DispatchQueue.main.async {
                    self?.isStreaming = false
                }
            },
            onError: { [weak self] error in
                DispatchQueue.main.async {
                    self?.isStreaming = false
                    print("Stream error: \(error)")
                }
            }
        )
    }
    
    func cancelStreaming() {
        streamManager.cancelStream(id: streamId)
        isStreaming = false
    }
}
EOF

cat > "stream-03-reconnect.swift" << 'EOF'
// StreamReconnection.swift
import Foundation
import OpenAIKit

class ReconnectingStream {
    private let maxRetries = 3
    private var retryCount = 0
    private let client: OpenAIKit
    
    init(client: OpenAIKit) {
        self.client = client
    }
    
    func streamWithReconnect(
        request: ChatCompletionRequest,
        onChunk: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) async {
        while retryCount < maxRetries {
            do {
                let stream = try await client.chat.completionsStream(request)
                retryCount = 0 // Reset on success
                
                for try await chunk in stream {
                    if let content = chunk.choices.first?.delta.content {
                        onChunk(content)
                    }
                }
                
                break // Success, exit loop
            } catch {
                retryCount += 1
                
                if retryCount >= maxRetries {
                    onError(error)
                    break
                }
                
                // Wait before retry with exponential backoff
                let delay = pow(2.0, Double(retryCount))
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }
}
EOF

cat > "stream-04-timeout.swift" << 'EOF'
// StreamTimeout.swift
import Foundation
import OpenAIKit

class TimeoutStream {
    func streamWithTimeout(
        request: ChatCompletionRequest,
        client: OpenAIKit,
        timeout: TimeInterval,
        onChunk: @escaping (String) -> Void,
        onTimeout: @escaping () -> Void
    ) async throws {
        let streamTask = Task {
            let stream = try await client.chat.completionsStream(request)
            
            for try await chunk in stream {
                if let content = chunk.choices.first?.delta.content {
                    onChunk(content)
                }
            }
        }
        
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            streamTask.cancel()
            onTimeout()
        }
        
        // Wait for either to complete
        _ = await streamTask.result
        timeoutTask.cancel()
    }
}
EOF

# Advanced streaming files
cat > "advanced-01-tokens.swift" << 'EOF'
// TokenStreaming.swift
import Foundation
import OpenAIKit

class TokenStreamProcessor {
    @Published var tokens: [String] = []
    @Published var tokenCount = 0
    @Published var tokensPerSecond: Double = 0
    
    private var startTime: Date?
    private var tokenBuffer = ""
    
    func processChunk(_ chunk: String) {
        if startTime == nil {
            startTime = Date()
        }
        
        tokenBuffer += chunk
        
        // Simple tokenization by spaces
        let newTokens = tokenBuffer.components(separatedBy: .whitespaces)
        if newTokens.count > 1 {
            tokens.append(contentsOf: newTokens.dropLast())
            tokenBuffer = newTokens.last ?? ""
            tokenCount = tokens.count
            
            // Calculate tokens per second
            if let start = startTime {
                let elapsed = Date().timeIntervalSince(start)
                tokensPerSecond = elapsed > 0 ? Double(tokenCount) / elapsed : 0
            }
        }
    }
    
    func finalize() {
        if !tokenBuffer.isEmpty {
            tokens.append(tokenBuffer)
            tokenCount = tokens.count
            tokenBuffer = ""
        }
    }
}
EOF

cat > "advanced-02-throttle.swift" << 'EOF'
// StreamThrottling.swift
import Foundation
import Combine

class ThrottledStreamProcessor {
    private let updateInterval: TimeInterval
    private var buffer = ""
    private var updateTimer: Timer?
    private let onUpdate: (String) -> Void
    
    init(updateInterval: TimeInterval = 0.1, onUpdate: @escaping (String) -> Void) {
        self.updateInterval = updateInterval
        self.onUpdate = onUpdate
    }
    
    func processChunk(_ chunk: String) {
        buffer += chunk
        
        if updateTimer == nil {
            updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
                self.flushBuffer()
            }
        }
    }
    
    func finish() {
        updateTimer?.invalidate()
        updateTimer = nil
        flushBuffer()
    }
    
    private func flushBuffer() {
        if !buffer.isEmpty {
            onUpdate(buffer)
            buffer = ""
        }
    }
}
EOF

cat > "advanced-03-json.swift" << 'EOF'
// JSONStreamParser.swift
import Foundation

class JSONStreamParser {
    private var buffer = ""
    private var depth = 0
    
    func parse(_ chunk: String) -> [Any]? {
        buffer += chunk
        var objects: [Any] = []
        
        var startIndex = buffer.startIndex
        for (index, char) in buffer.enumerated() {
            switch char {
            case "{", "[":
                depth += 1
            case "}", "]":
                depth -= 1
                
                if depth == 0 {
                    // Complete JSON object
                    let endIndex = buffer.index(buffer.startIndex, offsetBy: index + 1)
                    let jsonString = String(buffer[startIndex..<endIndex])
                    
                    if let data = jsonString.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) {
                        objects.append(json)
                    }
                    
                    startIndex = endIndex
                }
            default:
                break
            }
        }
        
        // Keep unparsed data in buffer
        if startIndex < buffer.endIndex {
            buffer = String(buffer[startIndex...])
        } else {
            buffer = ""
        }
        
        return objects.isEmpty ? nil : objects
    }
}
EOF

cat > "advanced-04-markdown.swift" << 'EOF'
// MarkdownStreamRenderer.swift
import SwiftUI

struct MarkdownStreamView: View {
    let text: String
    let isComplete: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(parseMarkdown(text), id: \.self) { element in
                    renderElement(element)
                }
                
                if !isComplete {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding()
        }
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownElement] {
        // Simple markdown parser
        var elements: [MarkdownElement] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            if line.hasPrefix("# ") {
                elements.append(.heading(String(line.dropFirst(2))))
            } else if line.hasPrefix("- ") {
                elements.append(.listItem(String(line.dropFirst(2))))
            } else if line.hasPrefix("```") {
                elements.append(.codeBlock(line))
            } else if !line.isEmpty {
                elements.append(.paragraph(line))
            }
        }
        
        return elements
    }
    
    @ViewBuilder
    private func renderElement(_ element: MarkdownElement) -> some View {
        switch element {
        case .heading(let text):
            Text(text)
                .font(.title2)
                .fontWeight(.bold)
        case .paragraph(let text):
            Text(text)
        case .listItem(let text):
            HStack(alignment: .top) {
                Text("•")
                Text(text)
            }
        case .codeBlock(let code):
            Text(code)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
        }
    }
}

enum MarkdownElement: Hashable {
    case heading(String)
    case paragraph(String)
    case listItem(String)
    case codeBlock(String)
}
EOF

cat > "advanced-05-cache.swift" << 'EOF'
// StreamCache.swift
import Foundation

class StreamCache {
    private var cache: [String: CachedStream] = [:]
    private let maxCacheSize = 100
    private let cacheLifetime: TimeInterval = 3600 // 1 hour
    
    struct CachedStream {
        let content: String
        let timestamp: Date
        let metadata: [String: Any]
    }
    
    func store(key: String, content: String, metadata: [String: Any] = [:]) {
        cache[key] = CachedStream(
            content: content,
            timestamp: Date(),
            metadata: metadata
        )
        
        // Clean old entries if cache is too large
        if cache.count > maxCacheSize {
            cleanOldEntries()
        }
    }
    
    func retrieve(key: String) -> String? {
        guard let cached = cache[key] else { return nil }
        
        // Check if cache is still valid
        if Date().timeIntervalSince(cached.timestamp) > cacheLifetime {
            cache.removeValue(forKey: key)
            return nil
        }
        
        return cached.content
    }
    
    private func cleanOldEntries() {
        let cutoffDate = Date().addingTimeInterval(-cacheLifetime)
        cache = cache.filter { $0.value.timestamp > cutoffDate }
    }
}
EOF

cat > "platform-01-interface.swift" << 'EOF'
// PlatformStreamInterface.swift
import Foundation

protocol StreamInterface {
    func startStream(request: ChatCompletionRequest) async throws
    func processChunk(_ chunk: ChatStreamChunk)
    func handleError(_ error: Error)
    func complete()
}

class BaseStreamHandler: StreamInterface {
    func startStream(request: ChatCompletionRequest) async throws {
        fatalError("Must be implemented by subclass")
    }
    
    func processChunk(_ chunk: ChatStreamChunk) {
        // Process streaming chunk
    }
    
    func handleError(_ error: Error) {
        // Handle streaming error
    }
    
    func complete() {
        // Stream completed
    }
}
EOF

cat > "platform-02-apple.swift" << 'EOF'
// AppleStreamHandler.swift
#if canImport(Combine)
import Combine
import Foundation
import OpenAIKit

class AppleStreamHandler: BaseStreamHandler {
    private var cancellables = Set<AnyCancellable>()
    @Published var streamText = ""
    @Published var isStreaming = false
    
    override func startStream(request: ChatCompletionRequest) async throws {
        isStreaming = true
        streamText = ""
        
        // Implementation using Combine for Apple platforms
    }
    
    override func processChunk(_ chunk: ChatStreamChunk) {
        if let content = chunk.choices.first?.delta.content {
            streamText += content
        }
    }
    
    override func complete() {
        isStreaming = false
    }
}
#endif
EOF

cat > "platform-03-linux.swift" << 'EOF'
// LinuxStreamHandler.swift
#if os(Linux)
import Foundation
import OpenAIKit

class LinuxStreamHandler: BaseStreamHandler {
    private var streamText = ""
    private var isStreaming = false
    
    override func startStream(request: ChatCompletionRequest) async throws {
        isStreaming = true
        streamText = ""
        
        // Linux-specific implementation
    }
    
    override func processChunk(_ chunk: ChatStreamChunk) {
        if let content = chunk.choices.first?.delta.content {
            streamText += content
            print(content, terminator: "") // Direct console output on Linux
        }
    }
    
    override func complete() {
        isStreaming = false
        print() // New line after stream completes
    }
}
#endif
EOF

cat > "platform-04-errors.swift" << 'EOF'
// StreamErrorHandling.swift
import Foundation

enum StreamError: LocalizedError {
    case connectionLost
    case timeout
    case invalidResponse
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .connectionLost:
            return "Connection lost during streaming"
        case .timeout:
            return "Stream timed out"
        case .invalidResponse:
            return "Invalid streaming response"
        case .rateLimited:
            return "Rate limit exceeded during streaming"
        }
    }
}

class StreamErrorHandler {
    static func handle(_ error: Error) -> StreamError {
        // Map various errors to stream errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return .timeout
            case .networkConnectionLost:
                return .connectionLost
            default:
                return .connectionLost
            }
        }
        
        return .invalidResponse
    }
}
EOF

# Image generation additional files
cat > "options-01-size.swift" << 'EOF'
// ImageSizeOptions.swift
import Foundation
import OpenAIKit

extension ImageGenerationRequest {
    static func withSize(_ size: ImageSize, prompt: String) -> ImageGenerationRequest {
        ImageGenerationRequest(
            prompt: prompt,
            model: "dall-e-3",
            n: 1,
            quality: .standard,
            responseFormat: .url,
            size: size,
            style: .natural,
            user: nil
        )
    }
}

enum ImageSizePreset {
    case square
    case landscape
    case portrait
    
    var size: ImageSize {
        switch self {
        case .square:
            return .size1024x1024
        case .landscape:
            return .size1792x1024
        case .portrait:
            return .size1024x1792
        }
    }
}
EOF

cat > "options-02-quality.swift" << 'EOF'
// ImageQualityOptions.swift
import Foundation
import OpenAIKit

struct ImageGenerationOptions {
    let size: ImageSize
    let quality: ImageQuality
    let style: ImageStyle
    
    static let standard = ImageGenerationOptions(
        size: .size1024x1024,
        quality: .standard,
        style: .natural
    )
    
    static let highQuality = ImageGenerationOptions(
        size: .size1024x1024,
        quality: .hd,
        style: .natural
    )
    
    static let vivid = ImageGenerationOptions(
        size: .size1024x1024,
        quality: .standard,
        style: .vivid
    )
    
    func createRequest(prompt: String) -> ImageGenerationRequest {
        ImageGenerationRequest(
            prompt: prompt,
            model: "dall-e-3",
            n: 1,
            quality: quality,
            responseFormat: .url,
            size: size,
            style: style,
            user: nil
        )
    }
}
EOF

cat > "options-03-style.swift" << 'EOF'
// ImageStyleOptions.swift
import Foundation
import OpenAIKit

class ImageStyleManager {
    func applyStyle(_ style: ImageStyle, to prompt: String) -> String {
        switch style {
        case .natural:
            return prompt
        case .vivid:
            return "\(prompt), vivid colors, high contrast, dramatic lighting"
        }
    }
    
    func enhancePrompt(_ prompt: String, with modifiers: [String]) -> String {
        let enhancedPrompt = ([prompt] + modifiers).joined(separator: ", ")
        return enhancedPrompt
    }
    
    func suggestModifiers(for category: ImageCategory) -> [String] {
        switch category {
        case .portrait:
            return ["professional lighting", "sharp focus", "detailed"]
        case .landscape:
            return ["wide angle", "cinematic", "high resolution"]
        case .abstract:
            return ["geometric", "modern", "vibrant colors"]
        case .illustration:
            return ["digital art", "stylized", "clean lines"]
        }
    }
}

enum ImageCategory {
    case portrait
    case landscape
    case abstract
    case illustration
}
EOF

cat > "options-04-multiple.swift" << 'EOF'
// MultipleImageGeneration.swift
import Foundation
import OpenAIKit

class BatchImageGenerator {
    let openAI: OpenAIKit
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
    }
    
    func generateVariations(
        prompt: String,
        count: Int,
        options: ImageGenerationOptions
    ) async throws -> [URL] {
        var urls: [URL] = []
        
        // DALL-E 3 only supports n=1, so we need multiple requests
        await withTaskGroup(of: URL?.self) { group in
            for i in 0..<count {
                group.addTask {
                    do {
                        let modifiedPrompt = "\(prompt), variation \(i + 1)"
                        let request = options.createRequest(prompt: modifiedPrompt)
                        let response = try await self.openAI.images.generations(request)
                        
                        if let urlString = response.data.first?.url,
                           let url = URL(string: urlString) {
                            return url
                        }
                    } catch {
                        print("Failed to generate image \(i + 1): \(error)")
                    }
                    return nil
                }
            }
            
            for await url in group {
                if let url = url {
                    urls.append(url)
                }
            }
        }
        
        return urls
    }
}
EOF

cat > "options-05-format.swift" << 'EOF'
// ImageFormatOptions.swift
import Foundation
import OpenAIKit

class ImageFormatHandler {
    func generateWithFormat(
        prompt: String,
        format: ImageResponseFormat,
        client: OpenAIKit
    ) async throws -> ImageData {
        let request = ImageGenerationRequest(
            prompt: prompt,
            model: "dall-e-3",
            n: 1,
            quality: .standard,
            responseFormat: format,
            size: .size1024x1024,
            style: .natural,
            user: nil
        )
        
        let response = try await client.images.generations(request)
        
        guard let imageData = response.data.first else {
            throw ImageError.noImageGenerated
        }
        
        switch format {
        case .url:
            if let url = imageData.url {
                return .url(url)
            }
        case .b64Json:
            if let b64 = imageData.b64Json {
                return .base64(b64)
            }
        }
        
        throw ImageError.invalidFormat
    }
}

enum ImageData {
    case url(String)
    case base64(String)
    
    func toData() throws -> Data {
        switch self {
        case .url(let urlString):
            guard let url = URL(string: urlString) else {
                throw ImageError.invalidURL
            }
            return try Data(contentsOf: url)
        case .base64(let base64String):
            guard let data = Data(base64Encoded: base64String) else {
                throw ImageError.invalidBase64
            }
            return data
        }
    }
}

extension ImageError {
    static let invalidFormat = ImageError.noImageGenerated
    static let invalidURL = ImageError.downloadFailed
    static let invalidBase64 = ImageError.invalidImageData
}
EOF

# UI files for image generation
cat > "ui-01-viewmodel.swift" << 'EOF'
// ImageGenerationViewModel.swift
import Foundation
import OpenAIKit
import SwiftUI

@MainActor
class ImageGenerationViewModel: ObservableObject {
    @Published var prompt = ""
    @Published var generatedImageURL: URL?
    @Published var isGenerating = false
    @Published var error: Error?
    @Published var options = ImageGenerationOptions.standard
    
    private let openAI: OpenAIKit
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
    }
    
    func generateImage() async {
        guard !prompt.isEmpty else { return }
        
        isGenerating = true
        error = nil
        
        do {
            let request = options.createRequest(prompt: prompt)
            let response = try await openAI.images.generations(request)
            
            if let urlString = response.data.first?.url,
               let url = URL(string: urlString) {
                generatedImageURL = url
            }
        } catch {
            self.error = error
        }
        
        isGenerating = false
    }
}
EOF

cat > "ui-02-prompt.swift" << 'EOF'
// PromptBuilderView.swift
import SwiftUI

struct PromptBuilderView: View {
    @Binding var prompt: String
    @State private var selectedCategory: ImageCategory = .portrait
    @State private var selectedModifiers: Set<String> = []
    
    let styleManager = ImageStyleManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Build Your Prompt")
                .font(.headline)
            
            TextEditor(text: $prompt)
                .frame(height: 100)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            // Category selector
            Picker("Category", selection: $selectedCategory) {
                Text("Portrait").tag(ImageCategory.portrait)
                Text("Landscape").tag(ImageCategory.landscape)
                Text("Abstract").tag(ImageCategory.abstract)
                Text("Illustration").tag(ImageCategory.illustration)
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedCategory) { _ in
                updateModifiers()
            }
            
            // Modifier chips
            Text("Suggested Modifiers")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            FlowLayout {
                ForEach(styleManager.suggestModifiers(for: selectedCategory), id: \.self) { modifier in
                    ModifierChip(
                        text: modifier,
                        isSelected: selectedModifiers.contains(modifier)
                    ) {
                        toggleModifier(modifier)
                    }
                }
            }
            
            Button("Apply Modifiers") {
                applyModifiers()
            }
            .disabled(selectedModifiers.isEmpty)
        }
        .padding()
    }
    
    private func updateModifiers() {
        selectedModifiers.removeAll()
    }
    
    private func toggleModifier(_ modifier: String) {
        if selectedModifiers.contains(modifier) {
            selectedModifiers.remove(modifier)
        } else {
            selectedModifiers.insert(modifier)
        }
    }
    
    private func applyModifiers() {
        prompt = styleManager.enhancePrompt(prompt, with: Array(selectedModifiers))
    }
}

struct ModifierChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

struct FlowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // Simple flow layout implementation
        .zero
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // Simple flow layout implementation
    }
}
EOF

# Continue with remaining files...
echo "Tutorial code generation completed!"
echo "Total files created: $(ls -1 | wc -l)"