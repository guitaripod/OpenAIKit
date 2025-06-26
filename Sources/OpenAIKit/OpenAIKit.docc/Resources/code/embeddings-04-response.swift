// EmbeddingGenerator.swift
import Foundation
import OpenAIKit

class EmbeddingGenerator {
    let openAI = OpenAIManager.shared.client
    
    func generateEmbedding(for text: String) async throws -> [Float] {
        guard let openAI = openAI else {
            throw OpenAIError.missingAPIKey
        }
        
        let request = EmbeddingRequest(
            input: text,
            model: Models.Embeddings.textEmbedding3Small,
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
}

enum EmbeddingError: LocalizedError {
    case noEmbeddingGenerated
    
    var errorDescription: String? {
        switch self {
        case .noEmbeddingGenerated:
            return "No embedding was generated"
        }
    }
}
