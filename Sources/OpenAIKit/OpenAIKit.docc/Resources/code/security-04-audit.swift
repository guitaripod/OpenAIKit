import Foundation
import OpenAIKit
import CryptoKit

// Implement audit logging for research activities

class ResearchAuditLogger {
    private let storage: AuditStorage
    private let encryptor: AuditEncryptor
    private let notifier: AuditNotifier
    private let sessionManager: SessionManager
    
    init(
        storage: AuditStorage = FileAuditStorage(),
        encryptor: AuditEncryptor = AuditEncryptor(),
        notifier: AuditNotifier = AuditNotifier()
    ) {
        self.storage = storage
        self.encryptor = encryptor
        self.notifier = notifier
        self.sessionManager = SessionManager()
    }
    
    // Start audit session
    func startSession(
        userId: String,
        metadata: SessionMetadata
    ) -> AuditSession {
        let session = sessionManager.createSession(
            userId: userId,
            metadata: metadata
        )
        
        let startEvent = AuditEvent(
            id: UUID().uuidString,
            sessionId: session.id,
            timestamp: Date(),
            eventType: .sessionStart,
            userId: userId,
            details: [
                "purpose": metadata.purpose,
                "environment": metadata.environment,
                "clientVersion": metadata.clientVersion
            ],
            severity: .info
        )
        
        logEvent(startEvent)
        return session
    }
    
    // Log research query
    func logResearchQuery(
        session: AuditSession,
        query: String,
        configuration: DeepResearchConfiguration,
        filters: [String: Any] = [:]
    ) {
        
        let queryHash = hashQuery(query)
        
        let event = AuditEvent(
            id: UUID().uuidString,
            sessionId: session.id,
            timestamp: Date(),
            eventType: .researchQuery,
            userId: session.userId,
            details: [
                "queryHash": queryHash,
                "queryLength": query.count,
                "maxSearchQueries": configuration.maxSearchQueries,
                "maxWebPages": configuration.maxWebPages,
                "searchDepth": String(describing: configuration.searchDepth),
                "filters": filters
            ],
            severity: .info
        )
        
        logEvent(event)
    }
    
    // Log research results
    func logResearchResults(
        session: AuditSession,
        queryHash: String,
        resultMetrics: ResultMetrics,
        security: SecurityMetrics
    ) {
        
        let event = AuditEvent(
            id: UUID().uuidString,
            sessionId: session.id,
            timestamp: Date(),
            eventType: .researchResult,
            userId: session.userId,
            details: [
                "queryHash": queryHash,
                "searchQueriesExecuted": resultMetrics.searchQueriesExecuted,
                "webPagesAnalyzed": resultMetrics.webPagesAnalyzed,
                "resultLength": resultMetrics.resultLength,
                "executionTime": resultMetrics.executionTime,
                "sensitiveDataDetected": security.sensitiveDataDetected,
                "filtersApplied": security.filtersApplied
            ],
            severity: security.sensitiveDataDetected > 0 ? .warning : .info
        )
        
        logEvent(event)
    }
    
    // Log security events
    func logSecurityEvent(
        session: AuditSession,
        securityEvent: SecurityEvent
    ) {
        
        let event = AuditEvent(
            id: UUID().uuidString,
            sessionId: session.id,
            timestamp: Date(),
            eventType: .security,
            userId: session.userId,
            details: [
                "securityType": securityEvent.type.rawValue,
                "description": securityEvent.description,
                "affectedData": securityEvent.affectedData ?? "N/A",
                "action": securityEvent.action.rawValue,
                "outcome": securityEvent.outcome.rawValue
            ],
            severity: securityEvent.severity
        )
        
        logEvent(event)
        
        // Notify if high severity
        if securityEvent.severity == .critical || securityEvent.severity == .high {
            notifier.sendSecurityAlert(event: event)
        }
    }
    
    // Log data access
    func logDataAccess(
        session: AuditSession,
        dataAccess: DataAccessEvent
    ) {
        
        let event = AuditEvent(
            id: UUID().uuidString,
            sessionId: session.id,
            timestamp: Date(),
            eventType: .dataAccess,
            userId: session.userId,
            details: [
                "dataSource": dataAccess.dataSource,
                "dataType": dataAccess.dataType,
                "operation": dataAccess.operation.rawValue,
                "recordCount": dataAccess.recordCount ?? 0,
                "success": dataAccess.success
            ],
            severity: .info
        )
        
        logEvent(event)
    }
    
