import Foundation
import OpenAIKit
import CryptoKit

// Implement secure credential storage for DeepResearch

class SecureCredentialManager {
    private let keychain = KeychainWrapper()
    private let encryptionManager = EncryptionManager()
    private var credentialCache: [String: Credential] = [:]
    private let cacheQueue = DispatchQueue(label: "credentials.cache", attributes: .concurrent)
    
    // Credential types
    enum CredentialType: String, CaseIterable {
        case openAIKey = "openai_api_key"
        case deepResearchKey = "deep_research_key"
        case mcpCredentials = "mcp_credentials"
        case proxyAuth = "proxy_authentication"
        case customService = "custom_service"
    }
    
    // Store credential securely
    func storeCredential(
        _ credential: Credential,
        type: CredentialType,
        identifier: String? = nil
    ) throws {
        let key = buildKey(type: type, identifier: identifier)
        
        // Encrypt sensitive data
        let encryptedData = try encryptionManager.encrypt(credential)
        
        // Store in keychain
        try keychain.store(
            data: encryptedData,
            for: key,
            accessible: .whenUnlockedThisDeviceOnly
        )
        
        // Update cache
        cacheQueue.async(flags: .barrier) {
            self.credentialCache[key] = credential
        }
        
        // Log storage (without sensitive data)
        logCredentialOperation(.stored, type: type, success: true)
    }
    
    // Retrieve credential
    func retrieveCredential(
        type: CredentialType,
        identifier: String? = nil
    ) throws -> Credential {
        let key = buildKey(type: type, identifier: identifier)
        
        // Check cache first
        if let cached = getCachedCredential(key: key) {
            return cached
        }
        
        // Retrieve from keychain
        guard let encryptedData = try keychain.retrieve(for: key) else {
            throw CredentialError.notFound(type)
        }
        
        // Decrypt
        let credential = try encryptionManager.decrypt(encryptedData, as: Credential.self)
        
        // Update cache
        cacheQueue.async(flags: .barrier) {
            self.credentialCache[key] = credential
        }
        
        // Log retrieval
        logCredentialOperation(.retrieved, type: type, success: true)
        
        return credential
    }
    
    // Update credential
    func updateCredential(
        type: CredentialType,
        identifier: String? = nil,
        update: (inout Credential) -> Void
    ) throws {
        var credential = try retrieveCredential(type: type, identifier: identifier)
        update(&credential)
        try storeCredential(credential, type: type, identifier: identifier)
    }
    
    // Delete credential
    func deleteCredential(
        type: CredentialType,
        identifier: String? = nil
    ) throws {
        let key = buildKey(type: type, identifier: identifier)
        
        try keychain.delete(for: key)
        
        // Remove from cache
        cacheQueue.async(flags: .barrier) {
            self.credentialCache.removeValue(forKey: key)
        }
        
        logCredentialOperation(.deleted, type: type, success: true)
    }
    
    // Rotate credentials
    func rotateCredential(
        type: CredentialType,
        identifier: String? = nil,
        newValue: String
    ) async throws {
        // Store old credential as backup
        let oldCredential = try retrieveCredential(type: type, identifier: identifier)
        let backupKey = buildKey(type: type, identifier: "backup_\(identifier ?? "default")")
        
        try storeCredential(
            oldCredential,
            type: type,
            identifier: "backup_\(identifier ?? "default")"
        )
        
        // Update with new value
        try updateCredential(type: type, identifier: identifier) { credential in
            credential.value = newValue
            credential.rotatedAt = Date()
            credential.version += 1
        }
        
        // Test new credential
        let testResult = await testCredential(type: type, value: newValue)
        
        if !testResult {
            // Rollback if test fails
            try storeCredential(oldCredential, type: type, identifier: identifier)
            try deleteCredential(type: type, identifier: "backup_\(identifier ?? "default")")
            throw CredentialError.rotationFailed
        }
        
        // Clean up backup after successful rotation
        try deleteCredential(type: type, identifier: "backup_\(identifier ?? "default")")
        
        logCredentialOperation(.rotated, type: type, success: true)
    }
    
    // Validate all credentials
    func validateAllCredentials() async -> CredentialValidationReport {
        var results: [CredentialType: ValidationResult] = [:]
        
        for type in CredentialType.allCases {
            do {
                let credential = try retrieveCredential(type: type)
                let isValid = await testCredential(type: type, value: credential.value)
                
                results[type] = ValidationResult(
                    isValid: isValid,
                    lastValidated: Date(),
                    expiresAt: credential.expiresAt,
                    error: nil
                )
            } catch {
                results[type] = ValidationResult(
                    isValid: false,
                    lastValidated: Date(),
                    expiresAt: nil,
                    error: error.localizedDescription
                )
            }
        }
        
        return CredentialValidationReport(
            results: results,
            overallValid: results.values.allSatisfy { $0.isValid },
            timestamp: Date()
        )
    }
    
