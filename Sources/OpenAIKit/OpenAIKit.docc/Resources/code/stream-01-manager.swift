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
