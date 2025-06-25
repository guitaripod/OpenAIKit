import Foundation

/// Represents HTTP methods supported by the OpenAI API.
///
/// This enum provides a type-safe way to specify HTTP methods for API requests.
/// All OpenAI API endpoints use one of these standard HTTP methods.
///
/// ## Topics
///
/// ### HTTP Methods
/// - ``get``
/// - ``post``
/// - ``delete``
public enum HTTPMethod: String, Sendable {
    /// The GET HTTP method.
    ///
    /// Used for retrieving resources from the server without modifying them.
    /// In OpenAI API, this is typically used for:
    /// - Fetching model information
    /// - Listing available resources
    /// - Retrieving status information
    case get = "GET"
    
    /// The POST HTTP method.
    ///
    /// Used for creating new resources or submitting data to the server.
    /// This is the most common method in OpenAI API, used for:
    /// - Creating chat completions
    /// - Generating embeddings
    /// - Creating images
    /// - Fine-tuning operations
    case post = "POST"
    
    /// The DELETE HTTP method.
    ///
    /// Used for removing resources from the server.
    /// In OpenAI API, this is typically used for:
    /// - Deleting fine-tuned models
    /// - Removing uploaded files
    /// - Canceling operations
    case delete = "DELETE"
}

/// A protocol that defines the structure of an API request.
///
/// The `Request` protocol provides a standardized way to define API requests in OpenAIKit.
/// It encapsulates all the necessary information needed to make an HTTP request to the OpenAI API,
/// including the endpoint path, HTTP method, request body, and expected response type.
///
/// ## Overview
///
/// Conforming types must specify:
/// - The endpoint path relative to the base API URL
/// - The HTTP method (defaults to POST)
/// - The request body type (can be `EmptyBody` for requests without a body)
/// - The expected response type
///
/// ## Example Implementation
///
/// Here's how to implement a custom request:
///
/// ```swift
/// struct CreateCompletionRequest: Request {
///     typealias Body = CreateCompletionBody
///     typealias Response = CompletionResponse
///     
///     let path = "/v1/completions"
///     let method: HTTPMethod = .post
///     let body: CreateCompletionBody?
///     
///     init(model: String, prompt: String, maxTokens: Int? = nil) {
///         self.body = CreateCompletionBody(
///             model: model,
///             prompt: prompt,
///             maxTokens: maxTokens
///         )
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Required Properties
/// - ``path``
/// - ``method``
/// - ``body``
///
/// ### Associated Types
/// - ``Body``
/// - ``Response``
public protocol Request: Sendable {
    /// The type of the request body.
    ///
    /// This must conform to `Encodable` for JSON serialization and `Sendable` for
    /// concurrent use. Use ``EmptyBody`` for requests that don't require a body.
    associatedtype Body: Encodable & Sendable
    
    /// The type of the expected response.
    ///
    /// This must conform to `Decodable` for JSON deserialization and `Sendable` for
    /// concurrent use. Use ``EmptyResponse`` for requests that don't return data.
    associatedtype Response: Decodable & Sendable
    
    /// The API endpoint path relative to the base URL.
    ///
    /// This should not include the base URL or API version prefix if it's already
    /// configured in the client. For example:
    /// - ✅ Good: `/chat/completions`
    /// - ❌ Bad: `https://api.openai.com/v1/chat/completions`
    var path: String { get }
    
    /// The HTTP method for this request.
    ///
    /// Defaults to `.post` if not specified in the conforming type.
    /// Most OpenAI API endpoints use POST, but some operations like
    /// listing resources or deleting models may use GET or DELETE.
    var method: HTTPMethod { get }
    
    /// The request body to be sent with the request.
    ///
    /// This is optional to support requests that may or may not have a body.
    /// For GET requests, this should typically be `nil`.
    /// The body will be encoded as JSON before sending.
    var body: Body? { get }
}

/// Default implementation for Request protocol.
public extension Request {
    /// Default HTTP method is POST, as most OpenAI endpoints use this method.
    var method: HTTPMethod { .post }
}

/// A protocol for requests that support server-sent events (SSE) streaming.
///
/// `StreamableRequest` extends the base ``Request`` protocol to support streaming responses
/// from the OpenAI API. This is particularly useful for real-time applications where you want
/// to process responses as they arrive rather than waiting for the complete response.
///
/// ## Overview
///
/// Streaming is supported by various OpenAI endpoints including:
/// - Chat completions (for real-time chat responses)
/// - Completions (for real-time text generation)
/// - Assistants API (for real-time message streaming)
///
/// The streaming response is typically a modified version of the regular response,
/// often containing delta objects instead of complete content.
///
/// ## Example Implementation
///
/// ```swift
/// struct StreamableChatRequest: StreamableRequest {
///     typealias Body = ChatRequestBody
///     typealias Response = ChatCompletionResponse
///     typealias StreamResponse = ChatCompletionChunk
///     
///     let path = "/v1/chat/completions"
///     let body: ChatRequestBody?
///     
///     init(messages: [ChatMessage], model: String, stream: Bool = true) {
///         self.body = ChatRequestBody(
///             model: model,
///             messages: messages,
///             stream: stream
///         )
///     }
/// }
/// ```
///
/// ## Usage with Client
///
/// ```swift
/// let request = StreamableChatRequest(
///     messages: [.user("Tell me a story")],
///     model: "gpt-4"
/// )
///
/// for try await chunk in client.stream(request) {
///     if let content = chunk.choices.first?.delta.content {
///         print(content, terminator: "")
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Associated Types
/// - ``StreamResponse``
public protocol StreamableRequest: Request {
    /// The type of each streamed response chunk.
    ///
    /// This represents individual pieces of the response that arrive via
    /// server-sent events. Each chunk must be independently decodable.
    /// Common patterns include:
    /// - Delta objects containing incremental content
    /// - Status updates during long-running operations
    /// - Partial results as they become available
    associatedtype StreamResponse: Decodable & Sendable
}

