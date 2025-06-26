// LinuxStreamHandler.swift
#if os(Linux)
import Foundation
import OpenAIKit

class LinuxStreamHandler: BaseStreamHandler {
    private var streamText = ""
    private var isStreaming = false
    
    override func startStream(request: ChatCompletionRequest) async throws {
        isStreaming = true
        streamText = ""
        
        // Linux-specific implementation
    }
    
    override func processChunk(_ chunk: ChatStreamChunk) {
        if let content = chunk.choices.first?.delta.content {
            streamText += content
            print(content, terminator: "") // Direct console output on Linux
        }
    }
    
    override func complete() {
        isStreaming = false
        print() // New line after stream completes
    }
}
#endif
