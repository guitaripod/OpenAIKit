// WeatherAssistantView.swift - With example queries
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Messages or examples
            if assistant.messages.count <= 1 {  // Only system message
                examplesView
            } else {
                messagesView
            }
            
            // Input
            inputView
        }
    }
    
    private var examplesView: some View {
        VStack(spacing: 20) {
            Text("Try asking:")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                ForEach(exampleQueries, id: \.self) { query in
                    Button(action: {
                        inputText = query
                        sendMessage()
                    }) {
                        Text(query)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
    }
}