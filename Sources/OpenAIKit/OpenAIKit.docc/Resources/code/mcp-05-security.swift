import Foundation
import OpenAIKit
import CryptoKit

// Handle MCP authentication and security

class MCPSecurityManager {
    private let keychain = KeychainManager()
    private var tokenCache: [String: MCPToken] = [:]
    private let tokenRefreshQueue = DispatchQueue(label: "mcp.token.refresh")
    
    // Secure credential storage
    struct MCPCredentials {
        let clientId: String
        let clientSecret: String
        let scope: [String]
        
        var isValid: Bool {
            !clientId.isEmpty && !clientSecret.isEmpty
        }
    }
    
    // MCP authentication token
    struct MCPToken {
        let accessToken: String
        let refreshToken: String?
        let expiresAt: Date
        let scope: [String]
        
        var isExpired: Bool {
            Date() >= expiresAt
        }
        
        var needsRefresh: Bool {
            // Refresh 5 minutes before expiry
            Date().addingTimeInterval(300) >= expiresAt
        }
    }
    
    // Authenticate with MCP server
    func authenticate(credentials: MCPCredentials) async throws -> MCPToken {
        // Check token cache first
        if let cachedToken = getCachedToken(for: credentials.clientId),
           !cachedToken.isExpired {
            return cachedToken
        }
        
        // Request new token
        let token = try await requestToken(credentials: credentials)
        
        // Cache the token
        cacheToken(token, for: credentials.clientId)
        
        // Store refresh token securely
        if let refreshToken = token.refreshToken {
            try keychain.store(
                refreshToken,
                for: "mcp.refresh.\(credentials.clientId)"
            )
        }
        
        return token
    }
    
    // Request token from MCP auth server
    private func requestToken(credentials: MCPCredentials) async throws -> MCPToken {
        guard let authURL = URL(string: "https://auth.mcp.company.internal/oauth/token") else {
            throw MCPSecurityError.invalidAuthURL
        }
        
        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Build OAuth2 request body
        let parameters = [
            "grant_type": "client_credentials",
            "client_id": credentials.clientId,
            "client_secret": credentials.clientSecret,
            "scope": credentials.scope.joined(separator: " ")
        ]
        
        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MCPSecurityError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw MCPSecurityError.authenticationFailed(statusCode: httpResponse.statusCode)
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        return MCPToken(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn)),
            scope: tokenResponse.scope.components(separatedBy: " ")
        )
    }
    
    // Refresh authentication token
    func refreshToken(clientId: String) async throws -> MCPToken {
        guard let refreshToken = try? keychain.retrieve(for: "mcp.refresh.\(clientId)") else {
            throw MCPSecurityError.noRefreshToken
        }
        
        guard let authURL = URL(string: "https://auth.mcp.company.internal/oauth/token") else {
            throw MCPSecurityError.invalidAuthURL
        }
        
        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientId
        ]
        
        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MCPSecurityError.tokenRefreshFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        let newToken = MCPToken(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken ?? refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn)),
            scope: tokenResponse.scope.components(separatedBy: " ")
        )
        
        // Update cache and keychain
        cacheToken(newToken, for: clientId)
        if let newRefreshToken = tokenResponse.refreshToken {
            try keychain.store(newRefreshToken, for: "mcp.refresh.\(clientId)")
        }
        
        return newToken
    }
    
    // Validate request permissions
    func validatePermissions(token: MCPToken, requiredScopes: [String]) throws {
        let hasRequiredScopes = requiredScopes.allSatisfy { required in
            token.scope.contains(required)
        }
        
        guard hasRequiredScopes else {
            throw MCPSecurityError.insufficientPermissions(
                required: requiredScopes,
                actual: token.scope
            )
        }
    }
    
    // Sign requests with HMAC
    func signRequest(_ request: inout URLRequest, with secret: String) throws {
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let nonce = UUID().uuidString
        
        // Create signature base string
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? ""
        let signatureBase = "\(method)\n\(url)\n\(timestamp)\n\(nonce)"
        
        // Generate HMAC signature
        guard let keyData = secret.data(using: .utf8),
              let messageData = signatureBase.data(using: .utf8) else {
            throw MCPSecurityError.signingFailed
        }
        
        let signature = HMAC<SHA256>.authenticationCode(
            for: messageData,
            using: SymmetricKey(data: keyData)
        )
        
        let signatureString = Data(signature).base64EncodedString()
        
        // Add security headers
        request.setValue(timestamp, forHTTPHeaderField: "X-MCP-Timestamp")
        request.setValue(nonce, forHTTPHeaderField: "X-MCP-Nonce")
        request.setValue(signatureString, forHTTPHeaderField: "X-MCP-Signature")
    }
    
    // Token cache management
    private func getCachedToken(for clientId: String) -> MCPToken? {
        tokenRefreshQueue.sync {
            tokenCache[clientId]
        }
    }
    
    private func cacheToken(_ token: MCPToken, for clientId: String) {
        tokenRefreshQueue.sync {
            tokenCache[clientId] = token
        }
    }
    
    // Clear all cached tokens
    func clearTokenCache() {
        tokenRefreshQueue.sync {
            tokenCache.removeAll()
        }
    }
}

