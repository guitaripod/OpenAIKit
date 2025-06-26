// ResearchPrompting.swift
import Foundation
import OpenAIKit

/// Best practices for effective research prompting with DeepResearch
class ResearchPromptingBestPractices {
    let openAI = OpenAIManager.shared.client
    
    /// Structure for well-formed research queries
    struct ResearchQueryStructure {
        let topic: String
        let objective: ResearchObjective
        let scope: ResearchScope
        let constraints: [Constraint]
        let outputFormat: OutputFormat
        
        enum ResearchObjective {
            case exploratory           // Broad overview
            case comparative          // Compare options
            case analytical           // Deep analysis
            case problemSolving       // Find solutions
            case predictive          // Future trends
            case evaluative          // Assess effectiveness
        }
        
        struct ResearchScope {
            let timeframe: String?
            let geography: String?
            let industries: [String]?
            let stakeholders: [String]?
            let depth: ResearchDepth
        }
        
        struct Constraint {
            let type: ConstraintType
            let value: String
            
            enum ConstraintType {
                case exclude
                case mustInclude
                case dataSource
                case methodology
                case budget
                case compliance
            }
        }
        
        enum OutputFormat {
            case executiveSummary
            case detailedReport
            case dataTable
            case presentation
            case actionPlan
            case custom(String)
        }
    }
    
    /// Templates for different research types
    enum ResearchTemplate {
        case marketAnalysis
        case competitiveIntelligence
        case technologyAssessment
        case riskAnalysis
        case trendForecast
        case academicReview
        case policyAnalysis
        
        var systemPrompt: String {
            switch self {
            case .marketAnalysis:
                return """
                You are a market research analyst specializing in comprehensive market analysis.
                Focus on data-driven insights, market dynamics, and actionable recommendations.
                Always cite sources and provide confidence levels for predictions.
                """
                
            case .competitiveIntelligence:
                return """
                You are a competitive intelligence specialist.
                Analyze competitors objectively, identify strategic advantages, and uncover market opportunities.
                Maintain ethical standards and use only publicly available information.
                """
                
            case .technologyAssessment:
                return """
                You are a technology assessment expert.
                Evaluate technologies based on maturity, adoption potential, risks, and business impact.
                Consider both technical and business perspectives.
                """
                
            case .riskAnalysis:
                return """
                You are a risk analysis specialist.
                Identify, assess, and prioritize risks systematically.
                Provide mitigation strategies and contingency plans.
                """
                
            case .trendForecast:
                return """
                You are a trends forecasting analyst.
                Identify emerging patterns, analyze drivers of change, and project future scenarios.
                Base predictions on data and clearly state assumptions.
                """
                
            case .academicReview:
                return """
                You are an academic researcher conducting systematic reviews.
                Follow academic standards for literature review, critical analysis, and citation.
                Maintain objectivity and acknowledge limitations.
                """
                
            case .policyAnalysis:
                return """
                You are a policy analyst.
                Evaluate policies based on effectiveness, efficiency, equity, and feasibility.
                Consider multiple stakeholder perspectives and unintended consequences.
                """
            }
        }
        
        func structurePrompt(for topic: String) -> String {
            switch self {
            case .marketAnalysis:
                return """
                Conduct a comprehensive market analysis for: \(topic)
                
                Structure your analysis as follows:
                1. Market Overview
                   - Current market size and growth rate
                   - Key market segments
                   - Geographic distribution
                
                2. Market Dynamics
                   - Drivers and restraints
                   - Opportunities and threats
                   - Porter's Five Forces analysis
                
                3. Competitive Landscape
                   - Major players and market share
                   - Competitive strategies
                   - Recent M&A activity
                
                4. Customer Analysis
                   - Target segments
                   - Buying behavior
                   - Unmet needs
                
                5. Future Outlook
                   - Growth projections
                   - Emerging trends
                   - Potential disruptions
                
                6. Strategic Recommendations
                   - Market entry strategies
                   - Positioning recommendations
                   - Risk mitigation
                """
                
            default:
                return "Research: \(topic)"
            }
        }
    }
    
