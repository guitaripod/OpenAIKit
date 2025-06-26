// OpenAIClient.swift
import OpenAIKit
import Foundation

enum OpenAIError: LocalizedError {
    case missingAPIKey
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key not found. Please set the OPENAI_API_KEY environment variable."
        }
    }
}

class OpenAIManager {
    static let shared = OpenAIManager()
    
    private var apiKey: String? {
        ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
    }
    
    let client: OpenAIKit?
    
    private init() {
        guard let apiKey = apiKey else {
            print("Warning: \(OpenAIError.missingAPIKey.errorDescription ?? "")")
            self.client = nil
            return
        }
        
        let configuration = Configuration(apiKey: apiKey)
        self.client = OpenAIKit(configuration: configuration)
    }
}