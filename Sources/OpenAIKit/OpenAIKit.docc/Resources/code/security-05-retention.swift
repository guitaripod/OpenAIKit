import Foundation
import OpenAIKit

// Add data retention and cleanup policies for DeepResearch

class DataRetentionManager {
    private let policies: [RetentionPolicy]
    private let storage: SecureDataStorage
    private let scheduler: RetentionScheduler
    private let auditLogger: RetentionAuditLogger
    
    init(
        policies: [RetentionPolicy] = RetentionPolicy.defaultPolicies,
        storage: SecureDataStorage = SecureDataStorage(),
        scheduler: RetentionScheduler = RetentionScheduler()
    ) {
        self.policies = policies
        self.storage = storage
        self.scheduler = scheduler
        self.auditLogger = RetentionAuditLogger()
        
        // Schedule automatic cleanup
        scheduleCleanupTasks()
    }
    
    // Store research data with retention metadata
    func storeResearchData(
        _ data: ResearchData,
        classification: DataClassification,
        retentionOverride: RetentionPeriod? = nil
    ) async throws {
        
        // Determine retention period
        let retentionPeriod = retentionOverride ?? determineRetentionPeriod(
            for: classification,
            dataType: data.type
        )
        
        // Create retention metadata
        let metadata = RetentionMetadata(
            dataId: data.id,
            createdAt: Date(),
            classification: classification,
            retentionPeriod: retentionPeriod,
            expiresAt: calculateExpiryDate(from: Date(), period: retentionPeriod),
            lastAccessed: Date(),
            accessCount: 0,
            tags: data.tags
        )
        
        // Encrypt and store
        let encryptedData = try await storage.encryptAndStore(
            data: data,
            metadata: metadata
        )
        
        // Log storage
        auditLogger.logDataStorage(
            dataId: data.id,
            classification: classification,
            retentionPeriod: retentionPeriod,
            size: encryptedData.size
        )
    }
    
    // Retrieve data with access tracking
    func retrieveResearchData(
        id: String,
        purpose: AccessPurpose
    ) async throws -> ResearchData {
        
        // Check if data exists and is not expired
        guard let metadata = try await storage.getMetadata(for: id) else {
            throw RetentionError.dataNotFound(id)
        }
        
        if metadata.isExpired {
            throw RetentionError.dataExpired(id, expiredAt: metadata.expiresAt)
        }
        
        // Retrieve and decrypt
        let data = try await storage.retrieveAndDecrypt(id: id)
        
        // Update access metadata
        try await storage.updateAccessMetadata(
            id: id,
            lastAccessed: Date(),
            incrementAccessCount: true
        )
        
        // Log access
        auditLogger.logDataAccess(
            dataId: id,
            purpose: purpose,
            userId: purpose.userId
        )
        
        return data
    }
    
    // Manual data deletion
    func deleteData(
        id: String,
        reason: DeletionReason,
        authorizedBy: String
    ) async throws {
        
        guard let metadata = try await storage.getMetadata(for: id) else {
            throw RetentionError.dataNotFound(id)
        }
        
        // Check deletion authorization
        try validateDeletionAuthorization(
            metadata: metadata,
            reason: reason,
            authorizedBy: authorizedBy
        )
        
        // Perform secure deletion
        let deletionResult = try await storage.secureDelete(id: id)
        
        // Log deletion
        auditLogger.logDataDeletion(
            dataId: id,
            reason: reason,
            authorizedBy: authorizedBy,
            metadata: metadata,
            result: deletionResult
        )
    }
    
    // Execute retention policies
    func executeRetentionPolicies() async throws -> RetentionReport {
        var report = RetentionReport(
            executionDate: Date(),
            policiesExecuted: [],
            dataProcessed: 0,
            dataDeleted: 0,
            dataArchived: 0,
            errors: []
        )
        
        for policy in policies {
            do {
                let result = try await executePolicy(policy)
                report.policiesExecuted.append(result)
                report.dataProcessed += result.dataProcessed
                report.dataDeleted += result.dataDeleted
                report.dataArchived += result.dataArchived
            } catch {
                report.errors.append(
                    RetentionError.policyExecutionFailed(
                        policy: policy.name,
                        error: error
                    )
                )
            }
        }
        
        // Log execution report
        auditLogger.logRetentionExecution(report: report)
        
        return report
    }
    
