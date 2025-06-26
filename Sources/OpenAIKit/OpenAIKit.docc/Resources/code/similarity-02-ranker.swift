import Foundation

// MARK: - Similarity Ranker

class SimilarityRanker {
    
    // Rank results by similarity score
    func rankResults<T: Embeddable>(
        query: String,
        queryEmbedding: [Float],
        candidates: [T],
        metric: SimilarityMetric = .cosine,
        topK: Int? = nil
    ) -> [RankedResult<T>] {
        var rankedResults: [RankedResult<T>] = []
        
        for candidate in candidates {
            let score = metric.calculate(queryEmbedding, candidate.embedding)
            let normalizedScore = SimilarityCalculator.normalizeSimilarity(score, metric: metric)
            
            let result = RankedResult(
                item: candidate,
                score: normalizedScore,
                relevanceScore: calculateRelevanceScore(
                    similarityScore: normalizedScore,
                    query: query,
                    content: candidate.content
                )
            )
            
            rankedResults.append(result)
        }
        
        // Sort by relevance score (descending)
        rankedResults.sort { $0.relevanceScore > $1.relevanceScore }
        
        // Return top K results if specified
        if let k = topK {
            return Array(rankedResults.prefix(k))
        }
        
        return rankedResults
    }
    
    // Multi-factor ranking with weights
    func rankWithMultipleFactors<T: Embeddable>(
        query: String,
        queryEmbedding: [Float],
        candidates: [T],
        factors: [RankingFactor] = RankingFactor.defaultFactors
    ) -> [RankedResult<T>] {
        var rankedResults: [RankedResult<T>] = []
        
        for candidate in candidates {
            var totalScore: Float = 0
            var factorScores: [String: Float] = [:]
            
            for factor in factors {
                let score = factor.calculate(
                    query: query,
                    queryEmbedding: queryEmbedding,
                    candidate: candidate
                )
                factorScores[factor.name] = score
                totalScore += score * factor.weight
            }
            
            let result = RankedResult(
                item: candidate,
                score: totalScore,
                relevanceScore: totalScore,
                factorScores: factorScores
            )
            
            rankedResults.append(result)
        }
        
        rankedResults.sort { $0.relevanceScore > $1.relevanceScore }
        
        return rankedResults
    }
    
    // Re-rank results using additional context
    func rerank<T: Embeddable>(
        results: [RankedResult<T>],
        context: RerankingContext
    ) -> [RankedResult<T>] {
        var rerankedResults = results
        
        // Apply boost factors
        for (index, result) in rerankedResults.enumerated() {
            var boostedScore = result.relevanceScore
            
            // Recency boost
            if let createdAt = result.item.metadata?["createdAt"] as? Date {
                let age = Date().timeIntervalSince(createdAt)
                let recencyBoost = context.recencyBoost(for: age)
                boostedScore *= recencyBoost
            }
            
            // Source boost
            if let source = result.item.metadata?["source"] as? String,
               let sourceBoost = context.sourceBoosts[source] {
                boostedScore *= sourceBoost
            }
            
            // Popularity boost
            if let viewCount = result.item.metadata?["viewCount"] as? Int {
                let popularityBoost = context.popularityBoost(for: viewCount)
                boostedScore *= popularityBoost
            }
            
            rerankedResults[index].relevanceScore = boostedScore
        }
        
        // Re-sort
        rerankedResults.sort { $0.relevanceScore > $1.relevanceScore }
        
        // Apply diversity if needed
        if context.diversityEnabled {
            rerankedResults = applyDiversity(to: rerankedResults, threshold: context.diversityThreshold)
        }
        
        return rerankedResults
    }
    
    // Calculate relevance score combining similarity and other factors
    private func calculateRelevanceScore(
        similarityScore: Float,
        query: String,
        content: String
    ) -> Float {
        var relevance = similarityScore
        
        // Boost for exact match
        if content.lowercased().contains(query.lowercased()) {
            relevance *= 1.2
        }
        
        // Boost for query terms
        let queryTerms = query.lowercased().split(separator: " ")
        let contentLower = content.lowercased()
        var termMatches = 0
        
        for term in queryTerms {
            if contentLower.contains(term) {
                termMatches += 1
            }
        }
        
        if queryTerms.count > 0 {
            let termMatchRatio = Float(termMatches) / Float(queryTerms.count)
            relevance *= (1 + termMatchRatio * 0.3)
        }
        
        return min(relevance, 1.0)  // Cap at 1.0
    }
    
