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
