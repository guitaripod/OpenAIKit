import Foundation

/// A request to create embeddings for the given input.
///
/// `EmbeddingRequest` transforms text into high-dimensional numerical vectors that capture
/// semantic meaning. These embeddings power intelligent applications like semantic search,
/// recommendation systems, clustering, and classification.
///
/// ## Overview
///
/// Embeddings are the foundation of modern AI applications. They convert text into vectors
/// where similar meanings are geometrically close. This enables:
///
/// - **Semantic Search**: Find related content by meaning, not keywords
/// - **Clustering**: Group similar documents automatically
/// - **Classification**: Categorize text based on examples
/// - **Recommendations**: Suggest related items
/// - **Anomaly Detection**: Identify outliers in text data
///
/// ## Example Usage
///
/// ### Basic Embedding
/// ```swift
/// // Simple text embedding
/// let request = EmbeddingRequest(
///     input: "What is machine learning?",
///     model: Models.Embeddings.textEmbedding3Small
/// )
///
/// let response = try await openAI.embeddings.create(request)
/// let vector = response.data.first?.embedding
/// ```
///
/// ### Batch Processing
/// ```swift
/// // Embed multiple documents efficiently
/// let documents = [
///     "Introduction to Swift programming",
///     "Advanced iOS development techniques",
///     "SwiftUI best practices"
/// ]
///
/// let request = EmbeddingRequest(
///     input: documents,
///     model: Models.Embeddings.textEmbedding3Small
/// )
/// ```
///
/// ### Optimized for Storage
/// ```swift
/// // Reduce dimensions and use base64 encoding
/// let request = EmbeddingRequest(
///     input: "Large corpus of text",
///     model: Models.Embeddings.textEmbedding3Small,
///     dimensions: 512,           // Reduce from 1536
///     encodingFormat: .base64    // Compact transfer
/// )
/// ```
///
/// ## Model Selection
///
/// - **text-embedding-3-small**: 1536 dimensions, best value
/// - **text-embedding-3-large**: 3072 dimensions, highest accuracy
/// - **text-embedding-ada-002**: 1536 dimensions, legacy
///
/// ## Best Practices
///
/// 1. Batch requests when possible (up to 2048 inputs)
/// 2. Use dimension reduction for large-scale applications
/// 3. Normalize vectors for cosine similarity
/// 4. Store embeddings in vector databases
///
/// - SeeAlso: ``EmbeddingResponse``, ``Embedding``, ``EmbeddingsEndpoint``
public struct EmbeddingRequest: Codable, Sendable {
    /// The input text to embed.
    ///
    /// Supports flexible input formats:
    /// - Single text string
    /// - Array of text strings (batch processing)
    /// - Pre-tokenized integer arrays (advanced use)
    ///
    /// ## Input Limits
    ///
    /// - Maximum 2048 inputs per request
    /// - Each input limited by model's context window
    /// - Longer texts are truncated, not errored
    ///
    /// ## Examples
    ///
    /// ```swift
    /// // Single text
    /// input: .string("Hello world")
    ///
    /// // Batch processing
    /// input: .array(["Text 1", "Text 2", "Text 3"])
    ///
    /// // Pre-tokenized (advanced)
    /// input: .intArray([1234, 5678, 9012])
    /// ```
    ///
    /// - SeeAlso: ``EmbeddingInput``
    public let input: EmbeddingInput
    
    /// The ID of the model to use.
    ///
    /// Choose based on your performance, accuracy, and cost requirements.
    ///
    /// ## Available Models
    ///
    /// **text-embedding-3-small** (Recommended)
    /// - Dimensions: 1536 (reducible)
    /// - Performance: Excellent
    /// - Cost: Lower
    /// - Use for: Most applications
    ///
    /// **text-embedding-3-large**
    /// - Dimensions: 3072 (reducible)
    /// - Performance: Superior
    /// - Cost: Higher
    /// - Use for: Maximum accuracy needs
    ///
    /// **text-embedding-ada-002** (Legacy)
    /// - Dimensions: 1536 (fixed)
    /// - Performance: Good
    /// - Cost: Lowest
    /// - Use for: Existing systems only
    ///
    /// ## Model Comparison
    ///
    /// ```swift
    /// // Best value
    /// model: Models.Embeddings.textEmbedding3Small
    ///
    /// // Maximum accuracy
    /// model: Models.Embeddings.textEmbedding3Large
    /// ```
    ///
    /// - Note: Newer models support dimension reduction
    public let model: String
    
