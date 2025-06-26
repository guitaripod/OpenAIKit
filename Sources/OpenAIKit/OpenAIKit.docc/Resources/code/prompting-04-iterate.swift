import Foundation
import OpenAIKit

// Implement iterative research refinement

class IterativeResearchEngine {
    private let openAI: OpenAI
    private let deepResearch: DeepResearch
    private var researchHistory: [ResearchIteration] = []
    
    init(apiKey: String) {
        self.openAI = OpenAI(Configuration(apiKey: apiKey))
        self.deepResearch = DeepResearch(client: openAI)
    }
    
    // Execute iterative research with automatic refinement
    func executeIterativeResearch(
        initialQuery: String,
        maxIterations: Int = 5,
        refinementStrategy: RefinementStrategy = .adaptive,
        qualityCriteria: QualityCriteria
    ) async throws -> IterativeResearchResult {
        
        var currentQuery = initialQuery
        var iterations: [ResearchIteration] = []
        var cumulativeFindings = CumulativeFindings()
        
        for iterationNumber in 1...maxIterations {
            print("Starting iteration \(iterationNumber)")
            
            // Execute research for current iteration
            let iteration = try await performIteration(
                query: currentQuery,
                iterationNumber: iterationNumber,
                previousIterations: iterations,
                cumulativeFindings: cumulativeFindings
            )
            
            iterations.append(iteration)
            
            // Update cumulative findings
            cumulativeFindings.update(with: iteration)
            
            // Evaluate quality
            let qualityAssessment = try await assessQuality(
                iteration: iteration,
                criteria: qualityCriteria,
                cumulativeFindings: cumulativeFindings
            )
            
            print("Quality score: \(qualityAssessment.overallScore)")
            
            // Check if quality criteria are met
            if qualityAssessment.meetsCriteria {
                print("Quality criteria met. Stopping iterations.")
                break
            }
            
            // Check if we've reached max iterations
            if iterationNumber == maxIterations {
                print("Reached maximum iterations.")
                break
            }
            
            // Refine query for next iteration
            let refinement = try await refineQuery(
                currentQuery: currentQuery,
                iteration: iteration,
                qualityAssessment: qualityAssessment,
                strategy: refinementStrategy,
                cumulativeFindings: cumulativeFindings
            )
            
            currentQuery = refinement.refinedQuery
            
            // Check if refinement suggests stopping
            if refinement.shouldStop {
                print("Refinement suggests stopping. Reason: \(refinement.stopReason ?? "Unknown")")
                break
            }
        }
        
        // Generate final synthesis
        let synthesis = try await synthesizeIterativeResults(
            initialQuery: initialQuery,
            iterations: iterations,
            cumulativeFindings: cumulativeFindings
        )
        
        return IterativeResearchResult(
            initialQuery: initialQuery,
            iterations: iterations,
            finalSynthesis: synthesis,
            totalDuration: iterations.reduce(0) { $0 + $1.duration },
            qualityMetrics: extractQualityMetrics(from: iterations)
        )
    }
    
    // Perform a single research iteration
    private func performIteration(
        query: String,
        iterationNumber: Int,
        previousIterations: [ResearchIteration],
        cumulativeFindings: CumulativeFindings
    ) async throws -> ResearchIteration {
        
        let startTime = Date()
        
        // Build enhanced query with iteration context
        let enhancedQuery = buildIterationQuery(
            baseQuery: query,
            iterationNumber: iterationNumber,
            previousFindings: cumulativeFindings.keyFindings,
            gaps: cumulativeFindings.identifiedGaps
        )
        
        // Configure based on iteration needs
        let config = configureForIteration(
            iterationNumber: iterationNumber,
            gaps: cumulativeFindings.identifiedGaps
        )
        
        // Execute research
        let result = try await deepResearch.research(
            query: enhancedQuery,
            configuration: config
        )
        
        // Extract new findings
        let newFindings = try await extractNewFindings(
            content: result.content,
            previousFindings: cumulativeFindings.allFindings
        )
        
        // Identify remaining gaps
        let gaps = try await identifyGaps(
            query: query,
            findings: result.content,
            cumulativeFindings: cumulativeFindings
        )
        
        let endTime = Date()
        
        return ResearchIteration(
            iterationNumber: iterationNumber,
            query: query,
            enhancedQuery: enhancedQuery,
            findings: result.content,
            newFindings: newFindings,
            identifiedGaps: gaps,
            searchQueries: result.searchQueries,
            duration: endTime.timeIntervalSince(startTime)
        )
    }
    