    /// Structure research queries effectively
    func structureResearchQuery(
        structure: ResearchQueryStructure
    ) -> String {
        var prompt = ""
        
        // Start with clear objective
        prompt += "Research Objective: \(describeObjective(structure.objective))\n\n"
        
        // Define the topic clearly
        prompt += "Topic: \(structure.topic)\n\n"
        
        // Specify scope
        prompt += "Scope:\n"
        if let timeframe = structure.scope.timeframe {
            prompt += "- Timeframe: \(timeframe)\n"
        }
        if let geography = structure.scope.geography {
            prompt += "- Geography: \(geography)\n"
        }
        if let industries = structure.scope.industries {
            prompt += "- Industries: \(industries.joined(separator: ", "))\n"
        }
        if let stakeholders = structure.scope.stakeholders {
            prompt += "- Stakeholders: \(stakeholders.joined(separator: ", "))\n"
        }
        prompt += "- Depth: \(structure.scope.depth.description)\n\n"
        
        // Add constraints
        if !structure.constraints.isEmpty {
            prompt += "Constraints:\n"
            for constraint in structure.constraints {
                prompt += "- \(describeConstraint(constraint))\n"
            }
            prompt += "\n"
        }
        
        // Specify output format
        prompt += "Output Format: \(describeOutputFormat(structure.outputFormat))\n\n"
        
        // Add specific instructions
        prompt += """
        Please provide:
        1. Comprehensive findings with supporting evidence
        2. Clear source citations for all data points
        3. Confidence levels for predictions or estimates
        4. Identification of data gaps or limitations
        5. Actionable insights and recommendations
        """
        
        return prompt
    }
    
    /// Add context and constraints to research requests
    func addContextAndConstraints(
        basePrompt: String,
        context: ResearchContext,
        constraints: [ResearchConstraint]
    ) -> String {
        var enhancedPrompt = basePrompt + "\n\n"
        
        // Add context
        enhancedPrompt += "Context:\n"
        
        if let background = context.background {
            enhancedPrompt += "Background: \(background)\n"
        }
        
        if let previousResearch = context.previousResearch {
            enhancedPrompt += "Previous Research: \(previousResearch)\n"
        }
        
        if let assumptions = context.assumptions {
            enhancedPrompt += "Key Assumptions: \(assumptions.joined(separator: "; "))\n"
        }
        
        if let terminology = context.specializedTerminology {
            enhancedPrompt += "Terminology: \(terminology.map { "\($0.key): \($0.value)" }.joined(separator: "; "))\n"
        }
        
        // Add constraints
        if !constraints.isEmpty {
            enhancedPrompt += "\nConstraints and Requirements:\n"
            
            for constraint in constraints {
                switch constraint {
                case .dataRecency(let days):
                    enhancedPrompt += "- Use data from the last \(days) days only\n"
                case .sourceReliability(let level):
                    enhancedPrompt += "- Only use sources with reliability level: \(level)\n"
                case .geographicFocus(let regions):
                    enhancedPrompt += "- Focus on regions: \(regions.joined(separator: ", "))\n"
                case .excludeSources(let sources):
                    enhancedPrompt += "- Exclude these sources: \(sources.joined(separator: ", "))\n"
                case .languageRequirement(let languages):
                    enhancedPrompt += "- Include sources in: \(languages.joined(separator: ", "))\n"
                case .complianceRequirement(let standard):
                    enhancedPrompt += "- Ensure compliance with: \(standard)\n"
                case .confidentialityLevel(let level):
                    enhancedPrompt += "- Maintain confidentiality level: \(level)\n"
                }
            }
        }
        
        return enhancedPrompt
    }
    
    /// Use chain-of-thought prompting for complex analysis
    func createChainOfThoughtPrompt(
        topic: String,
        steps: [AnalysisStep]
    ) -> String {
        var prompt = "Analyze '\(topic)' using a systematic chain-of-thought approach:\n\n"
        
        for (index, step) in steps.enumerated() {
            prompt += "Step \(index + 1): \(step.title)\n"
            prompt += "Objective: \(step.objective)\n"
            
            if !step.subQuestions.isEmpty {
                prompt += "Address these questions:\n"
                for question in step.subQuestions {
                    prompt += "  - \(question)\n"
                }
            }
            
            if let methodology = step.methodology {
                prompt += "Methodology: \(methodology)\n"
            }
            
            if let outputExpectation = step.outputExpectation {
                prompt += "Expected Output: \(outputExpectation)\n"
            }
            
            prompt += "\n"
        }
        
        prompt += """
        For each step:
        1. Show your reasoning process
        2. Identify key findings
        3. Note any assumptions or limitations
        4. Connect insights to previous steps
        5. Build toward a comprehensive conclusion
        """
        
        return prompt
    }
    
