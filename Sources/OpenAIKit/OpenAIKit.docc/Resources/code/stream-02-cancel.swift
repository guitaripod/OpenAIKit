// StreamCancellation.swift
import Foundation
import OpenAIKit

class CancellableStreamViewModel: ObservableObject {
    @Published var streamText = ""
    @Published var isStreaming = false
    
    private let streamManager = StreamManager()
    private let streamId = UUID()
    private let openAI: OpenAIKit
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
    }
    
    func startStreaming(prompt: String) {
        streamText = ""
        isStreaming = true
        
        let request = ChatCompletionRequest(
            messages: [ChatMessage(role: .user, content: prompt)],
            model: "gpt-4o-mini",
            stream: true
        )
        
        streamManager.startStream(
            id: streamId,
            request: request,
            client: openAI,
            onChunk: { [weak self] chunk in
                DispatchQueue.main.async {
                    if let content = chunk.choices.first?.delta.content {
                        self?.streamText += content
                    }
                }
            },
            onComplete: { [weak self] in
                DispatchQueue.main.async {
                    self?.isStreaming = false
                }
            },
            onError: { [weak self] error in
                DispatchQueue.main.async {
                    self?.isStreaming = false
                    print("Stream error: \(error)")
                }
            }
        )
    }
    
    func cancelStreaming() {
        streamManager.cancelStream(id: streamId)
        isStreaming = false
    }
}
