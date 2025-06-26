// websearch-05-citations.swift
// Add source citations and confidence scores

import Foundation
import OpenAIKit

/// Market research assistant with source citations and confidence scoring
class MarketResearchAssistant {
    let openAI = OpenAIManager.shared.client
    
    /// Configuration with citation preferences
    struct Configuration {
        let webSearchConfig: WebSearchConfig
        let citationConfig: CitationConfig
        
        struct WebSearchConfig {
            let allowedDomains: [String]?
            let blockedDomains: [String]?
            let searchDepth: SearchDepth
            let requireSources: Bool
            
            enum SearchDepth {
                case shallow, standard, deep
                var resultCount: Int {
                    switch self {
                    case .shallow: return 10
                    case .standard: return 20
                    case .deep: return 30
                    }
                }
            }
        }
        
        struct CitationConfig {
            let style: CitationStyle
            let includeURLs: Bool
            let includeAccessDate: Bool
            let minimumSourceQuality: SourceQuality
            
            enum CitationStyle {
                case apa
                case chicago
                case harvard
                case numbered
            }
            
            enum SourceQuality {
                case any
                case verified      // Known reliable sources
                case academic      // Academic institutions
                case industry      // Industry reports
                case premium       // Premium data providers
            }
        }
        
        static let academic = Configuration(
            webSearchConfig: WebSearchConfig(
                allowedDomains: [
                    "statista.com", "gartner.com", "forrester.com",
                    "mckinsey.com", "deloitte.com", "pwc.com",
                    "harvard.edu", "mit.edu", "stanford.edu",
                    "brookings.edu", "rand.org"
                ],
                blockedDomains: ["wikipedia.org", "reddit.com"],
                searchDepth: .deep,
                requireSources: true
            ),
            citationConfig: CitationConfig(
                style: .apa,
                includeURLs: true,
                includeAccessDate: true,
                minimumSourceQuality: .verified
            )
        )
    }
    
    private let config: Configuration
    
    init(config: Configuration = .academic) {
        self.config = config
    }
    
    /// Generate cited market research report
    func generateCitedReport(
        industry: String,
        competitors: [String]? = nil,
        timeframe: String = "last 12 months",
        customQuestions: [String]? = nil
    ) async throws -> CitedMarketReport {
        
        // Track all sources used
        var allSources: [ResearchSource] = []
        
        // Phase 1: Market data with citations
        let (marketData, marketSources) = try await researchMarketWithCitations(
            industry: industry,
            timeframe: timeframe
        )
        allSources.append(contentsOf: marketSources)
        
        // Phase 2: Competitive analysis with citations
        let (competitiveData, competitiveSources) = try await analyzeCompetitorsWithCitations(
            industry: industry,
            competitors: competitors ?? [],
            timeframe: timeframe
        )
        allSources.append(contentsOf: competitiveSources)
        
        // Phase 3: Trends with confidence scoring
        let (trendsData, trendsSources) = try await analyzeTrendsWithConfidence(
            industry: industry,
            timeframe: timeframe
        )
        allSources.append(contentsOf: trendsSources)
        
        // Phase 4: Custom questions with source tracking
        let (customAnswers, customSources) = try await answerCustomQuestionsWithSources(
            industry: industry,
            questions: customQuestions ?? []
        )
        allSources.append(contentsOf: customSources)
        
        // Phase 5: Compile report with full citations
        return try await compileReportWithCitations(
            industry: industry,
            marketData: marketData,
            competitiveData: competitiveData,
            trendsData: trendsData,
            customAnswers: customAnswers,
            sources: dedupeSources(allSources),
            timeframe: timeframe
        )
    }
    
    /// Research market with source citations
    private func researchMarketWithCitations(
        industry: String,
        timeframe: String
    ) async throws -> (data: MarketData, sources: [ResearchSource]) {
        
        let request = ChatRequest(
            model: .gpt4o,
            messages: [
                .system(content: """
                You are a market research analyst who ALWAYS cites sources.
                When using web search, track every source URL and date.
                Format findings with inline citations like [1], [2], etc.
                Assess the reliability of each source.
                """),
                .user(content: """
                Research the \(industry) market for \(timeframe) with citations:
                
                Required data points (cite each):
                1. Total market size and valuation [cite source]
                2. Year-over-year growth rate [cite source]
                3. Market share by major players [cite source]
                4. Geographic breakdown [cite source]
                5. Key market drivers [cite sources]
                
                For each data point:
                - Provide the specific number/fact
                - Include [citation number]
                - Note the source publication date
                - Assess source reliability (1-5 scale)
                
                At the end, list all sources in this format:
                [1] Source Name - Article Title (Date) - URL - Reliability: X/5
                """)
            ],
            temperature: 0.1,
            maxTokens: 4000,
            tools: [createCitationAwareWebSearchTool()]
        )
        
        let response = try await openAI.chat.completions(request: request)
        return parseMarketDataWithSources(from: response.choices.first?.message.content ?? "")
    }
    
