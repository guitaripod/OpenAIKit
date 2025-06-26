// PlatformStreamInterface.swift
import Foundation

protocol StreamInterface {
    func startStream(request: ChatCompletionRequest) async throws
    func processChunk(_ chunk: ChatStreamChunk)
    func handleError(_ error: Error)
    func complete()
}

class BaseStreamHandler: StreamInterface {
    func startStream(request: ChatCompletionRequest) async throws {
        fatalError("Must be implemented by subclass")
    }
    
    func processChunk(_ chunk: ChatStreamChunk) {
        // Process streaming chunk
    }
    
    func handleError(_ error: Error) {
        // Handle streaming error
    }
    
    func complete() {
        // Stream completed
    }
}
