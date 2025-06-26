import OpenAIKit
import Foundation

// Search analytics and insights
class SearchAnalytics {
    let openAI: OpenAI
    let analyticsStore: AnalyticsStore
    let insightGenerator: InsightGenerator
    
    init(apiKey: String) {
        self.openAI = OpenAI(apiKey: apiKey)
        self.analyticsStore = AnalyticsStore()
        self.insightGenerator = InsightGenerator(openAI: openAI)
    }
    
    // Track search query
    func trackSearch(_ searchEvent: SearchEvent) async throws {
        // Store search event
        try await analyticsStore.store(searchEvent)
        
        // Update real-time metrics
        try await updateMetrics(for: searchEvent)
        
        // Check for insight generation triggers
        if shouldGenerateInsights() {
            try await generateAndStoreInsights()
        }
    }
    
    // Get analytics dashboard data
    func getDashboardData(timeRange: TimeRange) async throws -> AnalyticsDashboard {
        // Fetch search events
        let events = try await analyticsStore.getEvents(in: timeRange)
        
        // Calculate metrics
        let metrics = calculateMetrics(from: events)
        
        // Get top queries
        let topQueries = getTopQueries(from: events, limit: 10)
        
        // Get search patterns
        let patterns = try await analyzeSearchPatterns(events: events)
        
        // Get user behavior insights
        let behaviorInsights = try await analyzeUserBehavior(events: events)
        
        // Get content gaps
        let contentGaps = try await identifyContentGaps(events: events)
        
        return AnalyticsDashboard(
            timeRange: timeRange,
            metrics: metrics,
            topQueries: topQueries,
            searchPatterns: patterns,
            userBehaviorInsights: behaviorInsights,
            contentGaps: contentGaps,
            generatedAt: Date()
        )
    }
    
    // Calculate search metrics
    private func calculateMetrics(from events: [SearchEvent]) -> SearchMetrics {
        let totalSearches = events.count
        let uniqueUsers = Set(events.map { $0.userId }).count
        
        // Calculate average results per search
        let avgResultsPerSearch = events.isEmpty ? 0 :
            Double(events.map { $0.resultCount }.reduce(0, +)) / Double(events.count)
        
        // Calculate click-through rate
        let searchesWithClicks = events.filter { !$0.clickedResults.isEmpty }.count
        let clickThroughRate = totalSearches > 0 ?
            Double(searchesWithClicks) / Double(totalSearches) : 0
        
        // Calculate zero result rate
        let zeroResultSearches = events.filter { $0.resultCount == 0 }.count
        let zeroResultRate = totalSearches > 0 ?
            Double(zeroResultSearches) / Double(totalSearches) : 0
        
        // Calculate average search refinements
        let refinementCounts = Dictionary(grouping: events, by: { $0.sessionId })
            .map { $0.value.count - 1 } // -1 for initial search
            .filter { $0 > 0 }
        let avgRefinements = refinementCounts.isEmpty ? 0 :
            Double(refinementCounts.reduce(0, +)) / Double(refinementCounts.count)
        
        return SearchMetrics(
            totalSearches: totalSearches,
            uniqueUsers: uniqueUsers,
            avgResultsPerSearch: avgResultsPerSearch,
            clickThroughRate: clickThroughRate,
            zeroResultRate: zeroResultRate,
            avgSearchRefinements: avgRefinements
        )
    }
    
    // Get top queries
    private func getTopQueries(from events: [SearchEvent], limit: Int) -> [TopQuery] {
        // Count query frequencies
        let queryCounts = Dictionary(grouping: events, by: { $0.query })
            .mapValues { $0.count }
        
        // Sort by frequency and create top queries
        return queryCounts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { query, count in
                let queryEvents = events.filter { $0.query == query }
                let avgResultCount = Double(queryEvents.map { $0.resultCount }.reduce(0, +)) / Double(queryEvents.count)
                let clickRate = Double(queryEvents.filter { !$0.clickedResults.isEmpty }.count) / Double(queryEvents.count)
                
                return TopQuery(
                    query: query,
                    searchCount: count,
                    avgResultCount: avgResultCount,
                    clickRate: clickRate
                )
            }
    }
    
    // Analyze search patterns
    private func analyzeSearchPatterns(events: [SearchEvent]) async throws -> [SearchPattern] {
        var patterns: [SearchPattern] = []
        
        // Time-based patterns
        let timePatterns = analyzeTimePatterns(events: events)
        patterns.append(contentsOf: timePatterns)
        
        // Query complexity patterns
        let complexityPatterns = analyzeQueryComplexity(events: events)
        patterns.append(contentsOf: complexityPatterns)
        
        // Category patterns
        let categoryPatterns = analyzeCategoryPatterns(events: events)
        patterns.append(contentsOf: categoryPatterns)
        
        // Use LLM to identify additional patterns
        let llmPatterns = try await identifyPatternsWithLLM(events: events)
        patterns.append(contentsOf: llmPatterns)
        
        return patterns
    }
    