    /// The number of dimensions for the output embeddings.
    ///
    /// Reduce embedding dimensions to optimize storage and computation while preserving
    /// most semantic information. Only supported by text-embedding-3 models.
    ///
    /// ## Dimension Trade-offs
    ///
    /// | Dimensions | Quality | Storage | Speed |
    /// |------------|---------|---------|-------|
    /// | Full (1536/3072) | 100% | 1x | Baseline |
    /// | 1024 | ~99% | 0.67x | Faster |
    /// | 512 | ~97% | 0.33x | Much faster |
    /// | 256 | ~94% | 0.17x | Very fast |
    ///
    /// ## Examples
    ///
    /// ```swift
    /// // Full quality
    /// dimensions: nil  // Uses model default
    ///
    /// // Balanced (recommended)
    /// dimensions: 1024
    ///
    /// // Storage optimized
    /// dimensions: 512
    ///
    /// // Maximum efficiency
    /// dimensions: 256
    /// ```
    ///
    /// ## Guidelines
    ///
    /// - Start with full dimensions
    /// - Test quality with your data
    /// - Reduce until quality drops
    /// - Consider 512-1024 for most uses
    ///
    /// - Maximum: Model's native size
    /// - Minimum: ~256 for useful results
    public let dimensions: Int?
    
    /// The format to return the embeddings in.
    ///
    /// Choose based on your data transfer and processing needs.
    ///
    /// ## Format Options
    ///
    /// **Float** (Default)
    /// - JSON array of numbers
    /// - Human-readable
    /// - Larger transfer size
    /// - Direct use in code
    ///
    /// **Base64**
    /// - Compact binary encoding  
    /// - ~25% smaller transfers
    /// - Requires decoding
    /// - Better for large batches
    ///
    /// ## Usage Examples
    ///
    /// ```swift
    /// // Standard format
    /// encodingFormat: .float
    /// // Response: [0.123, -0.456, ...]
    ///
    /// // Optimized transfer
    /// encodingFormat: .base64
    /// // Response: "Pczji0a3..."
    ///
    /// // Decode base64
    /// let data = Data(base64Encoded: base64String)!
    /// let floats = data.withUnsafeBytes {
    ///     Array($0.bindMemory(to: Float32.self))
    /// }
    /// ```
    ///
    /// - Tip: Use base64 for >100 embeddings
    /// - SeeAlso: ``EncodingFormat``
    public let encodingFormat: EncodingFormat?
    
    /// A unique identifier representing your end-user.
    ///
    /// This can help OpenAI monitor and detect abuse.
    public let user: String?
    
    /// Creates an embedding request with flexible input options.
    ///
    /// - Parameters:
    ///   - input: The input to embed as an ``EmbeddingInput`` enum.
    ///   - model: The model ID to use for generating embeddings.
    ///   - dimensions: Optional dimension count for the output vectors.
    ///   - encodingFormat: The format for the embedding data (float or base64).
    ///   - user: Optional unique identifier for the end-user.
    public init(
        input: EmbeddingInput,
        model: String,
        dimensions: Int? = nil,
        encodingFormat: EncodingFormat? = nil,
        user: String? = nil
    ) {
        self.input = input
        self.model = model
        self.dimensions = dimensions
        self.encodingFormat = encodingFormat
        self.user = user
    }
    
