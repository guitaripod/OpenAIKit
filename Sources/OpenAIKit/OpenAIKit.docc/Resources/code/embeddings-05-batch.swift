// EmbeddingGenerator.swift - Batch processing
import Foundation
import OpenAIKit

class EmbeddingGenerator {
    let openAI = OpenAIManager.shared.client
    private let maxBatchSize = 100
    
    func generateEmbedding(for text: String) async throws -> [Float] {
        guard let openAI = openAI else {
            throw OpenAIError.missingAPIKey
        }
        
        let request = EmbeddingRequest(
            input: text,
            model: "text-embedding-3-small",
            dimensions: nil,
            encodingFormat: .float,
            user: nil
        )
        
        let response = try await openAI.embeddings.create(request)
        
        guard let embedding = response.data.first?.embedding,
              let floatValues = embedding.floatValues else {
            throw EmbeddingError.noEmbeddingGenerated
        }
        
        return floatValues
    }
    
    func generateEmbeddings(for texts: [String]) async throws -> [[Float]] {
        guard let openAI = openAI else {
            throw OpenAIError.missingAPIKey
        }
        
        var allEmbeddings: [[Float]] = []
        
        // Process in batches
        for chunk in texts.chunked(into: maxBatchSize) {
            let request = EmbeddingRequest(
                input: chunk,
                model: "text-embedding-3-small",
                dimensions: nil,
                encodingFormat: .float,
                user: nil
            )
            
            let response = try await openAI.embeddings.create(request)
            
            let embeddings = response.data.compactMap { data -> [Float]? in
                guard let embedding = data.embedding,
                      let floatValues = embedding.floatValues else {
                    return nil
                }
                return floatValues
            }
            
            allEmbeddings.append(contentsOf: embeddings)
        }
        
        return allEmbeddings
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
