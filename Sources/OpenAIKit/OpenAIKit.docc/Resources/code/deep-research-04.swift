// MCPIntegration.swift
import Foundation
import OpenAIKit

/// Integration with Model Context Protocol (MCP) servers for custom data access
class MCPIntegration {
    let openAI = OpenAIManager.shared.client
    
    /// MCP server configuration
    struct MCPServerConfig {
        let serverURL: URL
        let apiKey: String?
        let namespace: String
        let timeout: TimeInterval
        let retryPolicy: RetryPolicy
        
        struct RetryPolicy {
            let maxRetries: Int
            let backoffMultiplier: Double
            let initialDelay: TimeInterval
        }
        
        static func create(
            serverURL: URL,
            apiKey: String? = nil,
            namespace: String = "default"
        ) -> MCPServerConfig {
            return MCPServerConfig(
                serverURL: serverURL,
                apiKey: apiKey,
                namespace: namespace,
                timeout: 30.0,
                retryPolicy: RetryPolicy(
                    maxRetries: 3,
                    backoffMultiplier: 2.0,
                    initialDelay: 1.0
                )
            )
        }
    }
    
    /// Available MCP data sources
    enum MCPDataSource {
        case companyDatabase
        case productCatalog
        case customerData
        case analyticsWarehouse
        case documentRepository
        case custom(String)
    }
    
    private var servers: [String: MCPServerConfig] = [:]
    private let secureStorage = SecureCredentialStorage()
    
    /// Register an MCP server
    func registerServer(
        name: String,
        config: MCPServerConfig
    ) throws {
        // Validate server configuration
        guard config.serverURL.scheme == "https" else {
            throw MCPError.insecureConnection
        }
        
        // Store credentials securely
        if let apiKey = config.apiKey {
            try secureStorage.store(
                credential: apiKey,
                for: "mcp_\(name)_apikey"
            )
        }
        
        servers[name] = config
    }
    
    /// Create a research assistant with MCP access
    func createMCPResearchAssistant(
        serverName: String,
        dataSources: [MCPDataSource]
    ) async throws -> MCPResearchAssistant {
        
        guard let config = servers[serverName] else {
            throw MCPError.serverNotFound(serverName)
        }
        
        // Retrieve stored credentials
        let apiKey = try secureStorage.retrieve(for: "mcp_\(serverName)_apikey")
        
        return MCPResearchAssistant(
            config: config,
            dataSources: dataSources,
            openAI: openAI
        )
    }
    
    /// Query internal databases through MCP
    func queryDatabase(
        serverName: String,
        query: DatabaseQuery
    ) async throws -> QueryResult {
        
        guard let config = servers[serverName] else {
            throw MCPError.serverNotFound(serverName)
        }
        
        // Build MCP query prompt
        let prompt = """
        Query the \(query.dataSource.description) with the following parameters:
        - Query: \(query.sqlQuery ?? query.naturalLanguageQuery)
        - Filters: \(query.filters.map { "\($0.key): \($0.value)" }.joined(separator: ", "))
        - Limit: \(query.limit)
        - Include metadata: \(query.includeMetadata)
        """
        
        // Create request with MCP tool
        let request = ChatRequest(
            model: .gpt4o,
            messages: [
                .system(content: """
                You have access to internal company data through MCP servers.
                Execute queries and provide comprehensive results with context.
                Always respect data privacy and access controls.
                """),
                .user(content: prompt)
            ],
            temperature: 0.1,
            maxTokens: 4000,
            tools: [createMCPTool(config: config, dataSource: query.dataSource)]
        )
        
        let response = try await openAI.chat.completions(request: request)
        
        return processQueryResult(response: response, query: query)
    }
    
    /// Combine MCP data with web research
    func hybridResearch(
        topic: String,
        internalSources: [MCPDataSource],
        webSearchEnabled: Bool = true
    ) async throws -> HybridResearchResult {
        
        // Prepare research context
        let context = """
        Research Topic: \(topic)
        
        You have access to:
        1. Internal data sources: \(internalSources.map { $0.description }.joined(separator: ", "))
        2. Web search: \(webSearchEnabled ? "Enabled" : "Disabled")
        
        Provide comprehensive analysis combining internal and external data.
        Clearly distinguish between internal proprietary data and public information.
        """
        
        // Create tools array
        var tools: [ChatRequest.Tool] = []
        
        // Add MCP tools for each internal source
        for source in internalSources {
            if let serverConfig = servers.values.first {
                tools.append(createMCPTool(config: serverConfig, dataSource: source))
            }
        }
        
        // Add web search tool if enabled
        if webSearchEnabled {
            tools.append(createWebSearchTool())
        }
        
        // Execute hybrid research
        let request = ChatRequest(
            model: .gpt4o,
            messages: [
                .system(content: "You are a research analyst with access to both internal company data and public web information."),
                .user(content: context)
            ],
            temperature: 0.5,
            maxTokens: 4000,
            tools: tools
        )
        
        let response = try await openAI.chat.completions(request: request)
        
        return processHybridResults(
            response: response,
            topic: topic,
            sources: internalSources
        )
    }
    
    // MARK: - Helper Methods
    