    // Build query for specific iteration
    private func buildIterationQuery(
        baseQuery: String,
        iterationNumber: Int,
        previousFindings: [String],
        gaps: [ResearchGap]
    ) -> String {
        
        var query = "Iteration \(iterationNumber) - Refined Research\n\n"
        query += "Original Query: \(baseQuery)\n\n"
        
        if !previousFindings.isEmpty {
            query += "Already Discovered:\n"
            for finding in previousFindings.prefix(5) {
                query += "• \(finding)\n"
            }
            query += "\n"
        }
        
        if !gaps.isEmpty {
            query += "Please focus on these gaps:\n"
            for gap in gaps {
                query += "• \(gap.description) (Priority: \(gap.priority.rawValue))\n"
            }
            query += "\n"
        }
        
        query += "Provide new information not covered in previous findings.\n"
        query += "Focus on depth and accuracy rather than repeating known information."
        
        return query
    }
    
    // Configure research for specific iteration
    private func configureForIteration(
        iterationNumber: Int,
        gaps: [ResearchGap]
    ) -> DeepResearchConfiguration {
        
        // Adjust search intensity based on iteration and gaps
        let hasHighPriorityGaps = gaps.contains { $0.priority == .high }
        let searchQueries = hasHighPriorityGaps ? 8 : (5 + iterationNumber)
        let webPages = hasHighPriorityGaps ? 15 : (10 + iterationNumber * 2)
        
        return DeepResearchConfiguration(
            maxSearchQueries: min(searchQueries, 15),
            maxWebPages: min(webPages, 30),
            searchDepth: iterationNumber > 2 ? .comprehensive : .standard,
            customInstructions: "Focus on filling knowledge gaps and providing detailed evidence"
        )
    }
    
