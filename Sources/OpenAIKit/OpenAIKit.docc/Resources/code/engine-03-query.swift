import Foundation
import OpenAIKit

extension SemanticSearchEngine {
    /// Search for documents matching the query
    func search(
        query: String,
        limit: Int = 10,
        threshold: Double = 0.7
    ) async throws -> [SearchResult] {
        guard !documents.isEmpty else {
            throw SearchError.indexNotBuilt
        }
        
        // Expand query for better results
        let expandedQuery = try await expandQuery(query)
        
        // Generate embedding for the expanded query
        let queryEmbedding = try await generateEmbedding(for: expandedQuery)
        
        // Calculate similarities
        var results: [(document: SearchDocument, score: Double)] = []
        
        for document in documents {
            guard let docEmbedding = embeddings[document.id] else { continue }
            
            let similarity = cosineSimilarity(queryEmbedding, docEmbedding)
            if similarity >= threshold {
                results.append((document, similarity))
            }
        }
        
        // Sort by relevance and limit results
        results.sort { $0.score > $1.score }
        let topResults = Array(results.prefix(limit))
        
        // Generate highlights for results
        return try await generateHighlights(for: topResults, query: query)
    }
    
    /// Expand query with synonyms and related terms
    private func expandQuery(_ query: String) async throws -> String {
        let prompt = """
        Expand this search query with synonyms and related terms.
        Keep the expansion concise and relevant.
        
        Query: "\(query)"
        
        Expanded query:
        """
        
        let request = CreateChatCompletionRequest(
            model: .gpt3_5Turbo,
            messages: [
                .init(role: .user, content: .text(prompt))
            ],
            temperature: 0.3,
            maxTokens: 100
        )
        
        let response = try await openAI.chat.create(chatCompletion: request)
        let expandedQuery = response.choices.first?.message.content?.string ?? query
        
        return "\(query) \(expandedQuery)"
    }
    
    /// Advanced search with filters
    func advancedSearch(
        query: String,
        filters: SearchFilters,
        limit: Int = 10
    ) async throws -> [SearchResult] {
        // Get initial results
        var results = try await search(query: query, limit: limit * 2)
        
        // Apply filters
        results = results.filter { result in
            // Date filter
            if let afterDate = filters.afterDate {
                guard result.document.timestamp >= afterDate else { return false }
            }
            
            // Metadata filters
            for (key, value) in filters.metadata {
                guard let docValue = result.document.metadata[key] as? String,
                      docValue == value else { return false }
            }
            
            return true
        }
        
        // Apply boosting
        if !filters.boostTerms.isEmpty {
            results = applyBoost(to: results, boostTerms: filters.boostTerms)
        }
        
        return Array(results.prefix(limit))
    }
    
    /// Apply score boosting for specific terms
    private func applyBoost(
        to results: [SearchResult],
        boostTerms: [String]
    ) -> [SearchResult] {
        return results.map { result in
            var boostedScore = result.score
            
            for term in boostTerms {
                let termLower = term.lowercased()
                let content = result.document.content.lowercased()
                let title = result.document.title.lowercased()
                
                // Boost if term appears in title (higher boost)
                if title.contains(termLower) {
                    boostedScore *= 1.5
                }
                
                // Boost if term appears in content
                if content.contains(termLower) {
                    boostedScore *= 1.2
                }
            }
            
            return SearchResult(
                document: result.document,
                score: min(boostedScore, 1.0), // Cap at 1.0
                highlights: result.highlights
            )
        }.sorted { $0.score > $1.score }
    }
    
    /// Generate contextual highlights
    private func generateHighlights(
        for results: [(document: SearchDocument, score: Double)],
        query: String
    ) async throws -> [SearchResult] {
        let highlights = try await withThrowingTaskGroup(of: (Int, [String]).self) { group in
            for (index, result) in results.enumerated() {
                group.addTask {
                    let highlights = try await self.extractHighlights(
                        from: result.document.content,
                        query: query
                    )
                    return (index, highlights)
                }
            }
            
            var highlightMap: [Int: [String]] = [:]
            for try await (index, highlights) in group {
                highlightMap[index] = highlights
            }
            return highlightMap
        }
        
        return results.enumerated().map { index, result in
            SearchResult(
                document: result.document,
                score: result.score,
                highlights: highlights[index] ?? []
            )
        }
    }
    
    /// Extract relevant text snippets
    private func extractHighlights(
        from content: String,
        query: String
    ) async throws -> [String] {
        // Simple implementation - find sentences containing query terms
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let queryTerms = query.lowercased().split(separator: " ").map(String.init)
        
        var highlights: [String] = []
        for sentence in sentences {
            let lowerSentence = sentence.lowercased()
            if queryTerms.contains(where: { lowerSentence.contains($0) }) {
                highlights.append(sentence.trimmingCharacters(in: .whitespaces))
            }
        }
        
        return Array(highlights.prefix(3)) // Return top 3 highlights
    }
    
    struct SearchFilters {
        var afterDate: Date?
        var metadata: [String: String] = [:]
        var boostTerms: [String] = []
    }
}

// Example usage
Task {
    let engine = SemanticSearchEngine(apiKey: "your-api-key")
    
    // Simple search
    let results = try await engine.search(
        query: "Swift programming async",
        limit: 5,
        threshold: 0.6
    )
    
    for result in results {
        print("Document: \(result.document.title)")
        print("Score: \(result.score)")
        print("Highlights:")
        result.highlights.forEach { print("  - \($0)") }
        print("---")
    }
    
    // Advanced search with filters
    let filters = SemanticSearchEngine.SearchFilters(
        afterDate: Date().addingTimeInterval(-7 * 24 * 60 * 60), // Last week
        metadata: ["category": "AI"],
        boostTerms: ["neural networks", "deep learning"]
    )
    
    let advancedResults = try await engine.advancedSearch(
        query: "machine learning",
        filters: filters,
        limit: 10
    )
}