    // Archive data before deletion
    func archiveData(
        id: String,
        archiveLocation: ArchiveLocation
    ) async throws {
        
        guard let metadata = try await storage.getMetadata(for: id) else {
            throw RetentionError.dataNotFound(id)
        }
        
        // Retrieve data for archiving
        let data = try await storage.retrieveAndDecrypt(id: id)
        
        // Create archive package
        let archivePackage = ArchivePackage(
            data: data,
            metadata: metadata,
            archivedAt: Date(),
            archiveLocation: archiveLocation,
            compressionType: .gzip,
            encryptionKey: generateArchiveKey()
        )
        
        // Store in archive
        try await storage.archive(package: archivePackage)
        
        // Update metadata
        try await storage.updateMetadata(id: id) { metadata in
            metadata.archived = true
            metadata.archiveLocation = archiveLocation
            metadata.archivedAt = Date()
        }
        
        auditLogger.logDataArchival(
            dataId: id,
            location: archiveLocation,
            size: archivePackage.compressedSize
        )
    }
    
    // Private methods
    private func scheduleCleanupTasks() {
        // Daily cleanup at 2 AM
        scheduler.scheduleDailyTask(at: 2) { [weak self] in
            Task {
                try await self?.executeRetentionPolicies()
            }
        }
        
        // Weekly deep cleanup
        scheduler.scheduleWeeklyTask(dayOfWeek: 1, hour: 3) { [weak self] in
            Task {
                try await self?.performDeepCleanup()
            }
        }
    }
    
    private func determineRetentionPeriod(
        for classification: DataClassification,
        dataType: ResearchDataType
    ) -> RetentionPeriod {
        
        // Check policies for matching rules
        for policy in policies {
            if policy.appliesTo(classification: classification, dataType: dataType) {
                return policy.retentionPeriod
            }
        }
        
        // Default retention periods
        switch classification {
        case .public:
            return .days(30)
        case .internal:
            return .days(90)
        case .confidential:
            return .days(180)
        case .restricted:
            return .years(1)
        case .regulatory:
            return .years(7)
        }
    }
    
    private func calculateExpiryDate(
        from date: Date,
        period: RetentionPeriod
    ) -> Date {
        
        switch period {
        case .days(let days):
            return Calendar.current.date(
                byAdding: .day,
                value: days,
                to: date
            ) ?? date
            
        case .months(let months):
            return Calendar.current.date(
                byAdding: .month,
                value: months,
                to: date
            ) ?? date
            
        case .years(let years):
            return Calendar.current.date(
                byAdding: .year,
                value: years,
                to: date
            ) ?? date
            
        case .indefinite:
            return Date.distantFuture
            
        case .custom(let calculator):
            return calculator(date)
        }
    }
    
    private func executePolicy(_ policy: RetentionPolicy) async throws -> PolicyExecutionResult {
        var result = PolicyExecutionResult(
            policyName: policy.name,
            startTime: Date(),
            dataProcessed: 0,
            dataDeleted: 0,
            dataArchived: 0
        )
        
        // Find data matching policy criteria
        let matchingData = try await storage.findData(
            matching: policy.criteria
        )
        
        result.dataProcessed = matchingData.count
        
        for metadata in matchingData {
            // Check if data should be deleted
            if shouldDelete(metadata: metadata, policy: policy) {
                if policy.archiveBeforeDelete {
                    try await archiveData(
                        id: metadata.dataId,
                        archiveLocation: policy.archiveLocation ?? .cloudStorage
                    )
                    result.dataArchived += 1
                }
                
                try await storage.secureDelete(id: metadata.dataId)
                result.dataDeleted += 1
            }
        }
        
        result.endTime = Date()
        return result
    }
    