    /// Implement iterative research refinement
    func createIterativeResearchPlan(
        initialTopic: String,
        iterations: Int = 3
    ) -> IterativeResearchPlan {
        let plan = IterativeResearchPlan(
            topic: initialTopic,
            iterations: []
        )
        
        // First iteration: Broad exploration
        plan.iterations.append(
            ResearchIteration(
                number: 1,
                focus: "Broad exploration and initial understanding",
                prompt: """
                Conduct initial exploratory research on: \(initialTopic)
                
                Goals for this iteration:
                1. Define key concepts and terminology
                2. Identify major themes and categories
                3. Discover primary sources of information
                4. Map the landscape of the topic
                5. Identify areas requiring deeper investigation
                
                Provide a structured overview that will guide focused research in subsequent iterations.
                """,
                expectedOutcomes: [
                    "Topic definition and scope",
                    "Key themes identified",
                    "Initial source list",
                    "Questions for deeper research"
                ]
            )
        )
        
        // Second iteration: Focused investigation
        plan.iterations.append(
            ResearchIteration(
                number: 2,
                focus: "Focused investigation of key areas",
                prompt: """
                Based on initial findings, conduct focused research on the most important aspects of: \(initialTopic)
                
                Goals for this iteration:
                1. Deep dive into identified key themes
                2. Gather quantitative data and statistics
                3. Analyze relationships and patterns
                4. Identify gaps in current knowledge
                5. Evaluate conflicting information
                
                Build upon the initial exploration with detailed analysis.
                """,
                expectedOutcomes: [
                    "Detailed analysis of key themes",
                    "Data-supported findings",
                    "Pattern identification",
                    "Knowledge gaps documented"
                ]
            )
        )
        
        // Third iteration: Synthesis and insights
        plan.iterations.append(
            ResearchIteration(
                number: 3,
                focus: "Synthesis and actionable insights",
                prompt: """
                Synthesize all research findings on: \(initialTopic)
                
                Goals for this iteration:
                1. Integrate findings across all sources
                2. Resolve conflicting information
                3. Draw evidence-based conclusions
                4. Generate actionable recommendations
                5. Identify future research directions
                
                Provide a comprehensive synthesis with clear, actionable insights.
                """,
                expectedOutcomes: [
                    "Integrated findings",
                    "Evidence-based conclusions",
                    "Actionable recommendations",
                    "Future research directions"
                ]
            )
        )
        
        return plan
    }
    
    /// Create reusable research templates
    func createResearchTemplate(
        type: ResearchTemplate,
        customization: TemplateCustomization? = nil
    ) -> ResearchTemplateInstance {
        let baseTemplate = ResearchTemplateInstance(
            type: type,
            systemPrompt: type.systemPrompt,
            sections: getTemplateSections(for: type),
            requiredDataPoints: getRequiredDataPoints(for: type),
            qualityChecks: getQualityChecks(for: type)
        )
        
        // Apply customization if provided
        if let customization = customization {
            baseTemplate.applyCustomization(customization)
        }
        
        return baseTemplate
    }
    
    // MARK: - Helper Methods
    
    private func describeObjective(_ objective: ResearchQueryStructure.ResearchObjective) -> String {
        switch objective {
        case .exploratory:
            return "Explore and understand the topic comprehensively"
        case .comparative:
            return "Compare and contrast different options or approaches"
        case .analytical:
            return "Conduct deep analysis to uncover insights"
        case .problemSolving:
            return "Identify problems and develop solutions"
        case .predictive:
            return "Forecast future trends and developments"
        case .evaluative:
            return "Evaluate effectiveness and performance"
        }
    }
    
    private func describeConstraint(_ constraint: ResearchQueryStructure.Constraint) -> String {
        switch constraint.type {
        case .exclude:
            return "Exclude: \(constraint.value)"
        case .mustInclude:
            return "Must include: \(constraint.value)"
        case .dataSource:
            return "Data source requirement: \(constraint.value)"
        case .methodology:
            return "Methodology: \(constraint.value)"
        case .budget:
            return "Budget constraint: \(constraint.value)"
        case .compliance:
            return "Compliance requirement: \(constraint.value)"
        }
    }
    
