// SecurityPractices.swift
import Foundation
import OpenAIKit
import CryptoKit
import Security

/// Security best practices for DeepResearch implementations
class ResearchSecurityPractices {
    let openAI = OpenAIManager.shared.client
    
    /// Secure credential storage using Keychain (iOS/macOS) or equivalent
    class SecureCredentialManager {
        static let shared = SecureCredentialManager()
        
        private let serviceName = "com.openaikit.deepresearch"
        
        /// Store API key or credential securely
        func storeCredential(
            _ credential: String,
            for account: String,
            accessGroup: String? = nil
        ) throws {
            let data = credential.data(using: .utf8)!
            
            #if os(iOS) || os(macOS)
            // Use Keychain on Apple platforms
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: account,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            
            // Add to access group if specified
            var finalQuery = query
            if let accessGroup = accessGroup {
                finalQuery[kSecAttrAccessGroup as String] = accessGroup
            }
            
            // Delete existing item if any
            SecItemDelete(query as CFDictionary)
            
            // Add new item
            let status = SecItemAdd(finalQuery as CFDictionary, nil)
            
            guard status == errSecSuccess else {
                throw SecurityError.keychainError(status)
            }
            #else
            // Use file-based encryption for other platforms
            try storeCredentialSecurely(data, for: account)
            #endif
        }
        
        /// Retrieve credential securely
        func retrieveCredential(for account: String) throws -> String? {
            #if os(iOS) || os(macOS)
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: account,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            
            guard status == errSecSuccess,
                  let data = result as? Data,
                  let credential = String(data: data, encoding: .utf8) else {
                return nil
            }
            
            return credential
            #else
            return try retrieveCredentialSecurely(for: account)
            #endif
        }
        
        /// Delete credential
        func deleteCredential(for account: String) throws {
            #if os(iOS) || os(macOS)
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: account
            ]
            
