// Complete Weather Assistant UI
import SwiftUI
import OpenAIKit

struct WeatherAssistantView: View {
    @StateObject private var assistant: WeatherAssistant
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    
    let exampleQueries = [
        "What's the weather in San Francisco?",
        "Is it raining in London?",
        "Temperature in Tokyo in Fahrenheit",
        "How's the weather in Paris today?"
    ]
    
    init(openAI: OpenAIKit) {
        _assistant = StateObject(wrappedValue: WeatherAssistant(openAI: openAI))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            if assistant.messages.count <= 1 {
                examplesView
            } else {
                messagesView
            }
            
            if let error = assistant.error {
                errorView(error)
            }
            
            inputView
        }
        .onAppear {
            isInputFocused = true
        }
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: "cloud.sun.fill")
                .font(.title2)
                .foregroundColor(.blue)
            Text("Weather Assistant")
                .font(.title2)
                .fontWeight(.semibold)
            Spacer()
            if assistant.messages.count > 1 {
                Button("Clear") {
                    assistant.clearConversation()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(radius: 1)
    }
    
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(assistant.messages.enumerated()), id: \.offset) { index, message in
                        if message.role != .system {
                            MessageRow(message: message)
                                .id(index)
                        }
                    }
                    
                    if assistant.isProcessing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Getting weather information...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .id("loading")
                    }
                }
                .padding()
                .onChange(of: assistant.messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(assistant.isProcessing ? "loading" : assistant.messages.count - 1)
                    }
                }
            }
        }
    }
    
    private var examplesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cloud.sun.rain.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding()
            
            Text("Ask me about the weather!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Try one of these:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                ForEach(exampleQueries, id: \.self) { query in
                    Button(action: {
                        inputText = query
                        sendMessage()
                    }) {
                        HStack {
                            Image(systemName: "text.bubble")
                                .foregroundColor(.blue)
                            Text(query)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 40)
    }
    
    private var inputView: some View {
        HStack(spacing: 12) {
            TextField("Ask about weather...", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)
                .onSubmit {
                    sendMessage()
                }
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(sendButtonColor)
            }
            .disabled(inputText.isEmpty || assistant.isProcessing)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
    
    private func errorView(_ error: Error) -> some View {
        Text("Error: \(error.localizedDescription)")
            .font(.caption)
            .foregroundColor(.red)
            .padding(.horizontal)
    }
    
    private var sendButtonColor: Color {
        inputText.isEmpty || assistant.isProcessing ? .gray : .blue
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

// Message Row View
struct MessageRow: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Image(systemName: avatarIcon)
                .font(.title3)
                .foregroundColor(avatarColor)
                .frame(width: 30, height: 30)
                .background(Circle().fill(avatarColor.opacity(0.1)))
            
            // Message content
            VStack(alignment: .leading, spacing: 4) {
                Text(roleTitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                if message.role == .tool {
                    // Show weather card for function results
                    if let data = message.content.data(using: .utf8),
                       let weatherData = try? JSONDecoder().decode(WeatherData.self, from: data) {
                        WeatherCardView(weatherData: weatherData)
                    } else {
                        Text(message.content)
                            .font(.subheadline)
                    }
                } else {
                    Text(message.content)
                        .font(.subheadline)
                        .textSelection(.enabled)
                }
            }
            
            Spacer()
        }
    }
    
    private var avatarIcon: String {
        switch message.role {
        case .user:
            return "person.circle.fill"
        case .assistant:
            return "cloud.sun.fill"
        case .tool:
            return "function"
        default:
            return "circle.fill"
        }
    }
    
    private var avatarColor: Color {
        switch message.role {
        case .user:
            return .blue
        case .assistant:
            return .green
        case .tool:
            return .orange
        default:
            return .gray
        }
    }
    
    private var roleTitle: String {
        switch message.role {
        case .user:
            return "You"
        case .assistant:
            return "Weather Assistant"
        case .tool:
            return "Weather Data"
        default:
            return "System"
        }
    }
}