    private func shouldDelete(
        metadata: RetentionMetadata,
        policy: RetentionPolicy
    ) -> Bool {
        
        // Check expiry
        if metadata.isExpired {
            return true
        }
        
        // Check last access
        if let maxInactiveDays = policy.maxInactiveDays {
            let daysSinceAccess = Calendar.current.dateComponents(
                [.day],
                from: metadata.lastAccessed,
                to: Date()
            ).day ?? 0
            
            if daysSinceAccess > maxInactiveDays {
                return true
            }
        }
        
        // Check access frequency
        if let minAccessCount = policy.minAccessCountToRetain,
           metadata.accessCount < minAccessCount {
            let age = Calendar.current.dateComponents(
                [.day],
                from: metadata.createdAt,
                to: Date()
            ).day ?? 0
            
            if age > 30 { // Grace period
                return true
            }
        }
        
        return false
    }
    
    private func validateDeletionAuthorization(
        metadata: RetentionMetadata,
        reason: DeletionReason,
        authorizedBy: String
    ) throws {
        
        // Check if data is under legal hold
        if metadata.legalHold {
            throw RetentionError.legalHoldActive(metadata.dataId)
        }
        
        // Validate authorization level
        switch metadata.classification {
        case .regulatory:
            guard reason == .regulatoryCompliance || reason == .legalRequest else {
                throw RetentionError.insufficientAuthorization
            }
        case .restricted, .confidential:
            guard authorizedBy.contains("admin") || authorizedBy.contains("security") else {
                throw RetentionError.insufficientAuthorization
            }
        default:
            break
        }
    }
    
    private func performDeepCleanup() async throws {
        // Clean up orphaned data
        let orphanedCount = try await storage.cleanupOrphanedData()
        
        // Compact storage
        let compactionResult = try await storage.compactStorage()
        
        // Clean temporary files
        let tempFilesDeleted = try await storage.cleanupTemporaryFiles(
            olderThan: .days(7)
        )
        
        auditLogger.logDeepCleanup(
            orphanedData: orphanedCount,
            compactionSaved: compactionResult.savedBytes,
            tempFilesDeleted: tempFilesDeleted
        )
    }
    
    private func generateArchiveKey() -> Data {
        var keyData = Data(count: 32)
        _ = keyData.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 32, bytes.baseAddress!)
        }
        return keyData
    }
}

// Retention models
struct RetentionPolicy {
    let name: String
    let description: String
    let criteria: RetentionCriteria
    let retentionPeriod: RetentionPeriod
    let archiveBeforeDelete: Bool
    let archiveLocation: ArchiveLocation?
    let maxInactiveDays: Int?
    let minAccessCountToRetain: Int?
    
    func appliesTo(
        classification: DataClassification,
        dataType: ResearchDataType
    ) -> Bool {
        return criteria.classifications.contains(classification) &&
               criteria.dataTypes.contains(dataType)
    }
    
    static let defaultPolicies: [RetentionPolicy] = [
        RetentionPolicy(
            name: "Public Data Retention",
            description: "Retention policy for public research data",
            criteria: RetentionCriteria(
                classifications: [.public],
                dataTypes: [.searchResults, .webContent]
            ),
            retentionPeriod: .days(30),
            archiveBeforeDelete: false,
            archiveLocation: nil,
            maxInactiveDays: 14,
            minAccessCountToRetain: nil
        ),
        RetentionPolicy(
            name: "Confidential Data Retention",
            description: "Retention policy for confidential research",
            criteria: RetentionCriteria(
                classifications: [.confidential, .restricted],
                dataTypes: [.researchReport, .analysis]
            ),
            retentionPeriod: .days(180),
            archiveBeforeDelete: true,
            archiveLocation: .secureArchive,
            maxInactiveDays: 90,
            minAccessCountToRetain: 2
        ),
        RetentionPolicy(
            name: "Regulatory Compliance",
            description: "Retention for regulatory compliance",
            criteria: RetentionCriteria(
                classifications: [.regulatory],
                dataTypes: ResearchDataType.allCases
            ),
            retentionPeriod: .years(7),
            archiveBeforeDelete: true,
            archiveLocation: .complianceArchive,
            maxInactiveDays: nil,
            minAccessCountToRetain: nil
        )
    ]
}

struct RetentionCriteria {
    let classifications: [DataClassification]
    let dataTypes: [ResearchDataType]
    let tags: [String]?
    let createdBefore: Date?
    let createdAfter: Date?
}

enum RetentionPeriod {
    case days(Int)
    case months(Int)
    case years(Int)
    case indefinite
    case custom((Date) -> Date)
}

