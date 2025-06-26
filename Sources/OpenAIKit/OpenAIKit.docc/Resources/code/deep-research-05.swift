// StreamingResearch.swift
import Foundation
import OpenAIKit
import Combine

/// View model for streaming research responses
@MainActor
class StreamingResearchViewModel: ObservableObject {
    @Published var currentResearch: StreamingResearch?
    @Published var researchProgress: ResearchProgress = .idle
    @Published var findings: [ResearchFinding] = []
    @Published var error: Error?
    
    private let openAI = OpenAIManager.shared.client
    private var streamTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    /// Research progress states
    enum ResearchProgress {
        case idle
        case initializing
        case searchingWeb(query: String)
        case analyzingData(source: String)
        case synthesizing
        case completed
        case failed(Error)
        
        var description: String {
            switch self {
            case .idle:
                return "Ready to research"
            case .initializing:
                return "Initializing research..."
            case .searchingWeb(let query):
                return "Searching web for: \(query)"
            case .analyzingData(let source):
                return "Analyzing data from: \(source)"
            case .synthesizing:
                return "Synthesizing findings..."
            case .completed:
                return "Research completed"
            case .failed(let error):
                return "Failed: \(error.localizedDescription)"
            }
        }
        
        var isActive: Bool {
            switch self {
            case .idle, .completed, .failed:
                return false
            default:
                return true
            }
        }
    }
    
    /// Start streaming research
    func startResearch(
        topic: String,
        depth: ResearchDepth = .standard,
        sources: [ResearchSource] = [.webSearch, .academic]
    ) {
        // Cancel any existing research
        cancelResearch()
        
        // Reset state
        findings.removeAll()
        error = nil
        researchProgress = .initializing
        
        // Create research configuration
        let research = StreamingResearch(
            id: UUID().uuidString,
            topic: topic,
            depth: depth,
            sources: sources,
            startTime: Date()
        )
        
        currentResearch = research
        
        // Start streaming task
        streamTask = Task {
            await performStreamingResearch(research: research)
        }
    }
    
    /// Perform streaming research with real-time updates
    private func performStreamingResearch(research: StreamingResearch) async {
        do {
            // Build research prompt
            let prompt = buildResearchPrompt(
                topic: research.topic,
                depth: research.depth,
                sources: research.sources
            )
            
            // Create streaming request
            let request = ChatRequest(
                model: .gpt4o,
                messages: [
                    .system(content: """
                    You are a comprehensive research assistant.
                    Provide detailed, step-by-step research findings.
                    Structure your response with clear sections and progress indicators.
                    Use markdown formatting for clarity.
                    """),
                    .user(content: prompt)
                ],
                temperature: 0.5,
                maxTokens: 4000,
                stream: true
            )
            
            // Stream the response
            let stream = try await openAI.chat.completionsStream(request: request)
            
            var accumulatedContent = ""
            var currentSection: ResearchSection?
            
            for try await chunk in stream {
                // Check if cancelled
                if Task.isCancelled { break }
                
                guard let delta = chunk.choices.first?.delta else { continue }
                
                if let content = delta.content {
                    accumulatedContent += content
                    
                    // Parse progress indicators
                    if let progress = parseProgressIndicator(from: content) {
                        await updateProgress(progress)
                    }
                    
                    // Parse sections and findings
                    if let section = parseSection(from: accumulatedContent) {
                        if section != currentSection {
                            currentSection = section
                            await addFinding(
                                ResearchFinding(
                                    id: UUID().uuidString,
                                    section: section,
                                    content: "",
                                    sources: [],
                                    confidence: 0.0,
                                    timestamp: Date()
                                )
                            )
                        }
                    }
                    
                    // Update current finding
                    if let currentSection = currentSection,
                       let lastFinding = findings.last,
                       lastFinding.section == currentSection {
                        await updateFinding(
                            id: lastFinding.id,
                            content: extractSectionContent(
                                from: accumulatedContent,
                                section: currentSection
                            )
                        )
                    }
                }
                
                // Handle function calls (web search, data analysis, etc.)
                if let functionCall = delta.toolCalls?.first?.function {
                    await handleFunctionCall(functionCall)
                }
            }
            
            // Mark as completed
            await completeResearch()
            
        } catch {
            await handleError(error)
        }
    }
    
    /// Cancel ongoing research
    func cancelResearch() {
        streamTask?.cancel()
        streamTask = nil
        
        if researchProgress.isActive {
            researchProgress = .idle
        }
    }
    
    /// Pause research (can be resumed)
    func pauseResearch() {
        guard researchProgress.isActive else { return }
        
        // Store current state for resume
        if let research = currentResearch {
            research.pausedAt = Date()
            research.pausedProgress = researchProgress
        }
        
        // Cancel current task
        streamTask?.cancel()
        streamTask = nil
    }
    
    /// Resume paused research
    func resumeResearch() {
        guard let research = currentResearch,
              research.pausedAt != nil else { return }
        
        // Restore progress
        if let pausedProgress = research.pausedProgress {
            researchProgress = pausedProgress
        }
        
        research.pausedAt = nil
        research.pausedProgress = nil
        
        // Continue research from where it left off
        streamTask = Task {
            await continueResearch(research: research)
        }
    }
    
    // MARK: - Helper Methods
    