    // Log errors
    func logError(
        session: AuditSession,
        error: Error,
        context: ErrorContext
    ) {
        
        let event = AuditEvent(
            id: UUID().uuidString,
            sessionId: session.id,
            timestamp: Date(),
            eventType: .error,
            userId: session.userId,
            details: [
                "errorType": String(describing: type(of: error)),
                "errorMessage": error.localizedDescription,
                "context": context.description,
                "stackTrace": context.stackTrace ?? "N/A",
                "recoverable": context.recoverable
            ],
            severity: context.recoverable ? .warning : .high
        )
        
        logEvent(event)
    }
    
    // End session
    func endSession(
        _ session: AuditSession,
        summary: SessionSummary
    ) {
        
        let endEvent = AuditEvent(
            id: UUID().uuidString,
            sessionId: session.id,
            timestamp: Date(),
            eventType: .sessionEnd,
            userId: session.userId,
            details: [
                "totalQueries": summary.totalQueries,
                "totalResults": summary.totalResults,
                "totalErrors": summary.totalErrors,
                "duration": summary.duration,
                "successRate": summary.successRate
            ],
            severity: .info
        )
        
        logEvent(endEvent)
        sessionManager.closeSession(session)
    }
    
    // Query audit logs
    func queryLogs(
        criteria: AuditQueryCriteria
    ) async throws -> [AuditEvent] {
        
        let events = try await storage.query(criteria: criteria)
        
        // Log the audit query itself
        let queryEvent = AuditEvent(
            id: UUID().uuidString,
            sessionId: "audit-query",
            timestamp: Date(),
            eventType: .auditQuery,
            userId: criteria.requesterId,
            details: [
                "dateRange": "\(criteria.startDate) to \(criteria.endDate)",
                "eventTypes": criteria.eventTypes?.map { $0.rawValue } ?? ["all"],
                "resultsFound": events.count
            ],
            severity: .info
        )
        
        logEvent(queryEvent)
        
        return events
    }
    
    // Generate audit report
    func generateReport(
        criteria: ReportCriteria
    ) async throws -> AuditReport {
        
        let events = try await queryLogs(
            criteria: AuditQueryCriteria(
                startDate: criteria.startDate,
                endDate: criteria.endDate,
                userId: criteria.userId,
                eventTypes: nil,
                severityLevels: criteria.minimumSeverity != nil ? [criteria.minimumSeverity!] : nil,
                requesterId: criteria.requesterId
            )
        )
        
        let statistics = calculateStatistics(from: events)
        let anomalies = detectAnomalies(in: events)
        let compliance = assessCompliance(events: events, standards: criteria.complianceStandards)
        
        return AuditReport(
            id: UUID().uuidString,
            generatedAt: Date(),
            criteria: criteria,
            events: events,
            statistics: statistics,
            anomalies: anomalies,
            compliance: compliance
        )
    }
    
    // Private methods
    private func logEvent(_ event: AuditEvent) {
        // Encrypt sensitive details
        let encryptedEvent = encryptor.encryptEvent(event)
        
        // Store event
        Task {
            do {
                try await storage.store(event: encryptedEvent)
            } catch {
                print("Failed to store audit event: \(error)")
                // In production, implement fallback logging
            }
        }
        
        // Real-time monitoring
        if event.severity == .critical {
            notifier.sendCriticalAlert(event: event)
        }
    }
    
