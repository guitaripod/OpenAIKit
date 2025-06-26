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