    // Extract new findings not in previous iterations
    private func extractNewFindings(
        content: String,
        previousFindings: Set<String>
    ) async throws -> [String] {
        
        let extractionPrompt = """
        Extract key findings from this content that are NOT already known:
        
        New Content:
        \(content)
        
        Already Known (DO NOT REPEAT):
        \(previousFindings.prefix(20).joined(separator: "\n"))
        
        List only genuinely NEW findings.
        """
        
        let messages: [ChatMessage] = [
            ChatMessage(role: .system, content: "You are an expert at identifying novel information."),
            ChatMessage(role: .user, content: extractionPrompt)
        ]
        
        let request = ChatCompletionRequest(
            model: .gpt4,
            messages: messages,
            temperature: 0.3,
            maxTokens: 1000
        )
        
        let response = try await openAI.chats.create(request)
        let findings = response.choices.first?.message.content ?? ""
        
        return findings
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !previousFindings.contains($0) }
    }
    
    // Identify gaps in current research
    private func identifyGaps(
        query: String,
        findings: String,
        cumulativeFindings: CumulativeFindings
    ) async throws -> [ResearchGap] {
        
        let gapAnalysisPrompt = """
        Original Query: \(query)
        
        Current Findings Summary:
        \(findings.prefix(2000))
        
        Identify what important aspects of the query remain unanswered or need more depth.
        For each gap, specify:
        1. What is missing
        2. Why it's important
        3. Priority (high/medium/low)
        """
        
        let messages: [ChatMessage] = [
            ChatMessage(role: .system, content: "You are an expert at research gap analysis."),
            ChatMessage(role: .user, content: gapAnalysisPrompt)
        ]
        
        let request = ChatCompletionRequest(
            model: .gpt4,
            messages: messages,
            temperature: 0.4,
            maxTokens: 1000
        )
        
        let response = try await openAI.chats.create(request)
        let gapText = response.choices.first?.message.content ?? ""
        
        // Parse gaps (simplified parsing)
        return parseGaps(from: gapText)
    }
    
    // Assess quality of research iteration
    private func assessQuality(
        iteration: ResearchIteration,
        criteria: QualityCriteria,
        cumulativeFindings: CumulativeFindings
    ) async throws -> QualityAssessment {
        
        var scores: [QualityDimension: Double] = [:]
        
        // Completeness
        let completenessScore = Double(cumulativeFindings.keyFindings.count) / Double(criteria.minKeyFindings)
        scores[.completeness] = min(completenessScore, 1.0)
        
        // Depth
        let avgFindingLength = cumulativeFindings.allFindings.map { $0.count }.reduce(0, +) / max(cumulativeFindings.allFindings.count, 1)
        let depthScore = Double(avgFindingLength) / 200.0 // Assume 200 chars is good depth
        scores[.depth] = min(depthScore, 1.0)
        
        // Accuracy (would need fact-checking in production)
        scores[.accuracy] = 0.85 // Placeholder
        
        // Relevance
        let relevanceScore = iteration.newFindings.isEmpty ? 0.5 : 0.9
        scores[.relevance] = relevanceScore
        
        // Coverage
        let gapRatio = Double(iteration.identifiedGaps.filter { $0.priority == .high }.count) / 10.0
        scores[.coverage] = max(0, 1.0 - gapRatio)
        
        let overallScore = scores.values.reduce(0, +) / Double(scores.count)
        let meetsCriteria = overallScore >= criteria.minimumScore &&
                           cumulativeFindings.keyFindings.count >= criteria.minKeyFindings
        
        return QualityAssessment(
            scores: scores,
            overallScore: overallScore,
            meetsCriteria: meetsCriteria,
            feedback: generateQualityFeedback(scores: scores)
        )
    }
    
    // Refine query for next iteration
    private func refineQuery(
        currentQuery: String,
        iteration: ResearchIteration,
        qualityAssessment: QualityAssessment,
        strategy: RefinementStrategy,
        cumulativeFindings: CumulativeFindings
    ) async throws -> QueryRefinement {
        
        let refinementPrompt = buildRefinementPrompt(
            currentQuery: currentQuery,
            gaps: iteration.identifiedGaps,
            qualityFeedback: qualityAssessment.feedback,
            strategy: strategy
        )
        
        let messages: [ChatMessage] = [
            ChatMessage(role: .system, content: "You are an expert at refining research queries for better results."),
            ChatMessage(role: .user, content: refinementPrompt)
        ]
        
        let request = ChatCompletionRequest(
            model: .gpt4,
            messages: messages,
            temperature: 0.5,
            maxTokens: 500
        )
        
        let response = try await openAI.chats.create(request)
        let refinementText = response.choices.first?.message.content ?? ""
        
        // Parse refinement
        return parseRefinement(from: refinementText, originalQuery: currentQuery)
    }
    
    // Build refinement prompt based on strategy
    private func buildRefinementPrompt(
        currentQuery: String,
        gaps: [ResearchGap],
        qualityFeedback: [String],
        strategy: RefinementStrategy
    ) -> String {
        
        var prompt = "Current Query: \(currentQuery)\n\n"
        
        prompt += "Identified Gaps:\n"
        for gap in gaps.prefix(5) {
            prompt += "• \(gap.description) (Priority: \(gap.priority.rawValue))\n"
        }
        prompt += "\n"
        
        prompt += "Quality Feedback:\n"
        for feedback in qualityFeedback {
            prompt += "• \(feedback)\n"
        }
        prompt += "\n"
        
        switch strategy {
        case .adaptive:
            prompt += "Refine the query to address the highest priority gaps while maintaining focus."
        case .expanding:
            prompt += "Broaden the query to explore related areas that might provide additional insights."
        case .narrowing:
            prompt += "Narrow the query to dive deeper into the most promising aspects."
        case .pivoting:
            prompt += "Consider alternative angles or perspectives that might yield better results."
        }
        
        prompt += "\n\nProvide:\n1. Refined query\n2. Explanation of changes\n3. Whether to continue iterating (yes/no) and why"
        
        return prompt
    }
    
    // Synthesize results from all iterations
    private func synthesizeIterativeResults(
        initialQuery: String,
        iterations: [ResearchIteration],
        cumulativeFindings: CumulativeFindings
    ) async throws -> IterativeSynthesis {
        
        let synthesisPrompt = """
        Synthesize the results of iterative research on: \(initialQuery)
        
        Research progressed through \(iterations.count) iterations.
        
        Key Findings:
        \(cumulativeFindings.keyFindings.joined(separator: "\n"))
        
        Evolution of Understanding:
        \(iterations.enumerated().map { "Iteration \($0.offset + 1): \($0.element.newFindings.count) new findings" }.joined(separator: "\n"))
        
        Please provide:
        1. Comprehensive summary of all findings
        2. How understanding evolved through iterations
        3. Most significant insights discovered
        4. Remaining questions or areas for future research
        5. Confidence level in the completeness of research
        """
        
        let messages: [ChatMessage] = [
            ChatMessage(role: .system, content: "You are an expert at synthesizing iterative research results."),
            ChatMessage(role: .user, content: synthesisPrompt)
        ]
        
        let request = ChatCompletionRequest(
            model: .gpt4,
            messages: messages,
            temperature: 0.3,
            maxTokens: 2500
        )
        
        let response = try await openAI.chats.create(request)
        let synthesis = response.choices.first?.message.content ?? ""
        
        return IterativeSynthesis(
            comprehensiveSummary: synthesis,
            evolutionNarrative: describeEvolution(iterations: iterations),
            keyInsights: cumulativeFindings.keyFindings,
            remainingQuestions: extractRemainingQuestions(from: synthesis),
            confidenceLevel: calculateConfidence(iterations: iterations, findings: cumulativeFindings)
        )
    }
    
    // Helper methods
    private func parseGaps(from text: String) -> [ResearchGap] {
        // Simplified parsing - in production use more sophisticated NLP
        let lines = text.components(separatedBy: .newlines)
        var gaps: [ResearchGap] = []
        
        for line in lines {
            if line.contains("high") || line.contains("High") {
                gaps.append(ResearchGap(
                    description: line.replacingOccurrences(of: "high", with: "").trimmingCharacters(in: .whitespaces),
                    priority: .high,
                    category: .depth
                ))
            } else if line.contains("medium") || line.contains("Medium") {
                gaps.append(ResearchGap(
                    description: line.replacingOccurrences(of: "medium", with: "").trimmingCharacters(in: .whitespaces),
                    priority: .medium,
                    category: .breadth
                ))
            }
        }
        
        return gaps
    }
    
    private func generateQualityFeedback(scores: [QualityDimension: Double]) -> [String] {
        var feedback: [String] = []
        
        for (dimension, score) in scores {
            if score < 0.7 {
                feedback.append("\(dimension.rawValue) needs improvement (score: \(String(format: "%.2f", score)))")
            }
        }
        
        return feedback
    }
    
    private func parseRefinement(from text: String, originalQuery: String) -> QueryRefinement {
        // Extract refined query (simplified)
        let lines = text.components(separatedBy: .newlines)
        let refinedQuery = lines.first { !$0.isEmpty } ?? originalQuery
        let shouldStop = text.lowercased().contains("no") || text.lowercased().contains("stop")
        
        return QueryRefinement(
            originalQuery: originalQuery,
            refinedQuery: refinedQuery,
            explanation: text,
            shouldStop: shouldStop,
            stopReason: shouldStop ? "Sufficient coverage achieved" : nil
        )
    }
    
    private func describeEvolution(iterations: [ResearchIteration]) -> String {
        return iterations.enumerated().map { index, iteration in
            "Iteration \(index + 1): Found \(iteration.newFindings.count) new insights, \(iteration.identifiedGaps.count) gaps remaining"
        }.joined(separator: "\n")
    }
    
    private func extractRemainingQuestions(from synthesis: String) -> [String] {
        // Simple extraction
        return synthesis
            .components(separatedBy: "remaining questions")
            .last?
            .components(separatedBy: .newlines)
            .compactMap { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return trimmed.isEmpty ? nil : trimmed
            } ?? []
    }
    
    private func calculateConfidence(iterations: [ResearchIteration], findings: CumulativeFindings) -> Double {
        let iterationScore = min(Double(iterations.count) / 3.0, 1.0)
        let findingsScore = min(Double(findings.keyFindings.count) / 20.0, 1.0)
        let gapScore = 1.0 - min(Double(iterations.last?.identifiedGaps.count ?? 0) / 10.0, 1.0)
        
        return (iterationScore + findingsScore + gapScore) / 3.0
    }
    
    private func extractQualityMetrics(from iterations: [ResearchIteration]) -> QualityMetrics {
        return QualityMetrics(
            totalFindings: iterations.reduce(0) { $0 + $1.newFindings.count },
            uniqueSearchQueries: Set(iterations.flatMap { $0.searchQueries }).count,
            averageIterationTime: iterations.map { $0.duration }.reduce(0, +) / Double(iterations.count),
            convergenceRate: calculateConvergenceRate(iterations: iterations)
        )
    }
    
    private func calculateConvergenceRate(iterations: [ResearchIteration]) -> Double {
        guard iterations.count > 1 else { return 0 }
        
        let findingCounts = iterations.map { Double($0.newFindings.count) }
        let differences = zip(findingCounts.dropFirst(), findingCounts).map { $0 - $1 }
        let avgDifference = differences.reduce(0, +) / Double(differences.count)
        
        return max(0, min(1, 1 - (avgDifference / 10.0)))
    }
}

