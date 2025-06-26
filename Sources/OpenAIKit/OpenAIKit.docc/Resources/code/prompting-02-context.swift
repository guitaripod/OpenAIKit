import Foundation
import OpenAIKit

// Add context and constraints to research requests

class ContextualResearchBuilder {
    private let openAI: OpenAI
    private let deepResearch: DeepResearch
    
    init(apiKey: String) {
        self.openAI = OpenAI(Configuration(apiKey: apiKey))
        self.deepResearch = DeepResearch(client: openAI)
    }
    
    // Build research query with rich context
    func buildContextualQuery(
        baseQuery: String,
        context: ResearchContext,
        constraints: ResearchConstraints
    ) -> ContextualQuery {
        
        var enhancedQuery = ""
        
        // Add background context
        if let background = context.background {
            enhancedQuery += "Background Context:\n\(background)\n\n"
        }
        
        // Add domain expertise level
        enhancedQuery += "Target Audience: \(context.expertiseLevel.description)\n\n"
        
        // Add the main query
        enhancedQuery += "Research Question:\n\(baseQuery)\n\n"
        
        // Add specific requirements
        if !context.specificRequirements.isEmpty {
            enhancedQuery += "Specific Requirements:\n"
            for requirement in context.specificRequirements {
                enhancedQuery += "• \(requirement)\n"
            }
            enhancedQuery += "\n"
        }
        
        // Add constraints
        enhancedQuery += constraints.toPromptSection()
        
        // Add output preferences
        if let preferences = context.outputPreferences {
            enhancedQuery += preferences.toPromptSection()
        }
        
        return ContextualQuery(
            query: enhancedQuery,
            context: context,
            constraints: constraints
        )
    }
    
    // Execute contextual research with automatic constraint enforcement
    func executeContextualResearch(
        query: String,
        context: ResearchContext,
        constraints: ResearchConstraints
    ) async throws -> ContextualResearchResult {
        
        let contextualQuery = buildContextualQuery(
            baseQuery: query,
            context: context,
            constraints: constraints
        )
        
        // Configure DeepResearch based on constraints
        let config = buildConfiguration(from: constraints)
        
        // Execute research
        let startTime = Date()
        let result = try await deepResearch.research(
            query: contextualQuery.query,
            configuration: config
        )
        let endTime = Date()
        
        // Post-process results based on context
        let processedContent = try await postProcessResults(
            content: result.content,
            context: context,
            constraints: constraints
        )
        
        // Validate results against constraints
        let validation = validateResults(
            content: processedContent,
            constraints: constraints
        )
        
        return ContextualResearchResult(
            originalQuery: query,
            enhancedQuery: contextualQuery.query,
            content: processedContent,
            context: context,
            constraints: constraints,
            validation: validation,
            executionTime: endTime.timeIntervalSince(startTime),
            searchQueries: result.searchQueries,
            searchResults: result.searchResults
        )
    }
    
    // Build configuration from constraints
    private func buildConfiguration(from constraints: ResearchConstraints) -> DeepResearchConfiguration {
        return DeepResearchConfiguration(
            maxSearchQueries: constraints.scope == .narrow ? 3 : 10,
            maxWebPages: constraints.scope == .narrow ? 5 : 20,
            searchDepth: constraints.scope == .comprehensive ? .comprehensive : .standard,
            includeImages: false,
            customInstructions: buildCustomInstructions(from: constraints)
        )
    }
    
    // Build custom instructions from constraints
    private func buildCustomInstructions(from constraints: ResearchConstraints) -> String {
        var instructions = ""
        
        if constraints.requirePeerReview {
            instructions += "Prioritize peer-reviewed and academic sources. "
        }
        
        if let minYear = constraints.publicationYearMin {
            instructions += "Focus on sources from \(minYear) or later. "
        }
        
        if !constraints.excludeSources.isEmpty {
            instructions += "Exclude these sources: \(constraints.excludeSources.joined(separator: ", ")). "
        }
        
        if constraints.factCheckingLevel == .strict {
            instructions += "Apply strict fact-checking and verify all claims with multiple sources. "
        }
        
        return instructions
    }
    
