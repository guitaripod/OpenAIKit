// ResearchAssistant.swift
import Foundation
import OpenAIKit

/// A comprehensive research assistant that leverages DeepResearch capabilities
class ResearchAssistant {
    let openAI: OpenAIKit
    
    /// Configuration for DeepResearch features
    struct ResearchConfig {
        let enableWebSearch: Bool
        let enableCodeInterpreter: Bool
        let enableMCPServers: Bool
        let maxOutputTokens: Int
        let useBackgroundMode: Bool
        
        static let `default` = ResearchConfig(
            enableWebSearch: true,
            enableCodeInterpreter: true,
            enableMCPServers: false,
            maxOutputTokens: 10000,  // DeepResearch needs high token limits
            useBackgroundMode: false
        )
    }
    
    private var config: ResearchConfig
    
    init(apiKey: String, config: ResearchConfig = .default) {
        // Configure with extended timeout for DeepResearch
        let apiConfig = Configuration(
            apiKey: apiKey,
            timeoutInterval: 1800  // 30 minutes for DeepResearch
        )
        self.openAI = OpenAIKit(configuration: apiConfig)
        self.config = config
    }
    
    /// Performs deep research on a given topic using the Responses API
    func performResearch(topic: String) async throws -> ResearchResult {
        // Configure tools based on settings
        var tools: [ResponseTool] = []
        
        if config.enableWebSearch {
            tools.append(.webSearchPreview(WebSearchPreviewTool()))
        }
        
        if config.enableCodeInterpreter {
            tools.append(.codeInterpreter(CodeInterpreterTool(
                container: CodeContainer(type: "auto")
            )))
        }
        
        let request = ResponseRequest(
            input: "Research the following topic thoroughly: \(topic). Provide comprehensive findings with citations.",
            model: Models.DeepResearch.o4MiniDeepResearch,
            tools: tools,
            maxOutputTokens: config.maxOutputTokens,
            background: config.useBackgroundMode
        )
        
        let response = try await openAI.responses.create(request)
        
        // Extract findings from output items
        var findings = ""
        var searchCount = 0
        
        if let output = response.output {
            for item in output {
                switch item.type {
                case "message":
                    findings += item.content ?? ""
                case "web_search_call":
                    searchCount += 1
                default:
                    break
                }
            }
        }
        
        return ResearchResult(
            topic: topic,
            findings: findings,
            webSearchesPerformed: searchCount,
            status: response.status ?? "unknown"
        )
    }
}

/// Result of a research query
struct ResearchResult {
    let topic: String
    let findings: String
    let webSearchesPerformed: Int
    let status: String
}