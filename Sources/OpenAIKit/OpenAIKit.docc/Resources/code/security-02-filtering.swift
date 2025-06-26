import Foundation
import OpenAIKit

// Add content filtering for sensitive data in DeepResearch

class ContentSecurityFilter {
    private let sensitivePatterns: [SensitivePattern]
    private let customFilters: [ContentFilter]
    private let redactionStrategy: RedactionStrategy
    private let auditLogger: AuditLogger
    
    init(
        patterns: [SensitivePattern] = SensitivePattern.defaultPatterns,
        customFilters: [ContentFilter] = [],
        redactionStrategy: RedactionStrategy = .mask,
        auditLogger: AuditLogger = AuditLogger()
    ) {
        self.sensitivePatterns = patterns
        self.customFilters = customFilters
        self.redactionStrategy = redactionStrategy
        self.auditLogger = auditLogger
    }
    
    // Filter content before sending to AI
    func filterOutgoing(
        _ content: String,
        context: FilterContext
    ) throws -> FilterResult {
        var filteredContent = content
        var detections: [Detection] = []
        
        // Apply pattern-based filters
        for pattern in sensitivePatterns {
            let patternDetections = detectPattern(
                pattern: pattern,
                in: filteredContent
            )
            
            for detection in patternDetections {
                filteredContent = applyRedaction(
                    to: filteredContent,
                    detection: detection,
                    strategy: redactionStrategy
                )
                detections.append(detection)
            }
        }
        
        // Apply custom filters
        for filter in customFilters {
            let filterResult = filter.apply(to: filteredContent, context: context)
            filteredContent = filterResult.content
            detections.append(contentsOf: filterResult.detections)
        }
        
        // Log filtering activity
        if !detections.isEmpty {
            auditLogger.logFiltering(
                direction: .outgoing,
                detections: detections,
                context: context
            )
        }
        
        // Check if content is safe to send
        let risk = assessRisk(detections: detections)
        if risk.level == .critical && !context.allowHighRisk {
            throw FilterError.contentBlocked(reason: risk.reason)
        }
        
        return FilterResult(
            originalContent: content,
            filteredContent: filteredContent,
            detections: detections,
            risk: risk,
            metadata: generateMetadata(detections: detections)
        )
    }
    
    // Filter content received from AI
    func filterIncoming(
        _ content: String,
        context: FilterContext
    ) -> FilterResult {
        var filteredContent = content
        var detections: [Detection] = []
        
        // Check for information disclosure
        let disclosurePatterns = [
            SensitivePattern(
                name: "Internal URL",
                regex: try! NSRegularExpression(
                    pattern: "https?://[\\w.-]+\\.internal[\\w./-]*"
                ),
                category: .infrastructure,
                severity: .medium
            ),
            SensitivePattern(
                name: "Private IP",
                regex: try! NSRegularExpression(
                    pattern: "\\b(?:10|172\\.(?:1[6-9]|2[0-9]|3[01])|192\\.168)\\.\\d{1,3}\\.\\d{1,3}\\b"
                ),
                category: .infrastructure,
                severity: .low
            )
        ]
        
        for pattern in disclosurePatterns {
            let patternDetections = detectPattern(
                pattern: pattern,
                in: filteredContent
            )
            
            for detection in patternDetections {
                filteredContent = applyRedaction(
                    to: filteredContent,
                    detection: detection,
                    strategy: .remove
                )
                detections.append(detection)
            }
        }
        
        // Log incoming filtering
        if !detections.isEmpty {
            auditLogger.logFiltering(
                direction: .incoming,
                detections: detections,
                context: context
            )
        }
        
        return FilterResult(
            originalContent: content,
            filteredContent: filteredContent,
            detections: detections,
            risk: assessRisk(detections: detections),
            metadata: generateMetadata(detections: detections)
        )
    }
    
    // Secure research execution with filtering
    func executeSecureResearch(
        query: String,
        deepResearch: DeepResearch,
        context: FilterContext
    ) async throws -> SecureResearchResult {
        
        // Filter outgoing query
        let filteredQuery = try filterOutgoing(query, context: context)
        
        if filteredQuery.risk.level == .high {
            print("Warning: High-risk content detected in query")
        }
        
        // Execute research with filtered query
        let config = DeepResearchConfiguration(
            maxSearchQueries: 5,
            maxWebPages: 10,
            customInstructions: "Do not include any personally identifiable information or sensitive data in responses"
        )
        
        let result = try await deepResearch.research(
            query: filteredQuery.filteredContent,
            configuration: config
        )
        
        // Filter incoming results
        let filteredResult = filterIncoming(result.content, context: context)
        
        // Create secure result
        return SecureResearchResult(
            originalQuery: query,
            filteredQuery: filteredQuery.filteredContent,
            content: filteredResult.filteredContent,
            outgoingDetections: filteredQuery.detections,
            incomingDetections: filteredResult.detections,
            totalRisk: combineRisks(
                outgoing: filteredQuery.risk,
                incoming: filteredResult.risk
            ),
            searchQueries: result.searchQueries,
            auditId: auditLogger.currentSessionId
        )
    }
    
