// SemanticMemory.swift
import Foundation
import OpenAIKit

class SemanticMemory: MemoryStore {
    private let openAI: OpenAIKit
    private var memories: [MemoryItem] = []
    private var embeddings: [UUID: [Float]] = [:]
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
    }
    
    func store(key: String, value: Any) async {
        let valueString = String(describing: value)
        
        // Generate embedding for the value
        let embedding = await generateEmbedding(for: valueString)
        
        let item = MemoryItem(
            key: key,
            value: valueString,
            timestamp: Date(),
            metadata: [:],
            relevanceScore: nil
        )
        
        memories.append(item)
        if let embedding = embedding {
            embeddings[item.id] = embedding
        }
    }
    
    func retrieve(key: String) async -> Any? {
        memories.first { $0.key == key }?.value
    }
    
    func search(query: String) async -> [MemoryItem] {
        // Generate embedding for query
        guard let queryEmbedding = await generateEmbedding(for: query) else {
            // Fallback to text search
            return memories.filter { item in
                item.key.localizedCaseInsensitiveContains(query) ||
                item.value.localizedCaseInsensitiveContains(query)
            }
        }
        
        // Calculate similarity scores
        let scoredMemories = memories.compactMap { item -> (MemoryItem, Double)? in
            guard let itemEmbedding = embeddings[item.id] else { return nil }
            let similarity = cosineSimilarity(queryEmbedding, itemEmbedding)
            return (item, similarity)
        }
        
        // Return top matches
        return scoredMemories
            .sorted { $0.1 > $1.1 }
            .prefix(10)
            .map { $0.0 }
    }
    
    func clear() async {
        memories.removeAll()
        embeddings.removeAll()
    }
    
    private func generateEmbedding(for text: String) async -> [Float]? {
        let request = EmbeddingRequest(
            input: text,
            model: "text-embedding-3-small"
        )
        
        do {
            let response = try await openAI.embeddings.create(request)
            if let embedding = response.data.first?.embedding {
                return embedding.floatValues ?? []
            }
        } catch {
            print("Failed to generate embedding: \(error)")
        }
        
        return nil
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Double {
        guard a.count == b.count else { return 0 }
        
        var dotProduct: Float = 0
        var normA: Float = 0
        var normB: Float = 0
        
        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        
        guard normA > 0 && normB > 0 else { return 0 }
        return Double(dotProduct / (sqrt(normA) * sqrt(normB)))
    }
}