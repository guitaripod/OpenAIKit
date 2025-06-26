import Foundation
import OpenAIKit

// Structure research queries effectively for DeepResearch

class ResearchQueryBuilder {
    // Build structured research queries with clear objectives
    static func buildStructuredQuery(
        topic: String,
        objectives: [String],
        constraints: QueryConstraints? = nil,
        outputFormat: OutputFormat = .detailed
    ) -> String {
        
        var query = ""
        
        // 1. Clear topic statement
        query += "Research Topic: \(topic)\n\n"
        
        // 2. Specific objectives
        if !objectives.isEmpty {
            query += "Research Objectives:\n"
            for (index, objective) in objectives.enumerated() {
                query += "\(index + 1). \(objective)\n"
            }
            query += "\n"
        }
        
        // 3. Apply constraints
        if let constraints = constraints {
            query += constraints.toQuerySection()
        }
        
        // 4. Output format instructions
        query += outputFormat.instructions
        
        return query
    }
    
    // Build comparative research queries
    static func buildComparativeQuery(
        subjects: [String],
        criteria: [String],
        context: String? = nil
    ) -> String {
        
        var query = "Comparative Analysis Request:\n\n"
        
        // Subjects to compare
        query += "Compare the following:\n"
        for subject in subjects {
            query += "- \(subject)\n"
        }
        query += "\n"
        
        // Comparison criteria
        query += "Evaluation Criteria:\n"
        for criterion in criteria {
            query += "• \(criterion)\n"
        }
        query += "\n"
        
        // Additional context
        if let context = context {
            query += "Context: \(context)\n\n"
        }
        
        // Structured output request
        query += """
        Please provide:
        1. A comparison matrix showing how each subject performs on each criterion
        2. Key differences and similarities
        3. Recommendations based on the analysis
        4. Supporting evidence for each comparison point
        """
        
        return query
    }
    
    // Build temporal research queries
    static func buildTemporalQuery(
        topic: String,
        timeframe: TimeFrame,
        focusAreas: [String] = []
    ) -> String {
        
        var query = "Historical/Temporal Research:\n\n"
        query += "Topic: \(topic)\n"
        query += "Timeframe: \(timeframe.description)\n\n"
        
        if !focusAreas.isEmpty {
            query += "Focus Areas:\n"
            for area in focusAreas {
                query += "- \(area)\n"
            }
            query += "\n"
        }
        
        query += """
        Please research and provide:
        1. Timeline of key events and developments
        2. Evolution and changes over the specified period
        3. Significant milestones and turning points
        4. Current state and future projections
        5. Relevant statistics and data points for each time period
        """
        
        return query
    }
    
    // Build causal analysis queries
    static func buildCausalAnalysisQuery(
        phenomenon: String,
        potentialCauses: [String] = [],
        potentialEffects: [String] = []
    ) -> String {
        
        var query = "Causal Analysis Research:\n\n"
        query += "Phenomenon: \(phenomenon)\n\n"
        
        if !potentialCauses.isEmpty {
            query += "Investigate these potential causes:\n"
            for cause in potentialCauses {
                query += "- \(cause)\n"
            }
            query += "\n"
        }
        
        if !potentialEffects.isEmpty {
            query += "Investigate these potential effects:\n"
            for effect in potentialEffects {
                query += "- \(effect)\n"
            }
            query += "\n"
        }
        
        query += """
        Research Requirements:
        1. Identify and validate causal relationships
        2. Provide evidence supporting each causal link
        3. Consider alternative explanations
        4. Assess the strength of each causal relationship
        5. Include relevant case studies or examples
        """
        
        return query
    }
}

// Query constraints model
struct QueryConstraints {
    let geographic: String?
    let temporal: String?
    let sources: [SourceType]?
    let excludeTerms: [String]?
    let requireTerms: [String]?
    let minSourceDate: Date?
    let languagePreference: String?
    
    func toQuerySection() -> String {
        var section = "Research Constraints:\n"
        
        if let geographic = geographic {
            section += "- Geographic scope: \(geographic)\n"
        }
        
        if let temporal = temporal {
            section += "- Time period: \(temporal)\n"
        }
        
        if let sources = sources, !sources.isEmpty {
            section += "- Preferred sources: \(sources.map { $0.rawValue }.joined(separator: ", "))\n"
        }
        
        if let excludeTerms = excludeTerms, !excludeTerms.isEmpty {
            section += "- Exclude: \(excludeTerms.joined(separator: ", "))\n"
        }
        
        if let requireTerms = requireTerms, !requireTerms.isEmpty {
            section += "- Must include: \(requireTerms.joined(separator: ", "))\n"
        }
        
        if let minDate = minSourceDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            section += "- Sources from: \(formatter.string(from: minDate)) or later\n"
        }
        
        if let language = languagePreference {
            section += "- Language preference: \(language)\n"
        }
        
        section += "\n"
        return section
    }
}

// Source type enumeration
enum SourceType: String {
    case academic = "Academic papers"
    case news = "News articles"
    case government = "Government sources"
    case industry = "Industry reports"
    case social = "Social media"
    case technical = "Technical documentation"
    case financial = "Financial reports"
}