    // Analyze time-based patterns
    private func analyzeTimePatterns(events: [SearchEvent]) -> [SearchPattern] {
        var patterns: [SearchPattern] = []
        
        // Group by hour of day
        let hourlyGroups = Dictionary(grouping: events) { event in
            Calendar.current.component(.hour, from: event.timestamp)
        }
        
        // Find peak hours
        if let peakHour = hourlyGroups.max(by: { $0.value.count < $1.value.count }) {
            patterns.append(SearchPattern(
                type: .temporal,
                description: "Peak search activity at \(peakHour.key):00",
                significance: Double(peakHour.value.count) / Double(events.count),
                affectedQueries: Array(Set(peakHour.value.map { $0.query }))
            ))
        }
        
        return patterns
    }
    
    // Analyze query complexity
    private func analyzeQueryComplexity(events: [SearchEvent]) -> [SearchPattern] {
        var patterns: [SearchPattern] = []
        
        let complexQueries = events.filter { $0.query.split(separator: " ").count > 5 }
        let complexityRate = Double(complexQueries.count) / Double(events.count)
        
        if complexityRate > 0.3 {
            patterns.append(SearchPattern(
                type: .complexity,
                description: "High rate of complex queries (\(Int(complexityRate * 100))%)",
                significance: complexityRate,
                affectedQueries: Array(Set(complexQueries.map { $0.query })).prefix(5).map { String($0) }
            ))
        }
        
        return patterns
    }
    
    // Analyze category patterns
    private func analyzeCategoryPatterns(events: [SearchEvent]) -> [SearchPattern] {
        var patterns: [SearchPattern] = []
        
        // Group by clicked result categories
        var categoryClicks: [String: Int] = [:]
        
        for event in events {
            for click in event.clickedResults {
                categoryClicks[click.category, default: 0] += 1
            }
        }
        
        // Find dominant categories
        if let topCategory = categoryClicks.max(by: { $0.value < $1.value }) {
            let dominance = Double(topCategory.value) / Double(categoryClicks.values.reduce(0, +))
            
            if dominance > 0.4 {
                patterns.append(SearchPattern(
                    type: .category,
                    description: "\(topCategory.key) category dominates search clicks",
                    significance: dominance,
                    affectedQueries: []
                ))
            }
        }
        
        return patterns
    }
    
    // Identify patterns using LLM
    private func identifyPatternsWithLLM(events: [SearchEvent]) async throws -> [SearchPattern] {
        // Prepare sample data for LLM
        let sampleQueries = Array(Set(events.map { $0.query })).prefix(50)
        
        let request = CreateChatCompletionRequest(
            model: .gpt4,
            messages: [
                .system("Analyze search queries to identify patterns and trends."),
                .user("""
                Search queries:
                \(sampleQueries.joined(separator: "\n"))
                
                Identify any notable patterns in topics, intent, or structure.
                Format as JSON array with pattern type, description, and significance.
                """)
            ],
            temperature: 0.3,
            responseFormat: .jsonObject
        )
        
        let response = try await openAI.chat.completions.create(request)
        
        // Parse and return patterns (simplified)
        return [
            SearchPattern(
                type: .semantic,
                description: "Growing interest in AI and machine learning topics",
                significance: 0.7,
                affectedQueries: ["machine learning", "AI algorithms", "neural networks"]
            )
        ]
    }
    
    // Analyze user behavior
    private func analyzeUserBehavior(events: [SearchEvent]) async throws -> [UserBehaviorInsight] {
        var insights: [UserBehaviorInsight] = []
        
        // Analyze refinement behavior
        let refinementInsight = analyzeRefinementBehavior(events: events)
        insights.append(refinementInsight)
        
        // Analyze click patterns
        let clickInsight = analyzeClickBehavior(events: events)
        insights.append(clickInsight)
        
        // Analyze abandonment
        let abandonmentInsight = analyzeAbandonment(events: events)
        insights.append(abandonmentInsight)
        
        return insights
    }
    
