import Foundation
import OpenAIKit

struct EmbeddingTests {
    let output = ConsoleOutput()
    
    func runAll(openAI: OpenAIKit) async {
        await testEmbeddings(openAI: openAI)
        await testMultipleEmbeddings(openAI: openAI)
    }
    
    func testEmbeddings(openAI: OpenAIKit) async {
        output.startTest("🔢 Testing Embeddings...")
        
        do {
            let request = EmbeddingRequest(
                input: "The quick brown fox jumps over the lazy dog",
                model: Models.Embeddings.textEmbedding3Small
            )
            
            let response = try await openAI.embeddings.create(request)
            
            output.success("Embeddings successful!")
            output.info("Model: \(response.model)")
            output.info("Embedding dimensions: \(response.data.first?.embedding.floatValues?.count ?? 0)")
            output.info("Usage: \(response.usage.totalTokens) tokens")
        } catch {
            output.failure("Embeddings failed", error: error)
        }
    }
    
    func testMultipleEmbeddings(openAI: OpenAIKit) async {
        output.startTest("Testing embeddings with multiple inputs...")
        
        do {
            let inputs = [
                "First text for embedding",
                "Second text for embedding", 
                "Third text for embedding"
            ]
            let request = EmbeddingRequest(
                input: inputs,
                model: Models.Embeddings.textEmbedding3Small,
                dimensions: 512  // Reduced dimensions
            )
            
            let response = try await openAI.embeddings.create(request)
            output.success("Multiple embeddings successful")
            output.info("Generated \(response.data.count) embeddings")
            output.info("Dimensions per embedding: \(response.data.first?.embedding.floatValues?.count ?? 0)")
            output.info("Total tokens used: \(response.usage.totalTokens)")
        } catch {
            output.failure("Multiple embeddings failed", error: error)
        }
    }
}