    // Secure OpenAI client initialization
    func createSecureOpenAIClient() throws -> OpenAI {
        let credential = try retrieveCredential(type: .openAIKey)
        
        // Validate before use
        guard credential.isValid else {
            throw CredentialError.expired(type: .openAIKey)
        }
        
        let configuration = Configuration(
            apiKey: credential.value,
            organizationId: credential.metadata["organization_id"] as? String
        )
        
        return OpenAI(configuration)
    }
    
    // Secure DeepResearch initialization
    func createSecureDeepResearch() throws -> DeepResearch {
        let openAI = try createSecureOpenAIClient()
        return DeepResearch(client: openAI)
    }
    
    // Environment-based credential loading
    func loadFromEnvironment() throws {
        // OpenAI API Key
        if let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            let credential = Credential(
                value: openAIKey,
                type: .apiKey,
                createdAt: Date(),
                metadata: [:]
            )
            try storeCredential(credential, type: .openAIKey)
        }
        
        // Other environment variables
        let envMappings: [(String, CredentialType)] = [
            ("MCP_CLIENT_ID", .mcpCredentials),
            ("PROXY_AUTH", .proxyAuth)
        ]
        
        for (envVar, credType) in envMappings {
            if let value = ProcessInfo.processInfo.environment[envVar] {
                let credential = Credential(
                    value: value,
                    type: .apiKey,
                    createdAt: Date(),
                    metadata: ["source": "environment"]
                )
                try storeCredential(credential, type: credType)
            }
        }
    }
    
    // Private helper methods
    private func buildKey(type: CredentialType, identifier: String?) -> String {
        if let identifier = identifier {
            return "\(type.rawValue).\(identifier)"
        }
        return type.rawValue
    }
    
    private func getCachedCredential(key: String) -> Credential? {
        cacheQueue.sync {
            credentialCache[key]
        }
    }
    
    private func testCredential(type: CredentialType, value: String) async -> Bool {
        switch type {
        case .openAIKey:
            return await testOpenAIKey(value)
        case .deepResearchKey:
            return await testDeepResearchKey(value)
        case .mcpCredentials:
            return await testMCPCredentials(value)
        default:
            return true // Skip validation for other types
        }
    }
    
    private func testOpenAIKey(_ key: String) async -> Bool {
        let config = Configuration(apiKey: key)
        let client = OpenAI(config)
        
        do {
            // Simple test request
            _ = try await client.models.list()
            return true
        } catch {
            return false
        }
    }
    
    private func testDeepResearchKey(_ key: String) async -> Bool {
        // Implement DeepResearch-specific validation
        return true
    }
    
    private func testMCPCredentials(_ credentials: String) async -> Bool {
        // Implement MCP-specific validation
        return true
    }
    
    private func logCredentialOperation(
        _ operation: CredentialOperation,
        type: CredentialType,
        success: Bool
    ) {
        // Log operation without exposing sensitive data
        print("Credential operation: \(operation.rawValue) for \(type.rawValue) - \(success ? "Success" : "Failed")")
    }
}

// Encryption manager for credential data
class EncryptionManager {
    private let key: SymmetricKey
    
    init() {
        // Generate or retrieve encryption key
        if let storedKey = try? KeychainWrapper().retrieve(for: "app.encryption.key"),
           let keyData = Data(base64Encoded: storedKey) {
            self.key = SymmetricKey(data: keyData)
        } else {
            // Generate new key
            self.key = SymmetricKey(size: .bits256)
            let keyData = key.withUnsafeBytes { Data($0) }
            try? KeychainWrapper().store(
                data: keyData.base64EncodedString().data(using: .utf8)!,
                for: "app.encryption.key",
                accessible: .whenUnlockedThisDeviceOnly
            )
        }
    }
    
    func encrypt<T: Encodable>(_ object: T) throws -> Data {
        let data = try JSONEncoder().encode(object)
        let sealed = try AES.GCM.seal(data, using: key)
        return sealed.combined ?? Data()
    }
    
    func decrypt<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
        let sealed = try AES.GCM.SealedBox(combined: data)
        let decrypted = try AES.GCM.open(sealed, using: key)
        return try JSONDecoder().decode(type, from: decrypted)
    }
}

// Keychain wrapper
class KeychainWrapper {
    enum Accessibility {
        case whenUnlocked
        case whenUnlockedThisDeviceOnly
        case afterFirstUnlock
        case afterFirstUnlockThisDeviceOnly
        
        var value: CFString {
            switch self {
            case .whenUnlocked:
                return kSecAttrAccessibleWhenUnlocked
            case .whenUnlockedThisDeviceOnly:
                return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            case .afterFirstUnlock:
                return kSecAttrAccessibleAfterFirstUnlock
            case .afterFirstUnlockThisDeviceOnly:
                return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            }
        }
    }
    
