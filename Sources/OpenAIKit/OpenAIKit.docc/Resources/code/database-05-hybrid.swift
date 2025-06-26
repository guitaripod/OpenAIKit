import Foundation
import NaturalLanguage

// MARK: - Hybrid Search Engine

/// Combines semantic search with text-based search for improved results
class HybridSearchEngine {
    private let vectorDatabase: VectorDatabase
    private let textSearchEngine: TextSearchEngine
    private let embeddingGenerator: EmbeddingGenerator
    private let knnEngine: KNNSearchEngine
    private let queue = DispatchQueue(label: "hybridsearch", attributes: .concurrent)
    
    // Search configuration
    struct SearchConfig {
        let semanticWeight: Float  // 0.0 to 1.0
        let textWeight: Float      // 0.0 to 1.0
        let reranking: RerankingStrategy
        let minConfidence: Float
        let boostFactors: BoostFactors
        
        struct BoostFactors {
            let recency: Float      // Boost recent documents
            let popularity: Float   // Boost frequently accessed
            let exactMatch: Float   // Boost exact phrase matches
            let fieldMatch: Float   // Boost matches in specific fields
        }
        
        enum RerankingStrategy {
            case reciprocalRankFusion
            case linearCombination
            case learned(model: RerankingModel)
            case crossEncoder
        }
        
        static let `default` = SearchConfig(
            semanticWeight: 0.6,
            textWeight: 0.4,
            reranking: .reciprocalRankFusion,
            minConfidence: 0.3,
            boostFactors: BoostFactors(
                recency: 1.2,
                popularity: 1.1,
                exactMatch: 2.0,
                fieldMatch: 1.5
            )
        )
    }
    
    init(
        vectorDatabase: VectorDatabase,
        dimension: Int
    ) {
        self.vectorDatabase = vectorDatabase
        self.textSearchEngine = TextSearchEngine()
        self.embeddingGenerator = EmbeddingGenerator()
        self.knnEngine = KNNSearchEngine(
            dimension: dimension,
            metric: .cosine,
            algorithm: .approximateNearestNeighbor(numTrees: 10)
        )
    }
    
    // MARK: - Hybrid Search
    
    func search(
        query: String,
        limit: Int = 10,
        filters: SearchFilters? = nil,
        config: SearchConfig = .default
    ) async throws -> [HybridSearchResult] {
        // Generate query embedding for semantic search
        let queryEmbedding = try await embeddingGenerator.generateEmbedding(for: query)
        
        // Perform parallel searches
        async let semanticResults = performSemanticSearch(
            embedding: queryEmbedding,
            limit: limit * 3,  // Get more candidates for reranking
            filters: filters
        )
        
        async let textResults = performTextSearch(
            query: query,
            limit: limit * 3,
            filters: filters
        )
        
        // Wait for both results
        let (semantic, text) = try await (semanticResults, textResults)
        
        // Combine and rerank results
        let combinedResults = await combineResults(
            semantic: semantic,
            text: text,
            query: query,
            queryEmbedding: queryEmbedding,
            config: config
        )
        
        // Apply final filtering and limit
        let filtered = combinedResults.filter { $0.confidence >= config.minConfidence }
        return Array(filtered.prefix(limit))
    }
    
    // MARK: - Semantic Search
    
    private func performSemanticSearch(
        embedding: [Float],
        limit: Int,
        filters: SearchFilters?
    ) async throws -> [SemanticSearchResult] {
        // Use vector database for similarity search
        let vectorQuery = VectorQuery(
            vector: embedding,
            limit: limit,
            threshold: 0.0,  // Get all results, filter later
            collection: filters?.collection,
            filter: filters?.predicate
        )
        
        let results = try await vectorDatabase.search(query: vectorQuery)
        
        return results.map { result in
            SemanticSearchResult(
                id: result.id,
                content: result.content,
                similarity: result.similarity,
                embedding: result.embedding,
                metadata: result.metadata
            )
        }
    }
    
    // MARK: - Text Search
    