/// A protocol for requests that upload files using multipart/form-data encoding.
///
/// `UploadRequest` is designed for API endpoints that require file uploads,
/// such as uploading training data for fine-tuning or uploading images for
/// vision models. Unlike regular ``Request`` types that use JSON encoding,
/// upload requests use multipart/form-data encoding.
///
/// ## Overview
///
/// Upload requests are used for:
/// - Uploading training/validation files for fine-tuning
/// - Uploading images for vision models
/// - Uploading audio files for transcription/translation
/// - Any endpoint requiring binary file data
///
/// ## Example Implementation
///
/// ```swift
/// struct FileUploadRequest: UploadRequest {
///     typealias Response = FileUploadResponse
///     
///     let path = "/v1/files"
///     let fileData: Data
///     let fileName: String
///     let purpose: String
///     
///     func multipartData(boundary: String) async throws -> Data {
///         var data = Data()
///         
///         // Add purpose field
///         data.append("--\(boundary)\r\n")
///         data.append("Content-Disposition: form-data; name=\"purpose\"\r\n\r\n")
///         data.append("\(purpose)\r\n")
///         
///         // Add file data
///         data.append("--\(boundary)\r\n")
///         data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
///         data.append("Content-Type: application/octet-stream\r\n\r\n")
///         data.append(fileData)
///         data.append("\r\n")
///         
///         // Close boundary
///         data.append("--\(boundary)--\r\n")
///         
///         return data
///     }
/// }
/// ```
///
/// ## Multipart Encoding
///
/// The `multipartData(boundary:)` method must properly format the data according to
/// RFC 7578 multipart/form-data specification. Each field should be separated by
/// the boundary string, and the final boundary must include trailing dashes.
///
/// ## Topics
///
/// ### Required Properties
/// - ``path``
/// - ``multipartData(boundary:)``
///
/// ### Associated Types
/// - ``Response``
public protocol UploadRequest: Sendable {
    /// The type of the expected response after upload.
    ///
    /// This typically includes information about the uploaded file such as
    /// its ID, size, creation timestamp, and purpose.
    associatedtype Response: Decodable & Sendable
    
    /// The API endpoint path for the upload.
    ///
    /// Similar to ``Request/path``, this should be relative to the base API URL.
    var path: String { get }
    
    /// Generates the multipart/form-data body for the upload request.
    ///
    /// This method is responsible for encoding all form fields and file data
    /// into a properly formatted multipart body. The boundary string is used
    /// to separate different parts of the form data.
    ///
    /// - Parameter boundary: A unique string used to separate form fields.
    ///                      This is typically generated by the client.
    /// - Returns: The complete multipart/form-data body as `Data`.
    /// - Throws: Any errors that occur during data encoding.
    ///
    /// - Important: The boundary string must not appear in the actual data.
    ///             The implementation should properly escape or validate content.
    func multipartData(boundary: String) async throws -> Data
}

/// A type representing an empty request body.
///
/// Use `EmptyBody` as the `Body` type for ``Request`` implementations
/// that don't send data in the request body. This is typically used for:
/// - GET requests that pass parameters via query string
/// - DELETE requests that only need a resource identifier
/// - Any request where all parameters are in the URL or headers
///
/// ## Example
///
/// ```swift
/// struct ListModelsRequest: Request {
///     typealias Body = EmptyBody
///     typealias Response = ModelsListResponse
///     
///     let path = "/v1/models"
///     let method: HTTPMethod = .get
///     let body: EmptyBody? = nil
/// }
/// ```
public struct EmptyBody: Codable, Sendable {}

/// A type representing an empty response.
///
/// Use `EmptyResponse` as the `Response` type for ``Request`` implementations
/// where the API doesn't return any data in the response body. This is typically
/// used for:
/// - DELETE operations that only return a status code
/// - Operations where success is indicated by HTTP status alone
/// - Endpoints that return 204 No Content
///
/// ## Example
///
/// ```swift
/// struct DeleteFileRequest: Request {
///     typealias Body = EmptyBody
///     typealias Response = EmptyResponse
///     
///     let path: String
///     let method: HTTPMethod = .delete
///     let body: EmptyBody? = nil
///     
///     init(fileId: String) {
///         self.path = "/v1/files/\(fileId)"
///     }
/// }
/// ```
///
/// - Note: Even when using `EmptyResponse`, the HTTP status code should still
///         be checked to ensure the operation succeeded.
public struct EmptyResponse: Codable, Sendable {}