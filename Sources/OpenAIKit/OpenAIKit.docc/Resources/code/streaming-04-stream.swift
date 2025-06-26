// StreamingChat.swift
import Foundation
import OpenAIKit

class StreamingChat {
    let openAI = OpenAIManager.shared.client
    
    func streamMessage(_ message: String) async throws -> AsyncThrowingStream<String, Error> {
        guard let openAI = openAI else {
            throw OpenAIError.missingAPIKey
        }
        
        let request = ChatCompletionRequest(
            messages: [
                ChatMessage(role: .user, content: message)
            ],
            model: "gpt-4o-mini",
            stream: true,
            streamOptions: StreamOptions(includeUsage: true)
        )
        
        let stream = try await openAI.chat.completionsStream(request)
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await chunk in stream {
                        if let content = chunk.choices.first?.delta.content {
                            continuation.yield(content)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
