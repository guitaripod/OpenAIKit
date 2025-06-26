// websearch-02-params.swift
// Add web search parameters and domain configuration

import Foundation
import OpenAIKit

/// Market research assistant with configurable web search parameters
class MarketResearchAssistant {
    let openAI = OpenAIManager.shared.client
    
    /// Configuration for web search parameters
    struct WebSearchConfig {
        let allowedDomains: [String]?
        let blockedDomains: [String]?
        let maxResults: Int
        let searchDepth: SearchDepth
        
        enum SearchDepth {
            case shallow  // Quick overview (5-10 results)
            case standard // Balanced approach (10-20 results)
            case deep     // Comprehensive analysis (20-30 results)
            
            var resultCount: Int {
                switch self {
                case .shallow: return 10
                case .standard: return 20
                case .deep: return 30
                }
            }
        }
        
        static let `default` = WebSearchConfig(
            allowedDomains: nil,
            blockedDomains: ["example.com", "test.com", "localhost"],
            maxResults: 20,
            searchDepth: .standard
        )
        
        static let trustedSources = WebSearchConfig(
            allowedDomains: [
                "statista.com",
                "gartner.com",
                "forrester.com",
                "mckinsey.com",
                "deloitte.com",
                "pwc.com",
                "bloomberg.com",
                "reuters.com"
            ],
            blockedDomains: nil,
            maxResults: 25,
            searchDepth: .deep
        )
    }
    
    private let config: WebSearchConfig
    
    init(config: WebSearchConfig = .default) {
        self.config = config
    }
    
    /// Performs market research with configurable parameters
    func researchMarket(
        industry: String,
        competitors: [String]? = nil,
        timeframe: String = "last 12 months",
        regions: [String]? = nil
    ) async throws -> String {
        
        // Build comprehensive research prompt
        var prompt = """
        Conduct market research for the \(industry) industry.
        Timeframe: \(timeframe)
        
        Research requirements:
        1. Market size and valuation
        2. Growth rate and projections
        3. Key market players and their market share
        4. Industry trends and innovations
        5. Regulatory landscape
        """
        
        if let competitors = competitors, !competitors.isEmpty {
            prompt += "\n\nAnalyze these specific competitors: \(competitors.joined(separator: ", "))"
        }
        
        if let regions = regions, !regions.isEmpty {
            prompt += "\n\nFocus on these geographic regions: \(regions.joined(separator: ", "))"
        }
        
        // Build search queries
        let searchQueries = buildSearchQueries(
            industry: industry,
            competitors: competitors,
            timeframe: timeframe
        )
        
        // Create request with enhanced web search tool
        let request = ChatRequest(
            model: .gpt4o,
            messages: [
                .system(content: """
                You are an expert market research analyst with access to web search.
                Provide data-driven insights with specific numbers and cite your sources.
                Focus on recent, reliable data from trusted sources.
                """),
                .user(content: prompt)
            ],
            temperature: 0.3,
            maxTokens: 4000,
            tools: [createEnhancedWebSearchTool()]
        )
        
        // Execute research
        let response = try await openAI.chat.completions(request: request)
        
        return response.choices.first?.message.content ?? "No research data found"
    }
    
    /// Build targeted search queries for comprehensive research
    private func buildSearchQueries(
        industry: String,
        competitors: [String]?,
        timeframe: String
    ) -> [String] {
        var queries = [
            "\(industry) market size \(timeframe)",
            "\(industry) industry growth rate statistics",
            "\(industry) market share leaders",
            "\(industry) industry trends analysis",
            "\(industry) market forecast projections"
        ]
        
        if let competitors = competitors {
            for competitor in competitors {
                queries.append("\(competitor) revenue market share \(industry)")
            }
        }
        
        return queries
    }
    
    /// Creates enhanced web search tool with parameters
    private func createEnhancedWebSearchTool() -> ChatRequest.Tool {
        var parameters: [String: Any] = [
            "query": [
                "type": "string",
                "description": "The search query for market research"
            ],
            "num_results": [
                "type": "integer",
                "description": "Number of search results to return",
                "default": config.searchDepth.resultCount
            ]
        ]
        
        // Add domain filtering if configured
        if let allowedDomains = config.allowedDomains {
            parameters["allowed_domains"] = [
                "type": "array",
                "items": ["type": "string"],
                "description": "Only include results from these domains",
                "default": allowedDomains
            ]
        }
        
        if let blockedDomains = config.blockedDomains {
            parameters["blocked_domains"] = [
                "type": "array",
                "items": ["type": "string"],
                "description": "Exclude results from these domains",
                "default": blockedDomains
            ]
        }
        
        return ChatRequest.Tool(
            type: .function,
            function: .init(
                name: "web_search",
                description: "Search the web for current market information with domain filtering",
                parameters: parameters
            )
        )
    }
}

// MARK: - Usage Example

func performConfiguredMarketResearch() async throws {
    // Use default configuration
    let defaultAssistant = MarketResearchAssistant()
    
    // Use trusted sources configuration
    let trustedAssistant = MarketResearchAssistant(config: .trustedSources)
    
    // Custom configuration
    let customConfig = MarketResearchAssistant.WebSearchConfig(
        allowedDomains: ["statista.com", "marketwatch.com", "forbes.com"],
        blockedDomains: nil,
        maxResults: 15,
        searchDepth: .standard
    )
    let customAssistant = MarketResearchAssistant(config: customConfig)
    
    // Perform research with parameters
    let research = try await trustedAssistant.researchMarket(
        industry: "renewable energy",
        competitors: ["Tesla Energy", "Enphase", "SunPower"],
        timeframe: "2023-2024",
        regions: ["North America", "Europe"]
    )
    
    print("Market Research Results:")
    print(research)
}

// Example usage:
// Task {
//     try await performConfiguredMarketResearch()
// }