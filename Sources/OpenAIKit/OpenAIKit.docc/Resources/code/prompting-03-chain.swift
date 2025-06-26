import Foundation
import OpenAIKit

// Use chain-of-thought prompting for complex analysis

class ChainOfThoughtResearcher {
    private let openAI: OpenAI
    private let deepResearch: DeepResearch
    
    init(apiKey: String) {
        self.openAI = OpenAI(Configuration(apiKey: apiKey))
        self.deepResearch = DeepResearch(client: openAI)
    }
    
    // Execute chain-of-thought research
    func executeChainOfThought(
        topic: String,
        steps: [ThoughtStep],
        context: ChainContext? = nil
    ) async throws -> ChainOfThoughtResult {
        
        var thoughtChain: [ThoughtResult] = []
        var accumulatedKnowledge = ""
        
        // Execute each step in the chain
        for (index, step) in steps.enumerated() {
            print("Executing step \(index + 1): \(step.name)")
            
            // Build step query with accumulated knowledge
            let stepQuery = buildStepQuery(
                step: step,
                previousResults: thoughtChain,
                accumulatedKnowledge: accumulatedKnowledge,
                context: context
            )
            
            // Execute research for this step
            let stepResult = try await executeStep(
                query: stepQuery,
                step: step,
                stepNumber: index + 1
            )
            
            // Add to chain
            thoughtChain.append(stepResult)
            
            // Update accumulated knowledge
            accumulatedKnowledge += "\n\n--- Step \(index + 1): \(step.name) ---\n"
            accumulatedKnowledge += stepResult.findings
            
            // Check if we should continue based on step result
            if let condition = step.continueCondition {
                let shouldContinue = try await evaluateCondition(
                    condition: condition,
                    result: stepResult
                )
                if !shouldContinue {
                    print("Stopping chain at step \(index + 1) based on condition")
                    break
                }
            }
        }
        
        // Synthesize final insights
        let synthesis = try await synthesizeResults(
            topic: topic,
            chain: thoughtChain,
            context: context
        )
        
        return ChainOfThoughtResult(
            topic: topic,
            thoughtChain: thoughtChain,
            synthesis: synthesis,
            totalDuration: thoughtChain.reduce(0) { $0 + $1.duration }
        )
    }
    
    // Build query for a specific step
    private func buildStepQuery(
        step: ThoughtStep,
        previousResults: [ThoughtResult],
        accumulatedKnowledge: String,
        context: ChainContext?
    ) -> String {
        
        var query = ""
        
        // Add chain-of-thought instruction
        query += "Chain-of-Thought Analysis - Step \(previousResults.count + 1): \(step.name)\n\n"
        
        // Add step objective
        query += "Objective: \(step.objective)\n\n"
        
        // Add context from previous steps
        if !previousResults.isEmpty {
            query += "Previous Analysis:\n"
            for (index, result) in previousResults.enumerated() {
                query += "\(index + 1). \(result.step.name): \(result.keySummary)\n"
            }
            query += "\n"
        }
        
        // Add specific prompts for this step
        query += "For this step, please:\n"
        for prompt in step.prompts {
            query += "• \(prompt)\n"
        }
        query += "\n"
        
        // Add analytical framework if specified
        if let framework = step.analyticalFramework {
            query += framework.toPromptSection()
        }
        
        // Add output requirements
        query += "Output Requirements:\n"
        query += "1. Clear reasoning process\n"
        query += "2. Evidence-based conclusions\n"
        query += "3. Identify key insights for next steps\n"
        query += "4. Note any assumptions or limitations\n"
        
        return query
    }
    