    // Apply diversity to reduce redundant results
    private func applyDiversity<T: Embeddable>(
        to results: [RankedResult<T>],
        threshold: Float
    ) -> [RankedResult<T>] {
        guard !results.isEmpty else { return results }
        
        var diverseResults: [RankedResult<T>] = [results[0]]
        
        for candidate in results.dropFirst() {
            var isDiverse = true
            
            for selected in diverseResults {
                let similarity = SimilarityCalculator.cosineSimilarity(
                    candidate.item.embedding,
                    selected.item.embedding
                )
                
                if similarity > threshold {
                    isDiverse = false
                    break
                }
            }
            
            if isDiverse {
                diverseResults.append(candidate)
            }
        }
        
        return diverseResults
    }
}

// MARK: - Ranking Factors

struct RankingFactor {
    let name: String
    let weight: Float
    let calculate: (String, [Float], any Embeddable) -> Float
    
    static let defaultFactors = [
        RankingFactor(
            name: "Semantic Similarity",
            weight: 0.7,
            calculate: { _, queryEmb, candidate in
                SimilarityCalculator.cosineSimilarity(queryEmb, candidate.embedding)
            }
        ),
        RankingFactor(
            name: "Keyword Match",
            weight: 0.2,
            calculate: { query, _, candidate in
                let queryTerms = Set(query.lowercased().split(separator: " ").map(String.init))
                let contentTerms = Set(candidate.content.lowercased().split(separator: " ").map(String.init))
                let intersection = queryTerms.intersection(contentTerms)
                
                guard !queryTerms.isEmpty else { return 0 }
                return Float(intersection.count) / Float(queryTerms.count)
            }
        ),
        RankingFactor(
            name: "Length Penalty",
            weight: 0.1,
            calculate: { _, _, candidate in
                let idealLength = 200
                let length = candidate.content.count
                let deviation = abs(length - idealLength)
                return max(0, 1 - Float(deviation) / Float(idealLength))
            }
        )
    ]
}

// MARK: - Reranking Context

struct RerankingContext {
    let diversityEnabled: Bool
    let diversityThreshold: Float
    let sourceBoosts: [String: Float]
    let recencyBoost: (TimeInterval) -> Float
    let popularityBoost: (Int) -> Float
    
    static let `default` = RerankingContext(
        diversityEnabled: true,
        diversityThreshold: 0.85,
        sourceBoosts: [
            "official": 1.2,
            "verified": 1.1,
            "community": 0.9
        ],
        recencyBoost: { age in
            // Boost newer content
            let days = age / 86400
            if days < 7 {
                return 1.2
            } else if days < 30 {
                return 1.1
            } else if days < 365 {
                return 1.0
            } else {
                return 0.9
            }
        },
        popularityBoost: { viewCount in
            // Logarithmic boost for popular content
            if viewCount > 1000 {
                return 1.1
            } else if viewCount > 100 {
                return 1.05
            } else {
                return 1.0
            }
        }
    )
}

// MARK: - Models

protocol Embeddable {
    var id: String { get }
    var content: String { get }
    var embedding: [Float] { get }
    var metadata: [String: Any]? { get }
}

struct RankedResult<T: Embeddable> {
    let item: T
    var score: Float
    var relevanceScore: Float
    var factorScores: [String: Float]?
    
    var explanation: String {
        var parts: [String] = []
        
        parts.append("Overall Score: \(String(format: "%.2f", relevanceScore * 100))%")
        
        if let factors = factorScores {
            parts.append("Factors:")
            for (name, score) in factors.sorted(by: { $0.value > $1.value }) {
                parts.append("  - \(name): \(String(format: "%.2f", score * 100))%")
            }
        }
        
        return parts.joined(separator: "\n")
    }
}