import Foundation
import OpenAIKit

/// A semantic search engine using OpenAI embeddings
class SemanticSearchEngine {
    private let openAI: OpenAIKit
    private var documents: [SearchDocument] = []
    private var embeddings: [String: [Double]] = [:]
    
    /// Represents a searchable document
    struct SearchDocument {
        let id: String
        let title: String
        let content: String
        let metadata: [String: Any]
        let timestamp: Date
        
        init(title: String, content: String, metadata: [String: Any] = [:]) {
            self.id = UUID().uuidString
            self.title = title
            self.content = content
            self.metadata = metadata
            self.timestamp = Date()
        }
    }
    
    /// Search result with relevance score
    struct SearchResult {
        let document: SearchDocument
        let score: Double
        let highlights: [String]
    }
    
    init(apiKey: String) {
        self.openAI = OpenAIKit(apiKey: apiKey)
    }
    
    /// Add a document to the search engine
    func addDocument(_ document: SearchDocument) async throws {
        documents.append(document)
        
        // Generate embedding for the document
        let text = "\(document.title) \(document.content)"
        let embedding = try await generateEmbedding(for: text)
        embeddings[document.id] = embedding
    }
    
    /// Generate embedding for text
    private func generateEmbedding(for text: String) async throws -> [Double] {
        let request = CreateEmbeddingRequest(
            model: .textEmbeddingAda002,
            input: .string(text)
        )
        
        let response = try await openAI.embeddings.create(embedding: request)
        return response.data.first?.embedding ?? []
    }
    
    /// Calculate cosine similarity between two vectors
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return 0 }
        
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        guard magnitudeA > 0 && magnitudeB > 0 else { return 0 }
        return dotProduct / (magnitudeA * magnitudeB)
    }
}

// Example usage
let engine = SemanticSearchEngine(apiKey: "your-api-key")

// Add documents
let doc1 = SemanticSearchEngine.SearchDocument(
    title: "Introduction to Machine Learning",
    content: "Machine learning is a subset of artificial intelligence...",
    metadata: ["category": "AI", "difficulty": "beginner"]
)

let doc2 = SemanticSearchEngine.SearchDocument(
    title: "Deep Learning Fundamentals",
    content: "Deep learning uses neural networks with multiple layers...",
    metadata: ["category": "AI", "difficulty": "intermediate"]
)

Task {
    try await engine.addDocument(doc1)
    try await engine.addDocument(doc2)
}