    private func performTextSearch(
        query: String,
        limit: Int,
        filters: SearchFilters?
    ) async -> [TextSearchResult] {
        await textSearchEngine.search(
            query: query,
            limit: limit,
            filters: filters
        )
    }
    
    // MARK: - Result Combination
    
    private func combineResults(
        semantic: [SemanticSearchResult],
        text: [TextSearchResult],
        query: String,
        queryEmbedding: [Float],
        config: SearchConfig
    ) async -> [HybridSearchResult] {
        var combinedScores: [String: HybridScore] = [:]
        
        // Process semantic results
        for (rank, result) in semantic.enumerated() {
            let score = HybridScore(
                semanticScore: result.similarity,
                semanticRank: rank + 1,
                textScore: 0,
                textRank: Int.max
            )
            combinedScores[result.id] = score
        }
        
        // Process text results
        for (rank, result) in text.enumerated() {
            if var score = combinedScores[result.id] {
                score.textScore = result.relevance
                score.textRank = rank + 1
                combinedScores[result.id] = score
            } else {
                let score = HybridScore(
                    semanticScore: 0,
                    semanticRank: Int.max,
                    textScore: result.relevance,
                    textRank: rank + 1
                )
                combinedScores[result.id] = score
            }
        }
        
        // Apply reranking strategy
        let rerankedResults = await applyReranking(
            scores: combinedScores,
            semantic: semantic,
            text: text,
            query: query,
            queryEmbedding: queryEmbedding,
            config: config
        )
        
        return rerankedResults
    }
    
    // MARK: - Reranking Strategies
    
    private func applyReranking(
        scores: [String: HybridScore],
        semantic: [SemanticSearchResult],
        text: [TextSearchResult],
        query: String,
        queryEmbedding: [Float],
        config: SearchConfig
    ) async -> [HybridSearchResult] {
        switch config.reranking {
        case .reciprocalRankFusion:
            return applyRRF(scores: scores, semantic: semantic, text: text, config: config)
            
        case .linearCombination:
            return applyLinearCombination(scores: scores, semantic: semantic, text: text, config: config)
            
        case .learned(let model):
            return await applyLearnedReranking(
                scores: scores,
                semantic: semantic,
                text: text,
                query: query,
                model: model,
                config: config
            )
            
        case .crossEncoder:
            return await applyCrossEncoderReranking(
                scores: scores,
                semantic: semantic,
                text: text,
                query: query,
                queryEmbedding: queryEmbedding,
                config: config
            )
        }
    }
    
    private func applyRRF(
        scores: [String: HybridScore],
        semantic: [SemanticSearchResult],
        text: [TextSearchResult],
        config: SearchConfig
    ) -> [HybridSearchResult] {
        let k = 60.0  // RRF constant
        
        var results: [HybridSearchResult] = []
        
        // Create result lookup maps
        let semanticMap = Dictionary(uniqueKeysWithValues: semantic.map { ($0.id, $0) })
        let textMap = Dictionary(uniqueKeysWithValues: text.map { ($0.id, $0) })
        
        for (id, score) in scores {
            let semanticRRF = config.semanticWeight / (k + Double(score.semanticRank))
            let textRRF = config.textWeight / (k + Double(score.textRank))
            let combinedScore = Float(semanticRRF + textRRF)
            
            // Get content and metadata from available results
            let content = semanticMap[id]?.content ?? textMap[id]?.content ?? ""
            let metadata = semanticMap[id]?.metadata ?? textMap[id]?.metadata
            
            // Apply boost factors
            var boostedScore = combinedScore
            
            if let metadata = metadata {
                // Recency boost
                if let timestamp = metadata["timestamp"] as? Date {
                    let age = Date().timeIntervalSince(timestamp)
                    let recencyFactor = exp(-age / (30 * 24 * 3600))  // Decay over 30 days
                    boostedScore *= config.boostFactors.recency * Float(recencyFactor)
                }
                
                // Popularity boost
                if let accessCount = metadata["accessCount"] as? Int {
                    let popularityFactor = log(Double(accessCount + 1)) / log(10.0)
                    boostedScore *= config.boostFactors.popularity * Float(popularityFactor)
                }
            }
            
            // Exact match boost
            if content.lowercased().contains(query.lowercased()) {
                boostedScore *= config.boostFactors.exactMatch
            }
            
            results.append(HybridSearchResult(
                id: id,
                content: content,
                confidence: boostedScore,
                semanticScore: score.semanticScore,
                textScore: score.textScore,
                metadata: metadata,
                highlights: extractHighlights(from: content, query: query)
            ))
        }
        
        return results.sorted { $0.confidence > $1.confidence }
    }
    
