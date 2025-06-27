// ResearchAssistant.swift
import Foundation
import OpenAIKit

/// A comprehensive research assistant that leverages DeepResearch capabilities
class ResearchAssistant {
    let openAI: OpenAIKit
    
    init(apiKey: String) {
        // Configure with extended timeout for DeepResearch
        let config = Configuration(
            apiKey: apiKey,
            timeoutInterval: 1800  // 30 minutes for DeepResearch
        )
        self.openAI = OpenAIKit(configuration: config)
    }
}