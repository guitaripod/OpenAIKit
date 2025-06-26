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
        
        // Send request next
        return []
    }
}
