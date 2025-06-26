// OpenAIClient.swift
import OpenAIKit
import Foundation

class OpenAIManager {
    static let shared = OpenAIManager()
    
    private var apiKey: String {
        guard let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            fatalError("Missing OPENAI_API_KEY environment variable")
        }
        return key
    }
    
    let client: OpenAIKit
    
    private init() {
        let configuration = Configuration(apiKey: apiKey)
        self.client = OpenAIKit(configuration: configuration)
    }
}