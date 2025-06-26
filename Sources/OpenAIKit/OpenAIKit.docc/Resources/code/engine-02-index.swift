import Foundation
import OpenAIKit

extension SemanticSearchEngine {
    /// Build or rebuild the search index
    func buildIndex(from documents: [SearchDocument]) async throws {
        // Clear existing data
        self.documents.removeAll()
        self.embeddings.removeAll()
        
        // Process documents in batches for efficiency
        let batchSize = 10
        for batch in documents.chunked(into: batchSize) {
            try await processBatch(batch)
        }
        
        print("Index built with \(documents.count) documents")
    }
    
    /// Process a batch of documents
    private func processBatch(_ batch: [SearchDocument]) async throws {
        // Generate embeddings concurrently
        try await withThrowingTaskGroup(of: (String, [Double]).self) { group in
            for document in batch {
                group.addTask {
                    let text = self.preprocessText(document)
                    let embedding = try await self.generateEmbedding(for: text)
                    return (document.id, embedding)
                }
                self.documents.append(document)
            }
            
            // Collect results
            for try await (docId, embedding) in group {
                self.embeddings[docId] = embedding
            }
        }
    }
    
    /// Preprocess text for better embedding quality
    private func preprocessText(_ document: SearchDocument) -> String {
        // Combine title and content with proper weighting
        let titleWeight = 2.0 // Title is more important
        let weightedTitle = Array(repeating: document.title, count: Int(titleWeight))
            .joined(separator: " ")
        
        // Clean and normalize text
        let cleanedContent = document.content
            .replacingOccurrences(of: "\n+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return "\(weightedTitle) \(cleanedContent)"
    }
    
    /// Update a single document in the index
    func updateDocument(_ documentId: String, newContent: String) async throws {
        guard let index = documents.firstIndex(where: { $0.id == documentId }) else {
            throw SearchError.documentNotFound
        }
        
        // Update document
        var updatedDoc = documents[index]
        updatedDoc = SearchDocument(
            title: updatedDoc.title,
            content: newContent,
            metadata: updatedDoc.metadata
        )
        documents[index] = updatedDoc
        
        // Update embedding
        let text = preprocessText(updatedDoc)
        embeddings[documentId] = try await generateEmbedding(for: text)
    }
    
    /// Remove a document from the index
    func removeDocument(_ documentId: String) {
        documents.removeAll { $0.id == documentId }
        embeddings.removeValue(forKey: documentId)
    }
    
    /// Get index statistics
    func getIndexStats() -> IndexStats {
        IndexStats(
            documentCount: documents.count,
            totalSize: embeddings.values.reduce(0) { $0 + $1.count * 8 }, // bytes
            averageDocumentLength: documents.isEmpty ? 0 :
                documents.map { $0.content.count }.reduce(0, +) / documents.count
        )
    }
    
    struct IndexStats {
        let documentCount: Int
        let totalSize: Int
        let averageDocumentLength: Int
    }
    
    enum SearchError: Error {
        case documentNotFound
        case indexNotBuilt
        case embeddingGenerationFailed
    }
}

// Helper extension for array chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// Example usage
Task {
    let engine = SemanticSearchEngine(apiKey: "your-api-key")
    
    // Prepare documents
    let documents = [
        SemanticSearchEngine.SearchDocument(
            title: "Swift Programming",
            content: "Swift is a powerful programming language for iOS development..."
        ),
        SemanticSearchEngine.SearchDocument(
            title: "SwiftUI Basics",
            content: "SwiftUI is a declarative framework for building user interfaces..."
        ),
        SemanticSearchEngine.SearchDocument(
            title: "Async/Await in Swift",
            content: "Swift's async/await syntax makes asynchronous programming easier..."
        )
    ]
    
    // Build index
    try await engine.buildIndex(from: documents)
    
    // Get stats
    let stats = engine.getIndexStats()
    print("Index contains \(stats.documentCount) documents")
}