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
