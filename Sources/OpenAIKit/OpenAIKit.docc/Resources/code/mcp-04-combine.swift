import Foundation
import OpenAIKit

// Combine MCP data with web research for comprehensive analysis

class HybridResearchAssistant {
    private let openAI: OpenAI
    private let mcpManager: MCPServerManager
    private let deepResearch: DeepResearch
    
    init(apiKey: String, mcpConfiguration: MCPConfiguration = .defaultConfiguration) {
        self.openAI = OpenAI(Configuration(apiKey: apiKey))
        self.mcpManager = MCPServerManager(configuration: mcpConfiguration)
        self.deepResearch = DeepResearch(client: openAI)
    }
    
    // Perform hybrid research combining internal and external data
    func performHybridResearch(
        topic: String,
        internalSources: [String] = ["knowledge_base", "documents", "analytics"],
        webSearchEnabled: Bool = true
    ) async throws -> HybridResearchResult {
        
        // Step 1: Gather internal data through MCP
        let internalData = try await gatherInternalData(topic: topic, sources: internalSources)
        
        // Step 2: Perform web research if enabled
        var webResearchResult: DeepResearchResult?
        if webSearchEnabled {
            webResearchResult = try await performWebResearch(
                topic: topic,
                context: internalData.summary
            )
        }
        
        // Step 3: Cross-reference and validate findings
        let validatedFindings = try await crossReferenceFindings(
            internal: internalData,
            external: webResearchResult
        )
        
        // Step 4: Generate comprehensive report
        let report = try await generateHybridReport(
            topic: topic,
            internalData: internalData,
            webData: webResearchResult,
            validatedFindings: validatedFindings
        )
        
        return HybridResearchResult(
            topic: topic,
            internalData: internalData,
            webResearch: webResearchResult,
            validatedFindings: validatedFindings,
            report: report,
            timestamp: Date()
        )
    }
    
    // Gather internal data through MCP
    private func gatherInternalData(topic: String, sources: [String]) async throws -> InternalDataResult {
        var findings: [String: Any] = [:]
        var metadata: [String: Any] = [:]
        
        // Query each internal source
        for source in sources {
            do {
                let data = try await mcpManager.searchDataSource(
                    source: source,
                    query: topic,
                    options: [
                        "relevance_threshold": 0.7,
                        "max_results": 50,
                        "include_metadata": true
                    ]
                )
                findings[source] = data
                metadata[source] = ["status": "success", "count": (data as? [Any])?.count ?? 0]
            } catch {
                metadata[source] = ["status": "error", "error": error.localizedDescription]
            }
        }
        
        // Generate summary of internal findings
        let summary = try await summarizeInternalData(findings: findings)
        
        return InternalDataResult(
            sources: sources,
            findings: findings,
            summary: summary,
            metadata: metadata
        )
    }
    
    // Perform web research with internal context
    private func performWebResearch(topic: String, context: String) async throws -> DeepResearchResult {
        let enhancedQuery = """
        Research Topic: \(topic)
        
        Internal Context:
        \(context)
        
        Please research this topic on the web, focusing on:
        1. Recent developments and trends
        2. External perspectives and analysis
        3. Industry benchmarks and comparisons
        4. Expert opinions and case studies
        """
        
        let config = DeepResearchConfiguration(
            maxSearchQueries: 5,
            maxWebPages: 10,
            searchDepth: .comprehensive,
            includeImages: false,
            customInstructions: "Focus on information that complements our internal data"
        )
        
        return try await deepResearch.research(query: enhancedQuery, configuration: config)
    }
    
    // Cross-reference internal and external findings
    private func crossReferenceFindings(
        internal: InternalDataResult,
        external: DeepResearchResult?
    ) async throws -> ValidatedFindings {
        
        let validationPrompt = """
        Compare and validate the following findings:
        
        INTERNAL DATA:
        \(internal.summary)
        
        EXTERNAL RESEARCH:
        \(external?.content ?? "No external research conducted")
        
        Please:
        1. Identify agreements between internal and external data
        2. Highlight any discrepancies or contradictions
        3. Assess the reliability of each finding
        4. Provide confidence scores for key insights
        """
        
        let messages: [ChatMessage] = [
            ChatMessage(role: .system, content: "You are a data validation expert skilled at cross-referencing multiple sources."),
            ChatMessage(role: .user, content: validationPrompt)
        ]
        
        let request = ChatCompletionRequest(
            model: .gpt4,
            messages: messages,
            temperature: 0.2,
            maxTokens: 2000
        )
        
        let response = try await openAI.chats.create(request)
        let validationResult = response.choices.first?.message.content ?? ""
        
        // Parse validation results
        return ValidatedFindings(
            agreements: extractAgreements(from: validationResult),
            discrepancies: extractDiscrepancies(from: validationResult),
            confidenceScores: extractConfidenceScores(from: validationResult),
            summary: validationResult
        )
    }
    
