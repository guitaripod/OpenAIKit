// ResearchAssistant.swift
import Foundation
import OpenAIKit

/// A comprehensive research assistant that leverages DeepResearch capabilities
class ResearchAssistant {
    let openAI = OpenAIManager.shared.client
    
    /// Configuration for DeepResearch features
    struct ResearchConfig {
        let enableWebSearch: Bool
        let enableCodeInterpreter: Bool
        let enableMCPServers: Bool
        let maxOutputTokens: Int
        let useBackgroundMode: Bool
        let timeout: TimeInterval
        
        static let `default` = ResearchConfig(
            enableWebSearch: true,
            enableCodeInterpreter: true,
            enableMCPServers: false,
            maxOutputTokens: 10000,  // DeepResearch needs high token limits
            useBackgroundMode: false,
            timeout: 1800.0  // 30 minutes for DeepResearch
        )
    }
    
    private var config: ResearchConfig
    
    init(config: ResearchConfig = .default) {
        self.config = config
    }
    
    /// Performs deep research on a given topic using the Responses API
    func performResearch(topic: String) async throws -> ResearchResult {
        // Configure tools for DeepResearch
        var tools: [ResponseTool] = []
        
        if config.enableWebSearch {
            tools.append(.webSearchPreview(WebSearchPreviewTool()))
        }
        
        if config.enableCodeInterpreter {
            tools.append(.codeInterpreter(CodeInterpreterTool(
                container: CodeContainer(type: "auto")
            )))
        }
        
        // Create a DeepResearch request
        let request = ResponseRequest(
            input: "Research the following topic thoroughly: \(topic). Provide comprehensive findings with citations.",
            model: Models.DeepResearch.o4MiniDeepResearch,  // Or .o3DeepResearch for more comprehensive
            tools: tools,
            maxOutputTokens: config.maxOutputTokens,
            background: config.useBackgroundMode
        )
        
        let response = try await openAI.responses.create(request)
        
        // Extract findings from output items
        var findings = ""
        var sources: [ResearchSource] = []
        
        if let output = response.output {
            for item in output {
                switch item.type {
                case "message":
                    findings += item.content?.text ?? ""
                case "web_search_call":
                    // Extract search results as sources
                    if let toolCall = item.toolCall,
                       let query = toolCall.arguments {
                        // Process web search results
                    }
                default:
                    break
                }
            }
        }
        
        return ResearchResult(
            topic: topic,
            findings: findings,
            sources: sources,
            status: response.status ?? "unknown"
        )
    }
}

/// Represents the result of a research query
struct ResearchResult {
    let topic: String
    let findings: String
    let sources: [ResearchSource]
    let status: String  // "complete", "incomplete", etc.
}

/// Represents a source used in research
struct ResearchSource {
    let title: String
    let url: String?
    let snippet: String
    let relevanceScore: Double
}