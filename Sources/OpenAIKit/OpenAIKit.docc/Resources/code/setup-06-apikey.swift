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
    
    private init() {}
}