struct RetentionMetadata {
    let dataId: String
    let createdAt: Date
    let classification: DataClassification
    let retentionPeriod: RetentionPeriod
    let expiresAt: Date
    var lastAccessed: Date
    var accessCount: Int
    let tags: [String]
    var archived: Bool = false
    var archiveLocation: ArchiveLocation?
    var archivedAt: Date?
    var legalHold: Bool = false
    
    var isExpired: Bool {
        Date() > expiresAt
    }
}

enum DataClassification {
    case `public`
    case `internal`
    case confidential
    case restricted
    case regulatory
}

enum ResearchDataType: CaseIterable {
    case query
    case searchResults
    case webContent
    case researchReport
    case analysis
    case metadata
}

struct ResearchData {
    let id: String
    let type: ResearchDataType
    let content: Data
    let metadata: [String: Any]
    let tags: [String]
    let size: Int
}

enum AccessPurpose {
    case userRequest(userId: String)
    case systemProcess(processName: String)
    case compliance(reason: String)
    case support(ticketId: String)
    
    var userId: String {
        switch self {
        case .userRequest(let userId):
            return userId
        case .systemProcess(let name):
            return "system:\(name)"
        case .compliance(let reason):
            return "compliance:\(reason)"
        case .support(let ticketId):
            return "support:\(ticketId)"
        }
    }
}

enum DeletionReason {
    case expired
    case userRequest
    case dataMinimization
    case regulatoryCompliance
    case legalRequest
    case securityIncident
}

enum ArchiveLocation {
    case cloudStorage
    case secureArchive
    case complianceArchive
    case coldStorage
}

struct ArchivePackage {
    let data: ResearchData
    let metadata: RetentionMetadata
    let archivedAt: Date
    let archiveLocation: ArchiveLocation
    let compressionType: CompressionType
    let encryptionKey: Data
    
    var compressedSize: Int {
        // Calculate compressed size
        return data.size / 3 // Simplified
    }
    
    enum CompressionType {
        case none
        case gzip
        case lz4
        case zstd
    }
}

// Execution results
struct RetentionReport {
    let executionDate: Date
    var policiesExecuted: [PolicyExecutionResult]
    var dataProcessed: Int
    var dataDeleted: Int
    var dataArchived: Int
    var errors: [Error]
}

struct PolicyExecutionResult {
    let policyName: String
    let startTime: Date
    var endTime: Date?
    var dataProcessed: Int
    var dataDeleted: Int
    var dataArchived: Int
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
}

// Storage interface
class SecureDataStorage {
    func encryptAndStore(
        data: ResearchData,
        metadata: RetentionMetadata
    ) async throws -> (id: String, size: Int) {
        // Implementation
        return (data.id, data.size)
    }
    
    func retrieveAndDecrypt(id: String) async throws -> ResearchData {
        // Implementation
        throw RetentionError.dataNotFound(id)
    }
    
    func getMetadata(for id: String) async throws -> RetentionMetadata? {
        // Implementation
        return nil
    }
    
    func updateMetadata(
        id: String,
        update: (inout RetentionMetadata) -> Void
    ) async throws {
        // Implementation
    }
    
    func updateAccessMetadata(
        id: String,
        lastAccessed: Date,
        incrementAccessCount: Bool
    ) async throws {
        // Implementation
    }
    
    func secureDelete(id: String) async throws -> DeletionResult {
        // Implementation with secure overwrite
        return DeletionResult(
            dataId: id,
            deletedAt: Date(),
            verificationHash: "hash"
        )
    }
    
    func findData(
        matching criteria: RetentionCriteria
    ) async throws -> [RetentionMetadata] {
        // Implementation
        return []
    }
    
    func archive(package: ArchivePackage) async throws {
        // Implementation
    }
    
    func cleanupOrphanedData() async throws -> Int {
        // Implementation
        return 0
    }
    
    func compactStorage() async throws -> CompactionResult {
        // Implementation
        return CompactionResult(savedBytes: 0)
    }
    
    func cleanupTemporaryFiles(olderThan period: RetentionPeriod) async throws -> Int {
        // Implementation
        return 0
    }
}

struct DeletionResult {
    let dataId: String
    let deletedAt: Date
    let verificationHash: String
}

