import OpenAIKit
import Foundation

// Document ingestion pipeline for semantic search
class DocumentIngestionPipeline {
    let openAI: OpenAI
    let vectorStore: VectorStore
    
    init(apiKey: String) {
        self.openAI = OpenAI(apiKey: apiKey)
        self.vectorStore = VectorStore()
    }
    
    // Process and ingest a document
    func ingestDocument(_ document: Document) async throws {
        print("Ingesting document: \(document.title)")
        
        // Split document into chunks
        let chunks = splitIntoChunks(document.content, maxTokens: 500)
        
        // Generate embeddings for each chunk
        for (index, chunk) in chunks.enumerated() {
            let embedding = try await generateEmbedding(for: chunk)
            
            // Store chunk with metadata
            let chunkDocument = ChunkDocument(
                id: "\(document.id)_\(index)",
                documentId: document.id,
                content: chunk,
                embedding: embedding,
                metadata: ChunkMetadata(
                    title: document.title,
                    author: document.author,
                    category: document.category,
                    tags: document.tags,
                    chunkIndex: index,
                    totalChunks: chunks.count
                )
            )
            
            try await vectorStore.store(chunkDocument)
        }
        
        print("Successfully ingested \(chunks.count) chunks")
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
    
    // Split text into chunks with overlap
    private func splitIntoChunks(_ text: String, maxTokens: Int) -> [String] {
        let sentences = text.components(separatedBy: ". ")
        var chunks: [String] = []
        var currentChunk = ""
        var tokenCount = 0
        
        for sentence in sentences {
            let sentenceTokens = estimateTokens(sentence)
            
            if tokenCount + sentenceTokens > maxTokens && !currentChunk.isEmpty {
                chunks.append(currentChunk.trimmingCharacters(in: .whitespaces))
                // Keep last sentence for overlap
                currentChunk = chunks.last?.components(separatedBy: ". ").last ?? ""
                tokenCount = estimateTokens(currentChunk)
            }
            
            currentChunk += sentence + ". "
            tokenCount += sentenceTokens
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk.trimmingCharacters(in: .whitespaces))
        }
        
        return chunks
    }
    
    // Simple token estimation
    private func estimateTokens(_ text: String) -> Int {
        return text.split(separator: " ").count * 4 / 3
    }
}

// Document model
struct Document {
    let id: String
    let title: String
    let content: String
    let author: String
    let category: String
    let tags: [String]
    let createdAt: Date
}

// Chunk document with embedding
struct ChunkDocument {
    let id: String
    let documentId: String
    let content: String
    let embedding: [Double]
    let metadata: ChunkMetadata
}

// Chunk metadata
struct ChunkMetadata {
    let title: String
    let author: String
    let category: String
    let tags: [String]
    let chunkIndex: Int
    let totalChunks: Int
}

// Vector store protocol
protocol VectorStoreProtocol {
    func store(_ document: ChunkDocument) async throws
    func search(embedding: [Double], limit: Int) async throws -> [SearchResult]
}

// In-memory vector store implementation
class VectorStore: VectorStoreProtocol {
    private var documents: [ChunkDocument] = []
    
    func store(_ document: ChunkDocument) async throws {
        documents.append(document)
    }
    
    func search(embedding: [Double], limit: Int) async throws -> [SearchResult] {
        // Calculate cosine similarity for each document
        let results = documents.map { doc in
            let similarity = cosineSimilarity(embedding, doc.embedding)
            return SearchResult(
                document: doc,
                score: similarity
            )
        }
        
        // Sort by similarity and return top results
        return Array(results.sorted { $0.score > $1.score }.prefix(limit))
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

struct SearchResult {
    let document: ChunkDocument
    let score: Double
}

// Usage example
func demonstrateIngestion() async throws {
    let pipeline = DocumentIngestionPipeline(apiKey: "your-api-key")
    
    let document = Document(
        id: "doc001",
        title: "Introduction to Machine Learning",
        content: """
        Machine learning is a subset of artificial intelligence that focuses on 
        the development of algorithms and statistical models that enable computer 
        systems to improve their performance on a specific task through experience. 
        Unlike traditional programming where explicit instructions are provided, 
        machine learning systems learn patterns from data and make decisions based 
        on that learning. The field encompasses various approaches including 
        supervised learning, unsupervised learning, and reinforcement learning. 
        Applications range from image recognition and natural language processing 
        to recommendation systems and autonomous vehicles.
        """,
        author: "Dr. Sarah Johnson",
        category: "Technology",
        tags: ["AI", "Machine Learning", "Data Science"],
        createdAt: Date()
    )
    
    try await pipeline.ingestDocument(document)
}