import OpenAIKit
import Foundation

// Finding related documents
class RelatedDocumentsFinder {
    let openAI: OpenAI
    let vectorStore: VectorStore
    let similarityAnalyzer: SimilarityAnalyzer
    
    init(apiKey: String) {
        self.openAI = OpenAI(apiKey: apiKey)
        self.vectorStore = VectorStore()
        self.similarityAnalyzer = SimilarityAnalyzer(openAI: openAI)
    }
    
    // Find related documents for a given document
    func findRelated(
        to documentId: String,
        limit: Int = 5,
        strategy: RelatedSearchStrategy = .hybrid
    ) async throws -> [RelatedDocument] {
        // Get the original document
        guard let originalDoc = try await vectorStore.getDocument(id: documentId) else {
            throw RelatedDocumentError.documentNotFound
        }
        
        // Find related documents based on strategy
        let relatedDocs = try await findRelatedByStrategy(
            document: originalDoc,
            strategy: strategy,
            limit: limit * 2 // Get more candidates for filtering
        )
        
        // Analyze relationships
        let analyzedDocs = try await analyzeRelationships(
            original: originalDoc,
            candidates: relatedDocs
        )
        
        // Filter and rank
        let rankedDocs = rankRelatedDocuments(analyzedDocs)
            .prefix(limit)
            .map { $0 }
        
        return rankedDocs
    }
    
    // Find related documents by strategy
    private func findRelatedByStrategy(
        document: ChunkDocument,
        strategy: RelatedSearchStrategy,
        limit: Int
    ) async throws -> [SearchResult] {
        switch strategy {
        case .embedding:
            return try await findByEmbedding(document: document, limit: limit)
            
        case .content:
            return try await findByContent(document: document, limit: limit)
            
        case .metadata:
            return try await findByMetadata(document: document, limit: limit)
            
        case .hybrid:
            // Combine multiple strategies
            let embeddingResults = try await findByEmbedding(document: document, limit: limit / 2)
            let contentResults = try await findByContent(document: document, limit: limit / 2)
            let metadataResults = try await findByMetadata(document: document, limit: limit / 2)
            
            // Merge and deduplicate
            return mergeResults([embeddingResults, contentResults, metadataResults])
        }
    }
    
    // Find by embedding similarity
    private func findByEmbedding(document: ChunkDocument, limit: Int) async throws -> [SearchResult] {
        let results = try await vectorStore.search(
            embedding: document.embedding,
            limit: limit + 1 // +1 to exclude self
        )
        
        // Filter out the original document
        return results.filter { $0.document.id != document.id }
    }
    
    // Find by content analysis
    private func findByContent(document: ChunkDocument, limit: Int) async throws -> [SearchResult] {
        // Extract key concepts from document
        let concepts = try await extractKeyConcepts(from: document.content)
        
        // Generate embedding for concepts
        let conceptsText = concepts.joined(separator: " ")
        let embedding = try await generateEmbedding(for: conceptsText)
        
        // Search using concepts embedding
        return try await vectorStore.search(
            embedding: embedding,
            limit: limit
        ).filter { $0.document.id != document.id }
    }
    
    // Find by metadata similarity
    private func findByMetadata(document: ChunkDocument, limit: Int) async throws -> [SearchResult] {
        // Create metadata-based query
        let metadataQuery = """
        \(document.metadata.category) \(document.metadata.tags.joined(separator: " "))
        """
        
        let embedding = try await generateEmbedding(for: metadataQuery)
        
        return try await vectorStore.search(
            embedding: embedding,
            limit: limit
        ).filter { $0.document.id != document.id }
    }
    
    // Extract key concepts using LLM
    private func extractKeyConcepts(from content: String) async throws -> [String] {
        let request = CreateChatCompletionRequest(
            model: .gpt4,
            messages: [
                .system("Extract 5-10 key concepts or topics from the text."),
                .user("Text: \(content)\n\nKey concepts:")
            ],
            temperature: 0.3,
            maxTokens: 100
        )
        
        let response = try await openAI.chat.completions.create(request)
        let conceptsText = response.choices.first?.message.content ?? ""
        
        return conceptsText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    // Analyze relationships between documents
    private func analyzeRelationships(
        original: ChunkDocument,
        candidates: [SearchResult]
    ) async throws -> [RelatedDocument] {
        var relatedDocs: [RelatedDocument] = []
        
        for candidate in candidates {
            let relationship = try await similarityAnalyzer.analyze(
                document1: original,
                document2: candidate.document
            )
            
            relatedDocs.append(RelatedDocument(
                document: candidate.document,
                relationship: relationship,
                similarityScore: candidate.score
            ))
        }
        
        return relatedDocs
    }
    
    // Rank related documents
    private func rankRelatedDocuments(_ documents: [RelatedDocument]) -> [RelatedDocument] {
        return documents.sorted { doc1, doc2 in
            // Combined score from similarity and relationship strength
            let score1 = doc1.similarityScore * 0.6 + doc1.relationship.strength * 0.4
            let score2 = doc2.similarityScore * 0.6 + doc2.relationship.strength * 0.4
            return score1 > score2
        }
    }
    
    // Generate embedding
    private func generateEmbedding(for text: String) async throws -> [Double] {
        let request = CreateEmbeddingRequest(
            model: .textEmbeddingAda002,
            input: .text(text)
        )
        
        let response = try await openAI.embeddings.create(request)
        return response.data.first?.embedding ?? []
    }
    
    // Merge and deduplicate results
    private func mergeResults(_ resultSets: [[SearchResult]]) -> [SearchResult] {
        var merged: [String: SearchResult] = [:]
        
        for results in resultSets {
            for result in results {
                let id = result.document.id
                if let existing = merged[id] {
                    // Keep the one with higher score
                    if result.score > existing.score {
                        merged[id] = result
                    }
                } else {
                    merged[id] = result
                }
            }
        }
        
        return Array(merged.values).sorted { $0.score > $1.score }
    }
}

// Similarity analyzer
class SimilarityAnalyzer {
    let openAI: OpenAI
    