// Models for iterative research
struct ResearchIteration {
    let iterationNumber: Int
    let query: String
    let enhancedQuery: String
    let findings: String
    let newFindings: [String]
    let identifiedGaps: [ResearchGap]
    let searchQueries: [String]
    let duration: TimeInterval
}

struct ResearchGap {
    let description: String
    let priority: Priority
    let category: GapCategory
    
    enum Priority: String {
        case high = "High"
        case medium = "Medium"
        case low = "Low"
    }
    
    enum GapCategory {
        case depth
        case breadth
        case accuracy
        case recency
    }
}

struct CumulativeFindings {
    private(set) var allFindings: Set<String> = []
    private(set) var keyFindings: [String] = []
    private(set) var identifiedGaps: [ResearchGap] = []
    
    mutating func update(with iteration: ResearchIteration) {
        allFindings.formUnion(iteration.newFindings)
        
        // Add significant new findings to key findings
        let significantFindings = iteration.newFindings.filter { $0.count > 50 }
        keyFindings.append(contentsOf: significantFindings)
        
        // Update gaps
        identifiedGaps = iteration.identifiedGaps
    }
}

enum RefinementStrategy {
    case adaptive    // Adjust based on what's working
    case expanding   // Broaden scope
    case narrowing   // Focus deeper
    case pivoting    // Try different angle
}

