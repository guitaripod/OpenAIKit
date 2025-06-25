import Foundation

/// A request to create embeddings for the given input.
///
/// Embeddings are numerical representations of text that capture semantic meaning,
/// allowing for tasks like semantic search, clustering, and similarity comparisons.
///
/// ## Overview
///
/// Use `EmbeddingRequest` to convert text into high-dimensional vectors that can be
/// used for various natural language processing tasks. The resulting embeddings can be
/// stored in vector databases for efficient similarity searches.
///
/// ## Example Usage
///
/// ### Single Text Embedding
/// ```swift
/// let request = EmbeddingRequest(
///     input: "What is the meaning of life?",
///     model: "text-embedding-3-small"
/// )
/// ```
///
/// ### Multiple Text Embeddings
/// ```swift
/// let request = EmbeddingRequest(
///     input: ["Apple", "Orange", "Banana"],
///     model: "text-embedding-3-small",
///     dimensions: 256  // Reduce dimensions for efficiency
/// )
/// ```
///
/// ### With Custom Encoding
/// ```swift
/// let request = EmbeddingRequest(
///     input: .string("Neural networks are fascinating"),
///     model: "text-embedding-3-large",
///     encodingFormat: .base64  // For more efficient data transfer
/// )
/// ```
///
/// - Note: Different models have different dimension outputs. The `text-embedding-3-small`
///   model outputs 1536 dimensions by default, while `text-embedding-3-large` outputs 3072.
///
/// - SeeAlso: ``EmbeddingResponse``, ``EmbeddingsEndpoint``
public struct EmbeddingRequest: Codable, Sendable {
    /// The input text to embed, provided as a string, array of strings, or token arrays.
    ///
    /// - SeeAlso: ``EmbeddingInput``
    public let input: EmbeddingInput
    
    /// The ID of the model to use.
    ///
    /// Available models include:
    /// - `"text-embedding-3-small"`: Efficient model with good performance
    /// - `"text-embedding-3-large"`: Higher accuracy model with more dimensions
    /// - `"text-embedding-ada-002"`: Legacy model (not recommended for new applications)
    public let model: String
    
    /// The number of dimensions for the output embeddings.
    ///
    /// This parameter is only supported in `text-embedding-3` and later models.
    /// Reducing dimensions can improve performance and reduce storage costs while
    /// maintaining most of the semantic information.
    ///
    /// - Note: The dimensions must be less than or equal to the model's native dimension count.
    public let dimensions: Int?
    
    /// The format to return the embeddings in.
    ///
    /// Can be either `float` (default) or `base64`. Base64 encoding can reduce
    /// the size of the response when transferring large amounts of embedding data.
    ///
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
/// The embedding API accepts different input formats to accommodate various use cases,
/// from simple text strings to pre-tokenized inputs.
///
/// ## Cases
///
/// - `string`: A single text string to embed
/// - `array`: Multiple text strings to embed in batch
/// - `intArray`: A single array of token IDs (for pre-tokenized input)
/// - `nestedIntArray`: Multiple arrays of token IDs (for batch pre-tokenized input)
///
/// ## Usage Examples
///
/// ### Text Input
/// ```swift
/// let singleText = EmbeddingInput.string("Hello, world!")
/// let multipleTexts = EmbeddingInput.array(["Hello", "World"])
/// ```
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