            let status = SecItemDelete(query as CFDictionary)
            
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw SecurityError.keychainError(status)
            }
            #else
            try deleteCredentialSecurely(for: account)
            #endif
        }
        
        // Platform-agnostic secure storage
        private func storeCredentialSecurely(_ data: Data, for account: String) throws {
            // Encrypt data before storing
            let encryptedData = try encrypt(data)
            
            // Store in secure location
            let url = try getSecureStorageURL(for: account)
            try encryptedData.write(to: url)
            
            // Set file permissions
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: url.path
            )
        }
        
        private func retrieveCredentialSecurely(for account: String) throws -> String? {
            let url = try getSecureStorageURL(for: account)
            
            guard FileManager.default.fileExists(atPath: url.path) else {
                return nil
            }
            
            let encryptedData = try Data(contentsOf: url)
            let decryptedData = try decrypt(encryptedData)
            
            return String(data: decryptedData, encoding: .utf8)
        }
        
        private func deleteCredentialSecurely(for account: String) throws {
            let url = try getSecureStorageURL(for: account)
            
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        }
        
        private func getSecureStorageURL(for account: String) throws -> URL {
            let appSupport = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            
            let secureDir = appSupport.appendingPathComponent("OpenAIKit/Secure")
            try FileManager.default.createDirectory(
                at: secureDir,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
            
            return secureDir.appendingPathComponent("\(account).enc")
        }
        
        private func encrypt(_ data: Data) throws -> Data {
            // Use CryptoKit for encryption
            let key = try getOrCreateEncryptionKey()
            let sealedBox = try AES.GCM.seal(data, using: key)
            
            guard let encryptedData = sealedBox.combined else {
                throw SecurityError.encryptionFailed
            }
            
            return encryptedData
        }
        
        private func decrypt(_ data: Data) throws -> Data {
            let key = try getOrCreateEncryptionKey()
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            
            return decryptedData
        }
        
        private func getOrCreateEncryptionKey() throws -> SymmetricKey {
            let keyData = try retrieveMasterKey() ?? createMasterKey()
            return SymmetricKey(data: keyData)
        }
        
        private func createMasterKey() throws -> Data {
            let key = SymmetricKey(size: .bits256)
            let keyData = key.withUnsafeBytes { Data($0) }
            
            // Store master key securely
            try storeMasterKey(keyData)
            
            return keyData
        }
        
        private func storeMasterKey(_ keyData: Data) throws {
            // Implementation depends on platform
            // Could use hardware security module, TPM, etc.
        }
        
        private func retrieveMasterKey() throws -> Data? {
            // Implementation depends on platform
            return nil
        }
    }
    
    /// Content filtering for sensitive data
    class ContentFilter {
        /// Patterns for sensitive data detection
        enum SensitivePattern {
            case creditCard
            case ssn
            case email
            case phone
            case apiKey
            case password
            case ipAddress
            case custom(pattern: String)
            
            var regex: String {
                switch self {
                case .creditCard:
                    return #"\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b"#
                case .ssn:
                    return #"\b\d{3}-\d{2}-\d{4}\b"#
                case .email:
                    return #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"#
                case .phone:
                    return #"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"#
                case .apiKey:
                    return #"\b(api[_-]?key|apikey|api_secret|api[_-]?token)[\s]*[:=][\s]*['"]?[\w\-]{20,}['"]?\b"#
                case .password:
                    return #"\b(password|passwd|pwd)[\s]*[:=][\s]*['"]?[\w\-!@#$%^&*()]{8,}['"]?\b"#
                case .ipAddress:
                    return #"\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"#
                case .custom(let pattern):
                    return pattern
                }
            }
        }
        
        private let enabledPatterns: Set<SensitivePattern>
        private let customPatterns: [String]
        private let allowlist: Set<String>
        
        init(
            enabledPatterns: Set<SensitivePattern> = [.creditCard, .ssn, .apiKey, .password],
            customPatterns: [String] = [],
            allowlist: Set<String> = []
        ) {
            self.enabledPatterns = enabledPatterns
            self.customPatterns = customPatterns
            self.allowlist = allowlist
        }
        
        /// Filter sensitive content from text
        func filterContent(_ content: String) -> FilterResult {
            var filteredContent = content
            var detectedItems: [DetectedSensitiveItem] = []
            
            // Check each pattern
            for pattern in enabledPatterns {
                let matches = findMatches(pattern: pattern.regex, in: content)
                
                for match in matches {
                    // Skip if in allowlist
                    if allowlist.contains(match.value) {
                        continue
                    }
                    
                    // Redact the content
                    let redacted = redact(match.value, type: pattern)
                    filteredContent = filteredContent.replacingOccurrences(
                        of: match.value,
                        with: redacted
                    )
                    
                    detectedItems.append(
                        DetectedSensitiveItem(
                            type: describePattern(pattern),
                            value: match.value,
                            location: match.range,
                            redactedValue: redacted
                        )
                    )
                }
            }
            
            // Check custom patterns
            for customPattern in customPatterns {
                let matches = findMatches(pattern: customPattern, in: content)
                
                for match in matches {
                    let redacted = "[REDACTED_CUSTOM]"
                    filteredContent = filteredContent.replacingOccurrences(
                        of: match.value,
                        with: redacted
                    )
                    
                    detectedItems.append(
                        DetectedSensitiveItem(
                            type: "Custom Pattern",
                            value: match.value,
                            location: match.range,
                            redactedValue: redacted
                        )
                    )
                }
            }
            
            return FilterResult(
                originalContent: content,
                filteredContent: filteredContent,
                detectedItems: detectedItems,
                containsSensitiveData: !detectedItems.isEmpty
            )
        }
        
        private func findMatches(pattern: String, in text: String) -> [(value: String, range: NSRange)] {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                return []
            }
            
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            return matches.compactMap { match in
                guard let range = Range(match.range, in: text) else { return nil }
                return (String(text[range]), match.range)
            }
        }
        
        private func redact(_ value: String, type: SensitivePattern) -> String {
            switch type {
            case .creditCard:
                // Keep last 4 digits
                let digits = value.filter { $0.isNumber }
                if digits.count >= 4 {
                    let lastFour = String(digits.suffix(4))
                    return "[CARD-****-\(lastFour)]"
                }
                return "[REDACTED_CARD]"
                
            case .email:
                // Keep domain
                if let atIndex = value.firstIndex(of: "@") {
                    let domain = String(value[atIndex...])
                    return "[EMAIL-***\(domain)]"
                }
                return "[REDACTED_EMAIL]"
                
            case .phone:
                // Keep area code
                let digits = value.filter { $0.isNumber }
                if digits.count >= 3 {
                    let areaCode = String(digits.prefix(3))
                    return "[PHONE-\(areaCode)-***-****]"
                }
                return "[REDACTED_PHONE]"
                
            default:
                return "[REDACTED_\(describePattern(type).uppercased())]"
            }
        }
        
        private func describePattern(_ pattern: SensitivePattern) -> String {
            switch pattern {
            case .creditCard: return "Credit Card"
            case .ssn: return "SSN"
            case .email: return "Email"
            case .phone: return "Phone"
            case .apiKey: return "API Key"
            case .password: return "Password"
            case .ipAddress: return "IP Address"
            case .custom: return "Custom"
            }
        }
    }
    
    /// Network security configuration
    struct NetworkSecurityConfig {
        let requireHTTPS: Bool
        let certificatePinning: CertificatePinning?
        let proxy: ProxyConfiguration?
        let timeout: TimeInterval
        let retryPolicy: RetryPolicy
        
        struct CertificatePinning {
            let pinnedCertificates: [Data]
            let validateHost: Bool
            let allowSelfSigned: Bool
        }
        
        struct ProxyConfiguration {
            let host: String
            let port: Int
            let authentication: ProxyAuthentication?
            
            struct ProxyAuthentication {
                let username: String
                let password: String
            }
        }
        
        struct RetryPolicy {
            let maxRetries: Int
            let retryableErrors: Set<NetworkError>
            let backoffStrategy: BackoffStrategy
            
            enum BackoffStrategy {
                case constant(TimeInterval)
                case exponential(base: TimeInterval, multiplier: Double)
                case custom((Int) -> TimeInterval)
            }
        }
        
        static let `default` = NetworkSecurityConfig(
            requireHTTPS: true,
            certificatePinning: nil,
            proxy: nil,
            timeout: 30.0,
            retryPolicy: RetryPolicy(
                maxRetries: 3,
                retryableErrors: [.timeout, .connectionLost],
                backoffStrategy: .exponential(base: 1.0, multiplier: 2.0)
            )
        )
    }
    
    /// Audit logging for research activities
    class AuditLogger {
        private let logStore: LogStore
        private let encryptLogs: Bool
        
        init(logStore: LogStore, encryptLogs: Bool = true) {
            self.logStore = logStore
            self.encryptLogs = encryptLogs
        }
        
        /// Log research activity
        func logActivity(
            _ activity: ResearchActivity,
            metadata: [String: Any] = [:]
        ) async throws {
            let entry = AuditLogEntry(
                id: UUID().uuidString,
                timestamp: Date(),
                activity: activity,
                userId: getCurrentUserId(),
                sessionId: getCurrentSessionId(),
                metadata: metadata,
                ipAddress: getCurrentIPAddress(),
                userAgent: getCurrentUserAgent()
            )
            
            try await logStore.store(entry, encrypted: encryptLogs)
        }
        
        /// Query audit logs
        func queryLogs(
            filter: LogFilter,
            limit: Int = 100
        ) async throws -> [AuditLogEntry] {
            return try await logStore.query(filter: filter, limit: limit)
        }
        
        /// Export audit logs for compliance
        func exportLogs(
            startDate: Date,
            endDate: Date,
            format: ExportFormat
        ) async throws -> Data {
            let filter = LogFilter(
                startDate: startDate,
                endDate: endDate,
                activities: nil,
                users: nil
            )
            
            let logs = try await queryLogs(filter: filter, limit: .max)
            
            switch format {
            case .json:
                return try JSONEncoder().encode(logs)
            case .csv:
                return try exportAsCSV(logs)
            case .pdf:
                return try exportAsPDF(logs)
            }
        }
        
        private func getCurrentUserId() -> String {
            // Implementation to get current user ID
            return "current-user"
        }
        
        private func getCurrentSessionId() -> String {
            // Implementation to get current session ID
            return "current-session"
        }
        
        private func getCurrentIPAddress() -> String? {
            // Implementation to get current IP address
            return nil
        }
        
        private func getCurrentUserAgent() -> String? {
            // Implementation to get user agent
            return nil
        }
        
        private func exportAsCSV(_ logs: [AuditLogEntry]) throws -> Data {
            // CSV export implementation
            return Data()
        }
        
        private func exportAsPDF(_ logs: [AuditLogEntry]) throws -> Data {
            // PDF export implementation
            return Data()
        }
    }
    
    /// Data retention and cleanup policies
    class DataRetentionManager {
        private let retentionPolicy: RetentionPolicy
        private let cleanupScheduler: CleanupScheduler
        
        struct RetentionPolicy {
            let researchData: RetentionPeriod
            let auditLogs: RetentionPeriod
            let temporaryFiles: RetentionPeriod
            let sensitiveData: RetentionPeriod
            let anonymizationRules: [AnonymizationRule]
            
            struct RetentionPeriod {
                let duration: TimeInterval
                let action: RetentionAction
                
                enum RetentionAction {
                    case delete
                    case archive
                    case anonymize
                }
            }
            
            struct AnonymizationRule {
                let dataType: String
                let fields: [String]
                let method: AnonymizationMethod
                
                enum AnonymizationMethod {
                    case hash
                    case randomize
                    case generalize
                    case remove
                }
            }
        }
        
        init(policy: RetentionPolicy) {
            self.retentionPolicy = policy
            self.cleanupScheduler = CleanupScheduler()
            
            // Schedule cleanup tasks
            scheduleCleanupTasks()
        }
        
        /// Apply retention policy to data
        func applyRetentionPolicy() async throws {
            // Clean research data
            try await cleanupResearchData()
            
            // Clean audit logs
            try await cleanupAuditLogs()
            
            // Clean temporary files
            try await cleanupTemporaryFiles()
            
            // Handle sensitive data
            try await handleSensitiveData()
        }
        
        private func scheduleCleanupTasks() {
            // Schedule daily cleanup
            cleanupScheduler.scheduleDaily { [weak self] in
                Task {
                    try? await self?.applyRetentionPolicy()
                }
            }
        }
        
        private func cleanupResearchData() async throws {
            let cutoffDate = Date().addingTimeInterval(-retentionPolicy.researchData.duration)
            
            // Find data older than retention period
            let oldData = try await findOldResearchData(before: cutoffDate)
            
            // Apply retention action
            switch retentionPolicy.researchData.action {
            case .delete:
                try await deleteResearchData(oldData)
            case .archive:
                try await archiveResearchData(oldData)
            case .anonymize:
                try await anonymizeResearchData(oldData)
            }
        }
        
        private func cleanupAuditLogs() async throws {
            // Similar implementation for audit logs
        }
        
        private func cleanupTemporaryFiles() async throws {
            // Similar implementation for temporary files
        }
        
        private func handleSensitiveData() async throws {
            // Apply special handling for sensitive data
        }
        
        private func findOldResearchData(before date: Date) async throws -> [ResearchData] {
            // Implementation to find old data
            return []
        }
        
        private func deleteResearchData(_ data: [ResearchData]) async throws {
            // Secure deletion implementation
        }
        
        private func archiveResearchData(_ data: [ResearchData]) async throws {
            // Archive implementation
        }
        
        private func anonymizeResearchData(_ data: [ResearchData]) async throws {
            // Apply anonymization rules
            for item in data {
                for rule in retentionPolicy.anonymizationRules {
                    try await applyAnonymizationRule(rule, to: item)
                }
            }
        }
        
        private func applyAnonymizationRule(
            _ rule: RetentionPolicy.AnonymizationRule,
            to data: ResearchData
        ) async throws {
            // Implementation of anonymization
        }
    }
}

