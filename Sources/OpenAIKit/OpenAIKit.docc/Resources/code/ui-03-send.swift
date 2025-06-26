// StreamingViewModel.swift - Sending messages
import Foundation
import OpenAIKit
import SwiftUI

extension StreamingViewModel {
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
        let assistantMessageIndex = messages.count
        messages.append(StreamMessage(
            role: .assistant,
            content: "",
            isComplete: false
        ))
        
        streamTask = Task {
            do {
                guard let openAI = openAI else {
                    throw OpenAIError.missingAPIKey
                }
                
                let request = ChatCompletionRequest(
                    messages: messages.map { ChatMessage(role: $0.role, content: $0.content) },
                    model: "gpt-4o-mini",
                    stream: true
                )
                
                let stream = try await openAI.chat.completionsStream(request)
                
                for try await chunk in stream {
                    guard !Task.isCancelled else { break }
                    
                    if let content = chunk.choices.first?.delta.content {
                        await MainActor.run {
                            currentStreamText += content
                            messages[assistantMessageIndex].content = currentStreamText
                        }
                    }
                }
                
                await MainActor.run {
                    messages[assistantMessageIndex].isComplete = true
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
            
            await MainActor.run {
                isStreaming = false
            }
        }
    }
}