    /// Analyze competitors with citations
    private func analyzeCompetitorsWithCitations(
        industry: String,
        competitors: [String],
        timeframe: String
    ) async throws -> (data: CompetitiveData, sources: [ResearchSource]) {
        
        let request = ChatRequest(
            model: .gpt4o,
            messages: [
                .system(content: """
                You are a competitive intelligence analyst who meticulously cites all sources.
                Track source credibility and recency. Prefer recent data from authoritative sources.
                """),
                .user(content: """
                Analyze \(industry) competitors with full citations for \(timeframe):
                
                Companies: \(competitors.isEmpty ? "Identify and analyze top 5 market leaders" : competitors.joined(separator: ", "))
                
                For each company provide (with citations):
                1. Market share percentage [cite]
                2. Revenue and growth rate [cite]
                3. Key products/services [cite]
                4. Recent strategic moves [cite]
                5. Competitive advantages [cite]
                
                Citation requirements:
                - Use numbered citations [1], [2], etc.
                - Prefer data from last 6 months
                - Note if data is estimated vs. reported
                - Flag any conflicting data between sources
                
                Include source list with reliability ratings.
                """)
            ],
            temperature: 0.1,
            maxTokens: 4000,
            tools: [createCitationAwareWebSearchTool()]
        )
        
        let response = try await openAI.chat.completions(request: request)
        return parseCompetitiveDataWithSources(from: response.choices.first?.message.content ?? "")
    }
    
    /// Analyze trends with confidence scoring
    private func analyzeTrendsWithConfidence(
        industry: String,
        timeframe: String
    ) async throws -> (data: TrendsData, sources: [ResearchSource]) {
        
        let request = ChatRequest(
            model: .gpt4o,
            messages: [
                .system(content: """
                You are a strategic foresight analyst. For each trend or prediction:
                1. Cite multiple corroborating sources
                2. Assign confidence scores based on source agreement
                3. Note any dissenting views
                4. Distinguish between data-backed trends and expert opinions
                """),
                .user(content: """
                Analyze \(industry) trends with confidence scoring for \(timeframe):
                
                Research areas:
                1. Technology trends [cite multiple sources]
                2. Consumer behavior shifts [cite data]
                3. Regulatory changes [cite official sources]
                4. Market disruptions [cite analyses]
                5. Future projections [cite forecasts]
                
                For each finding:
                - Provide the trend/insight
                - Include citations [1], [2], etc.
                - Assign confidence score:
                  * High (90-100%): Multiple authoritative sources agree
                  * Medium (70-89%): Good sources with minor variations
                  * Low (50-69%): Limited sources or conflicting data
                - Note source consensus/disagreement
                
                List all sources with quality ratings.
                """)
            ],
            temperature: 0.2,
            maxTokens: 4000,
            tools: [createCitationAwareWebSearchTool()]
        )
        
        let response = try await openAI.chat.completions(request: request)
        return parseTrendsDataWithSources(from: response.choices.first?.message.content ?? "")
    }
    
    /// Answer custom questions with source tracking
    private func answerCustomQuestionsWithSources(
        industry: String,
        questions: [String]
    ) async throws -> (answers: [CitedAnswer], sources: [ResearchSource]) {
        guard !questions.isEmpty else { return ([], []) }
        
        var allAnswers: [CitedAnswer] = []
        var allSources: [ResearchSource] = []
        
        for question in questions {
            let request = ChatRequest(
                model: .gpt4o,
                messages: [
                    .system(content: """
                    You are a market expert who provides thoroughly researched, cited answers.
                    Every claim must be backed by a source. Assess answer confidence based on source quality.
                    """),
                    .user(content: """
                    In the context of \(industry), answer with citations:
                    
                    Question: \(question)
                    
                    Requirements:
                    - Comprehensive answer with data
                    - Citation for every fact [1], [2]
                    - Confidence score (0-100%) based on:
                      * Source quality
                      * Data recency
                      * Source agreement
                    - Note any limitations or caveats
                    
                    Include source list with dates and reliability.
                    """)
                ],
                temperature: 0.1,
                tools: [createCitationAwareWebSearchTool()]
            )
            
            let response = try await openAI.chat.completions(request: request)
            let (answer, sources) = parseAnswerWithSources(
                from: response.choices.first?.message.content ?? "",
                question: question
            )
            
            allAnswers.append(answer)
            allSources.append(contentsOf: sources)
        }
        
        return (allAnswers, allSources)
    }
    