    init(openAI: OpenAI) {
        self.openAI = openAI
    }
    
    func analyze(
        document1: ChunkDocument,
        document2: ChunkDocument
    ) async throws -> DocumentRelationship {
        // Analyze semantic relationship
        let semanticRelation = try await analyzeSemanticRelation(
            content1: document1.content,
            content2: document2.content
        )
        
        // Calculate metadata similarity
        let metadataSimilarity = calculateMetadataSimilarity(
            metadata1: document1.metadata,
            metadata2: document2.metadata
        )
        
        // Determine relationship type
        let relationType = determineRelationType(
            semantic: semanticRelation,
            metadataSimilarity: metadataSimilarity
        )
        
        return DocumentRelationship(
            type: relationType,
            strength: semanticRelation.similarity,
            commonTopics: semanticRelation.commonTopics,
            explanation: semanticRelation.explanation
        )
    }
    
    private func analyzeSemanticRelation(
        content1: String,
        content2: String
    ) async throws -> SemanticRelation {
        let request = CreateChatCompletionRequest(
            model: .gpt4,
            messages: [
                .system("Analyze the semantic relationship between two documents."),
                .user("""
                Document 1: \(content1.prefix(500))...
                
                Document 2: \(content2.prefix(500))...
                
                Provide:
                1. Similarity score (0-1)
                2. Common topics
                3. Relationship explanation
                
                Format as JSON.
                """)
            ],
            temperature: 0.2,
            responseFormat: .jsonObject
        )
        
        let response = try await openAI.chat.completions.create(request)
        
        // Parse response (simplified for example)
        return SemanticRelation(
            similarity: 0.75,
            commonTopics: ["machine learning", "algorithms"],
            explanation: "Both documents discuss machine learning concepts"
        )
    }
    
    private func calculateMetadataSimilarity(
        metadata1: ChunkMetadata,
        metadata2: ChunkMetadata
    ) -> Double {
        var similarity = 0.0
        var factors = 0.0
        
        // Category similarity
        if metadata1.category == metadata2.category {
            similarity += 0.3
        }
        factors += 0.3
        
        // Author similarity
        if metadata1.author == metadata2.author {
            similarity += 0.2
        }
        factors += 0.2
        
        // Tags similarity
        let tags1 = Set(metadata1.tags)
        let tags2 = Set(metadata2.tags)
        let commonTags = tags1.intersection(tags2)
        let allTags = tags1.union(tags2)
        
        if !allTags.isEmpty {
            let tagSimilarity = Double(commonTags.count) / Double(allTags.count)
            similarity += tagSimilarity * 0.5
        }
        factors += 0.5
        
        return factors > 0 ? similarity / factors : 0
    }
    
    private func determineRelationType(
        semantic: SemanticRelation,
        metadataSimilarity: Double
    ) -> RelationType {
        if semantic.similarity > 0.8 && metadataSimilarity > 0.7 {
            return .stronglyRelated
        } else if semantic.similarity > 0.6 {
            return .related
        } else if metadataSimilarity > 0.5 {
            return .weaklyRelated
        } else {
            return .tangential
        }
    }
}

// Models
enum RelatedSearchStrategy {
    case embedding
    case content
    case metadata
    case hybrid
}

struct RelatedDocument {
    let document: ChunkDocument
    let relationship: DocumentRelationship
    let similarityScore: Double
}

struct DocumentRelationship {
    let type: RelationType
    let strength: Double
    let commonTopics: [String]
    let explanation: String
}

enum RelationType {
    case stronglyRelated
    case related
    case weaklyRelated
    case tangential
}

struct SemanticRelation {
    let similarity: Double
    let commonTopics: [String]
    let explanation: String
}

enum RelatedDocumentError: Error {
    case documentNotFound
}

// Extension for VectorStore
extension VectorStore {
    func getDocument(id: String) async throws -> ChunkDocument? {
        // In a real implementation, this would fetch from storage
        return nil
    }
}

// Usage example
func demonstrateRelatedDocuments() async throws {
    let finder = RelatedDocumentsFinder(apiKey: "your-api-key")
    
    // Find related documents using hybrid strategy
    let relatedDocs = try await finder.findRelated(
        to: "doc001_0",
        limit: 5,
        strategy: .hybrid
    )
    
    print("Related Documents:")
    for (index, related) in relatedDocs.enumerated() {
        print("\n\(index + 1). \(related.document.metadata.title)")
        print("   Relationship: \(related.relationship.type)")
        print("   Strength: \(String(format: "%.2f", related.relationship.strength))")
        print("   Common Topics: \(related.relationship.commonTopics.joined(separator: ", "))")
        print("   \(related.relationship.explanation)")
    }
    
    // Find related by specific strategy
    let contentRelated = try await finder.findRelated(
        to: "doc001_0",
        limit: 3,
        strategy: .content
    )
    
    print("\n\nContent-based Related Documents:")
    for related in contentRelated {
        print("- \(related.document.metadata.title)")
    }
}