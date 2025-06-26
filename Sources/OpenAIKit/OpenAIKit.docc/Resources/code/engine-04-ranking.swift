import Foundation
import OpenAIKit

extension SemanticSearchEngine {
    /// Advanced ranking system with multiple signals
    class RankingEngine {
        private let openAI: OpenAIKit
        
        init(openAI: OpenAIKit) {
            self.openAI = openAI
        }
        
        /// Rank results using multiple signals
        func rankResults(
            _ results: [SearchResult],
            query: String,
            userContext: UserContext? = nil
        ) async throws -> [SearchResult] {
            var rankedResults = results
            
            // Apply semantic reranking
            rankedResults = try await semanticRerank(rankedResults, query: query)
            
            // Apply personalization if user context available
            if let context = userContext {
                rankedResults = personalizeResults(rankedResults, context: context)
            }
            
            // Apply diversity to avoid redundant results
            rankedResults = diversifyResults(rankedResults)
            
            return rankedResults
        }
        
        /// Semantic reranking using GPT
        private func semanticRerank(
            _ results: [SearchResult],
            query: String
        ) async throws -> [SearchResult] {
            guard !results.isEmpty else { return results }
            
            // Create prompt for reranking
            let documentsDescription = results.enumerated()
                .map { index, result in
                    "[\(index)] \(result.document.title): \(String(result.document.content.prefix(200)))"
                }
                .joined(separator: "\n")
            
            let prompt = """
            Given this search query: "\(query)"
            
            Rank these documents by relevance (most relevant first):
            \(documentsDescription)
            
            Return only the indices in order, separated by commas.
            """
            
            let request = CreateChatCompletionRequest(
                model: .gpt3_5Turbo,
                messages: [.init(role: .user, content: .text(prompt))],
                temperature: 0.1,
                maxTokens: 50
            )
            
            let response = try await openAI.chat.create(chatCompletion: request)
            guard let ranking = response.choices.first?.message.content?.string else {
                return results
            }
            
            // Parse ranking
            let indices = ranking
                .split(separator: ",")
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            
            // Reorder results
            var rerankedResults: [SearchResult] = []
            for index in indices {
                if index < results.count {
                    rerankedResults.append(results[index])
                }
            }
            
            // Add any missing results at the end
            for result in results {
                if !rerankedResults.contains(where: { $0.document.id == result.document.id }) {
                    rerankedResults.append(result)
                }
            }
            
            return rerankedResults
        }
        
        /// Personalize results based on user context
        private func personalizeResults(
            _ results: [SearchResult],
            context: UserContext
        ) -> [SearchResult] {
            return results.map { result in
                var personalizedScore = result.score
                
                // Boost based on user interests
                for interest in context.interests {
                    if result.document.content.lowercased().contains(interest.lowercased()) ||
                       result.document.title.lowercased().contains(interest.lowercased()) {
                        personalizedScore *= 1.2
                    }
                }
                
                // Boost based on recent interactions
                if context.recentlyViewed.contains(result.document.id) {
                    personalizedScore *= 0.8 // Slightly penalize recently viewed
                }
                
                // Boost based on user level
                if let difficulty = result.document.metadata["difficulty"] as? String {
                    if matchesUserLevel(difficulty, userLevel: context.level) {
                        personalizedScore *= 1.1
                    }
                }
                
                return SearchResult(
                    document: result.document,
                    score: min(personalizedScore, 1.0),
                    highlights: result.highlights
                )
            }.sorted { $0.score > $1.score }
        }
        
        /// Ensure diversity in results
        private func diversifyResults(_ results: [SearchResult]) -> [SearchResult] {
            var diversifiedResults: [SearchResult] = []
            var seenCategories: Set<String> = []
            var categoryCount: [String: Int] = [:]
            
            for result in results {
                let category = result.document.metadata["category"] as? String ?? "general"
                
                // Limit results per category
                let count = categoryCount[category, default: 0]
                if count < 3 { // Max 3 per category in top results
                    diversifiedResults.append(result)
                    categoryCount[category] = count + 1
                    seenCategories.insert(category)
                } else if diversifiedResults.count < 10 {
                    // After initial diversity, add remaining high-score results
                    diversifiedResults.append(result)
                }
            }
            
            return diversifiedResults
        }
        
