import OpenAIKit
import Foundation

// Search interface implementation
class SemanticSearchInterface {
    let openAI: OpenAI
    let vectorStore: VectorStore
    let queryProcessor: QueryProcessor
    
    init(apiKey: String) {
        self.openAI = OpenAI(apiKey: apiKey)
        self.vectorStore = VectorStore()
        self.queryProcessor = QueryProcessor(openAI: openAI)
    }
    
    // Main search function
    func search(query: String, filters: SearchFilters? = nil) async throws -> SearchResponse {
        // Process and enhance query
        let processedQuery = try await queryProcessor.process(query)
        
        // Generate embedding for search query
        let queryEmbedding = try await generateEmbedding(for: processedQuery.enhancedQuery)
        
        // Search vector store
        var results = try await vectorStore.search(
            embedding: queryEmbedding,
            limit: filters?.limit ?? 10
        )
        
        // Apply filters
        if let filters = filters {
            results = applyFilters(results, filters: filters)
        }
        
        // Re-rank results using LLM
        let rerankedResults = try await rerankResults(
            query: processedQuery.enhancedQuery,
            results: results
        )
        
        // Generate search response
        return SearchResponse(
            query: query,
            processedQuery: processedQuery,
            results: rerankedResults,
            totalResults: rerankedResults.count,
            searchTime: Date()
        )
    }
    
    // Generate embedding for text
    private func generateEmbedding(for text: String) async throws -> [Double] {
        let request = CreateEmbeddingRequest(
            model: .textEmbeddingAda002,
            input: .text(text)
        )
        
        let response = try await openAI.embeddings.create(request)
        return response.data.first?.embedding ?? []
    }
    
    // Apply search filters
    private func applyFilters(_ results: [SearchResult], filters: SearchFilters) -> [SearchResult] {
        return results.filter { result in
            let metadata = result.document.metadata
            
            // Category filter
            if let category = filters.category,
               metadata.category != category {
                return false
            }
            
            // Author filter
            if let author = filters.author,
               !metadata.author.lowercased().contains(author.lowercased()) {
                return false
            }
            
            // Tags filter
            if let tags = filters.tags,
               Set(metadata.tags).intersection(tags).isEmpty {
                return false
            }
            
            // Score threshold
            if let minScore = filters.minScore,
               result.score < minScore {
                return false
            }
            
            return true
        }
    }
    
    // Re-rank results using LLM
    private func rerankResults(query: String, results: [SearchResult]) async throws -> [RankedSearchResult] {
        guard !results.isEmpty else { return [] }
        
        // Create re-ranking prompt
        let prompt = """
        Query: "\(query)"
        
        Please rank the following search results from most to least relevant.
        Consider both semantic similarity and practical usefulness.
        
        Results:
        \(results.enumerated().map { index, result in
            "\(index + 1). \(result.document.metadata.title)\n   \(result.document.content.prefix(200))..."
        }.joined(separator: "\n\n"))
        
        Return a JSON array of indices in order of relevance.
        """
        
        let request = CreateChatCompletionRequest(
            model: .gpt4,
            messages: [
                .system("You are a search result ranking expert."),
                .user(prompt)
            ],
            responseFormat: .jsonObject
        )
        
        let response = try await openAI.chat.completions.create(request)
        
        // Parse ranking and create ranked results
        var rankedResults: [RankedSearchResult] = []
        
        // For simplicity, use original order with enhanced scoring
        for (index, result) in results.enumerated() {
            rankedResults.append(RankedSearchResult(
                searchResult: result,
                rank: index + 1,
                relevanceScore: result.score * (1.0 - Double(index) * 0.05),
                explanation: generateExplanation(query: query, result: result)
            ))
        }
        
        return rankedResults
    }
    
    // Generate relevance explanation
    private func generateExplanation(query: String, result: SearchResult) -> String {
        // Simple explanation based on score
        if result.score > 0.9 {
            return "Highly relevant - strong semantic match"
        } else if result.score > 0.7 {
            return "Good match - relevant content"
        } else {
            return "Partial match - some relevant information"
        }
    }
}

// Query processor for enhancing search queries
class QueryProcessor {
    let openAI: OpenAI
    
    init(openAI: OpenAI) {
        self.openAI = openAI
    }
    
    func process(_ query: String) async throws -> ProcessedQuery {
        // Expand query with synonyms and related terms
        let expandedQuery = try await expandQuery(query)
        
        // Extract intent and entities
        let intent = try await extractIntent(query)
        
        return ProcessedQuery(
            originalQuery: query,
            enhancedQuery: expandedQuery,
            intent: intent,
            keywords: extractKeywords(query)
        )
    }
    
    private func expandQuery(_ query: String) async throws -> String {
        let request = CreateChatCompletionRequest(
            model: .gpt4,
            messages: [
                .system("Expand the search query with relevant synonyms and related terms."),
                .user("Query: \(query)\nExpanded query:")
            ],
            temperature: 0.3,
            maxTokens: 100
        )
        
        let response = try await openAI.chat.completions.create(request)
        return response.choices.first?.message.content ?? query
    }
    
    private func extractIntent(_ query: String) async throws -> SearchIntent {
        // Simple intent classification
        if query.lowercased().contains("how") || query.lowercased().contains("what") {
            return .informational
        } else if query.lowercased().contains("find") || query.lowercased().contains("locate") {
            return .navigational
        } else {
            return .exploratory
        }
    }
    
    private func extractKeywords(_ query: String) -> [String] {
        // Simple keyword extraction
        let stopWords = Set(["the", "is", "at", "which", "on", "a", "an", "and", "or", "but"])
        return query.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !stopWords.contains($0) && $0.count > 2 }
    }
}

// Search models
struct SearchFilters {
    let category: String?
    let author: String?
    let tags: Set<String>?
    let minScore: Double?
    let limit: Int
}

struct ProcessedQuery {
    let originalQuery: String
    let enhancedQuery: String
    let intent: SearchIntent
    let keywords: [String]
}

enum SearchIntent {
    case informational
    case navigational
    case exploratory
}

struct SearchResponse {
    let query: String
    let processedQuery: ProcessedQuery
    let results: [RankedSearchResult]
    let totalResults: Int
    let searchTime: Date
}

struct RankedSearchResult {
    let searchResult: SearchResult
    let rank: Int
    let relevanceScore: Double
    let explanation: String
}

// Usage example
func demonstrateSearch() async throws {
    let searchInterface = SemanticSearchInterface(apiKey: "your-api-key")
    
    // Simple search
    let response = try await searchInterface.search(
        query: "machine learning algorithms"
    )
    
    print("Search Results for: \(response.query)")
    print("Enhanced Query: \(response.processedQuery.enhancedQuery)")
    print("\nResults:")
    
    for result in response.results {
        print("\n\(result.rank). \(result.searchResult.document.metadata.title)")
        print("   Score: \(result.relevanceScore)")
        print("   \(result.explanation)")
    }
    
    // Search with filters
    let filteredResponse = try await searchInterface.search(
        query: "neural networks",
        filters: SearchFilters(
            category: "Technology",
            author: nil,
            tags: Set(["AI", "Deep Learning"]),
            minScore: 0.7,
            limit: 5
        )
    )
    
    print("\n\nFiltered Search Results: \(filteredResponse.totalResults) results")
}