// Secure MCP connection with authentication
class SecureMCPConnection {
    private let securityManager: MCPSecurityManager
    private let credentials: MCPSecurityManager.MCPCredentials
    private var currentToken: MCPSecurityManager.MCPToken?
    
    init(credentials: MCPSecurityManager.MCPCredentials) {
        self.securityManager = MCPSecurityManager()
        self.credentials = credentials
    }
    
    // Execute authenticated request
    func executeAuthenticatedRequest<T: Decodable>(
        url: URL,
        method: String = "GET",
        body: Data? = nil,
        requiredScopes: [String] = [],
        responseType: T.Type
    ) async throws -> T {
        // Ensure we have a valid token
        let token = try await ensureValidToken()
        
        // Validate permissions
        if !requiredScopes.isEmpty {
            try securityManager.validatePermissions(token: token, requiredScopes: requiredScopes)
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Sign request for additional security
        try securityManager.signRequest(&request, with: credentials.clientSecret)
        
        // Execute request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MCPSecurityError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw MCPSecurityError.requestFailed(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(responseType, from: data)
    }
    
    // Ensure we have a valid token, refreshing if necessary
    private func ensureValidToken() async throws -> MCPSecurityManager.MCPToken {
        if let token = currentToken {
            if token.needsRefresh {
                currentToken = try await securityManager.refreshToken(clientId: credentials.clientId)
            } else if !token.isExpired {
                return token
            }
        }
        
        currentToken = try await securityManager.authenticate(credentials: credentials)
        return currentToken!
    }
}

// Keychain manager for secure storage
class KeychainManager {
    func store(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw MCPSecurityError.keychainError
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw MCPSecurityError.keychainError
        }
    }
    
    func retrieve(for key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw MCPSecurityError.keychainError
        }
        
        return value
    }
}

// Security error types
enum MCPSecurityError: LocalizedError {
    case invalidAuthURL
    case invalidResponse
    case authenticationFailed(statusCode: Int)
    case tokenRefreshFailed
    case noRefreshToken
    case insufficientPermissions(required: [String], actual: [String])
    case signingFailed
    case keychainError
    case requestFailed(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidAuthURL:
            return "Invalid authentication URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .authenticationFailed(let code):
            return "Authentication failed with status code: \(code)"
        case .tokenRefreshFailed:
            return "Failed to refresh authentication token"
        case .noRefreshToken:
            return "No refresh token available"
        case .insufficientPermissions(let required, let actual):
            return "Insufficient permissions. Required: \(required), Actual: \(actual)"
        case .signingFailed:
            return "Failed to sign request"
        case .keychainError:
            return "Keychain operation failed"
        case .requestFailed(let code):
            return "Request failed with status code: \(code)"
        }
    }
}

// Token response model
struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let scope: String
    let tokenType: String
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case scope
        case tokenType = "token_type"
    }
}

// Example usage
func demonstrateMCPSecurity() async {
    let credentials = MCPSecurityManager.MCPCredentials(
        clientId: "your-client-id",
        clientSecret: "your-client-secret",
        scope: ["read:data", "write:data", "admin:reports"]
    )
    
    let connection = SecureMCPConnection(credentials: credentials)
    
    do {
        // Example: Fetch secure data
        struct DataResponse: Codable {
            let data: [String: Any]
            let timestamp: Date
        }
        
        let response = try await connection.executeAuthenticatedRequest(
            url: URL(string: "https://api.mcp.company.internal/v1/secure/data")!,
            requiredScopes: ["read:data"],
            responseType: DataResponse.self
        )
        
        print("Secure data retrieved: \(response)")
    } catch {
        print("Security error: \(error)")
    }
}