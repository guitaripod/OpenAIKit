// TokenStreaming.swift
import Foundation
import OpenAIKit

class TokenStreamProcessor {
    @Published var tokens: [String] = []
    @Published var tokenCount = 0
    @Published var tokensPerSecond: Double = 0
    
    private var startTime: Date?
    private var tokenBuffer = ""
    
    func processChunk(_ chunk: String) {
        if startTime == nil {
            startTime = Date()
        }
        
        tokenBuffer += chunk
        
        // Simple tokenization by spaces
        let newTokens = tokenBuffer.components(separatedBy: .whitespaces)
        if newTokens.count > 1 {
            tokens.append(contentsOf: newTokens.dropLast())
            tokenBuffer = newTokens.last ?? ""
            tokenCount = tokens.count
            
            // Calculate tokens per second
            if let start = startTime {
                let elapsed = Date().timeIntervalSince(start)
                tokensPerSecond = elapsed > 0 ? Double(tokenCount) / elapsed : 0
            }
        }
    }
    
    func finalize() {
        if !tokenBuffer.isEmpty {
            tokens.append(tokenBuffer)
            tokenCount = tokens.count
            tokenBuffer = ""
        }
    }
}
