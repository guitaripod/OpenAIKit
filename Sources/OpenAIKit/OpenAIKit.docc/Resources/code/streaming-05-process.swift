// StreamingChat.swift - Processing streamed responses
import Foundation
import OpenAIKit

class StreamingChat: ObservableObject {
    @Published var streamedText = ""
    @Published var isStreaming = false
    
    let openAI = OpenAIManager.shared.client
    private var streamTask: Task<Void, Never>?
    
    func streamMessage(_ message: String) {
        streamTask?.cancel()
        streamedText = ""
        isStreaming = true
        
        streamTask = Task {
            do {
                guard let openAI = openAI else {
                    throw OpenAIError.missingAPIKey
                }
                
                let request = ChatCompletionRequest(
                    messages: [
                        ChatMessage(role: .user, content: message)
                    ],
                    model: "gpt-4o-mini",
                    stream: true
                )
                
                let stream = try await openAI.chat.completionsStream(request)
                
                for try await chunk in stream {
                    guard !Task.isCancelled else { break }
                    
                    if let content = chunk.choices.first?.delta.content {
                        await MainActor.run {
                            streamedText += content
                        }
                    }
                }
            } catch {
                print("Streaming error: \(error)")
            }
            
            await MainActor.run {
                isStreaming = false
            }
        }
    }
    
    func cancelStream() {
        streamTask?.cancel()
        isStreaming = false
    }
}