    // Analyze refinement behavior
    private func analyzeRefinementBehavior(events: [SearchEvent]) -> UserBehaviorInsight {
        let sessionGroups = Dictionary(grouping: events, by: { $0.sessionId })
        let refinementSessions = sessionGroups.filter { $0.value.count > 1 }
        
        let avgRefinements = refinementSessions.isEmpty ? 0 :
            Double(refinementSessions.map { $0.value.count - 1 }.reduce(0, +)) /
            Double(refinementSessions.count)
        
        return UserBehaviorInsight(
            type: .searchRefinement,
            metric: avgRefinements,
            description: "Users refine searches \(String(format: "%.1f", avgRefinements)) times on average",
            recommendation: avgRefinements > 2 ?
                "Consider improving initial search relevance" :
                "Search refinement behavior is normal"
        )
    }
    
    // Analyze click behavior
    private func analyzeClickBehavior(events: [SearchEvent]) -> UserBehaviorInsight {
        let eventsWithClicks = events.filter { !$0.clickedResults.isEmpty }
        let avgClickPosition = eventsWithClicks.isEmpty ? 0 :
            Double(eventsWithClicks.flatMap { $0.clickedResults.map { $0.position } }.reduce(0, +)) /
            Double(eventsWithClicks.flatMap { $0.clickedResults }.count)
        
        return UserBehaviorInsight(
            type: .clickPosition,
            metric: avgClickPosition,
            description: "Average click position: \(String(format: "%.1f", avgClickPosition))",
            recommendation: avgClickPosition > 3 ?
                "Consider improving result ranking algorithm" :
                "Click positions indicate good ranking"
        )
    }
    
    // Analyze abandonment
    private func analyzeAbandonment(events: [SearchEvent]) -> UserBehaviorInsight {
        let abandonedSearches = events.filter { $0.clickedResults.isEmpty && $0.resultCount > 0 }
        let abandonmentRate = events.isEmpty ? 0 :
            Double(abandonedSearches.count) / Double(events.count)
        
        return UserBehaviorInsight(
            type: .abandonment,
            metric: abandonmentRate,
            description: "\(Int(abandonmentRate * 100))% of searches are abandoned",
            recommendation: abandonmentRate > 0.5 ?
                "High abandonment rate - review result quality" :
                "Abandonment rate is acceptable"
        )
    }
    
    // Identify content gaps
    private func identifyContentGaps(events: [SearchEvent]) async throws -> [ContentGap] {
        // Find queries with no results
        let zeroResultQueries = events
            .filter { $0.resultCount == 0 }
            .map { $0.query }
        
        // Find queries with low click rates
        let lowClickQueries = Dictionary(grouping: events, by: { $0.query })
            .filter { queries in
                let clickRate = Double(queries.value.filter { !$0.clickedResults.isEmpty }.count) /
                               Double(queries.value.count)
                return clickRate < 0.2 && queries.value.count > 3
            }
            .map { $0.key }
        
        // Use LLM to analyze gaps
        let gaps = try await insightGenerator.analyzeContentGaps(
            zeroResultQueries: Array(Set(zeroResultQueries)),
            lowClickQueries: Array(Set(lowClickQueries))
        )
        
        return gaps
    }
    
    // Update real-time metrics
    private func updateMetrics(for event: SearchEvent) async throws {
        // Update counters, rates, etc.
        // This would typically update a cache or real-time database
    }
    
    // Check if insights should be generated
    private func shouldGenerateInsights() -> Bool {
        // Check based on event count, time elapsed, etc.
        return true // Simplified
    }
    
    // Generate and store insights
    private func generateAndStoreInsights() async throws {
        let recentEvents = try await analyticsStore.getEvents(
            in: TimeRange(start: Date().addingTimeInterval(-3600), end: Date())
        )
        
        let insights = try await insightGenerator.generateInsights(from: recentEvents)
        try await analyticsStore.storeInsights(insights)
    }
}

// Analytics store
class AnalyticsStore {
    private var events: [SearchEvent] = []
    private var insights: [GeneratedInsight] = []
    
    func store(_ event: SearchEvent) async throws {
        events.append(event)
    }
    
    func getEvents(in timeRange: TimeRange) async throws -> [SearchEvent] {
        return events.filter { event in
            event.timestamp >= timeRange.start && event.timestamp <= timeRange.end
        }
    }
    
    func storeInsights(_ insights: [GeneratedInsight]) async throws {
        self.insights.append(contentsOf: insights)
    }
}

// Insight generator
class InsightGenerator {
    let openAI: OpenAI
    
    init(openAI: OpenAI) {
        self.openAI = openAI
    }
    
    func generateInsights(from events: [SearchEvent]) async throws -> [GeneratedInsight] {
        // Use LLM to generate insights
        return []
    }
    