    private func describeOutputFormat(_ format: ResearchQueryStructure.OutputFormat) -> String {
        switch format {
        case .executiveSummary:
            return "Executive summary (2-3 pages)"
        case .detailedReport:
            return "Detailed report with sections and subsections"
        case .dataTable:
            return "Structured data tables with analysis"
        case .presentation:
            return "Presentation-ready slides format"
        case .actionPlan:
            return "Action plan with timeline and responsibilities"
        case .custom(let description):
            return description
        }
    }
    
    private func getTemplateSections(for type: ResearchTemplate) -> [TemplateSection] {
        // Return appropriate sections based on template type
        return []
    }
    
    private func getRequiredDataPoints(for type: ResearchTemplate) -> [String] {
        // Return required data points for the template
        return []
    }
    
    private func getQualityChecks(for type: ResearchTemplate) -> [QualityCheck] {
        // Return quality checks for the template
        return []
    }
}

// MARK: - Supporting Types

struct ResearchContext {
    let background: String?
    let previousResearch: String?
    let assumptions: [String]?
    let specializedTerminology: [String: String]?
}

enum ResearchConstraint {
    case dataRecency(days: Int)
    case sourceReliability(level: ReliabilityLevel)
    case geographicFocus(regions: [String])
    case excludeSources(sources: [String])
    case languageRequirement(languages: [String])
    case complianceRequirement(standard: String)
    case confidentialityLevel(level: ConfidentialityLevel)
    
    enum ReliabilityLevel {
        case verified
        case reputable
        case any
    }
    
    enum ConfidentialityLevel {
        case public
        case internal
        case confidential
        case restricted
    }
}

struct AnalysisStep {
    let title: String
    let objective: String
    let subQuestions: [String]
    let methodology: String?
    let outputExpectation: String?
}

class IterativeResearchPlan {
    let topic: String
    var iterations: [ResearchIteration]
    var currentIteration: Int = 0
    
    init(topic: String, iterations: [ResearchIteration]) {
        self.topic = topic
        self.iterations = iterations
    }
    
    func nextIteration() -> ResearchIteration? {
        guard currentIteration < iterations.count else { return nil }
        let iteration = iterations[currentIteration]
        currentIteration += 1
        return iteration
    }
}

struct ResearchIteration {
    let number: Int
    let focus: String
    let prompt: String
    let expectedOutcomes: [String]
    var results: String?
    var refinements: [String] = []
}

class ResearchTemplateInstance {
    let type: ResearchPromptingBestPractices.ResearchTemplate
    var systemPrompt: String
    var sections: [TemplateSection]
    var requiredDataPoints: [String]
    var qualityChecks: [QualityCheck]
    
    init(
        type: ResearchPromptingBestPractices.ResearchTemplate,
        systemPrompt: String,
        sections: [TemplateSection],
        requiredDataPoints: [String],
        qualityChecks: [QualityCheck]
    ) {
        self.type = type
        self.systemPrompt = systemPrompt
        self.sections = sections
        self.requiredDataPoints = requiredDataPoints
        self.qualityChecks = qualityChecks
    }
    
    func applyCustomization(_ customization: TemplateCustomization) {
        // Apply customization logic
        if let additionalSections = customization.additionalSections {
            sections.append(contentsOf: additionalSections)
        }
        
        if let excludedDataPoints = customization.excludedDataPoints {
            requiredDataPoints.removeAll { excludedDataPoints.contains($0) }
        }
        
        if let customPrompt = customization.systemPromptAddition {
            systemPrompt += "\n\n" + customPrompt
        }
    }
    
    func generatePrompt(for topic: String) -> String {
        return type.structurePrompt(for: topic)
    }
}

struct TemplateSection {
    let title: String
    let description: String
    let requiredElements: [String]
}

struct QualityCheck {
    let name: String
    let criteria: String
    let weight: Double
}

struct TemplateCustomization {
    let additionalSections: [TemplateSection]?
    let excludedDataPoints: [String]?
    let systemPromptAddition: String?
    let customQualityChecks: [QualityCheck]?
}