    // Execute a single step
    private func executeStep(
        query: String,
        step: ThoughtStep,
        stepNumber: Int
    ) async throws -> ThoughtResult {
        
        let startTime = Date()
        
        // Configure based on step requirements
        let config = DeepResearchConfiguration(
            maxSearchQueries: step.searchIntensity.queryCount,
            maxWebPages: step.searchIntensity.pageCount,
            searchDepth: step.requiresDeepSearch ? .comprehensive : .standard,
            customInstructions: "Focus on: \(step.objective)"
        )
        
        // Execute research
        let result = try await deepResearch.research(
            query: query,
            configuration: config
        )
        
        // Extract key insights
        let insights = try await extractKeyInsights(
            from: result.content,
            step: step
        )
        
        let endTime = Date()
        
        return ThoughtResult(
            step: step,
            stepNumber: stepNumber,
            findings: result.content,
            keyInsights: insights,
            keySummary: insights.first ?? "No key insights found",
            searchQueries: result.searchQueries,
            duration: endTime.timeIntervalSince(startTime)
        )
    }
    
    // Extract key insights from step results
    private func extractKeyInsights(
        from content: String,
        step: ThoughtStep
    ) async throws -> [String] {
        
        let extractionPrompt = """
        From the following research content, extract the TOP 3-5 key insights related to: \(step.objective)
        
        Content:
        \(content)
        
        Format each insight as a clear, concise statement.
        Focus on insights that will be valuable for subsequent analysis steps.
        """
        
        let messages: [ChatMessage] = [
            ChatMessage(role: .system, content: "You are an expert at extracting key insights from research."),
            ChatMessage(role: .user, content: extractionPrompt)
        ]
        
        let request = ChatCompletionRequest(
            model: .gpt4,
            messages: messages,
            temperature: 0.3,
            maxTokens: 500
        )
        
        let response = try await openAI.chats.create(request)
        let insightText = response.choices.first?.message.content ?? ""
        
        // Parse insights (simple line-based parsing)
        return insightText
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    // Evaluate continue condition
    private func evaluateCondition(
        condition: ContinueCondition,
        result: ThoughtResult
    ) async throws -> Bool {
        
        switch condition {
        case .always:
            return true
        case .never:
            return false
        case .ifInsightsFound:
            return !result.keyInsights.isEmpty
        case .custom(let evaluator):
            return evaluator(result)
        }
    }
    
    // Synthesize results from the entire chain
    private func synthesizeResults(
        topic: String,
        chain: [ThoughtResult],
        context: ChainContext?
    ) async throws -> Synthesis {
        
        let synthesisPrompt = """
        Synthesize the following chain-of-thought research on: \(topic)
        
        Research Steps Completed:
        \(chain.enumerated().map { "\($0.offset + 1). \($0.element.step.name): \($0.element.keySummary)" }.joined(separator: "\n"))
        
        Please provide:
        1. Overall conclusions drawn from the analysis chain
        2. How each step built upon previous findings
        3. Key insights that emerged from the process
        4. Recommendations based on the cumulative analysis
        5. Areas where further research might be beneficial
        
        Focus on insights that emerged from the analytical process itself, not just individual findings.
        """
        
        let messages: [ChatMessage] = [
            ChatMessage(role: .system, content: "You are an expert at synthesizing complex analytical chains into coherent insights."),
            ChatMessage(role: .user, content: synthesisPrompt)
        ]
        
        let request = ChatCompletionRequest(
            model: .gpt4,
            messages: messages,
            temperature: 0.4,
            maxTokens: 2000
        )
        
        let response = try await openAI.chats.create(request)
        let synthesisContent = response.choices.first?.message.content ?? ""
        
        // Extract structured synthesis
        return Synthesis(
            overallConclusions: extractSection(from: synthesisContent, section: "conclusions"),
            emergentInsights: extractSection(from: synthesisContent, section: "insights"),
            recommendations: extractSection(from: synthesisContent, section: "recommendations"),
            furtherResearch: extractSection(from: synthesisContent, section: "further research"),
            fullSynthesis: synthesisContent
        )
    }
    
    // Helper to extract sections from synthesis
    private func extractSection(from text: String, section: String) -> [String] {
        // Simple extraction - in production use more sophisticated parsing
        let lines = text.components(separatedBy: .newlines)
        var inSection = false
        var sectionContent: [String] = []
        
        for line in lines {
            if line.lowercased().contains(section) {
                inSection = true
                continue
            }
            if inSection && line.trimmingCharacters(in: .whitespaces).isEmpty {
                break
            }
            if inSection {
                sectionContent.append(line.trimmingCharacters(in: .whitespaces))
            }
        }
        
        return sectionContent.filter { !$0.isEmpty }
    }
}

// Chain-of-thought models
struct ThoughtStep {
    let name: String
    let objective: String
    let prompts: [String]
    let searchIntensity: SearchIntensity
    let requiresDeepSearch: Bool
    let analyticalFramework: AnalyticalFramework?
    let continueCondition: ContinueCondition?
    