    // Post-process results based on context
    private func postProcessResults(
        content: String,
        context: ResearchContext,
        constraints: ResearchConstraints
    ) async throws -> String {
        
        let processingPrompt = """
        Original Research Results:
        \(content)
        
        Please process these results according to:
        - Expertise Level: \(context.expertiseLevel.description)
        - Bias Mitigation: \(constraints.biasMitigation ? "Required" : "Not required")
        - Fact Checking: \(constraints.factCheckingLevel.rawValue)
        
        Additional Processing Requirements:
        \(context.specificRequirements.joined(separator: "\n"))
        
        Reformat the content appropriately for the target audience while maintaining accuracy.
        """
        
        let messages: [ChatMessage] = [
            ChatMessage(role: .system, content: "You are a research editor who adapts content for specific audiences."),
            ChatMessage(role: .user, content: processingPrompt)
        ]
        
        let request = ChatCompletionRequest(
            model: .gpt4,
            messages: messages,
            temperature: 0.3,
            maxTokens: 3000
        )
        
        let response = try await openAI.chats.create(request)
        return response.choices.first?.message.content ?? content
    }
    
    // Validate results against constraints
    private func validateResults(
        content: String,
        constraints: ResearchConstraints
    ) -> ValidationResult {
        
        var issues: [String] = []
        var warnings: [String] = []
        
        // Check for excluded sources
        for source in constraints.excludeSources {
            if content.lowercased().contains(source.lowercased()) {
                warnings.append("Content may reference excluded source: \(source)")
            }
        }
        
        // Check for required elements
        for element in constraints.requiredElements {
            if !content.lowercased().contains(element.lowercased()) {
                issues.append("Missing required element: \(element)")
            }
        }
        
        // Estimate recency
        let currentYear = Calendar.current.component(.year, from: Date())
        if let minYear = constraints.publicationYearMin {
            let yearRange = minYear...currentYear
            var foundRecentSource = false
            for year in yearRange {
                if content.contains(String(year)) {
                    foundRecentSource = true
                    break
                }
            }
            if !foundRecentSource {
                warnings.append("No explicit references to sources from \(minYear) or later")
            }
        }
        
        return ValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            warnings: warnings,
            confidence: issues.isEmpty ? (warnings.isEmpty ? 1.0 : 0.8) : 0.5
        )
    }
}

// Context models
struct ResearchContext {
    let background: String?
    let expertiseLevel: ExpertiseLevel
    let specificRequirements: [String]
    let outputPreferences: OutputPreferences?
    let previousResearch: [String]?
    
    static func academic(field: String, requirements: [String] = []) -> ResearchContext {
        return ResearchContext(
            background: "Academic research in \(field)",
            expertiseLevel: .expert,
            specificRequirements: requirements + [
                "Include academic citations",
                "Use technical terminology",
                "Provide methodological details"
            ],
            outputPreferences: OutputPreferences(
                citationStyle: .academic,
                includeMethodology: true,
                includeLimitations: true
            ),
            previousResearch: nil
        )
    }
    
    static func business(industry: String, requirements: [String] = []) -> ResearchContext {
        return ResearchContext(
            background: "Business analysis for \(industry) industry",
            expertiseLevel: .professional,
            specificRequirements: requirements + [
                "Focus on practical applications",
                "Include market data",
                "Provide actionable insights"
            ],
            outputPreferences: OutputPreferences(
                citationStyle: .simple,
                includeMethodology: false,
                includeLimitations: false
            ),
            previousResearch: nil
        )
    }
}

enum ExpertiseLevel {
    case beginner
    case intermediate
    case professional
    case expert
    
    var description: String {
        switch self {
        case .beginner:
            return "General audience with basic knowledge"
        case .intermediate:
            return "Some domain knowledge assumed"
        case .professional:
            return "Professional practitioners in the field"
        case .expert:
            return "Domain experts and researchers"
        }
    }
}

// Constraint models
struct ResearchConstraints {
    let scope: ResearchScope
    let requirePeerReview: Bool
    let publicationYearMin: Int?
    let excludeSources: [String]
    let requiredElements: [String]
    let geographicFocus: String?
    let languageRestriction: String?
    let biasMitigation: Bool
    let factCheckingLevel: FactCheckingLevel
    
    func toPromptSection() -> String {
        var section = "Research Constraints:\n"
        
        section += "- Scope: \(scope.rawValue)\n"
        
        if requirePeerReview {
            section += "- Require peer-reviewed sources\n"
        }
        
        if let yearMin = publicationYearMin {
            section += "- Sources from \(yearMin) or later\n"
        }
        
        if !excludeSources.isEmpty {
            section += "- Exclude: \(excludeSources.joined(separator: ", "))\n"
        }
        
        if !requiredElements.isEmpty {
            section += "- Must include: \(requiredElements.joined(separator: ", "))\n"
        }
        
        if let geo = geographicFocus {
            section += "- Geographic focus: \(geo)\n"
        }
        
        if let lang = languageRestriction {
            section += "- Language: \(lang)\n"
        }
        
        if biasMitigation {
            section += "- Apply bias mitigation techniques\n"
        }
        
        section += "- Fact-checking level: \(factCheckingLevel.rawValue)\n\n"
        
        return section
    }
}