        /// Calculate relevance score with multiple factors
        func calculateRelevanceScore(
            document: SearchDocument,
            query: String,
            embedding: [Double],
            queryEmbedding: [Double]
        ) -> Double {
            // Base semantic similarity
            let semanticScore = cosineSimilarity(embedding, queryEmbedding)
            
            // Text matching score
            let textScore = calculateTextMatchScore(document: document, query: query)
            
            // Freshness score
            let freshnessScore = calculateFreshnessScore(timestamp: document.timestamp)
            
            // Combine scores with weights
            let weights = (semantic: 0.6, text: 0.3, freshness: 0.1)
            let finalScore = (semanticScore * weights.semantic) +
                           (textScore * weights.text) +
                           (freshnessScore * weights.freshness)
            
            return finalScore
        }
        
        /// Calculate text matching score
        private func calculateTextMatchScore(document: SearchDocument, query: String) -> Double {
            let queryTerms = query.lowercased().split(separator: " ").map(String.init)
            let content = document.content.lowercased()
            let title = document.title.lowercased()
            
            var matchCount = 0
            var titleMatchCount = 0
            
            for term in queryTerms {
                if content.contains(term) {
                    matchCount += 1
                }
                if title.contains(term) {
                    titleMatchCount += 1
                }
            }
            
            // Title matches are worth more
            let score = (Double(matchCount) + Double(titleMatchCount) * 2) / Double(queryTerms.count * 3)
            return min(score, 1.0)
        }
        
        /// Calculate freshness score
        private func calculateFreshnessScore(timestamp: Date) -> Double {
            let daysSinceCreation = Date().timeIntervalSince(timestamp) / (24 * 60 * 60)
            
            // Decay function - documents lose relevance over time
            let decayRate = 0.01
            return exp(-decayRate * daysSinceCreation)
        }
        
        private func matchesUserLevel(_ difficulty: String, userLevel: String) -> Bool {
            let levelOrder = ["beginner", "intermediate", "advanced"]
            guard let docLevel = levelOrder.firstIndex(of: difficulty),
                  let userLevelIndex = levelOrder.firstIndex(of: userLevel) else {
                return true
            }
            
            // Match if document is at or below user level
            return docLevel <= userLevelIndex
        }
        
        private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
            guard a.count == b.count else { return 0 }
            
            let dotProduct = zip(a, b).map(*).reduce(0, +)
            let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
            let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
            
            guard magnitudeA > 0 && magnitudeB > 0 else { return 0 }
            return dotProduct / (magnitudeA * magnitudeB)
        }
    }
    
    struct UserContext {
        let interests: [String]
        let level: String
        let recentlyViewed: Set<String>
    }
}

// Example usage
Task {
    let engine = SemanticSearchEngine(apiKey: "your-api-key")
    let rankingEngine = SemanticSearchEngine.RankingEngine(openAI: engine.openAI)
    
    // Search and get initial results
    let initialResults = try await engine.search(query: "machine learning basics")
    
    // Apply advanced ranking with user context
    let userContext = SemanticSearchEngine.UserContext(
        interests: ["neural networks", "Python", "data science"],
        level: "intermediate",
        recentlyViewed: ["doc123", "doc456"]
    )
    
    let rankedResults = try await rankingEngine.rankResults(
        initialResults,
        query: "machine learning basics",
        userContext: userContext
    )
    
    // Display ranked results
    for (index, result) in rankedResults.enumerated() {
        print("\(index + 1). \(result.document.title) (Score: \(result.score))")
    }
}