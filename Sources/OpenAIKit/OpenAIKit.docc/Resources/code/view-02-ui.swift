// WeatherAssistantView.swift
import SwiftUI

struct WeatherAssistantView: View {
    @StateObject private var assistant: WeatherAssistant
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    
    init(openAI: OpenAIKit) {
        _assistant = StateObject(wrappedValue: WeatherAssistant(openAI: openAI))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Weather Assistant")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .shadow(radius: 1)
            
            // Messages
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(assistant.messages.filter { $0.role != .system }, id: \.content) { message in
                        MessageRow(message: message)
                    }
                    
                    if assistant.isProcessing {
                        HStack {
                            ProgressView()
                            Text("Getting weather information...")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
                .padding()
            }
            
            // Input
            HStack {
                TextField("Ask about weather...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)
                
                Button("Send") {
                    sendMessage()
                }
                .disabled(inputText.isEmpty || assistant.isProcessing)
            }
            .padding()
        }
    }
    
    private func sendMessage() {
        let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        inputText = ""
        Task {
            await assistant.sendMessage(message)
        }
    }
}