    private func createMCPTool(
        config: MCPServerConfig,
        dataSource: MCPDataSource
    ) -> ChatRequest.Tool {
        return ChatRequest.Tool(
            type: .function,
            function: .init(
                name: "query_mcp_\(dataSource.identifier)",
                description: "Query \(dataSource.description) through MCP server",
                parameters: [
                    "query": [
                        "type": "string",
                        "description": "The query to execute"
                    ],
                    "filters": [
                        "type": "object",
                        "description": "Optional filters to apply"
                    ],
                    "limit": [
                        "type": "integer",
                        "description": "Maximum number of results",
                        "default": 100
                    ]
                ]
            )
        )
    }
    
    private func createWebSearchTool() -> ChatRequest.Tool {
        return ChatRequest.Tool(
            type: .function,
            function: .init(
                name: "web_search",
                description: "Search the public web for information",
                parameters: [
                    "query": [
                        "type": "string",
                        "description": "The search query"
                    ]
                ]
            )
        )
    }
    
    private func processQueryResult(
        response: ChatResponse,
        query: DatabaseQuery
    ) -> QueryResult {
        let content = response.choices.first?.message.content ?? ""
        
        return QueryResult(
            query: query,
            results: [],
            metadata: QueryMetadata(
                executionTime: 0,
                rowsReturned: 0,
                dataSource: query.dataSource.description
            ),
            summary: content
        )
    }
    
    private func processHybridResults(
        response: ChatResponse,
        topic: String,
        sources: [MCPDataSource]
    ) -> HybridResearchResult {
        let content = response.choices.first?.message.content ?? ""
        
        return HybridResearchResult(
            topic: topic,
            internalFindings: extractInternalFindings(from: content),
            externalFindings: extractExternalFindings(from: content),
            synthesis: extractSynthesis(from: content),
            recommendations: extractRecommendations(from: content),
            dataSources: sources.map { $0.description },
            confidenceScore: calculateConfidence(from: content)
        )
    }
    
    private func extractInternalFindings(from content: String) -> [Finding] {
        return []
    }
    
    private func extractExternalFindings(from content: String) -> [Finding] {
        return []
    }
    
    private func extractSynthesis(from content: String) -> String {
        return ""
    }
    
    private func extractRecommendations(from content: String) -> [String] {
        return []
    }
    
    private func calculateConfidence(from content: String) -> Double {
        return 0.0
    }
}

// MARK: - MCP Research Assistant

class MCPResearchAssistant {
    let config: MCPIntegration.MCPServerConfig
    let dataSources: [MCPIntegration.MCPDataSource]
    let openAI: OpenAI
    
    init(
        config: MCPIntegration.MCPServerConfig,
        dataSources: [MCPIntegration.MCPDataSource],
        openAI: OpenAI
    ) {
        self.config = config
        self.dataSources = dataSources
        self.openAI = openAI
    }
    
    func research(topic: String) async throws -> ResearchResult {
        // Implementation for MCP-specific research
        return ResearchResult(
            topic: topic,
            findings: "",
            sources: [],
            confidence: 0.0
        )
    }
}

// MARK: - Data Models

struct DatabaseQuery {
    let dataSource: MCPIntegration.MCPDataSource
    let naturalLanguageQuery: String
    let sqlQuery: String?
    let filters: [String: Any]
    let limit: Int
    let includeMetadata: Bool
}

struct QueryResult {
    let query: DatabaseQuery
    let results: [[String: Any]]
    let metadata: QueryMetadata
    let summary: String
}

struct QueryMetadata {
    let executionTime: TimeInterval
    let rowsReturned: Int
    let dataSource: String
}

struct HybridResearchResult {
    let topic: String
    let internalFindings: [Finding]
    let externalFindings: [Finding]
    let synthesis: String
    let recommendations: [String]
    let dataSources: [String]
    let confidenceScore: Double
}

struct Finding {
    let content: String
    let source: String
    let confidence: Double
    let timestamp: Date?
}

// MARK: - Security

class SecureCredentialStorage {
    func store(credential: String, for key: String) throws {
        // Implementation would use Keychain on iOS/macOS
        // or secure storage on other platforms
    }
    
    func retrieve(for key: String) throws -> String? {
        // Retrieve from secure storage
        return nil
    }
    
    func delete(for key: String) throws {
        // Delete from secure storage
    }
}

// MARK: - Errors

enum MCPError: LocalizedError {
    case serverNotFound(String)
    case insecureConnection
    case authenticationFailed
    case queryTimeout
    case dataAccessDenied
    
    var errorDescription: String? {
        switch self {
        case .serverNotFound(let name):
            return "MCP server '\(name)' not found"
        case .insecureConnection:
            return "MCP servers require HTTPS connections"
        case .authenticationFailed:
            return "Failed to authenticate with MCP server"
        case .queryTimeout:
            return "MCP query timed out"
        case .dataAccessDenied:
            return "Access denied to requested data source"
        }
    }
}

// MARK: - Extensions

extension MCPIntegration.MCPDataSource {
    var description: String {
        switch self {
        case .companyDatabase:
            return "Company Database"
        case .productCatalog:
            return "Product Catalog"
        case .customerData:
            return "Customer Data"
        case .analyticsWarehouse:
            return "Analytics Warehouse"
        case .documentRepository:
            return "Document Repository"
        case .custom(let name):
            return name
        }
    }
    
    var identifier: String {
        switch self {
        case .companyDatabase:
            return "company_db"
        case .productCatalog:
            return "product_catalog"
        case .customerData:
            return "customer_data"
        case .analyticsWarehouse:
            return "analytics"
        case .documentRepository:
            return "documents"
        case .custom(let name):
            return name.lowercased().replacingOccurrences(of: " ", with: "_")
        }
    }
}