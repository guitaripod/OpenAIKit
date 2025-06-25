import Foundation
import OpenAIKit

// OpenAIClient.swift - A shared instance for OpenAI API access
class OpenAIClient {
    static let shared = OpenAIClient()
    
    private(set) var openai: OpenAIKit?
    
    private var apiKey: String? {
        ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
    }
    
    private init() {
        if let apiKey = apiKey {
            self.openai = OpenAIKit(apiKey: apiKey)
        }
    }
}