enum ResearchScope: String {
    case narrow = "Narrow - Focus on specific aspects"
    case standard = "Standard - Balanced coverage"
    case comprehensive = "Comprehensive - Exhaustive research"
}

enum FactCheckingLevel: String {
    case basic = "Basic"
    case standard = "Standard"
    case strict = "Strict"
}

// Output preference models
struct OutputPreferences {
    let citationStyle: CitationStyle
    let includeMethodology: Bool
    let includeLimitations: Bool
    let visualPreference: VisualPreference?
    let summaryLength: SummaryLength?
    
    func toPromptSection() -> String {
        var section = "Output Preferences:\n"
        
        section += "- Citation style: \(citationStyle.rawValue)\n"
        
        if includeMethodology {
            section += "- Include research methodology\n"
        }
        
        if includeLimitations {
            section += "- Include limitations and caveats\n"
        }
        
        if let visual = visualPreference {
            section += "- Visual preference: \(visual.rawValue)\n"
        }
        
        if let length = summaryLength {
            section += "- Summary length: \(length.rawValue)\n"
        }
        
        section += "\n"
        return section
    }
}

enum CitationStyle: String {
    case none = "No citations"
    case simple = "Simple inline references"
    case academic = "Full academic citations"
    case footnotes = "Footnote style"
}

enum VisualPreference: String {
    case none = "Text only"
    case minimal = "Minimal visuals"
    case rich = "Rich visuals and diagrams"
}

enum SummaryLength: String {
    case brief = "Brief (under 500 words)"
    case standard = "Standard (500-1500 words)"
    case detailed = "Detailed (1500+ words)"
}

// Result models
struct ContextualQuery {
    let query: String
    let context: ResearchContext
    let constraints: ResearchConstraints
}

struct ContextualResearchResult {
    let originalQuery: String
    let enhancedQuery: String
    let content: String
    let context: ResearchContext
    let constraints: ResearchConstraints
    let validation: ValidationResult
    let executionTime: TimeInterval
    let searchQueries: [String]
    let searchResults: [SearchResult]
}

struct ValidationResult {
    let isValid: Bool
    let issues: [String]
    let warnings: [String]
    let confidence: Double
}

// Example usage
func demonstrateContextualResearch() async {
    let builder = ContextualResearchBuilder(apiKey: "your-api-key")
    
    // Academic context example
    let academicContext = ResearchContext.academic(
        field: "Machine Learning",
        requirements: [
            "Focus on transformer architectures",
            "Include recent breakthroughs",
            "Compare different approaches"
        ]
    )
    
    let academicConstraints = ResearchConstraints(
        scope: .comprehensive,
        requirePeerReview: true,
        publicationYearMin: 2020,
        excludeSources: ["blogs", "social media"],
        requiredElements: ["methodology", "results", "evaluation"],
        geographicFocus: nil,
        languageRestriction: "English",
        biasMitigation: true,
        factCheckingLevel: .strict
    )
    
    // Business context example
    let businessContext = ResearchContext.business(
        industry: "FinTech",
        requirements: [
            "Market size and growth",
            "Competitive landscape",
            "Regulatory considerations"
        ]
    )
    
    let businessConstraints = ResearchConstraints(
        scope: .standard,
        requirePeerReview: false,
        publicationYearMin: 2022,
        excludeSources: ["competitors' marketing materials"],
        requiredElements: ["market data", "trends", "opportunities"],
        geographicFocus: "North America",
        languageRestriction: nil,
        biasMitigation: true,
        factCheckingLevel: .standard
    )
    
    do {
        // Execute academic research
        let academicResult = try await builder.executeContextualResearch(
            query: "What are the latest advances in attention mechanisms for large language models?",
            context: academicContext,
            constraints: academicConstraints
        )
        
        print("Academic Research Result:")
        print("Validation: \(academicResult.validation.isValid ? "Passed" : "Failed")")
        print("Execution time: \(academicResult.executionTime)s")
        print("Confidence: \(academicResult.validation.confidence)")
        
        if !academicResult.validation.issues.isEmpty {
            print("Issues: \(academicResult.validation.issues)")
        }
        
        // Execute business research
        let businessResult = try await builder.executeContextualResearch(
            query: "What are the emerging opportunities in embedded finance?",
            context: businessContext,
            constraints: businessConstraints
        )
        
        print("\nBusiness Research Result:")
        print("Validation: \(businessResult.validation.isValid ? "Passed" : "Failed")")
        print("Search queries used: \(businessResult.searchQueries.count)")
        
    } catch {
        print("Contextual research error: \(error)")
    }
}