import Foundation
import OpenAIKit

// OpenAIClient.swift - A shared instance for OpenAI API access
class OpenAIClient {
    static let shared = OpenAIClient()
    
    private var apiKey: String? {
        ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
    }
    
    private init() {}
}