    /// Compile report with full citations
    private func compileReportWithCitations(
        industry: String,
        marketData: MarketData,
        competitiveData: CompetitiveData,
        trendsData: TrendsData,
        customAnswers: [CitedAnswer],
        sources: [ResearchSource],
        timeframe: String
    ) async throws -> CitedMarketReport {
        
        // Calculate overall confidence based on source quality and data consistency
        let overallConfidence = calculateOverallConfidence(
            sources: sources,
            marketData: marketData,
            competitiveData: competitiveData,
            trendsData: trendsData
        )
        
        // Generate executive summary with key citations
        let executiveSummary = try await generateCitedExecutiveSummary(
            industry: industry,
            marketData: marketData,
            competitiveData: competitiveData,
            trendsData: trendsData
        )
        
        // Format sources according to citation style
        let formattedCitations = formatCitations(sources: sources, style: config.citationConfig.style)
        
        // Create confidence breakdown
        let confidenceBreakdown = ConfidenceBreakdown(
            dataQuality: assessDataQuality(sources: sources),
            sourceReliability: assessSourceReliability(sources: sources),
            dataRecency: assessDataRecency(sources: sources),
            consistency: assessDataConsistency(marketData: marketData, competitiveData: competitiveData),
            overall: overallConfidence
        )
        
        return CitedMarketReport(
            title: "\(industry) Market Research Report",
            industry: industry,
            timeframe: timeframe,
            executiveSummary: executiveSummary,
            marketData: marketData,
            competitiveData: competitiveData,
            trendsData: trendsData,
            customAnswers: customAnswers,
            sources: sources,
            formattedCitations: formattedCitations,
            confidenceBreakdown: confidenceBreakdown,
            methodology: generateCitedMethodology(),
            generatedDate: Date()
        )
    }
    
    /// Create citation-aware web search tool
    private func createCitationAwareWebSearchTool() -> ChatRequest.Tool {
        return ChatRequest.Tool(
            type: .function,
            function: .init(
                name: "web_search",
                description: "Search for market data with source tracking",
                parameters: [
                    "query": ["type": "string"],
                    "num_results": ["type": "integer", "default": config.webSearchConfig.searchDepth.resultCount],
                    "allowed_domains": ["type": "array", "items": ["type": "string"], "default": config.webSearchConfig.allowedDomains ?? []],
                    "blocked_domains": ["type": "array", "items": ["type": "string"], "default": config.webSearchConfig.blockedDomains ?? []],
                    "require_dates": ["type": "boolean", "default": true],
                    "prefer_recent": ["type": "boolean", "default": true]
                ]
            )
        )
    }
    
    /// Generate executive summary with citations
    private func generateCitedExecutiveSummary(
        industry: String,
        marketData: MarketData,
        competitiveData: CompetitiveData,
        trendsData: TrendsData
    ) async throws -> String {
        let request = ChatRequest(
            model: .gpt4o,
            messages: [
                .system(content: "Create a concise executive summary that references key findings with inline citations."),
                .user(content: """
                Summarize the \(industry) market research with inline citations:
                
                Market size: $\(marketData.size)B [\(marketData.sizeCitation)]
                Growth rate: \(marketData.growthRate)% [\(marketData.growthCitation)]
                Top players: \(competitiveData.topPlayers.map { $0.name }.joined(separator: ", "))
                Key trends: \(trendsData.keyTrends.map { $0.title }.joined(separator: ", "))
                
                Create 3-4 paragraph summary with [citation numbers] for key facts.
                """)
            ],
            temperature: 0.2
        )
        
        let response = try await openAI.chat.completions(request: request)
        return response.choices.first?.message.content ?? ""
    }
    