    private func buildResearchPrompt(
        topic: String,
        depth: ResearchDepth,
        sources: [ResearchSource]
    ) -> String {
        var prompt = "Research Topic: \(topic)\n\n"
        
        prompt += "Research Depth: \(depth.description)\n"
        prompt += "Sources: \(sources.map { $0.rawValue }.joined(separator: ", "))\n\n"
        
        prompt += """
        Please conduct comprehensive research following this structure:
        
        [PROGRESS: Initializing]
        ## Overview
        Brief introduction to the topic
        
        [PROGRESS: Searching Web]
        ## Current Information
        Latest developments and news
        
        [PROGRESS: Analyzing Data]
        ## Analysis
        In-depth analysis of findings
        
        [PROGRESS: Synthesizing]
        ## Synthesis
        Key insights and conclusions
        
        ## Sources
        List all sources used
        
        Use [PROGRESS: status] markers to indicate current activity.
        """
        
        return prompt
    }
    
    @MainActor
    private func updateProgress(_ progress: ResearchProgress) {
        researchProgress = progress
    }
    
    @MainActor
    private func addFinding(_ finding: ResearchFinding) {
        findings.append(finding)
    }
    
    @MainActor
    private func updateFinding(id: String, content: String) {
        if let index = findings.firstIndex(where: { $0.id == id }) {
            findings[index].content = content
        }
    }
    
    @MainActor
    private func completeResearch() {
        researchProgress = .completed
        currentResearch?.endTime = Date()
    }
    
    @MainActor
    private func handleError(_ error: Error) {
        self.error = error
        researchProgress = .failed(error)
    }
    
    private func parseProgressIndicator(from content: String) -> ResearchProgress? {
        let pattern = #"\[PROGRESS:\s*(.+?)\]"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: content,
                range: NSRange(content.startIndex..., in: content)
              ),
              let range = Range(match.range(at: 1), in: content) else {
            return nil
        }
        
        let status = String(content[range]).trimmingCharacters(in: .whitespaces)
        
        switch status.lowercased() {
        case "initializing":
            return .initializing
        case let s where s.contains("searching"):
            let query = s.replacingOccurrences(of: "searching web", with: "")
                .trimmingCharacters(in: .whitespaces)
            return .searchingWeb(query: query.isEmpty ? "general" : query)
        case let s where s.contains("analyzing"):
            let source = s.replacingOccurrences(of: "analyzing data", with: "")
                .trimmingCharacters(in: .whitespaces)
            return .analyzingData(source: source.isEmpty ? "results" : source)
        case "synthesizing":
            return .synthesizing
        default:
            return nil
        }
    }
    
    private func parseSection(from content: String) -> ResearchSection? {
        let sections: [(pattern: String, section: ResearchSection)] = [
            ("## Overview", .overview),
            ("## Current Information", .currentInfo),
            ("## Analysis", .analysis),
            ("## Synthesis", .synthesis),
            ("## Sources", .sources)
        ]
        
        for (pattern, section) in sections {
            if content.contains(pattern) {
                return section
            }
        }
        
        return nil
    }
    
    private func extractSectionContent(
        from content: String,
        section: ResearchSection
    ) -> String {
        // Extract content for specific section
        let sectionMarker = "## \(section.title)"
        guard let startRange = content.range(of: sectionMarker) else {
            return ""
        }
        
        let afterMarker = content[startRange.upperBound...]
        
        // Find next section marker
        let nextPattern = "##"
        if let nextRange = afterMarker.range(of: nextPattern) {
            return String(afterMarker[..<nextRange.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return String(afterMarker)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func handleFunctionCall(_ functionCall: ChatResponse.Choice.Message.ToolCall.Function) async {
        // Handle different function calls (web search, data analysis, etc.)
        switch functionCall.name {
        case "web_search":
            if let args = functionCall.arguments,
               let query = args["query"] as? String {
                await updateProgress(.searchingWeb(query: query))
            }
        case let name where name.starts(with: "analyze_"):
            await updateProgress(.analyzingData(source: name))
        default:
            break
        }
    }
    
    private func continueResearch(research: StreamingResearch) async {
        // Implementation to continue from paused state
        // This would need to track progress and resume appropriately
    }
}

// MARK: - Data Models

class StreamingResearch {
    let id: String
    let topic: String
    let depth: ResearchDepth
    let sources: [ResearchSource]
    let startTime: Date
    var endTime: Date?
    var pausedAt: Date?
    var pausedProgress: StreamingResearchViewModel.ResearchProgress?
    
    init(
        id: String,
        topic: String,
        depth: ResearchDepth,
        sources: [ResearchSource],
        startTime: Date
    ) {
        self.id = id
        self.topic = topic
        self.depth = depth
        self.sources = sources
        self.startTime = startTime
    }
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
}

enum ResearchDepth {
    case quick
    case standard
    case deep
    case exhaustive
    
    var description: String {
        switch self {
        case .quick: return "Quick overview"
        case .standard: return "Standard research"
        case .deep: return "Deep analysis"
        case .exhaustive: return "Exhaustive investigation"
        }
    }
}

enum ResearchSource: String, CaseIterable {
    case webSearch = "Web Search"
    case academic = "Academic Papers"
    case news = "News Articles"
    case social = "Social Media"
    case databases = "Databases"
    case internal = "Internal Sources"
}

enum ResearchSection {
    case overview
    case currentInfo
    case analysis
    case synthesis
    case sources
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .currentInfo: return "Current Information"
        case .analysis: return "Analysis"
        case .synthesis: return "Synthesis"
        case .sources: return "Sources"
        }
    }
}

struct ResearchFinding: Identifiable {
    let id: String
    let section: ResearchSection
    var content: String
    let sources: [String]
    let confidence: Double
    let timestamp: Date
}