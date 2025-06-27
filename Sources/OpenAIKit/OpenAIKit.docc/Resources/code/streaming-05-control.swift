// StreamingResearch.swift
import Foundation
import OpenAIKit

/// View model for streaming DeepResearch responses with flow control
@MainActor
class StreamingResearchViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var researchProgress = ""
    @Published var searchCount = 0
    @Published var reasoningCount = 0
    @Published var finalContent = ""
    @Published var error: String?
    @Published var tokenUsage: (input: Int, output: Int, total: Int)?
    
    private let openAI: OpenAIKit
    private var currentTask: Task<Void, Never>?
    private var startTime: Date?
    
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
        researchProgress = "Research cancelled"
    }
    
    func performResearch(query: String, useBackgroundMode: Bool = false) {
        // Cancel any existing research
        cancelResearch()
        
        // Reset state
        isLoading = true
        researchProgress = "Starting research..."
        searchCount = 0
        reasoningCount = 0
        finalContent = ""
        error = nil
        tokenUsage = nil
        startTime = Date()
        
        // Create DeepResearch request
        let request = ResponseRequest(
            input: query,
            model: Models.DeepResearch.o4MiniDeepResearch,
            tools: [.webSearchPreview(WebSearchPreviewTool())],
            maxOutputTokens: 20000,  // High limit for complete responses
            background: useBackgroundMode
        )
        
        if useBackgroundMode {
            // Handle background mode
            currentTask = Task {
                do {
                    let response = try await openAI.responses.create(request)
                    researchProgress = "Background task created: \(response.id)"
                    // In production, poll for status or use webhooks
                } catch {
                    self.error = error.localizedDescription
                }
                self.isLoading = false
            }
        } else {
            // Handle streaming mode
            currentTask = Task {
                do {
                    var messageChunks: [String] = []
                    
                    // Stream the response
                    for try await chunk in openAI.responses.createStream(request) {
                        // Check for cancellation
                        if Task.isCancelled { break }
                        
                        guard let eventType = chunk.type else { continue }
                        
                        switch eventType {
                        case "response.created":
                            researchProgress = "Research started..."
                            
                        case "response.output_item.added":
                            if let item = chunk.item {
                                switch item.type {
                                case "web_search_call":
                                    searchCount += 1
                                    researchProgress = "Performing web search #\(searchCount)..."
                                case "reasoning":
                                    reasoningCount += 1
                                    researchProgress = "Analyzing information (step \(reasoningCount))..."
                                default:
                                    break
                                }
                            }
                            
                        case "response.output_item.done":
                            if let item = chunk.item {
                                switch item.type {
                                case "message":
                                    if let content = item.content?.text {
                                        messageChunks.append(content)
                                        finalContent = messageChunks.joined()
                                        researchProgress = "Generating response..."
                                    }
                                case "web_search_call":
                                    if let action = item.action,
                                       let query = action.query {
                                        researchProgress = "Completed search: \(query)"
                                    }
                                default:
                                    break
                                }
                            }
                            
                        case "response.done":
                            if let response = chunk.response {
                                let elapsed = Date().timeIntervalSince(startTime ?? Date())
                                researchProgress = "Research completed in \(Int(elapsed))s"
                                
                                if response.status == "incomplete" {
                                    researchProgress += " (Incomplete - token limit reached)"
                                }
                                
                                // Extract token usage
                                if let usage = response.usage {
                                    tokenUsage = (
                                        input: usage.inputTokens ?? 0,
                                        output: usage.outputTokens ?? 0,
                                        total: usage.totalTokens ?? 0
                                    )
                                }
                            }
                            
                        default:
                            break
                        }
                    }
                } catch {
                    if error is CancellationError {
                        self.researchProgress = "Research cancelled"
                    } else {
                        self.error = error.localizedDescription
                        self.researchProgress = "Research failed"
                    }
                }
                self.isLoading = false
            }
        }
    }
    
    /// Get estimated cost for the research
    var estimatedCost: String? {
        guard let usage = tokenUsage else { return nil }
        
        // Rough cost estimation for o4-mini-deep-research
        let inputCost = Double(usage.input) / 1_000_000 * 3.0   // $3/1M input
        let outputCost = Double(usage.output) / 1_000_000 * 15.0 // $15/1M output
        let totalCost = inputCost + outputCost
        
        return String(format: "$%.4f", totalCost)
    }
}