    // Detect sensitive patterns
    private func detectPattern(
        pattern: SensitivePattern,
        in content: String
    ) -> [Detection] {
        let range = NSRange(content.startIndex..., in: content)
        let matches = pattern.regex.matches(in: content, range: range)
        
        return matches.map { match in
            let matchRange = Range(match.range, in: content)!
            let matchedText = String(content[matchRange])
            
            return Detection(
                pattern: pattern,
                matchedText: matchedText,
                range: match.range,
                confidence: pattern.confidence(for: matchedText)
            )
        }
    }
    
    // Apply redaction strategy
    private func applyRedaction(
        to content: String,
        detection: Detection,
        strategy: RedactionStrategy
    ) -> String {
        guard let range = Range(detection.range, in: content) else {
            return content
        }
        
        let redactedValue: String
        
        switch strategy {
        case .mask:
            redactedValue = String(repeating: "*", count: detection.matchedText.count)
        case .partial:
            redactedValue = partialRedaction(detection.matchedText)
        case .replace(let placeholder):
            redactedValue = placeholder
        case .remove:
            redactedValue = ""
        case .tokenize:
            redactedValue = "[REDACTED-\(detection.pattern.category.rawValue.uppercased())-\(UUID().uuidString.prefix(8))]"
        }
        
        return content.replacingCharacters(in: range, with: redactedValue)
    }
    
    // Partial redaction logic
    private func partialRedaction(_ text: String) -> String {
        let length = text.count
        if length <= 4 {
            return String(repeating: "*", count: length)
        }
        
        let visibleCount = min(3, length / 4)
        let prefix = String(text.prefix(visibleCount))
        let suffix = String(text.suffix(visibleCount))
        let maskedCount = length - (visibleCount * 2)
        
        return "\(prefix)\(String(repeating: "*", count: maskedCount))\(suffix)"
    }
    
    // Risk assessment
    private func assessRisk(detections: [Detection]) -> RiskAssessment {
        guard !detections.isEmpty else {
            return RiskAssessment(level: .none, score: 0, reason: "No sensitive data detected")
        }
        
        let maxSeverity = detections.map { $0.pattern.severity }.max() ?? .low
        let categoryCount = Set(detections.map { $0.pattern.category }).count
        let totalDetections = detections.count
        
        let score = calculateRiskScore(
            severity: maxSeverity,
            categoryCount: categoryCount,
            detectionCount: totalDetections
        )
        
        let level: RiskLevel
        let reason: String
        
        switch score {
        case 0..<0.3:
            level = .low
            reason = "Minimal sensitive data detected"
        case 0.3..<0.6:
            level = .medium
            reason = "Moderate sensitive data detected"
        case 0.6..<0.8:
            level = .high
            reason = "Significant sensitive data detected"
        default:
            level = .critical
            reason = "Critical sensitive data detected"
        }
        
        return RiskAssessment(level: level, score: score, reason: reason)
    }
    
    private func calculateRiskScore(
        severity: Severity,
        categoryCount: Int,
        detectionCount: Int
    ) -> Double {
        let severityScore: Double = {
            switch severity {
            case .low: return 0.2
            case .medium: return 0.5
            case .high: return 0.8
            case .critical: return 1.0
            }
        }()
        
        let categoryScore = min(Double(categoryCount) / 5.0, 1.0)
        let detectionScore = min(Double(detectionCount) / 10.0, 1.0)
        
        return (severityScore * 0.5) + (categoryScore * 0.3) + (detectionScore * 0.2)
    }
    
    private func combineRisks(
        outgoing: RiskAssessment,
        incoming: RiskAssessment
    ) -> RiskAssessment {
        let combinedScore = max(outgoing.score, incoming.score)
        let combinedLevel = max(outgoing.level, incoming.level)
        
        return RiskAssessment(
            level: combinedLevel,
            score: combinedScore,
            reason: "Combined risk from outgoing and incoming content"
        )
    }
    