// Output format enumeration
enum OutputFormat {
    case brief
    case detailed
    case executive
    case technical
    case academic
    
    var instructions: String {
        switch self {
        case .brief:
            return """
            Output Format: Brief Summary
            - Provide key findings in bullet points
            - Maximum 500 words
            - Include only essential information
            
            """
        case .detailed:
            return """
            Output Format: Detailed Report
            - Comprehensive analysis with sections
            - Include methodology and sources
            - Provide evidence for all claims
            - Add relevant statistics and data
            
            """
        case .executive:
            return """
            Output Format: Executive Summary
            - Start with key takeaways
            - Business implications
            - Actionable recommendations
            - Risk assessment
            - Keep language accessible
            
            """
        case .technical:
            return """
            Output Format: Technical Analysis
            - Include technical specifications
            - Detailed methodology
            - Data tables and metrics
            - Technical terminology acceptable
            - Code examples if relevant
            
            """
        case .academic:
            return """
            Output Format: Academic Style
            - Include literature review
            - Proper citations
            - Methodology section
            - Critical analysis
            - Limitations and future research
            
            """
        }
    }
}

// Time frame model
struct TimeFrame {
    let start: Date?
    let end: Date?
    let relative: RelativeTimeFrame?
    
    var description: String {
        if let relative = relative {
            return relative.description
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        if let start = start, let end = end {
            return "\(formatter.string(from: start)) to \(formatter.string(from: end))"
        } else if let start = start {
            return "From \(formatter.string(from: start)) onwards"
        } else if let end = end {
            return "Up to \(formatter.string(from: end))"
        } else {
            return "All time periods"
        }
    }
}

enum RelativeTimeFrame {
    case lastDays(Int)
    case lastMonths(Int)
    case lastYears(Int)
    case yearToDate
    case lastQuarter
    case custom(String)
    
    var description: String {
        switch self {
        case .lastDays(let days):
            return "Last \(days) days"
        case .lastMonths(let months):
            return "Last \(months) months"
        case .lastYears(let years):
            return "Last \(years) years"
        case .yearToDate:
            return "Year to date"
        case .lastQuarter:
            return "Last quarter"
        case .custom(let description):
            return description
        }
    }
}

// Example structured query usage
func demonstrateStructuredQueries() async {
    let openAI = OpenAI(Configuration(apiKey: "your-api-key"))
    let deepResearch = DeepResearch(client: openAI)
    
    // Example 1: Structured market research
    let marketQuery = ResearchQueryBuilder.buildStructuredQuery(
        topic: "Electric Vehicle Market Analysis",
        objectives: [
            "Current market size and growth projections",
            "Key players and market share",
            "Technological trends and innovations",
            "Regulatory landscape and incentives",
            "Consumer adoption barriers"
        ],
        constraints: QueryConstraints(
            geographic: "North America and Europe",
            temporal: "2020-2024",
            sources: [.industry, .government, .financial],
            excludeTerms: ["rumors", "speculation"],
            requireTerms: ["data", "statistics", "forecast"],
            minSourceDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()),
            languagePreference: "English"
        ),
        outputFormat: .executive
    )
    
    // Example 2: Comparative analysis
    let comparativeQuery = ResearchQueryBuilder.buildComparativeQuery(
        subjects: ["AWS", "Google Cloud", "Microsoft Azure"],
        criteria: [
            "Market share and revenue",
            "Service offerings and capabilities",
            "Pricing models",
            "Global infrastructure",
            "Developer ecosystem",
            "Enterprise adoption"
        ],
        context: "Focus on enterprise cloud computing services"
    )
    
    // Example 3: Historical research
    let historicalQuery = ResearchQueryBuilder.buildTemporalQuery(
        topic: "Evolution of AI in Healthcare",
        timeframe: TimeFrame(
            start: Calendar.current.date(from: DateComponents(year: 2010)),
            end: Date(),
            relative: nil
        ),
        focusAreas: [
            "Diagnostic applications",
            "Drug discovery",
            "Patient care automation",
            "Regulatory approvals",
            "Clinical outcomes"
        ]
    )
    
    // Example 4: Causal analysis
    let causalQuery = ResearchQueryBuilder.buildCausalAnalysisQuery(
        phenomenon: "Remote work adoption surge in 2020-2024",
        potentialCauses: [
            "COVID-19 pandemic",
            "Technology advancement",
            "Cost reduction pressures",
            "Employee preference shifts",
            "Environmental concerns"
        ],
        potentialEffects: [
            "Commercial real estate impact",
            "Urban vs suburban migration",
            "Productivity changes",
            "Work-life balance",
            "Company culture evolution"
        ]
    )
    
    // Execute research with structured query
    do {
        let config = DeepResearchConfiguration(
            searchDepth: .comprehensive,
            maxSearchQueries: 10,
            maxWebPages: 20
        )
        
        let result = try await deepResearch.research(
            query: marketQuery,
            configuration: config
        )
        
        print("Research completed successfully")
        print("Content length: \(result.content.count) characters")
    } catch {
        print("Research error: \(error)")
    }
}