    func store(data: Data, for key: String, accessible: Accessibility) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessible.value
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw CredentialError.keychainError(status)
        }
    }
    
    func retrieve(for key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw CredentialError.keychainError(status)
        }
        
        return result as? Data
    }
    
    func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CredentialError.keychainError(status)
        }
    }
}

// Models
struct Credential: Codable {
    let value: String
    let type: CredentialValueType
    let createdAt: Date
    var rotatedAt: Date?
    var expiresAt: Date?
    var version: Int = 1
    var metadata: [String: Any] = [:]
    
    var isValid: Bool {
        if let expiresAt = expiresAt {
            return Date() < expiresAt
        }
        return true
    }
    
    enum CredentialValueType: String, Codable {
        case apiKey
        case token
        case password
        case certificate
    }
    
    // Custom encoding for metadata
    enum CodingKeys: String, CodingKey {
        case value, type, createdAt, rotatedAt, expiresAt, version
    }
}

struct ValidationResult {
    let isValid: Bool
    let lastValidated: Date
    let expiresAt: Date?
    let error: String?
}

struct CredentialValidationReport {
    let results: [SecureCredentialManager.CredentialType: ValidationResult]
    let overallValid: Bool
    let timestamp: Date
}

enum CredentialOperation: String {
    case stored = "Stored"
    case retrieved = "Retrieved"
    case updated = "Updated"
    case deleted = "Deleted"
    case rotated = "Rotated"
}

enum CredentialError: LocalizedError {
    case notFound(SecureCredentialManager.CredentialType)
    case expired(type: SecureCredentialManager.CredentialType)
    case keychainError(OSStatus)
    case rotationFailed
    case validationFailed
    
    var errorDescription: String? {
        switch self {
        case .notFound(let type):
            return "Credential not found: \(type.rawValue)"
        case .expired(let type):
            return "Credential expired: \(type.rawValue)"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .rotationFailed:
            return "Credential rotation failed"
        case .validationFailed:
            return "Credential validation failed"
        }
    }
}

// Example usage with secure patterns
func demonstrateSecureCredentials() async {
    let credentialManager = SecureCredentialManager()
    
    do {
        // Load credentials from environment
        try credentialManager.loadFromEnvironment()
        
        // Store a new API key securely
        let apiKeyCredential = Credential(
            value: "sk-proj-...", // Never hardcode real keys
            type: .apiKey,
            createdAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .day, value: 90, to: Date()),
            metadata: ["environment": "production"]
        )
        
        try credentialManager.storeCredential(
            apiKeyCredential,
            type: .openAIKey
        )
        
        // Create secure clients
        let openAI = try credentialManager.createSecureOpenAIClient()
        let deepResearch = try credentialManager.createSecureDeepResearch()
        
        // Validate all credentials
        let validationReport = await credentialManager.validateAllCredentials()
        print("Credential validation: \(validationReport.overallValid ? "All valid" : "Some invalid")")
        
        for (type, result) in validationReport.results {
            print("\(type.rawValue): \(result.isValid ? "Valid" : "Invalid")")
            if let error = result.error {
                print("  Error: \(error)")
            }
        }
        
        // Rotate API key
        try await credentialManager.rotateCredential(
            type: .openAIKey,
            newValue: "sk-proj-new..."
        )
        
        // Use secure DeepResearch
        let config = DeepResearchConfiguration(
            maxSearchQueries: 5,
            maxWebPages: 10
        )
        
        let result = try await deepResearch.research(
            query: "Latest AI developments",
            configuration: config
        )
        
        print("Research completed securely")
        
    } catch {
        print("Security error: \(error)")
    }
}

// Best practices extension
extension SecureCredentialManager {
    // Credential security best practices
    static var bestPractices: [String] {
        return [
            "Never hardcode credentials in source code",
            "Use environment variables for development",
            "Rotate credentials regularly (every 90 days)",
            "Use device-only keychain accessibility when possible",
            "Implement credential validation before use",
            "Log credential operations without exposing values",
            "Use separate credentials for different environments",
            "Implement proper error handling for credential failures",
            "Store minimal metadata with credentials",
            "Clean up expired credentials automatically"
        ]
    }
    
    // Automatic cleanup of expired credentials
    func cleanupExpiredCredentials() throws {
        for type in SecureCredentialManager.CredentialType.allCases {
            do {
                let credential = try retrieveCredential(type: type)
                if !credential.isValid {
                    try deleteCredential(type: type)
                    print("Cleaned up expired credential: \(type.rawValue)")
                }
            } catch CredentialError.notFound {
                // Ignore missing credentials
                continue
            }
        }
    }
}