struct QualityCriteria {
    let minimumScore: Double
    let minKeyFindings: Int
    let maxGapsAllowed: Int
    let requiredDimensions: [QualityDimension]
}

enum QualityDimension: String {
    case completeness = "Completeness"
    case depth = "Depth"
    case accuracy = "Accuracy"
    case relevance = "Relevance"
    case coverage = "Coverage"
}

struct QualityAssessment {
    let scores: [QualityDimension: Double]
    let overallScore: Double
    let meetsCriteria: Bool
    let feedback: [String]
}

struct QueryRefinement {
    let originalQuery: String
    let refinedQuery: String
    let explanation: String
    let shouldStop: Bool
    let stopReason: String?
}

struct IterativeResearchResult {
    let initialQuery: String
    let iterations: [ResearchIteration]
    let finalSynthesis: IterativeSynthesis
    let totalDuration: TimeInterval
    let qualityMetrics: QualityMetrics
}

struct IterativeSynthesis {
    let comprehensiveSummary: String
    let evolutionNarrative: String
    let keyInsights: [String]
    let remainingQuestions: [String]
    let confidenceLevel: Double
}

struct QualityMetrics {
    let totalFindings: Int
    let uniqueSearchQueries: Int
    let averageIterationTime: TimeInterval
    let convergenceRate: Double
}

// Example usage
func demonstrateIterativeResearch() async {
    let engine = IterativeResearchEngine(apiKey: "your-api-key")
    
    let qualityCriteria = QualityCriteria(
        minimumScore: 0.8,
        minKeyFindings: 15,
        maxGapsAllowed: 3,
        requiredDimensions: [.completeness, .depth, .accuracy]
    )
    
    do {
        let result = try await engine.executeIterativeResearch(
            initialQuery: "What are the emerging cybersecurity threats for financial institutions in 2024?",
            maxIterations: 5,
            refinementStrategy: .adaptive,
            qualityCriteria: qualityCriteria
        )
        
        print("Iterative Research Complete")
        print("Iterations performed: \(result.iterations.count)")
        print("Total findings: \(result.qualityMetrics.totalFindings)")
        print("Confidence level: \(String(format: "%.2f", result.finalSynthesis.confidenceLevel))")
        print("Convergence rate: \(String(format: "%.2f", result.qualityMetrics.convergenceRate))")
        
        print("\nKey Insights:")
        for (index, insight) in result.finalSynthesis.keyInsights.prefix(5).enumerated() {
            print("\(index + 1). \(insight)")
        }
        
        print("\nRemaining Questions:")
        for question in result.finalSynthesis.remainingQuestions {
            print("- \(question)")
        }
        
    } catch {
        print("Iterative research error: \(error)")
    }
}