    private func applyLinearCombination(
        scores: [String: HybridScore],
        semantic: [SemanticSearchResult],
        text: [TextSearchResult],
        config: SearchConfig
    ) -> [HybridSearchResult] {
        var results: [HybridSearchResult] = []
        
        let semanticMap = Dictionary(uniqueKeysWithValues: semantic.map { ($0.id, $0) })
        let textMap = Dictionary(uniqueKeysWithValues: text.map { ($0.id, $0) })
        
        for (id, score) in scores {
            let combinedScore = config.semanticWeight * score.semanticScore +
                               config.textWeight * score.textScore
            
            let content = semanticMap[id]?.content ?? textMap[id]?.content ?? ""
            let metadata = semanticMap[id]?.metadata ?? textMap[id]?.metadata
            
            results.append(HybridSearchResult(
                id: id,
                content: content,
                confidence: combinedScore,
                semanticScore: score.semanticScore,
                textScore: score.textScore,
                metadata: metadata,
                highlights: extractHighlights(from: content, query: query)
            ))
        }
        
        return results.sorted { $0.confidence > $1.confidence }
    }
    
    private func applyLearnedReranking(
        scores: [String: HybridScore],
        semantic: [SemanticSearchResult],
        text: [TextSearchResult],
        query: String,
        model: RerankingModel,
        config: SearchConfig
    ) async -> [HybridSearchResult] {
        // Use a learned model to rerank results
        var results: [HybridSearchResult] = []
        
        let semanticMap = Dictionary(uniqueKeysWithValues: semantic.map { ($0.id, $0) })
        let textMap = Dictionary(uniqueKeysWithValues: text.map { ($0.id, $0) })
        
        for (id, score) in scores {
            let content = semanticMap[id]?.content ?? textMap[id]?.content ?? ""
            let metadata = semanticMap[id]?.metadata ?? textMap[id]?.metadata
            
            // Extract features for the model
            let features = extractFeatures(
                query: query,
                content: content,
                semanticScore: score.semanticScore,
                textScore: score.textScore,
                metadata: metadata
            )
            
            // Get model prediction
            let modelScore = await model.predict(features: features)
            
            results.append(HybridSearchResult(
                id: id,
                content: content,
                confidence: modelScore,
                semanticScore: score.semanticScore,
                textScore: score.textScore,
                metadata: metadata,
                highlights: extractHighlights(from: content, query: query)
            ))
        }
        
        return results.sorted { $0.confidence > $1.confidence }
    }
    
    private func applyCrossEncoderReranking(
        scores: [String: HybridScore],
        semantic: [SemanticSearchResult],
        text: [TextSearchResult],
        query: String,
        queryEmbedding: [Float],
        config: SearchConfig
    ) async -> [HybridSearchResult] {
        // Cross-encoder reranking for highest accuracy
        var results: [HybridSearchResult] = []
        
        let semanticMap = Dictionary(uniqueKeysWithValues: semantic.map { ($0.id, $0) })
        let textMap = Dictionary(uniqueKeysWithValues: text.map { ($0.id, $0) })
        
        // Process in batches for efficiency
        let batchSize = 10
        var processedResults: [(id: String, result: HybridSearchResult)] = []
        
        for (id, score) in scores {
            let content = semanticMap[id]?.content ?? textMap[id]?.content ?? ""
            let metadata = semanticMap[id]?.metadata ?? textMap[id]?.metadata
            
            // Generate cross-encoder features
            let crossScore = await computeCrossEncoderScore(
                query: query,
                queryEmbedding: queryEmbedding,
                content: content,
                contentEmbedding: semanticMap[id]?.embedding
            )
            
            let result = HybridSearchResult(
                id: id,
                content: content,
                confidence: crossScore,
                semanticScore: score.semanticScore,
                textScore: score.textScore,
                metadata: metadata,
                highlights: extractHighlights(from: content, query: query)
            )
            
            processedResults.append((id, result))
        }
        
        return processedResults
            .sorted { $0.result.confidence > $1.result.confidence }
            .map { $0.result }
    }
    