    private func hashQuery(_ query: String) -> String {
        let data = Data(query.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func calculateStatistics(from events: [AuditEvent]) -> AuditStatistics {
        let totalEvents = events.count
        let eventsByType = Dictionary(grouping: events) { $0.eventType }
        let eventsBySeverity = Dictionary(grouping: events) { $0.severity }
        
        let uniqueUsers = Set(events.map { $0.userId }).count
        let averageSessionDuration = calculateAverageSessionDuration(from: events)
        
        return AuditStatistics(
            totalEvents: totalEvents,
            eventsByType: eventsByType.mapValues { $0.count },
            eventsBySeverity: eventsBySeverity.mapValues { $0.count },
            uniqueUsers: uniqueUsers,
            averageSessionDuration: averageSessionDuration,
            peakHour: findPeakHour(from: events)
        )
    }
    
    private func detectAnomalies(in events: [AuditEvent]) -> [Anomaly] {
        var anomalies: [Anomaly] = []
        
        // Detect unusual query patterns
        let userQueryCounts = Dictionary(grouping: events.filter { $0.eventType == .researchQuery }) { $0.userId }
            .mapValues { $0.count }
        
        let averageQueries = Double(userQueryCounts.values.reduce(0, +)) / Double(userQueryCounts.count)
        
        for (userId, count) in userQueryCounts {
            if Double(count) > averageQueries * 3 {
                anomalies.append(Anomaly(
                    type: .unusualActivity,
                    description: "User \(userId) has excessive queries: \(count)",
                    severity: .medium,
                    timestamp: Date()
                ))
            }
        }
        
        // Detect security anomalies
        let securityEvents = events.filter { $0.eventType == .security }
        if securityEvents.count > 10 {
            anomalies.append(Anomaly(
                type: .securityThreat,
                description: "High number of security events: \(securityEvents.count)",
                severity: .high,
                timestamp: Date()
            ))
        }
        
        return anomalies
    }
    
    private func assessCompliance(
        events: [AuditEvent],
        standards: [ComplianceStandard]
    ) -> ComplianceAssessment {
        
        var results: [ComplianceStandard: Bool] = [:]
        
        for standard in standards {
            switch standard {
            case .gdpr:
                results[standard] = assessGDPRCompliance(events: events)
            case .sox:
                results[standard] = assessSOXCompliance(events: events)
            case .hipaa:
                results[standard] = assessHIPAACompliance(events: events)
            case .pci:
                results[standard] = assessPCICompliance(events: events)
            }
        }
        
        return ComplianceAssessment(
            standards: results,
            overallCompliant: results.values.allSatisfy { $0 },
            recommendations: generateComplianceRecommendations(results: results)
        )
    }
    
    private func assessGDPRCompliance(events: [AuditEvent]) -> Bool {
        // Check for proper data access logging
        let dataAccessEvents = events.filter { $0.eventType == .dataAccess }
        return !dataAccessEvents.isEmpty
    }
    
    private func assessSOXCompliance(events: [AuditEvent]) -> Bool {
        // Check for financial data access controls
        return true // Simplified
    }
    
    private func assessHIPAACompliance(events: [AuditEvent]) -> Bool {
        // Check for medical data protection
        return true // Simplified
    }
    
    private func assessPCICompliance(events: [AuditEvent]) -> Bool {
        // Check for payment data security
        return true // Simplified
    }
    
    private func generateComplianceRecommendations(
        results: [ComplianceStandard: Bool]
    ) -> [String] {
        var recommendations: [String] = []
        
        for (standard, compliant) in results {
            if !compliant {
                recommendations.append("Review \(standard.rawValue) compliance requirements")
            }
        }
        
        return recommendations
    }
    
    private func calculateAverageSessionDuration(from events: [AuditEvent]) -> TimeInterval {
        let sessionStarts = events.filter { $0.eventType == .sessionStart }
        let sessionEnds = events.filter { $0.eventType == .sessionEnd }
        
        var totalDuration: TimeInterval = 0
        var sessionCount = 0
        
        for start in sessionStarts {
            if let end = sessionEnds.first(where: { $0.sessionId == start.sessionId }) {
                totalDuration += end.timestamp.timeIntervalSince(start.timestamp)
                sessionCount += 1
            }
        }
        
        return sessionCount > 0 ? totalDuration / Double(sessionCount) : 0
    }
    
    private func findPeakHour(from events: [AuditEvent]) -> Int {
        let hourCounts = Dictionary(grouping: events) { event in
            Calendar.current.component(.hour, from: event.timestamp)
        }.mapValues { $0.count }
        
        return hourCounts.max(by: { $0.value < $1.value })?.key ?? 0
    }
}

// Audit models
struct AuditEvent {
    let id: String
    let sessionId: String
    let timestamp: Date
    let eventType: EventType
    let userId: String
    let details: [String: Any]
    let severity: Severity
    
    enum EventType: String {
        case sessionStart = "session_start"
        case sessionEnd = "session_end"
        case researchQuery = "research_query"
        case researchResult = "research_result"
        case dataAccess = "data_access"
        case security = "security"
        case error = "error"
        case auditQuery = "audit_query"
    }
}

struct AuditSession {
    let id: String
    let userId: String
    let startTime: Date
    let metadata: SessionMetadata
    var active: Bool = true
}

struct SessionMetadata {
    let purpose: String
    let environment: String
    let clientVersion: String
    let ipAddress: String?
    let userAgent: String?
}

struct SecurityEvent {
    enum SecurityType: String {
        case authenticationFailure = "auth_failure"
        case unauthorizedAccess = "unauthorized_access"
        case dataLeak = "data_leak"
        case suspiciousActivity = "suspicious_activity"
    }
    
    enum Action: String {
        case blocked = "blocked"
        case allowed = "allowed"
        case flagged = "flagged"
    }
    
    enum Outcome: String {
        case prevented = "prevented"
        case detected = "detected"
        case mitigated = "mitigated"
    }
    
    let type: SecurityType
    let description: String
    let affectedData: String?
    let action: Action
    let outcome: Outcome
    let severity: Severity
}

struct DataAccessEvent {
    enum Operation: String {
        case read = "read"
        case write = "write"
        case delete = "delete"
        case modify = "modify"
    }
    
    let dataSource: String
    let dataType: String
    let operation: Operation
    let recordCount: Int?
    let success: Bool
}

struct ErrorContext {
    let description: String
    let stackTrace: String?
    let recoverable: Bool
}

struct ResultMetrics {
    let searchQueriesExecuted: Int
    let webPagesAnalyzed: Int
    let resultLength: Int
    let executionTime: TimeInterval
}

struct SecurityMetrics {
    let sensitiveDataDetected: Int
    let filtersApplied: Int
}

struct SessionSummary {
    let totalQueries: Int
    let totalResults: Int
    let totalErrors: Int
    let duration: TimeInterval
    let successRate: Double
}

// Query and report models
struct AuditQueryCriteria {
    let startDate: Date
    let endDate: Date
    let userId: String?
    let eventTypes: [AuditEvent.EventType]?
    let severityLevels: [Severity]?
    let requesterId: String
}

struct ReportCriteria {
    let startDate: Date
    let endDate: Date
    let userId: String?
    let minimumSeverity: Severity?
    let complianceStandards: [ComplianceStandard]
    let requesterId: String
}

struct AuditReport {
    let id: String
    let generatedAt: Date
    let criteria: ReportCriteria
    let events: [AuditEvent]
    let statistics: AuditStatistics
    let anomalies: [Anomaly]
    let compliance: ComplianceAssessment
}

struct AuditStatistics {
    let totalEvents: Int
    let eventsByType: [AuditEvent.EventType: Int]
    let eventsBySeverity: [Severity: Int]
    let uniqueUsers: Int
    let averageSessionDuration: TimeInterval
    let peakHour: Int
}

struct Anomaly {
    enum AnomalyType {
        case unusualActivity
        case securityThreat
        case performanceIssue
        case dataAnomaly
    }
    
    let type: AnomalyType
    let description: String
    let severity: Severity
    let timestamp: Date
}

struct ComplianceAssessment {
    let standards: [ComplianceStandard: Bool]
    let overallCompliant: Bool
    let recommendations: [String]
}

enum ComplianceStandard: String {
    case gdpr = "GDPR"
    case sox = "SOX"
    case hipaa = "HIPAA"
    case pci = "PCI-DSS"
}

enum Severity: String, Comparable {
    case info = "info"
    case low = "low"
    case medium = "medium"
    case warning = "warning"
    case high = "high"
    case critical = "critical"
    
    static func < (lhs: Severity, rhs: Severity) -> Bool {
        let order: [Severity] = [.info, .low, .medium, .warning, .high, .critical]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

// Supporting classes
class SessionManager {
    private var activeSessions: [String: AuditSession] = [:]
    
    func createSession(userId: String, metadata: SessionMetadata) -> AuditSession {
        let session = AuditSession(
            id: UUID().uuidString,
            userId: userId,
            startTime: Date(),
            metadata: metadata
        )
        activeSessions[session.id] = session
        return session
    }
    
    func closeSession(_ session: AuditSession) {
        activeSessions[session.id]?.active = false
        activeSessions.removeValue(forKey: session.id)
    }
}

class AuditEncryptor {
    private let key = SymmetricKey(size: .bits256)
    
    func encryptEvent(_ event: AuditEvent) -> AuditEvent {
        // In production, encrypt sensitive details
        return event
    }
}

class AuditNotifier {
    func sendSecurityAlert(event: AuditEvent) {
        print("SECURITY ALERT: \(event.details["description"] ?? "Unknown")")
    }
    
    func sendCriticalAlert(event: AuditEvent) {
        print("CRITICAL ALERT: \(event.eventType.rawValue) - \(event.details)")
    }
}

// Storage protocol
protocol AuditStorage {
    func store(event: AuditEvent) async throws
    func query(criteria: AuditQueryCriteria) async throws -> [AuditEvent]
}

// File-based audit storage
class FileAuditStorage: AuditStorage {
    private let auditDirectory: URL
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.auditDirectory = documentsPath.appendingPathComponent("audit_logs")
        
        try? FileManager.default.createDirectory(at: auditDirectory, withIntermediateDirectories: true)
    }
    
    func store(event: AuditEvent) async throws {
        let fileName = "\(event.timestamp.timeIntervalSince1970)_\(event.id).json"
        let fileURL = auditDirectory.appendingPathComponent(fileName)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        // Convert details dictionary to encodable format
        let encodableEvent = EncodableAuditEvent(from: event)
        let data = try encoder.encode(encodableEvent)
        
        try data.write(to: fileURL)
    }
    
    func query(criteria: AuditQueryCriteria) async throws -> [AuditEvent] {
        // Simplified query implementation
        return []
    }
}

// Encodable wrapper for AuditEvent
struct EncodableAuditEvent: Codable {
    let id: String
    let sessionId: String
    let timestamp: Date
    let eventType: String
    let userId: String
    let details: String // JSON string
    let severity: String
    
    init(from event: AuditEvent) {
        self.id = event.id
        self.sessionId = event.sessionId
        self.timestamp = event.timestamp
        self.eventType = event.eventType.rawValue
        self.userId = event.userId
        self.details = (try? JSONSerialization.data(withJSONObject: event.details)
            .base64EncodedString()) ?? "{}"
        self.severity = event.severity.rawValue
    }
}

// Example usage
func demonstrateAuditLogging() async {
    let auditLogger = ResearchAuditLogger()
    
    // Start session
    let metadata = SessionMetadata(
        purpose: "market_research",
        environment: "production",
        clientVersion: "1.0.0",
        ipAddress: "192.168.1.100",
        userAgent: "OpenAIKit/1.0"
    )
    
    let session = auditLogger.startSession(
        userId: "user123",
        metadata: metadata
    )
    
    // Log research query
    let query = "What are the latest trends in renewable energy?"
    let config = DeepResearchConfiguration(
        maxSearchQueries: 5,
        maxWebPages: 10
    )
    
    auditLogger.logResearchQuery(
        session: session,
        query: query,
        configuration: config,
        filters: ["region": "North America", "timeframe": "2024"]
    )
    
    // Log results
    let resultMetrics = ResultMetrics(
        searchQueriesExecuted: 5,
        webPagesAnalyzed: 8,
        resultLength: 2500,
        executionTime: 15.5
    )
    
    let securityMetrics = SecurityMetrics(
        sensitiveDataDetected: 0,
        filtersApplied: 2
    )
    
    auditLogger.logResearchResults(
        session: session,
        queryHash: "abc123",
        resultMetrics: resultMetrics,
        security: securityMetrics
    )
    
    // Log security event
    let securityEvent = SecurityEvent(
        type: .suspiciousActivity,
        description: "Unusual query pattern detected",
        affectedData: nil,
        action: .flagged,
        outcome: .detected,
        severity: .medium
    )
    
    auditLogger.logSecurityEvent(
        session: session,
        securityEvent: securityEvent
    )
    
    // End session
    let summary = SessionSummary(
        totalQueries: 1,
        totalResults: 1,
        totalErrors: 0,
        duration: 20.0,
        successRate: 1.0
    )
    
    auditLogger.endSession(session, summary: summary)
    
    // Generate report
    do {
        let report = try await auditLogger.generateReport(
            criteria: ReportCriteria(
                startDate: Date().addingTimeInterval(-86400),
                endDate: Date(),
                userId: "user123",
                minimumSeverity: .info,
                complianceStandards: [.gdpr, .sox],
                requesterId: "admin"
            )
        )
        
        print("Audit Report Generated:")
        print("Total events: \(report.statistics.totalEvents)")
        print("Unique users: \(report.statistics.uniqueUsers)")
        print("Compliance: \(report.compliance.overallCompliant ? "Compliant" : "Non-compliant")")
        print("Anomalies detected: \(report.anomalies.count)")
        
    } catch {
        print("Failed to generate report: \(error)")
    }
}