    /// Creates an embedding request for a single text string.
    ///
    /// This is a convenience initializer for the most common use case of embedding
    /// a single piece of text.
    ///
    /// - Parameters:
    ///   - input: The text string to embed.
    ///   - model: The model ID to use for generating embeddings.
    ///   - dimensions: Optional dimension count for the output vectors.
    ///   - encodingFormat: The format for the embedding data (float or base64).
    ///   - user: Optional unique identifier for the end-user.
    ///
    /// ## Example
    /// ```swift
    /// let request = EmbeddingRequest(
    ///     input: "The quick brown fox jumps over the lazy dog",
    ///     model: "text-embedding-3-small"
    /// )
    /// ```
    public init(
        input: String,
        model: String,
        dimensions: Int? = nil,
        encodingFormat: EncodingFormat? = nil,
        user: String? = nil
    ) {
        self.init(
            input: .string(input),
            model: model,
            dimensions: dimensions,
            encodingFormat: encodingFormat,
            user: user
        )
    }
    
    /// Creates an embedding request for multiple text strings.
    ///
    /// Use this initializer to batch multiple texts into a single request,
    /// which is more efficient than making multiple individual requests.
    ///
    /// - Parameters:
    ///   - input: An array of text strings to embed.
    ///   - model: The model ID to use for generating embeddings.
    ///   - dimensions: Optional dimension count for the output vectors.
    ///   - encodingFormat: The format for the embedding data (float or base64).
    ///   - user: Optional unique identifier for the end-user.
    ///
    /// ## Example
    /// ```swift
    /// let request = EmbeddingRequest(
    ///     input: [
    ///         "First document about machine learning",
    ///         "Second document about deep learning",
    ///         "Third document about neural networks"
    ///     ],
    ///     model: "text-embedding-3-small"
    /// )
    /// ```
    ///
    /// - Note: The API supports up to 2048 input texts per request.
    public init(
        input: [String],
        model: String,
        dimensions: Int? = nil,
        encodingFormat: EncodingFormat? = nil,
        user: String? = nil
    ) {
        self.init(
            input: .array(input),
            model: model,
            dimensions: dimensions,
            encodingFormat: encodingFormat,
            user: user
        )
    }
}

/// Represents the various input formats supported for creating embeddings.
///
/// `EmbeddingInput` provides flexibility in how you submit text for embedding, from simple
/// strings to pre-tokenized formats for advanced control.
///
/// ## Input Types
///
/// ### Text Inputs (Common)
///
/// **Single String**
/// ```swift
/// let input = EmbeddingInput.string("What is artificial intelligence?")
/// ```
///
/// **Multiple Strings** (Batch)
/// ```swift
/// let input = EmbeddingInput.array([
///     "Document 1: Introduction to ML",
///     "Document 2: Deep Learning Basics",
///     "Document 3: Neural Networks"
/// ])
/// ```
///
/// ### Token Inputs (Advanced)
///
/// **Pre-tokenized Single Input**
/// ```swift
/// let tokens = tokenizer.encode("Hello world")
/// let input = EmbeddingInput.intArray(tokens)
/// ```
///
/// **Pre-tokenized Batch**
/// ```swift
/// let tokenBatches = texts.map { tokenizer.encode($0) }
/// let input = EmbeddingInput.nestedIntArray(tokenBatches)
/// ```
///
/// ## When to Use Each Type
///
/// - **string**: Single text, simple use cases
/// - **array**: Batch processing, efficiency
/// - **intArray**: Control over tokenization
/// - **nestedIntArray**: Batch with token control
///
/// ## Performance Tips
///
/// - Batch similar-length texts together
/// - Use batching for >10 texts
/// - Pre-tokenize for consistency
/// - Maximum 2048 inputs per request
///
/// ### Token Input
/// ```swift
/// let tokens = EmbeddingInput.intArray([1234, 5678, 9012])
/// let batchTokens = EmbeddingInput.nestedIntArray([[1234, 5678], [9012, 3456]])
/// ```
///
/// - Note: Token inputs are useful when you've pre-tokenized text using the same
///   tokenizer as the embedding model, allowing for more control over the tokenization process.
public enum EmbeddingInput: Codable, Sendable {
    /// A single text string to be embedded.
    case string(String)
    
    /// An array of text strings to be embedded in a single request.
    case array([String])
    