// MARK: - Supporting Types

enum SecurityError: LocalizedError {
    case keychainError(OSStatus)
    case encryptionFailed
    case decryptionFailed
    case invalidCredentials
    case accessDenied
    
    var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .invalidCredentials:
            return "Invalid credentials"
        case .accessDenied:
            return "Access denied"
        }
    }
}

enum NetworkError: Error {
    case timeout
    case connectionLost
    case sslError
    case proxyError
}

struct FilterResult {
    let originalContent: String
    let filteredContent: String
    let detectedItems: [DetectedSensitiveItem]
    let containsSensitiveData: Bool
}

struct DetectedSensitiveItem {
    let type: String
    let value: String
    let location: NSRange
    let redactedValue: String
}

enum ResearchActivity {
    case search(query: String)
    case dataAnalysis(type: String)
    case mcpQuery(server: String, query: String)
    case export(format: String)
    case share(recipient: String)
    case delete(resourceId: String)
}

struct AuditLogEntry: Codable {
    let id: String
    let timestamp: Date
    let activity: String // Simplified for Codable
    let userId: String
    let sessionId: String
    let metadata: [String: String] // Simplified for Codable
    let ipAddress: String?
    let userAgent: String?
}

protocol LogStore {
    func store(_ entry: AuditLogEntry, encrypted: Bool) async throws
    func query(filter: LogFilter, limit: Int) async throws -> [AuditLogEntry]
}

struct LogFilter {
    let startDate: Date?
    let endDate: Date?
    let activities: [ResearchActivity]?
    let users: [String]?
}

enum ExportFormat {
    case json
    case csv
    case pdf
}

class CleanupScheduler {
    func scheduleDaily(_ task: @escaping () -> Void) {
        // Implementation of scheduling
    }
}

struct ResearchData {
    let id: String
    let createdAt: Date
    let content: Data
    let metadata: [String: Any]
}