    // Predefined step templates
    static func problemDefinition(topic: String) -> ThoughtStep {
        return ThoughtStep(
            name: "Problem Definition",
            objective: "Clearly define and scope the problem or research question",
            prompts: [
                "What is the core problem or question?",
                "What are the key components and boundaries?",
                "What assumptions are we making?",
                "What success criteria should we use?"
            ],
            searchIntensity: .light,
            requiresDeepSearch: false,
            analyticalFramework: .structuredProblemSolving,
            continueCondition: .always
        )
    }
    
    static func dataGathering(focus: String) -> ThoughtStep {
        return ThoughtStep(
            name: "Data Gathering",
            objective: "Collect comprehensive data on \(focus)",
            prompts: [
                "What quantitative data is available?",
                "What qualitative insights exist?",
                "What are the primary sources?",
                "What data gaps exist?"
            ],
            searchIntensity: .intensive,
            requiresDeepSearch: true,
            analyticalFramework: nil,
            continueCondition: .ifInsightsFound
        )
    }
    
    static func analysis(method: String) -> ThoughtStep {
        return ThoughtStep(
            name: "Analysis",
            objective: "Analyze findings using \(method)",
            prompts: [
                "What patterns emerge from the data?",
                "What are the causal relationships?",
                "What contradictions or anomalies exist?",
                "What are the implications?"
            ],
            searchIntensity: .moderate,
            requiresDeepSearch: false,
            analyticalFramework: .causalAnalysis,
            continueCondition: .always
        )
    }
}

struct SearchIntensity {
    let queryCount: Int
    let pageCount: Int
    
    static let light = SearchIntensity(queryCount: 2, pageCount: 5)
    static let moderate = SearchIntensity(queryCount: 5, pageCount: 10)
    static let intensive = SearchIntensity(queryCount: 10, pageCount: 20)
}

enum ContinueCondition {
    case always
    case never
    case ifInsightsFound
    case custom((ThoughtResult) -> Bool)
}

enum AnalyticalFramework {
    case structuredProblemSolving
    case swotAnalysis
    case causalAnalysis
    case systemsThinking
    case criticalAnalysis
    
    func toPromptSection() -> String {
        switch self {
        case .structuredProblemSolving:
            return """
            Apply Structured Problem Solving:
            - Define the problem clearly
            - Identify root causes
            - Generate potential solutions
            - Evaluate trade-offs
            
            """
        case .swotAnalysis:
            return """
            Apply SWOT Analysis:
            - Strengths: What advantages exist?
            - Weaknesses: What limitations or gaps?
            - Opportunities: What potential benefits?
            - Threats: What risks or challenges?
            
            """
        case .causalAnalysis:
            return """
            Apply Causal Analysis:
            - Identify direct causes
            - Explore indirect influences
            - Map cause-effect relationships
            - Assess strength of causation
            
            """
        case .systemsThinking:
            return """
            Apply Systems Thinking:
            - Identify system components
            - Map interconnections
            - Find feedback loops
            - Consider emergent properties
            
            """
        case .criticalAnalysis:
            return """
            Apply Critical Analysis:
            - Question assumptions
            - Evaluate evidence quality
            - Consider alternative explanations
            - Assess biases and limitations
            
            """
        }
    }
}

// Result models
struct ThoughtResult {
    let step: ThoughtStep
    let stepNumber: Int
    let findings: String
    let keyInsights: [String]
    let keySummary: String
    let searchQueries: [String]
    let duration: TimeInterval
}

struct ChainOfThoughtResult {
    let topic: String
    let thoughtChain: [ThoughtResult]
    let synthesis: Synthesis
    let totalDuration: TimeInterval
    