    // MARK: - Helper Methods
    
    private func extractHighlights(from content: String, query: String) -> [TextHighlight] {
        var highlights: [TextHighlight] = []
        
        // Tokenize query and content
        let queryTokens = query.lowercased().split(separator: " ").map(String.init)
        let contentLower = content.lowercased()
        
        for token in queryTokens {
            var searchRange = contentLower.startIndex..<contentLower.endIndex
            
            while let range = contentLower.range(of: token, options: [], range: searchRange) {
                let startOffset = contentLower.distance(from: contentLower.startIndex, to: range.lowerBound)
                let endOffset = contentLower.distance(from: contentLower.startIndex, to: range.upperBound)
                
                highlights.append(TextHighlight(
                    startOffset: startOffset,
                    endOffset: endOffset,
                    score: 1.0
                ))
                
                searchRange = range.upperBound..<contentLower.endIndex
            }
        }
        
        return highlights
    }
    
    private func extractFeatures(
        query: String,
        content: String,
        semanticScore: Float,
        textScore: Float,
        metadata: [String: Any]?
    ) -> [Float] {
        var features: [Float] = []
        
        // Basic scores
        features.append(semanticScore)
        features.append(textScore)
        
        // Length features
        features.append(Float(query.count))
        features.append(Float(content.count))
        features.append(Float(content.count) / Float(query.count))
        
        // Term overlap
        let queryTerms = Set(query.lowercased().split(separator: " "))
        let contentTerms = Set(content.lowercased().split(separator: " "))
        let overlap = Float(queryTerms.intersection(contentTerms).count) / Float(queryTerms.count)
        features.append(overlap)
        
        // Metadata features
        if let metadata = metadata {
            features.append(Float(metadata["accessCount"] as? Int ?? 0))
            features.append(Float(metadata["rating"] as? Double ?? 0.0))
        } else {
            features.append(0)
            features.append(0)
        }
        
        return features
    }
    
    private func computeCrossEncoderScore(
        query: String,
        queryEmbedding: [Float],
        content: String,
        contentEmbedding: [Float]?
    ) async -> Float {
        // Simplified cross-encoder score computation
        // In practice, this would use a neural network model
        
        var score: Float = 0.0
        
        // Semantic similarity if embedding available
        if let contentEmbedding = contentEmbedding {
            score += SimilarityCalculator.cosineSimilarity(queryEmbedding, contentEmbedding) * 0.5
        }
        
        // Lexical similarity
        let queryTerms = Set(query.lowercased().split(separator: " "))
        let contentTerms = Set(content.lowercased().split(separator: " "))
        let jaccard = Float(queryTerms.intersection(contentTerms).count) /
                     Float(queryTerms.union(contentTerms).count)
        score += jaccard * 0.3
        
        // Position bonus for early matches
        if let firstMatch = content.lowercased().range(of: query.lowercased()) {
            let position = content.distance(from: content.startIndex, to: firstMatch.lowerBound)
            let positionScore = 1.0 - Float(position) / Float(content.count)
            score += positionScore * 0.2
        }
        
        return score
    }
}

// MARK: - Text Search Engine

class TextSearchEngine {
    private let tokenizer = NLTokenizer(unit: .word)
    private var invertedIndex: [String: Set<String>] = [:]
    private var documentFrequency: [String: Int] = [:]
    private var documents: [String: IndexedDocument] = [:]
    
    struct IndexedDocument {
        let id: String
        let content: String
        let tokens: [String]
        let termFrequency: [String: Int]
        let metadata: [String: Any]?
    }
    