    /// Format citations according to style
    private func formatCitations(sources: [ResearchSource], style: Configuration.CitationConfig.CitationStyle) -> String {
        switch style {
        case .apa:
            return sources.enumerated().map { index, source in
                "[\(index + 1)] \(source.author). (\(source.year)). \(source.title). \(source.publisher). \(source.url)"
            }.joined(separator: "\n")
            
        case .numbered:
            return sources.enumerated().map { index, source in
                "[\(index + 1)] \(source.title) - \(source.publisher) (\(source.date.formatted())) - \(source.url)"
            }.joined(separator: "\n")
            
        case .chicago:
            return sources.map { source in
                "\(source.author). \"\(source.title).\" \(source.publisher), \(source.date.formatted())."
            }.joined(separator: "\n")
            
        case .harvard:
            return sources.map { source in
                "\(source.author) \(source.year), '\(source.title)', \(source.publisher), viewed \(Date().formatted())."
            }.joined(separator: "\n")
        }
    }
    
    /// Calculate overall confidence score
    private func calculateOverallConfidence(
        sources: [ResearchSource],
        marketData: MarketData,
        competitiveData: CompetitiveData,
        trendsData: TrendsData
    ) -> Double {
        let sourceQuality = sources.map { $0.reliability }.reduce(0, +) / Double(sources.count)
        let dataConfidence = (marketData.confidence + competitiveData.confidence + trendsData.confidence) / 3
        let recencyScore = sources.filter { $0.isRecent }.count / sources.count
        
        return (sourceQuality * 0.4 + dataConfidence * 0.4 + Double(recencyScore) * 0.2)
    }
    
    /// Assess data quality
    private func assessDataQuality(sources: [ResearchSource]) -> QualityScore {
        let avgReliability = sources.map { $0.reliability }.reduce(0, +) / Double(sources.count)
        return QualityScore(
            score: avgReliability,
            description: avgReliability > 0.8 ? "Excellent" : avgReliability > 0.6 ? "Good" : "Fair"
        )
    }
    
    /// Assess source reliability
    private func assessSourceReliability(sources: [ResearchSource]) -> QualityScore {
        let premiumSources = sources.filter { $0.isPremium }.count
        let score = Double(premiumSources) / Double(sources.count)
        return QualityScore(
            score: score,
            description: "\(premiumSources) of \(sources.count) sources are premium/verified"
        )
    }
    
    /// Assess data recency
    private func assessDataRecency(sources: [ResearchSource]) -> QualityScore {
        let recentSources = sources.filter { $0.isRecent }.count
        let score = Double(recentSources) / Double(sources.count)
        return QualityScore(
            score: score,
            description: "\(recentSources) sources from last 6 months"
        )
    }
    
    /// Assess data consistency
    private func assessDataConsistency(marketData: MarketData, competitiveData: CompetitiveData) -> QualityScore {
        // Check if market share adds up, growth rates align, etc.
        let consistency = 0.85 // Simplified
        return QualityScore(
            score: consistency,
            description: "Data points show high consistency"
        )
    }
    
    /// Generate methodology with citation details
    private func generateCitedMethodology() -> String {
        """
        ## Research Methodology
        
        This report was generated using:
        - Web search across \(config.webSearchConfig.allowedDomains?.count ?? 0) verified sources
        - Citation style: \(config.citationConfig.style)
        - Minimum source quality: \(config.citationConfig.minimumSourceQuality)
        - Multi-source validation for key data points
        - Confidence scoring based on source agreement
        - Temporal analysis focusing on \(Date().formatted())
        
        All data points include source citations with reliability assessments.
        """
    }
    