    private func generateMetadata(detections: [Detection]) -> FilterMetadata {
        return FilterMetadata(
            totalDetections: detections.count,
            categoryCounts: Dictionary(
                grouping: detections,
                by: { $0.pattern.category }
            ).mapValues { $0.count },
            severityCounts: Dictionary(
                grouping: detections,
                by: { $0.pattern.severity }
            ).mapValues { $0.count },
            timestamp: Date()
        )
    }
}

// Pattern definitions
struct SensitivePattern {
    let name: String
    let regex: NSRegularExpression
    let category: DataCategory
    let severity: Severity
    let customHandler: ((String) -> String)?
    
    init(
        name: String,
        regex: NSRegularExpression,
        category: DataCategory,
        severity: Severity,
        customHandler: ((String) -> String)? = nil
    ) {
        self.name = name
        self.regex = regex
        self.category = category
        self.severity = severity
        self.customHandler = customHandler
    }
    
    func confidence(for match: String) -> Double {
        // Calculate confidence based on pattern specificity
        switch category {
        case .credentials:
            return match.count > 20 ? 0.95 : 0.8
        case .personal:
            return 0.9
        case .financial:
            return 0.95
        case .medical:
            return 0.9
        case .infrastructure:
            return 0.85
        case .proprietary:
            return 0.8
        }
    }
    
    // Default sensitive patterns
    static let defaultPatterns: [SensitivePattern] = [
        // API Keys and Tokens
        SensitivePattern(
            name: "API Key",
            regex: try! NSRegularExpression(
                pattern: "\\b(?:api[_-]?key|apikey|api[_-]?token)[\\s:=]+['\"]?([\\w-]{20,})\\b",
                options: .caseInsensitive
            ),
            category: .credentials,
            severity: .critical
        ),
        
        // Social Security Numbers
        SensitivePattern(
            name: "SSN",
            regex: try! NSRegularExpression(
                pattern: "\\b\\d{3}-\\d{2}-\\d{4}\\b|\\b\\d{9}\\b"
            ),
            category: .personal,
            severity: .critical
        ),
        
        // Credit Card Numbers
        SensitivePattern(
            name: "Credit Card",
            regex: try! NSRegularExpression(
                pattern: "\\b(?:\\d[ -]*?){13,19}\\b"
            ),
            category: .financial,
            severity: .critical
        ),
        
        // Email Addresses
        SensitivePattern(
            name: "Email",
            regex: try! NSRegularExpression(
                pattern: "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b"
            ),
            category: .personal,
            severity: .medium
        ),
        
        // Phone Numbers
        SensitivePattern(
            name: "Phone",
            regex: try! NSRegularExpression(
                pattern: "\\b(?:\\+?1[-.]?)?\\(?([0-9]{3})\\)?[-.]?([0-9]{3})[-.]?([0-9]{4})\\b"
            ),
            category: .personal,
            severity: .medium
        ),
        
        // AWS Keys
        SensitivePattern(
            name: "AWS Access Key",
            regex: try! NSRegularExpression(
                pattern: "\\b(?:AKIA|ASIA)[A-Z0-9]{16}\\b"
            ),
            category: .credentials,
            severity: .critical
        ),
        
        // Private Keys
        SensitivePattern(
            name: "Private Key",
            regex: try! NSRegularExpression(
                pattern: "-----BEGIN (?:RSA |EC )?PRIVATE KEY-----"
            ),
            category: .credentials,
            severity: .critical
        )
    ]
}

// Custom filter protocol
protocol ContentFilter {
    func apply(to content: String, context: FilterContext) -> (content: String, detections: [Detection])
}

// Example custom filter
struct CompanyDataFilter: ContentFilter {
    let companyNames: Set<String>
    let projectCodes: Set<String>
    
    func apply(to content: String, context: FilterContext) -> (content: String, detections: [Detection]) {
        var filteredContent = content
        var detections: [Detection] = []
        
        // Filter company names
        for company in companyNames {
            if content.contains(company) {
                let pattern = SensitivePattern(
                    name: "Company Name",
                    regex: try! NSRegularExpression(pattern: NSRegularExpression.escapedPattern(for: company)),
                    category: .proprietary,
                    severity: .high
                )
                
                let companyDetections = content.ranges(of: company).map { range in
                    Detection(
                        pattern: pattern,
                        matchedText: company,
                        range: NSRange(range, in: content),
                        confidence: 1.0
                    )
                }
                
                detections.append(contentsOf: companyDetections)
                filteredContent = filteredContent.replacingOccurrences(of: company, with: "[COMPANY]")
            }
        }
        
        return (filteredContent, detections)
    }
}

// Models
struct FilterContext {
    let userId: String
    let sessionId: String
    let purpose: String
    let allowHighRisk: Bool
    let customRules: [String: Any]
}

