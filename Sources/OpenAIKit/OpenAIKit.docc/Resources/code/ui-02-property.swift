// StreamingViewModel.swift - Property wrapper for streaming
import Foundation
import OpenAIKit
import SwiftUI

@MainActor
class StreamingViewModel: ObservableObject {
    @Published var messages: [StreamMessage] = []
    @Published var currentStreamText = ""
    @Published var isStreaming = false
    @Published var error: Error?
    
    private let openAI = OpenAIManager.shared.client
    private var streamTask: Task<Void, Never>?
    
    struct StreamMessage: Identifiable {
        let id = UUID()
        let role: ChatRole
        var content: String
        let timestamp = Date()
        var isComplete = true
    }
    
    func sendMessage(_ text: String) {
        // Add user message
        messages.append(StreamMessage(
            role: .user,
            content: text,
            isComplete: true
        ))
        
        // Start streaming response
        streamResponse(for: text)
    }
    
    private func streamResponse(for prompt: String) {
        streamTask?.cancel()
        currentStreamText = ""
        isStreaming = true
        error = nil
        
        // Add placeholder for assistant message
        let assistantMessage = StreamMessage(
            role: .assistant,
            content: "",
            isComplete: false
        )
        messages.append(assistantMessage)
        
        streamTask = Task {
            // Implementation next
        }
    }
}