    func indexDocument(id: String, content: String, metadata: [String: Any]? = nil) {
        // Tokenize content
        tokenizer.string = content
        var tokens: [String] = []
        var termFreq: [String: Int] = [:]
        
        tokenizer.enumerateTokens(in: content.startIndex..<content.endIndex) { range, _ in
            let token = String(content[range]).lowercased()
            tokens.append(token)
            termFreq[token, default: 0] += 1
            
            // Update inverted index
            invertedIndex[token, default: Set()].insert(id)
            
            return true
        }
        
        // Update document frequency
        for token in Set(tokens) {
            documentFrequency[token, default: 0] += 1
        }
        
        // Store document
        documents[id] = IndexedDocument(
            id: id,
            content: content,
            tokens: tokens,
            termFrequency: termFreq,
            metadata: metadata
        )
    }
    
    func search(
        query: String,
        limit: Int,
        filters: SearchFilters?
    ) async -> [TextSearchResult] {
        // Tokenize query
        tokenizer.string = query
        var queryTokens: [String] = []
        
        tokenizer.enumerateTokens(in: query.startIndex..<query.endIndex) { range, _ in
            queryTokens.append(String(query[range]).lowercased())
            return true
        }
        
        // Find candidate documents
        var candidates = Set<String>()
        for token in queryTokens {
            if let docs = invertedIndex[token] {
                candidates.formUnion(docs)
            }
        }
        
        // Score documents using TF-IDF
        var scores: [(id: String, score: Float)] = []
        let totalDocs = documents.count
        
        for docId in candidates {
            guard let doc = documents[docId] else { continue }
            
            // Apply filters
            if let filters = filters {
                if let collection = filters.collection,
                   let docCollection = doc.metadata?["collection"] as? String,
                   collection != docCollection {
                    continue
                }
            }
            
            // Calculate TF-IDF score
            var score: Float = 0.0
            
            for queryToken in queryTokens {
                let tf = Float(doc.termFrequency[queryToken] ?? 0) / Float(doc.tokens.count)
                let df = Float(documentFrequency[queryToken] ?? 0)
                let idf = log(Float(totalDocs) / (df + 1.0))
                
                score += tf * idf
            }
            
            scores.append((id: docId, score: score))
        }
        
        // Sort by score and limit
        scores.sort { $0.score > $1.score }
        let topResults = Array(scores.prefix(limit))
        
        // Convert to results
        return topResults.compactMap { result in
            guard let doc = documents[result.id] else { return nil }
            
            return TextSearchResult(
                id: doc.id,
                content: doc.content,
                relevance: result.score,
                metadata: doc.metadata,
                matchedTerms: Set(queryTokens).intersection(Set(doc.tokens))
            )
        }
    }
}

// MARK: - Models

struct HybridSearchResult {
    let id: String
    let content: String
    let confidence: Float
    let semanticScore: Float
    let textScore: Float
    let metadata: [String: Any]?
    let highlights: [TextHighlight]
}

struct SemanticSearchResult {
    let id: String
    let content: String
    let similarity: Float
    let embedding: [Float]
    let metadata: [String: Any]?
}

struct TextSearchResult {
    let id: String
    let content: String
    let relevance: Float
    let metadata: [String: Any]?
    let matchedTerms: Set<String>
}

struct TextHighlight {
    let startOffset: Int
    let endOffset: Int
    let score: Float
}

struct SearchFilters {
    let collection: String?
    let predicate: NSPredicate?
    let dateRange: DateRange?
    let tags: Set<String>?
    
    struct DateRange {
        let start: Date
        let end: Date
    }
}

struct HybridScore {
    var semanticScore: Float
    var semanticRank: Int
    var textScore: Float
    var textRank: Int
}

// MARK: - Placeholder Types

class EmbeddingGenerator {
    func generateEmbedding(for text: String) async throws -> [Float] {
        // Placeholder - would call OpenAI API
        return Array(repeating: 0.0, count: 1536)
    }
}

class RerankingModel {
    func predict(features: [Float]) async -> Float {
        // Placeholder - would use trained model
        return features.reduce(0, +) / Float(features.count)
    }
}

class SimilarityCalculator {
    static func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        // Placeholder - would use optimized implementation
        return 0.5
    }
}