struct FilterResult {
    let originalContent: String
    let filteredContent: String
    let detections: [Detection]
    let risk: RiskAssessment
    let metadata: FilterMetadata
}

struct Detection {
    let pattern: SensitivePattern
    let matchedText: String
    let range: NSRange
    let confidence: Double
}

struct RiskAssessment {
    let level: RiskLevel
    let score: Double
    let reason: String
}

enum RiskLevel: Comparable {
    case none
    case low
    case medium
    case high
    case critical
}

struct FilterMetadata {
    let totalDetections: Int
    let categoryCounts: [DataCategory: Int]
    let severityCounts: [Severity: Int]
    let timestamp: Date
}

enum DataCategory: String {
    case credentials = "credentials"
    case personal = "personal"
    case financial = "financial"
    case medical = "medical"
    case infrastructure = "infrastructure"
    case proprietary = "proprietary"
}

enum Severity: Comparable {
    case low
    case medium
    case high
    case critical
}

enum RedactionStrategy {
    case mask
    case partial
    case replace(String)
    case remove
    case tokenize
}

struct SecureResearchResult {
    let originalQuery: String
    let filteredQuery: String
    let content: String
    let outgoingDetections: [Detection]
    let incomingDetections: [Detection]
    let totalRisk: RiskAssessment
    let searchQueries: [String]
    let auditId: String
}

// Audit logger
class AuditLogger {
    let currentSessionId = UUID().uuidString
    
    enum Direction {
        case incoming
        case outgoing
    }
    
    func logFiltering(
        direction: Direction,
        detections: [Detection],
        context: FilterContext
    ) {
        let log = FilterAuditLog(
            sessionId: currentSessionId,
            userId: context.userId,
            direction: direction,
            detectionCount: detections.count,
            categories: Set(detections.map { $0.pattern.category }),
            severities: Set(detections.map { $0.pattern.severity }),
            timestamp: Date()
        )
        
        // In production, write to secure audit log
        print("Security Filter Audit: \(log)")
    }
}

struct FilterAuditLog {
    let sessionId: String
    let userId: String
    let direction: AuditLogger.Direction
    let detectionCount: Int
    let categories: Set<DataCategory>
    let severities: Set<Severity>
    let timestamp: Date
}

enum FilterError: LocalizedError {
    case contentBlocked(reason: String)
    case patternError(String)
    
    var errorDescription: String? {
        switch self {
        case .contentBlocked(let reason):
            return "Content blocked: \(reason)"
        case .patternError(let error):
            return "Pattern error: \(error)"
        }
    }
}

// String extension for finding ranges
extension String {
    func ranges(of searchString: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchStartIndex = self.startIndex
        
        while searchStartIndex < self.endIndex,
              let range = self.range(of: searchString, range: searchStartIndex..<self.endIndex),
              !range.isEmpty {
            ranges.append(range)
            searchStartIndex = range.upperBound
        }
        
        return ranges
    }
}

// Example usage
func demonstrateContentFiltering() async {
    let openAI = OpenAI(Configuration(apiKey: "your-api-key"))
    let deepResearch = DeepResearch(client: openAI)
    
    // Create custom filter for company data
    let companyFilter = CompanyDataFilter(
        companyNames: ["Acme Corp", "TechCo Inc"],
        projectCodes: ["PROJ-2024-001", "ALPHA-X"]
    )
    
    let securityFilter = ContentSecurityFilter(
        customFilters: [companyFilter],
        redactionStrategy: .tokenize
    )
    
    let context = FilterContext(
        userId: "user123",
        sessionId: UUID().uuidString,
        purpose: "market_research",
        allowHighRisk: false,
        customRules: [:]
    )
    
    do {
        // Example with sensitive data
        let sensitiveQuery = """
        Research the market position of Acme Corp (API key: sk-proj-1234567890abcdef).
        Contact John Doe at john.doe@acmecorp.com or 555-123-4567.
        Their AWS access key is AKIAIOSFODNN7EXAMPLE.
        """
        
        let result = try await securityFilter.executeSecureResearch(
            query: sensitiveQuery,
            deepResearch: deepResearch,
            context: context
        )
        
        print("Original query length: \(result.originalQuery.count)")
        print("Filtered query length: \(result.filteredQuery.count)")
        print("Outgoing detections: \(result.outgoingDetections.count)")
        print("Incoming detections: \(result.incomingDetections.count)")
        print("Risk level: \(result.totalRisk.level)")
        
        // Show filtered query
        print("\nFiltered query:")
        print(result.filteredQuery)
        
    } catch {
        print("Security filter error: \(error)")
    }
}