    /// An array of token IDs representing pre-tokenized text.
    case intArray([Int])
    
    /// Multiple arrays of token IDs for batch processing pre-tokenized texts.
    case nestedIntArray([[Int]])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([String].self) {
            self = .array(array)
        } else if let intArray = try? container.decode([Int].self) {
            self = .intArray(intArray)
        } else if let nestedIntArray = try? container.decode([[Int]].self) {
            self = .nestedIntArray(nestedIntArray)
        } else {
            throw DecodingError.typeMismatch(
                EmbeddingInput.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String, [String], [Int], or [[Int]]")
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let string):
            try container.encode(string)
        case .array(let array):
            try container.encode(array)
        case .intArray(let intArray):
            try container.encode(intArray)
        case .nestedIntArray(let nestedIntArray):
            try container.encode(nestedIntArray)
        }
    }
}

/// The format for returning embedding vectors.
///
/// Embeddings can be returned in different formats to optimize for various use cases
/// and network transfer efficiency.
///
/// ## Cases
///
/// - `float`: Returns embeddings as an array of floating-point numbers (default)
/// - `base64`: Returns embeddings as a base64-encoded string
///
/// ## Usage Considerations
///
/// ### Float Format
/// Use the `float` format when:
/// - You need to immediately process or analyze the embeddings
/// - You're performing calculations like cosine similarity
/// - Storage size is not a primary concern
///
/// ### Base64 Format
/// Use the `base64` format when:
/// - You're transferring large amounts of embedding data
/// - You want to reduce response payload size (approximately 30% smaller)
/// - You're storing embeddings directly without processing
///
/// ## Example
/// ```swift
/// // For immediate processing
/// let request = EmbeddingRequest(
///     input: "Sample text",
///     model: "text-embedding-3-small",
///     encodingFormat: .float
/// )
///
/// // For efficient transfer
/// let request = EmbeddingRequest(
///     input: Array(repeating: "Text", count: 1000),
///     model: "text-embedding-3-small",
///     encodingFormat: .base64
/// )
/// ```
public enum EncodingFormat: String, Codable, Sendable {
    /// Embeddings returned as an array of floating-point numbers.
    case float
    
    /// Embeddings returned as a base64-encoded string for efficient transfer.
    case base64
}

/// The response from an embedding creation request.
///
/// Contains the generated embeddings along with metadata about the request.
///
/// ## Example Usage
/// ```swift
/// let client = OpenAIKit(apiKey: "your-api-key")
/// let request = EmbeddingRequest(
///     input: "What is machine learning?",
///     model: "text-embedding-3-small"
/// )
///
/// let response = try await client.embeddings.create(request)
///
/// // Access the embedding vector
/// if let vector = response.data.first?.embedding.floatValues {
///     print("Embedding dimensions: \(vector.count)")
///     // Use vector for similarity calculations, storage, etc.
/// }
/// ```
///
/// - SeeAlso: ``Embedding``, ``EmbeddingUsage``
public struct EmbeddingResponse: Codable, Sendable {
    /// The object type, always "list" for embedding responses.
    public let object: String
    
    /// An array of embedding objects, one for each input.
    ///
    /// The order of embeddings matches the order of inputs in the request.
    public let data: [Embedding]
    
    /// The model used to generate the embeddings.
    public let model: String
    
    /// Token usage information for the request.
    public let usage: EmbeddingUsage
}

/// A single embedding result containing the vector representation of the input.
///
/// Each embedding corresponds to one input from the request, with the index
/// indicating its position in the original input array.
///
/// ## Accessing Embedding Data
/// ```swift
/// let embedding = response.data[0]
///
/// // For float format
/// if let floatVector = embedding.embedding.floatValues {
///     let magnitude = sqrt(floatVector.reduce(0) { $0 + $1 * $1 })
///     print("Vector magnitude: \(magnitude)")
/// }
///
/// // For base64 format
/// if let base64String = embedding.embedding.base64Value {
///     // Decode base64 to Data, then to float array if needed
/// }
/// ```
public struct Embedding: Codable, Sendable {
    /// The object type, always "embedding".
    public let object: String
    