    func analyzeContentGaps(
        zeroResultQueries: [String],
        lowClickQueries: [String]
    ) async throws -> [ContentGap] {
        guard !zeroResultQueries.isEmpty || !lowClickQueries.isEmpty else { return [] }
        
        let request = CreateChatCompletionRequest(
            model: .gpt4,
            messages: [
                .system("Analyze search queries to identify content gaps."),
                .user("""
                Zero result queries: \(zeroResultQueries.joined(separator: ", "))
                Low click queries: \(lowClickQueries.joined(separator: ", "))
                
                Identify content topics that should be added to improve search results.
                """)
            ],
            temperature: 0.3
        )
        
        let response = try await openAI.chat.completions.create(request)
        
        // Parse response (simplified)
        return [
            ContentGap(
                topic: "Advanced Machine Learning Techniques",
                affectedQueries: ["deep learning optimization", "neural architecture search"],
                priority: .high,
                suggestedContent: "Create comprehensive guides on advanced ML topics"
            )
        ]
    }
}

// Models
struct SearchEvent {
    let id: String
    let userId: String
    let sessionId: String
    let query: String
    let timestamp: Date
    let resultCount: Int
    let clickedResults: [ClickedResult]
    let searchDuration: TimeInterval
}

struct ClickedResult {
    let documentId: String
    let position: Int
    let category: String
    let clickTime: TimeInterval
}

struct TimeRange {
    let start: Date
    let end: Date
}

struct AnalyticsDashboard {
    let timeRange: TimeRange
    let metrics: SearchMetrics
    let topQueries: [TopQuery]
    let searchPatterns: [SearchPattern]
    let userBehaviorInsights: [UserBehaviorInsight]
    let contentGaps: [ContentGap]
    let generatedAt: Date
}

struct SearchMetrics {
    let totalSearches: Int
    let uniqueUsers: Int
    let avgResultsPerSearch: Double
    let clickThroughRate: Double
    let zeroResultRate: Double
    let avgSearchRefinements: Double
}

struct TopQuery {
    let query: String
    let searchCount: Int
    let avgResultCount: Double
    let clickRate: Double
}

struct SearchPattern {
    let type: PatternType
    let description: String
    let significance: Double
    let affectedQueries: [String]
}

enum PatternType {
    case temporal
    case complexity
    case category
    case semantic
}

struct UserBehaviorInsight {
    let type: BehaviorType
    let metric: Double
    let description: String
    let recommendation: String
}

enum BehaviorType {
    case searchRefinement
    case clickPosition
    case abandonment
}

struct ContentGap {
    let topic: String
    let affectedQueries: [String]
    let priority: Priority
    let suggestedContent: String
}

enum Priority {
    case high
    case medium
    case low
}

struct GeneratedInsight {
    let id: String
    let type: String
    let content: String
    let generatedAt: Date
}

// Usage example
func demonstrateAnalytics() async throws {
    let analytics = SearchAnalytics(apiKey: "your-api-key")
    
    // Track a search event
    let searchEvent = SearchEvent(
        id: UUID().uuidString,
        userId: "user123",
        sessionId: "session456",
        query: "machine learning algorithms",
        timestamp: Date(),
        resultCount: 10,
        clickedResults: [
            ClickedResult(
                documentId: "doc001",
                position: 2,
                category: "Technology",
                clickTime: 5.2
            )
        ],
        searchDuration: 1.3
    )
    
    try await analytics.trackSearch(searchEvent)
    
    // Get dashboard data
    let dashboard = try await analytics.getDashboardData(
        timeRange: TimeRange(
            start: Date().addingTimeInterval(-86400), // 24 hours ago
            end: Date()
        )
    )
    
    // Display metrics
    print("Search Analytics Dashboard")
    print("========================")
    print("\nMetrics:")
    print("- Total Searches: \(dashboard.metrics.totalSearches)")
    print("- Unique Users: \(dashboard.metrics.uniqueUsers)")
    print("- Click-through Rate: \(String(format: "%.1f%%", dashboard.metrics.clickThroughRate * 100))")
    print("- Zero Result Rate: \(String(format: "%.1f%%", dashboard.metrics.zeroResultRate * 100))")
    
    print("\nTop Queries:")
    for query in dashboard.topQueries.prefix(5) {
        print("- \"\(query.query)\" (\(query.searchCount) searches)")
    }
    
    print("\nUser Behavior Insights:")
    for insight in dashboard.userBehaviorInsights {
        print("- \(insight.description)")
        print("  Recommendation: \(insight.recommendation)")
    }
    
    print("\nContent Gaps:")
    for gap in dashboard.contentGaps {
        print("- \(gap.topic) (Priority: \(gap.priority))")
        print("  \(gap.suggestedContent)")
    }
}