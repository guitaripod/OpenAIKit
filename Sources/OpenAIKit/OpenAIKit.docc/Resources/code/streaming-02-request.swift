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
    
    func performResearch(query: String) {
        // Cancel any existing research
        cancelResearch()
        
        // Reset state
        isLoading = true
        researchProgress = "Starting research..."
        searchCount = 0
        reasoningCount = 0
        finalContent = ""
        error = nil
        
        // Create DeepResearch request
        let request = ResponseRequest(
            input: query,
            model: Models.DeepResearch.o4MiniDeepResearch,
            tools: [.webSearchPreview(WebSearchPreviewTool())],
            maxOutputTokens: 20000  // High limit for complete responses
        )
        
        currentTask = Task {
            do {
                // Stream the response
                for try await chunk in openAI.responses.createStream(request) {
                    // Handle streaming events (to be implemented)
                }
            } catch {
                self.error = error.localizedDescription
            }
            self.isLoading = false
        }
    }
}