    /// The embedding vector data in the requested format.
    ///
    /// - SeeAlso: ``EmbeddingVector``
    public let embedding: EmbeddingVector
    
    /// The index of this embedding in the input array.
    ///
    /// Use this to match embeddings with their corresponding inputs
    /// when processing batch requests.
    public let index: Int
}

/// Represents an embedding vector in either float or base64 format.
///
/// The format depends on the `encodingFormat` specified in the request.
/// Use the helper properties to safely access the vector data in the desired format.
///
/// ## Working with Embeddings
///
/// ### Cosine Similarity
/// ```swift
/// func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
///     let dotProduct = zip(a, b).map(*).reduce(0, +)
///     let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
///     let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
///     return dotProduct / (magnitudeA * magnitudeB)
/// }
///
/// if let vector1 = embedding1.floatValues,
///    let vector2 = embedding2.floatValues {
///     let similarity = cosineSimilarity(vector1, vector2)
///     print("Similarity: \(similarity)")
/// }
/// ```
///
/// ### Converting Base64 to Float Array
/// ```swift
/// if let base64String = embedding.base64Value {
///     if let data = Data(base64Encoded: base64String) {
///         let floats = data.withUnsafeBytes { buffer in
///             Array(buffer.bindMemory(to: Float32.self))
///         }
///         let doubles = floats.map { Double($0) }
///         // Use doubles array...
///     }
/// }
/// ```
public enum EmbeddingVector: Codable, Sendable {
    /// Embedding vector as an array of double-precision floating-point numbers.
    case float([Double])
    
    /// Embedding vector encoded as a base64 string.
    case base64(String)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let floatArray = try? container.decode([Double].self) {
            self = .float(floatArray)
        } else if let base64String = try? container.decode(String.self) {
            self = .base64(base64String)
        } else {
            throw DecodingError.typeMismatch(
                EmbeddingVector.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected [Double] or String")
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .float(let floatArray):
            try container.encode(floatArray)
        case .base64(let base64String):
            try container.encode(base64String)
        }
    }
    
    /// Returns the embedding vector as an array of doubles if in float format.
    ///
    /// - Returns: The vector as `[Double]` if the format is float, otherwise `nil`.
    ///
    /// ## Example
    /// ```swift
    /// if let vector = embedding.floatValues {
    ///     print("Vector has \(vector.count) dimensions")
    ///     let firstFive = vector.prefix(5)
    ///     print("First 5 values: \(firstFive)")
    /// }
    /// ```
    public var floatValues: [Double]? {
        switch self {
        case .float(let values):
            return values
        case .base64:
            return nil
        }
    }
    
    /// Returns the embedding vector as a base64 string if in base64 format.
    ///
    /// - Returns: The vector as a base64 string if the format is base64, otherwise `nil`.
    ///
    /// ## Example
    /// ```swift
    /// if let base64 = embedding.base64Value {
    ///     // Store in database or transmit over network
    ///     saveToDatabase(base64)
    /// }
    /// ```
    public var base64Value: String? {
        switch self {
        case .float:
            return nil
        case .base64(let value):
            return value
        }
    }
}

/// Token usage information for an embedding request.
///
/// Provides details about the number of tokens consumed by the request,
/// useful for monitoring usage and costs.
///
/// ## Token Counting
/// - Each input string is tokenized before creating embeddings
/// - Token count varies based on text length and complexity
/// - Different models may tokenize the same text differently
///
/// ## Example
/// ```swift
/// let usage = response.usage
/// print("Tokens used: \(usage.totalTokens)")
/// print("Cost estimate: $\(Double(usage.totalTokens) * 0.0001)")
/// ```
public struct EmbeddingUsage: Codable, Sendable {
    /// The number of tokens in the input(s).
    public let promptTokens: Int
    
    /// The total number of tokens used by the request.
    ///
    /// For embeddings, this is typically equal to `promptTokens`.
    public let totalTokens: Int
}