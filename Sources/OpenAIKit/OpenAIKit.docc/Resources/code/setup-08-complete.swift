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
        guard let apiKey = apiKey else {
            print("⚠️ Warning: OPENAI_API_KEY environment variable not set")
            print("Please add your API key to the environment variables")
            return
        }
        
        self.openai = OpenAIKit(apiKey: apiKey)
    }
}