    // Generate comprehensive hybrid report
    private func generateHybridReport(
        topic: String,
        internalData: InternalDataResult,
        webData: DeepResearchResult?,
        validatedFindings: ValidatedFindings
    ) async throws -> String {
        
        let reportPrompt = """
        Generate a comprehensive research report on: \(topic)
        
        VALIDATED FINDINGS:
        \(validatedFindings.summary)
        
        DATA SOURCES:
        - Internal Sources: \(internalData.sources.joined(separator: ", "))
        - Web Research: \(webData != nil ? "Included" : "Not conducted")
        
        Please create a professional report with:
        1. Executive Summary
        2. Key Findings (with confidence levels)
        3. Internal Insights
        4. External Perspectives
        5. Recommendations
        6. Areas for Further Investigation
        """
        
        let messages: [ChatMessage] = [
            ChatMessage(role: .system, content: "You are a professional research analyst creating comprehensive reports."),
            ChatMessage(role: .user, content: reportPrompt)
        ]
        
        let request = ChatCompletionRequest(
            model: .gpt4,
            messages: messages,
            temperature: 0.3,
            maxTokens: 3000
        )
        
        let response = try await openAI.chats.create(request)
        return response.choices.first?.message.content ?? ""
    }
    
    // Helper functions
    private func summarizeInternalData(findings: [String: Any]) async throws -> String {
        let summaryPrompt = "Summarize the following internal data findings:\n\(String(describing: findings))"
        
        let messages: [ChatMessage] = [
            ChatMessage(role: .system, content: "You are a data analyst summarizing internal company data."),
            ChatMessage(role: .user, content: summaryPrompt)
        ]
        
        let request = ChatCompletionRequest(
            model: .gpt35Turbo,
            messages: messages,
            temperature: 0.3,
            maxTokens: 1000
        )
        
        let response = try await openAI.chats.create(request)
        return response.choices.first?.message.content ?? ""
    }
    
    private func extractAgreements(from text: String) -> [String] {
        // Simple extraction - in production, use more sophisticated parsing
        return text.components(separatedBy: "Agreement:").dropFirst().map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    private func extractDiscrepancies(from text: String) -> [String] {
        return text.components(separatedBy: "Discrepancy:").dropFirst().map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    private func extractConfidenceScores(from text: String) -> [String: Double] {
        // Simple pattern matching - in production, use regex or NLP
        var scores: [String: Double] = [:]
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("confidence:") || line.contains("score:") {
                // Extract score logic
                scores[line] = 0.8 // Placeholder
            }
        }
        return scores
    }
}

// Models for hybrid research
struct HybridResearchResult {
    let topic: String
    let internalData: InternalDataResult
    let webResearch: DeepResearchResult?
    let validatedFindings: ValidatedFindings
    let report: String
    let timestamp: Date
}

struct InternalDataResult {
    let sources: [String]
    let findings: [String: Any]
    let summary: String
    let metadata: [String: Any]
}

struct ValidatedFindings {
    let agreements: [String]
    let discrepancies: [String]
    let confidenceScores: [String: Double]
    let summary: String
}

// Extension for MCP search functionality
extension MCPServerManager {
    func searchDataSource(source: String, query: String, options: [String: Any]) async throws -> Any {
        let searchURL = configuration.serverURL.appendingPathComponent("search/\(source)")
        
        var request = URLRequest(url: searchURL)
        request.httpMethod = "POST"
        
        let payload: [String: Any] = [
            "query": query,
            "options": options
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MCPError.dataSourceNotFound
        }
        
        return try JSONSerialization.jsonObject(with: data)
    }
}

// Example usage
func demonstrateHybridResearch() async {
    let assistant = HybridResearchAssistant(apiKey: "your-api-key")
    
    do {
        let result = try await assistant.performHybridResearch(
            topic: "Customer satisfaction trends in our mobile app",
            internalSources: ["customer_feedback", "app_analytics", "support_tickets"],
            webSearchEnabled: true
        )
        
        print("Hybrid Research Report:")
        print(result.report)
        print("\nValidated Findings:")
        print("Agreements: \(result.validatedFindings.agreements.count)")
        print("Discrepancies: \(result.validatedFindings.discrepancies.count)")
    } catch {
        print("Hybrid research error: \(error)")
    }
}