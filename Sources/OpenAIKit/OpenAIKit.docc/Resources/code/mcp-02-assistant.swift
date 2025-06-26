import Foundation
import OpenAIKit

// Create a company data research assistant using MCP integration
// This assistant can access internal databases and knowledge bases

class CompanyDataResearchAssistant {
    private let openAI: OpenAI
    private let mcpManager: MCPServerManager
    
    init(apiKey: String, mcpConfiguration: MCPConfiguration = .defaultConfiguration) {
        self.openAI = OpenAI(Configuration(apiKey: apiKey))
        self.mcpManager = MCPServerManager(configuration: mcpConfiguration)
    }
    
    // Research company data with MCP integration
    func researchCompanyData(query: String, dataSources: [String] = ["employees", "products", "customers"]) async throws -> ResearchResult {
        // First, query MCP data sources
        let mcpData = try await queryMCPDataSources(query: query, sources: dataSources)
        
        // Create a research request with MCP context
        let systemPrompt = """
        You are a company data research assistant with access to internal databases.
        You have been provided with data from the following sources: \(dataSources.joined(separator: ", "))
        
        Use this data to provide comprehensive insights and analysis.
        Always cite the data source when making claims.
        """
        
        let userPrompt = """
        Research Query: \(query)
        
        Available Company Data:
        \(mcpData.formattedData)
        
        Please analyze this data and provide insights.
        """
        
        let messages: [ChatMessage] = [
            ChatMessage(role: .system, content: systemPrompt),
            ChatMessage(role: .user, content: userPrompt)
        ]
        
        let chatRequest = ChatCompletionRequest(
            model: .gpt4,
            messages: messages,
            temperature: 0.3,
            maxTokens: 2000
        )
        
        let response = try await openAI.chats.create(chatRequest)
        
        return ResearchResult(
            query: query,
            findings: response.choices.first?.message.content ?? "",
            dataSources: mcpData.sources,
            timestamp: Date()
        )
    }
    
    // Query MCP data sources
    private func queryMCPDataSources(query: String, sources: [String]) async throws -> MCPData {
        var results: [String: Any] = [:]
        var accessedSources: [String] = []
        
        for source in sources {
            do {
                let data = try await mcpManager.queryDataSource(source: source, query: query)
                results[source] = data
                accessedSources.append(source)
            } catch {
                print("Failed to query \(source): \(error)")
            }
        }
        
        return MCPData(
            sources: accessedSources,
            rawData: results,
            formattedData: formatMCPData(results)
        )
    }
    
    // Format MCP data for AI processing
    private func formatMCPData(_ data: [String: Any]) -> String {
        var formatted = ""
        
        for (source, value) in data {
            formatted += "\n--- Data from \(source) ---\n"
            if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                formatted += jsonString
            } else {
                formatted += String(describing: value)
            }
            formatted += "\n"
        }
        
        return formatted
    }
}

// MCP data model
struct MCPData {
    let sources: [String]
    let rawData: [String: Any]
    let formattedData: String
}

// Research result model
struct ResearchResult {
    let query: String
    let findings: String
    let dataSources: [String]
    let timestamp: Date
    
    var summary: String {
        """
        Research Query: \(query)
        Date: \(timestamp)
        Data Sources: \(dataSources.joined(separator: ", "))
        
        Findings:
        \(findings)
        """
    }
}

// Extension for MCP data querying
extension MCPServerManager {
    func queryDataSource(source: String, query: String) async throws -> Any {
        let queryURL = configuration.serverURL.appendingPathComponent("query/\(source)")
        
        var request = URLRequest(url: queryURL)
        request.httpMethod = "POST"
        
        let payload = [
            "query": query,
            "format": "json",
            "limit": 100
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MCPError.dataSourceNotFound
        }
        
        return try JSONSerialization.jsonObject(with: data)
    }
}

// Example usage
func demonstrateMCPAssistant() async {
    let assistant = CompanyDataResearchAssistant(apiKey: "your-api-key")
    
    do {
        let result = try await assistant.researchCompanyData(
            query: "What are our top performing products in Q4 2024?",
            dataSources: ["products", "sales", "customer_feedback"]
        )
        
        print(result.summary)
    } catch {
        print("Research error: \(error)")
    }
}