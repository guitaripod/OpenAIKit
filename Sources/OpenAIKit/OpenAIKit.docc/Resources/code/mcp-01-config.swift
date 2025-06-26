import Foundation
import OpenAIKit

// Configure MCP (Model Context Protocol) server connection
// MCP allows AI assistants to access external data sources and tools

struct MCPConfiguration {
    let serverURL: URL
    let apiKey: String
    let timeout: TimeInterval
    
    // Default configuration for common MCP servers
    static let defaultConfiguration = MCPConfiguration(
        serverURL: URL(string: "https://mcp.company.internal/api/v1")!,
        apiKey: ProcessInfo.processInfo.environment["MCP_API_KEY"] ?? "",
        timeout: 30.0
    )
}

// MCP server connection manager
class MCPServerManager {
    private let configuration: MCPConfiguration
    private let urlSession: URLSession
    
    init(configuration: MCPConfiguration = .defaultConfiguration) {
        self.configuration = configuration
        
        // Configure URLSession with MCP-specific settings
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        sessionConfig.httpAdditionalHeaders = [
            "Authorization": "Bearer \(configuration.apiKey)",
            "Content-Type": "application/json",
            "X-MCP-Version": "1.0"
        ]
        
        self.urlSession = URLSession(configuration: sessionConfig)
    }
    
    // Test MCP server connection
    func testConnection() async throws -> Bool {
        let healthURL = configuration.serverURL.appendingPathComponent("health")
        let request = URLRequest(url: healthURL)
        
        let (_, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MCPError.invalidResponse
        }
        
        return httpResponse.statusCode == 200
    }
}

// MCP-specific errors
enum MCPError: LocalizedError {
    case invalidResponse
    case authenticationFailed
    case serverUnavailable
    case dataSourceNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from MCP server"
        case .authenticationFailed:
            return "MCP authentication failed"
        case .serverUnavailable:
            return "MCP server is unavailable"
        case .dataSourceNotFound:
            return "Requested data source not found"
        }
    }
}

// Example usage
func configureMCPConnection() async {
    let mcpManager = MCPServerManager()
    
    do {
        let isConnected = try await mcpManager.testConnection()
        print("MCP server connection: \(isConnected ? "Success" : "Failed")")
    } catch {
        print("MCP connection error: \(error)")
    }
}