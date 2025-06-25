import Foundation

/// Provides access to OpenAI's embeddings API for converting text into numerical vectors.
///
/// ## Overview
///
/// The `EmbeddingsEndpoint` class enables you to convert text into high-dimensional
/// vectors (embeddings) that capture semantic meaning. These embeddings can be used
/// for various natural language processing tasks such as:
///
/// - **Semantic Search**: Find documents similar to a query
/// - **Clustering**: Group similar texts together
/// - **Recommendations**: Suggest related content
/// - **Anomaly Detection**: Identify outliers in text data
/// - **Classification**: Train machine learning models on text features
///
/// ## Understanding Embeddings
///
/// Embeddings are dense numerical representations of text where semantically similar
/// texts have vectors that are close together in the high-dimensional space. The
/// distance between vectors (typically measured using cosine similarity) indicates
/// how related the texts are in meaning.
///
/// ## Available Models
///
/// ### text-embedding-3-small
/// - **Dimensions**: 1536 (can be reduced)
/// - **Use Case**: General-purpose, cost-effective
/// - **Performance**: Good balance of quality and speed
///
/// ### text-embedding-3-large
/// - **Dimensions**: 3072 (can be reduced)
/// - **Use Case**: Higher accuracy requirements
/// - **Performance**: Best quality, higher cost
///
/// ### text-embedding-ada-002 (Legacy)
/// - **Dimensions**: 1536 (fixed)
/// - **Use Case**: Backward compatibility only
/// - **Note**: Not recommended for new applications
///
/// ## Basic Usage
///
/// ```swift
/// let client = OpenAIKit(apiKey: "your-api-key")
///
/// // Single text embedding
/// let request = EmbeddingRequest(
///     input: "The history of artificial intelligence",
///     model: "text-embedding-3-small"
/// )
///
/// let response = try await client.embeddings.create(request)
/// let embedding = response.data.first?.embedding
/// ```
///
/// ## Advanced Examples
///
/// ### Semantic Search Implementation
/// ```swift
/// // 1. Create embeddings for your documents
/// let documents = [
///     "Swift is a powerful programming language",
///     "Python is popular for machine learning",
///     "JavaScript runs in web browsers"
/// ]
///
/// let docsRequest = EmbeddingRequest(
///     input: documents,
///     model: "text-embedding-3-small"
/// )
/// let docsResponse = try await client.embeddings.create(docsRequest)
///
/// // 2. Create embedding for search query
/// let queryRequest = EmbeddingRequest(
///     input: "What language should I use for iOS development?",
///     model: "text-embedding-3-small"
/// )
/// let queryResponse = try await client.embeddings.create(queryRequest)
///
/// // 3. Calculate similarities
/// if let queryVector = queryResponse.data.first?.embedding.floatValues {
///     let similarities = docsResponse.data.map { doc in
///         guard let docVector = doc.embedding.floatValues else { return 0.0 }
///         return cosineSimilarity(queryVector, docVector)
///     }
///     
///     // Find most similar document
///     if let maxIndex = similarities.enumerated().max(by: { $0.element < $1.element })?.offset {
///         print("Most relevant: \(documents[maxIndex])")
///     }
/// }
/// ```
///
/// ### Dimension Reduction for Efficiency
/// ```swift
/// let request = EmbeddingRequest(
///     input: "Large corpus of text to embed",
///     model: "text-embedding-3-small",
///     dimensions: 512  // Reduce from 1536 to 512
/// )
///
/// // Smaller embeddings = faster similarity calculations and less storage
/// let response = try await client.embeddings.create(request)
/// ```
///
/// ### Batch Processing with Base64 Encoding
/// ```swift
/// let batchRequest = EmbeddingRequest(
///     input: Array(repeating: "Sample text", count: 100),
///     model: "text-embedding-3-small",
///     encodingFormat: .base64  // More efficient for large batches
/// )
///
/// let response = try await client.embeddings.create(batchRequest)
/// // Store base64 strings directly in database
/// ```
///
/// ## Best Practices
///
/// 1. **Batch Requests**: Process multiple texts in a single request (up to 2048 inputs)
/// 2. **Cache Embeddings**: Store computed embeddings to avoid redundant API calls
/// 3. **Normalize Vectors**: For cosine similarity, pre-normalize vectors for faster calculations
/// 4. **Choose Right Model**: Use `text-embedding-3-small` for most use cases
/// 5. **Consider Dimensions**: Reduce dimensions when possible to save costs and improve speed
///
/// ## Error Handling
///
/// ```swift
/// do {
///     let response = try await client.embeddings.create(request)
///     // Process embeddings
/// } catch {
///     if let apiError = error as? OpenAIError {
///         switch apiError {
///         case .rateLimitExceeded:
///             // Implement backoff strategy
///         case .invalidRequest(let message):
///             print("Invalid request: \(message)")
///         default:
///             // Handle other errors
///         }
///     }
/// }
/// ```
///
/// - SeeAlso: ``EmbeddingRequest``, ``EmbeddingResponse``
public final class EmbeddingsEndpoint: Sendable {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    /// Creates embeddings for the given input text(s).
    ///
    /// This method converts text into numerical vector representations that capture
    /// semantic meaning. The resulting embeddings can be used for similarity comparisons,
    /// search, clustering, and other NLP tasks.
    ///
    /// - Parameter request: The embedding request containing input text(s) and configuration.
    /// - Returns: An ``EmbeddingResponse`` containing the generated embeddings and usage information.
    /// - Throws: An error if the request fails, including network errors or API errors.
    ///
    /// ## Example Usage
    ///
    /// ### Simple Embedding
    /// ```swift
    /// let request = EmbeddingRequest(
    ///     input: "What is machine learning?",
    ///     model: "text-embedding-3-small"
    /// )
    ///
    /// let response = try await embeddings.create(request)
    /// if let vector = response.data.first?.embedding.floatValues {
    ///     print("Embedding has \(vector.count) dimensions")
    /// }
    /// ```
    ///
    /// ### Batch Processing
    /// ```swift
    /// let texts = [
    ///     "First document about AI",
    ///     "Second document about ML",
    ///     "Third document about deep learning"
    /// ]
    ///
    /// let request = EmbeddingRequest(
    ///     input: texts,
    ///     model: "text-embedding-3-small",
    ///     dimensions: 256  // Reduce dimensions
    /// )
    ///
    /// let response = try await embeddings.create(request)
    /// for (index, embedding) in response.data.enumerated() {
    ///     print("Document \(index): \(texts[embedding.index])")
    /// }
    /// ```
    ///
    /// ## Common Use Cases
    ///
    /// ### Building a Semantic Search System
    /// ```swift
    /// // 1. Embed and store your documents
    /// struct Document {
    ///     let id: String
    ///     let content: String
    ///     let embedding: [Double]
    /// }
    ///
    /// var documents: [Document] = []
    ///
    /// for (id, content) in contentDatabase {
    ///     let request = EmbeddingRequest(input: content, model: "text-embedding-3-small")
    ///     let response = try await embeddings.create(request)
    ///     
    ///     if let vector = response.data.first?.embedding.floatValues {
    ///         documents.append(Document(id: id, content: content, embedding: vector))
    ///     }
    /// }
    ///
    /// // 2. Search by embedding similarity
    /// func search(query: String) async throws -> [Document] {
    ///     let queryRequest = EmbeddingRequest(input: query, model: "text-embedding-3-small")
    ///     let queryResponse = try await embeddings.create(queryRequest)
    ///     
    ///     guard let queryVector = queryResponse.data.first?.embedding.floatValues else {
    ///         return []
    ///     }
    ///     
    ///     // Calculate similarities and sort
    ///     let results = documents.map { doc in
    ///         (doc, cosineSimilarity(queryVector, doc.embedding))
    ///     }
    ///     .sorted { $0.1 > $1.1 }
    ///     .prefix(10)
    ///     .map { $0.0 }
    ///     
    ///     return Array(results)
    /// }
    /// ```
    ///
    /// - Important: The API has rate limits. Implement appropriate retry logic
    ///   and respect rate limit headers in production applications.
    ///
    /// - SeeAlso: ``EmbeddingRequest``, ``EmbeddingResponse``, ``EmbeddingVector``
    public func create(_ request: EmbeddingRequest) async throws -> EmbeddingResponse {
        let apiRequest = EmbeddingAPIRequest(request: request)
        return try await networkClient.execute(apiRequest)
    }
}

private struct EmbeddingAPIRequest: Request {
    typealias Body = EmbeddingRequest
    typealias Response = EmbeddingResponse
    
    let path = "embeddings"
    let method: HTTPMethod = .post
    let body: EmbeddingRequest?
    
    init(request: EmbeddingRequest) {
        self.body = request
    }
}