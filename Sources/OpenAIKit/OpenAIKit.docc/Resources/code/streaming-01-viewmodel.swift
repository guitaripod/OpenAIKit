// StreamingResearch.swift
import Foundation
import OpenAIKit

/// View model for streaming DeepResearch responses
@MainActor
class StreamingResearchViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var researchProgress = ""
    @Published var searchCount = 0
    @Published var reasoningCount = 0
    @Published var finalContent = ""
    @Published var error: String?
    
    private let openAI: OpenAIKit
    private var currentTask: Task<Void, Never>?
    
    init(apiKey: String) {
        // Configure with extended timeout for DeepResearch
        let config = Configuration(
            apiKey: apiKey,
            timeoutInterval: 1800  // 30 minutes
        )
        self.openAI = OpenAIKit(configuration: config)
    }
    
    func cancelResearch() {
        currentTask?.cancel()
        currentTask = nil
        isLoading = false
    }
}