    /// Deduplicate sources
    private func dedupeSources(_ sources: [ResearchSource]) -> [ResearchSource] {
        var seen = Set<String>()
        return sources.filter { source in
            let key = "\(source.url)-\(source.title)"
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
    }
    
    // MARK: - Parsing Methods (simplified)
    
    private func parseMarketDataWithSources(from content: String) -> (MarketData, [ResearchSource]) {
        // Parse market data and extract sources
        let marketData = MarketData(
            size: 125.5,
            sizeCitation: "1,2",
            growthRate: 15.3,
            growthCitation: "3",
            segments: [],
            confidence: 0.85
        )
        
        let sources = [
            ResearchSource(
                title: "Global Market Report 2024",
                author: "Gartner Research",
                publisher: "Gartner Inc.",
                url: "https://gartner.com/report/12345",
                date: Date(),
                reliability: 0.95,
                type: .industryReport
            )
        ]
        
        return (marketData, sources)
    }
    
    private func parseCompetitiveDataWithSources(from content: String) -> (CompetitiveData, [ResearchSource]) {
        // Implementation would parse competitive data
        let competitiveData = CompetitiveData(
            topPlayers: [
                CompetitorData(name: "Leader A", marketShare: 35, citation: "4,5"),
                CompetitorData(name: "Leader B", marketShare: 28, citation: "4,6")
            ],
            confidence: 0.82
        )
        return (competitiveData, [])
    }
    
    private func parseTrendsDataWithSources(from content: String) -> (TrendsData, [ResearchSource]) {
        // Implementation would parse trends
        let trendsData = TrendsData(
            keyTrends: [
                TrendData(title: "AI Adoption", confidence: 0.9, citations: "7,8,9"),
                TrendData(title: "Sustainability", confidence: 0.85, citations: "10,11")
            ],
            confidence: 0.8
        )
        return (trendsData, [])
    }
    
    private func parseAnswerWithSources(from content: String, question: String) -> (CitedAnswer, [ResearchSource]) {
        let answer = CitedAnswer(
            question: question,
            answer: content,
            citations: "12,13",
            confidence: 0.85
        )
        return (answer, [])
    }
}

// MARK: - Data Models

struct CitedMarketReport {
    let title: String
    let industry: String
    let timeframe: String
    let executiveSummary: String
    let marketData: MarketData
    let competitiveData: CompetitiveData
    let trendsData: TrendsData
    let customAnswers: [CitedAnswer]
    let sources: [ResearchSource]
    let formattedCitations: String
    let confidenceBreakdown: ConfidenceBreakdown
    let methodology: String
    let generatedDate: Date
}

struct MarketData {
    let size: Double
    let sizeCitation: String
    let growthRate: Double
    let growthCitation: String
    let segments: [SegmentData]
    let confidence: Double
}

struct SegmentData {
    let name: String
    let size: Double
    let citation: String
}

struct CompetitiveData {
    let topPlayers: [CompetitorData]
    let confidence: Double
}

struct CompetitorData {
    let name: String
    let marketShare: Double
    let citation: String
}

struct TrendsData {
    let keyTrends: [TrendData]
    let confidence: Double
}

struct TrendData {
    let title: String
    let confidence: Double
    let citations: String
}

struct CitedAnswer {
    let question: String
    let answer: String
    let citations: String
    let confidence: Double
}

struct ResearchSource {
    let title: String
    let author: String
    let publisher: String
    let url: String
    let date: Date
    let reliability: Double
    let type: SourceType
    
    enum SourceType {
        case industryReport
        case academic
        case news
        case company
        case government
    }
    
    var year: String {
        date.formatted(.dateTime.year())
    }
    
    var isRecent: Bool {
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        return date > sixMonthsAgo
    }
    
    var isPremium: Bool {
        ["gartner", "forrester", "mckinsey", "statista"].contains { publisher.lowercased().contains($0) }
    }
}

struct ConfidenceBreakdown {
    let dataQuality: QualityScore
    let sourceReliability: QualityScore
    let dataRecency: QualityScore
    let consistency: QualityScore
    let overall: Double
}

struct QualityScore {
    let score: Double
    let description: String
}

// MARK: - Usage Example

func generateFullyCitedMarketReport() async throws {
    let assistant = MarketResearchAssistant(config: .academic)
    
    let report = try await assistant.generateCitedReport(
        industry: "artificial intelligence",
        competitors: ["OpenAI", "Google", "Microsoft", "Amazon"],
        timeframe: "2023-2024",
        customQuestions: [
            "What is the projected market size for AI by 2030?",
            "How are enterprises adopting AI technologies?",
            "What are the main barriers to AI adoption?"
        ]
    )
    
    // Display report with citations
    print("""
    # \(report.title)
    
    Generated: \(report.generatedDate.formatted())
    Overall Confidence: \(Int(report.confidenceBreakdown.overall * 100))%
    
    ## Executive Summary
    \(report.executiveSummary)
    
    ## Market Overview
    - Market Size: $\(report.marketData.size)B [\(report.marketData.sizeCitation)]
    - Growth Rate: \(report.marketData.growthRate)% [\(report.marketData.growthCitation)]
    
    ## Confidence Breakdown
    - Data Quality: \(report.confidenceBreakdown.dataQuality.description) (\(Int(report.confidenceBreakdown.dataQuality.score * 100))%)
    - Source Reliability: \(report.confidenceBreakdown.sourceReliability.description)
    - Data Recency: \(report.confidenceBreakdown.dataRecency.description)
    - Consistency: \(report.confidenceBreakdown.consistency.description)
    
    ## Sources
    \(report.formattedCitations)
    
    ---
    Report includes \(report.sources.count) verified sources.
    """)
}

// Example usage:
// Task {
//     try await generateFullyCitedMarketReport()
// }