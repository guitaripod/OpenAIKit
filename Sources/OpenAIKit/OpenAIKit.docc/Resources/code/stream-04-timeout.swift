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