struct CompactionResult {
    let savedBytes: Int
}

// Scheduler
class RetentionScheduler {
    private var dailyTasks: [(hour: Int, task: () -> Void)] = []
    private var weeklyTasks: [(day: Int, hour: Int, task: () -> Void)] = []
    
    func scheduleDailyTask(at hour: Int, task: @escaping () -> Void) {
        dailyTasks.append((hour, task))
        // Schedule with system scheduler
    }
    
    func scheduleWeeklyTask(dayOfWeek: Int, hour: Int, task: @escaping () -> Void) {
        weeklyTasks.append((dayOfWeek, hour, task))
        // Schedule with system scheduler
    }
}

// Audit logger
class RetentionAuditLogger {
    func logDataStorage(
        dataId: String,
        classification: DataClassification,
        retentionPeriod: RetentionPeriod,
        size: Int
    ) {
        print("Data stored: \(dataId), Classification: \(classification), Size: \(size)")
    }
    
    func logDataAccess(
        dataId: String,
        purpose: AccessPurpose,
        userId: String
    ) {
        print("Data accessed: \(dataId) by \(userId) for \(purpose)")
    }
    
    func logDataDeletion(
        dataId: String,
        reason: DeletionReason,
        authorizedBy: String,
        metadata: RetentionMetadata,
        result: DeletionResult
    ) {
        print("Data deleted: \(dataId), Reason: \(reason), Authorized by: \(authorizedBy)")
    }
    
    func logDataArchival(
        dataId: String,
        location: ArchiveLocation,
        size: Int
    ) {
        print("Data archived: \(dataId) to \(location), Size: \(size)")
    }
    
    func logRetentionExecution(report: RetentionReport) {
        print("Retention execution: Processed \(report.dataProcessed), Deleted \(report.dataDeleted)")
    }
    
    func logDeepCleanup(
        orphanedData: Int,
        compactionSaved: Int,
        tempFilesDeleted: Int
    ) {
        print("Deep cleanup: Orphaned: \(orphanedData), Saved: \(compactionSaved) bytes")
    }
}

// Errors
enum RetentionError: LocalizedError {
    case dataNotFound(String)
    case dataExpired(String, expiredAt: Date)
    case insufficientAuthorization
    case legalHoldActive(String)
    case policyExecutionFailed(policy: String, error: Error)
    
    var errorDescription: String? {
        switch self {
        case .dataNotFound(let id):
            return "Data not found: \(id)"
        case .dataExpired(let id, let date):
            return "Data expired: \(id) at \(date)"
        case .insufficientAuthorization:
            return "Insufficient authorization for this operation"
        case .legalHoldActive(let id):
            return "Cannot delete data under legal hold: \(id)"
        case .policyExecutionFailed(let policy, let error):
            return "Policy execution failed for \(policy): \(error)"
        }
    }
}

// Example usage
func demonstrateDataRetention() async {
    let retentionManager = DataRetentionManager()
    
    // Store research data
    let researchData = ResearchData(
        id: UUID().uuidString,
        type: .researchReport,
        content: "Research content".data(using: .utf8)!,
        metadata: ["topic": "AI Safety"],
        tags: ["ai", "safety", "research"],
        size: 1024
    )
    
    do {
        // Store with classification
        try await retentionManager.storeResearchData(
            researchData,
            classification: .confidential
        )
        
        print("Research data stored with retention policy")
        
        // Retrieve data
        let retrieved = try await retentionManager.retrieveResearchData(
            id: researchData.id,
            purpose: .userRequest(userId: "user123")
        )
        
        print("Data retrieved successfully")
        
        // Execute retention policies
        let report = try await retentionManager.executeRetentionPolicies()
        
        print("Retention Report:")
        print("Policies executed: \(report.policiesExecuted.count)")
        print("Data processed: \(report.dataProcessed)")
        print("Data deleted: \(report.dataDeleted)")
        print("Data archived: \(report.dataArchived)")
        
        // Manual deletion with authorization
        try await retentionManager.deleteData(
            id: researchData.id,
            reason: .userRequest,
            authorizedBy: "admin@company.com"
        )
        
        print("Data manually deleted")
        
    } catch {
        print("Retention error: \(error)")
    }
}