    var summary: String {
        """
        Chain-of-Thought Research: \(topic)
        Steps: \(thoughtChain.count)
        Total Duration: \(String(format: "%.1f", totalDuration))s
        
        Key Insights by Step:
        \(thoughtChain.enumerated().map { "\($0.offset + 1). \($0.element.step.name): \($0.element.keySummary)" }.joined(separator: "\n"))
        
        Overall Conclusions:
        \(synthesis.overallConclusions.joined(separator: "\n"))
        """
    }
}

struct Synthesis {
    let overallConclusions: [String]
    let emergentInsights: [String]
    let recommendations: [String]
    let furtherResearch: [String]
    let fullSynthesis: String
}

struct ChainContext {
    let domain: String
    let constraints: [String]
    let priorKnowledge: String?
}

// Example usage
func demonstrateChainOfThought() async {
    let researcher = ChainOfThoughtResearcher(apiKey: "your-api-key")
    
    // Example: Analyze a complex business problem
    let thoughtChain = [
        ThoughtStep.problemDefinition(topic: "declining customer retention in SaaS"),
        ThoughtStep.dataGathering(focus: "customer churn patterns and industry benchmarks"),
        ThoughtStep(
            name: "Root Cause Analysis",
            objective: "Identify primary drivers of customer churn",
            prompts: [
                "What are the common characteristics of churned customers?",
                "At what point in the customer journey does churn occur?",
                "What feedback have churned customers provided?",
                "How do our retention rates compare to industry standards?"
            ],
            searchIntensity: .intensive,
            requiresDeepSearch: true,
            analyticalFramework: .causalAnalysis,
            continueCondition: .always
        ),
        ThoughtStep(
            name: "Solution Generation",
            objective: "Develop evidence-based retention strategies",
            prompts: [
                "What retention strategies have proven effective in similar contexts?",
                "How can we address the identified root causes?",
                "What quick wins vs long-term initiatives should we consider?",
                "What resources would be required?"
            ],
            searchIntensity: .moderate,
            requiresDeepSearch: false,
            analyticalFramework: .structuredProblemSolving,
            continueCondition: .always
        ),
        ThoughtStep(
            name: "Implementation Planning",
            objective: "Create actionable implementation roadmap",
            prompts: [
                "What is the optimal sequence for implementing solutions?",
                "What metrics should we track?",
                "What risks should we mitigate?",
                "How do we measure success?"
            ],
            searchIntensity: .light,
            requiresDeepSearch: false,
            analyticalFramework: nil,
            continueCondition: .always
        )
    ]
    
    let context = ChainContext(
        domain: "B2B SaaS",
        constraints: [
            "Budget limited to $500K",
            "Implementation within 6 months",
            "Minimal disruption to existing customers"
        ],
        priorKnowledge: "Company has 5000 customers, 20% annual churn rate"
    )
    
    do {
        let result = try await researcher.executeChainOfThought(
            topic: "Customer Retention Strategy for B2B SaaS",
            steps: thoughtChain,
            context: context
        )
        
        print(result.summary)
        
        print("\nEmergent Insights:")
        for insight in result.synthesis.emergentInsights {
            print("• \(insight)")
        }
        
        print("\nRecommendations:")
        for recommendation in result.synthesis.recommendations {
            print("• \(recommendation)")
        }
        
    } catch {
        print("Chain-of-thought error: \(error)")
    }
}