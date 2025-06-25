import Foundation

/// The primary error type for all OpenAI API interactions.
///
/// `OpenAIError` provides a comprehensive set of error cases that can occur when
/// interacting with the OpenAI API. Each case represents a specific type of failure,
/// making it easier to handle errors appropriately in your application.
///
/// ## Overview
///
/// This error type conforms to `LocalizedError` to provide user-friendly error messages
/// and `Sendable` to ensure thread-safety in concurrent environments.
///
/// ## Common Usage
///
/// ```swift
/// do {
///     let completion = try await openAI.completions.create(model: "gpt-3.5-turbo", prompt: "Hello")
/// } catch let error as OpenAIError {
///     switch error {
///     case .authenticationFailed:
///         print("Please check your API key")
///     case .rateLimitExceeded:
///         print("Too many requests. Please wait before trying again.")
///     case .apiError(let apiError):
///         print("API Error: \(apiError.error.message)")
///     default:
///         print("An error occurred: \(error.localizedDescription)")
///     }
/// } catch {
///     print("Unexpected error: \(error)")
/// }
/// ```
///
/// ## Topics
///
/// ### Network and URL Errors
/// - ``invalidURL``
/// - ``invalidResponse``
///
/// ### Authentication and Rate Limiting
/// - ``authenticationFailed``
/// - ``rateLimitExceeded``
///
/// ### API-Specific Errors
/// - ``apiError(_:)``
///
/// ### Data Processing Errors
/// - ``decodingFailed(_:)``
/// - ``encodingFailed(_:)``
/// - ``invalidFileData``
///
/// ### HTTP Status Errors
/// - ``clientError(statusCode:)``
/// - ``serverError(statusCode:)``
/// - ``unknownError(statusCode:)``
///
/// ### Feature Support
/// - ``streamingNotSupported``
public enum OpenAIError: LocalizedError, Sendable {
    /// The URL for the API request could not be constructed.
    ///
    /// This error typically occurs when:
    /// - The base URL is malformed
    /// - Path components contain invalid characters
    /// - URL encoding fails
    ///
    /// ## Example
    /// ```swift
    /// // This might throw invalidURL if the endpoint contains invalid characters
    /// let response = try await openAI.makeRequest(to: "invalid endpoint!")
    /// ```
    case invalidURL
    
    /// The server returned a response that couldn't be processed.
    ///
    /// This error occurs when:
    /// - The response body is empty when data was expected
    /// - The response format doesn't match the expected structure
    /// - The server returns HTML instead of JSON (often during outages)
    ///
    /// ## Example
    /// ```swift
    /// do {
    ///     let completion = try await openAI.completions.create(...)
    /// } catch OpenAIError.invalidResponse {
    ///     print("The server returned an unexpected response format")
    /// }
    /// ```
    case invalidResponse
    
    /// Authentication with the OpenAI API failed.
    ///
    /// This error indicates:
    /// - Missing API key
    /// - Invalid API key
    /// - Expired API key
    /// - Insufficient permissions for the requested operation
    ///
    /// ## Resolution
    /// 1. Verify your API key is correct
    /// 2. Check that the key hasn't been revoked
    /// 3. Ensure the key has the necessary permissions
    ///
    /// ## Example
    /// ```swift
    /// let openAI = OpenAI(apiKey: "invalid-key")
    /// do {
    ///     let models = try await openAI.models.list()
    /// } catch OpenAIError.authenticationFailed {
    ///     print("Please provide a valid API key")
    /// }
    /// ```
    case authenticationFailed
    
    /// The API rate limit has been exceeded.
    ///
    /// OpenAI enforces rate limits based on:
    /// - Requests per minute (RPM)
    /// - Tokens per minute (TPM)
    /// - Other usage-based limits
    ///
    /// ## Handling Rate Limits
    /// ```swift
    /// func makeRequestWithRetry() async throws {
    ///     var retryCount = 0
    ///     let maxRetries = 3
    ///     
    ///     while retryCount < maxRetries {
    ///         do {
    ///             return try await openAI.completions.create(...)
    ///         } catch OpenAIError.rateLimitExceeded {
    ///             retryCount += 1
    ///             let delay = pow(2.0, Double(retryCount)) // Exponential backoff
    ///             try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    ///         }
    ///     }
    ///     throw OpenAIError.rateLimitExceeded
    /// }
    /// ```
    case rateLimitExceeded
    
    /// An error response was received from the OpenAI API.
    ///
    /// This case wraps the structured error response from OpenAI's API,
    /// providing detailed information about what went wrong.
    ///
    /// - Parameter error: The ``APIError`` containing error details
    ///
    /// ## Example
    /// ```swift
    /// do {
    ///     let completion = try await openAI.completions.create(
    ///         model: "gpt-3.5-turbo",
    ///         messages: messages,
    ///         maxTokens: 5000 // Too high
    ///     )
    /// } catch OpenAIError.apiError(let apiError) {
    ///     print("Error type: \(apiError.error.type ?? "unknown")")
    ///     print("Error message: \(apiError.error.message)")
    ///     if let param = apiError.error.param {
    ///         print("Problem parameter: \(param)")
    ///     }
    /// }
    /// ```
    ///
    /// - SeeAlso: ``APIError``, ``APIErrorDetail``
    case apiError(APIError)
    
    /// Failed to decode the response data into the expected type.
    ///
    /// This error wraps the underlying decoding error and typically occurs when:
    /// - The API returns a different JSON structure than expected
    /// - Required fields are missing from the response
    /// - Data types don't match (e.g., string instead of number)
    ///
    /// - Parameter error: The underlying decoding error
    ///
    /// ## Debugging
    /// ```swift
    /// do {
    ///     let response = try await openAI.completions.create(...)
    /// } catch OpenAIError.decodingFailed(let error) {
    ///     if let decodingError = error as? DecodingError {
    ///         switch decodingError {
    ///         case .keyNotFound(let key, let context):
    ///             print("Missing key: \(key.stringValue)")
    ///         case .typeMismatch(let type, let context):
    ///             print("Type mismatch for type: \(type)")
    ///         default:
    ///             print("Decoding error: \(context.debugDescription)")
    ///         }
    ///     }
    /// }
    /// ```
    case decodingFailed(Error)
    
    /// Failed to encode the request data into the required format.
    ///
    /// This error occurs when:
    /// - Request parameters contain non-encodable values
    /// - Circular references exist in the data structure
    /// - Custom types don't properly implement `Encodable`
    ///
    /// - Parameter error: The underlying encoding error
    ///
    /// ## Example
    /// ```swift
    /// struct CustomData: Encodable {
    ///     let value: Double = .infinity // Non-encodable in JSON
    /// }
    /// 
    /// // This will throw encodingFailed
    /// let request = CompletionRequest(
    ///     model: "gpt-3.5-turbo",
    ///     messages: [...],
    ///     metadata: CustomData()
    /// )
    /// ```
    case encodingFailed(Error)
    
    /// A client error occurred (HTTP 4xx status codes).
    ///
    /// Common status codes:
    /// - 400: Bad Request - The request was malformed
    /// - 401: Unauthorized - Authentication failed
    /// - 403: Forbidden - Access denied to the resource
    /// - 404: Not Found - The endpoint doesn't exist
    /// - 429: Too Many Requests - Rate limit exceeded
    ///
    /// - Parameter statusCode: The HTTP status code returned
    ///
    /// ## Example
    /// ```swift
    /// do {
    ///     let response = try await openAI.makeRequest(...)
    /// } catch OpenAIError.clientError(let statusCode) {
    ///     switch statusCode {
    ///     case 400:
    ///         print("Check your request parameters")
    ///     case 404:
    ///         print("The requested endpoint doesn't exist")
    ///     default:
    ///         print("Client error: \(statusCode)")
    ///     }
    /// }
    /// ```
    case clientError(statusCode: Int)
    
    /// A server error occurred (HTTP 5xx status codes).
    ///
    /// Common status codes:
    /// - 500: Internal Server Error - Generic server error
    /// - 502: Bad Gateway - Invalid response from upstream server
    /// - 503: Service Unavailable - Server temporarily unavailable
    /// - 504: Gateway Timeout - Request timeout
    ///
    /// - Parameter statusCode: The HTTP status code returned
    ///
    /// ## Retry Strategy
    /// ```swift
    /// func handleServerError(_ statusCode: Int) async throws {
    ///     switch statusCode {
    ///     case 503:
    ///         // Service unavailable, retry with backoff
    ///         try await Task.sleep(nanoseconds: 5_000_000_000)
    ///         // Retry request
    ///     case 500, 502:
    ///         // Internal errors might be transient
    ///         // Consider retry with longer delay
    ///     default:
    ///         // Log and handle accordingly
    ///     }
    /// }
    /// ```
    case serverError(statusCode: Int)
    
    /// An unknown HTTP error occurred.
    ///
    /// This case handles HTTP status codes that don't fall into
    /// standard client (4xx) or server (5xx) error categories.
    ///
    /// - Parameter statusCode: The HTTP status code returned
    case unknownError(statusCode: Int)
    
    /// The requested operation doesn't support streaming responses.
    ///
    /// This error occurs when:
    /// - Attempting to use streaming with an endpoint that doesn't support it
    /// - The API version doesn't support streaming for the requested operation
    ///
    /// ## Example
    /// ```swift
    /// do {
    ///     // Some endpoints may not support streaming
    ///     let stream = try await openAI.embeddings.create(
    ///         model: "text-embedding-ada-002",
    ///         input: "Hello",
    ///         stream: true // Not supported
    ///     )
    /// } catch OpenAIError.streamingNotSupported {
    ///     print("This endpoint doesn't support streaming")
    /// }
    /// ```
    case streamingNotSupported
    
    /// The provided file data is invalid or corrupted.
    ///
    /// This error occurs when:
    /// - File data is empty
    /// - File format is not supported
    /// - File exceeds size limits
    /// - File data is corrupted
    ///
    /// ## Example
    /// ```swift
    /// do {
    ///     let emptyData = Data()
    ///     let file = try await openAI.files.upload(
    ///         file: emptyData,
    ///         purpose: "fine-tune"
    ///     )
    /// } catch OpenAIError.invalidFileData {
    ///     print("Please provide valid file data")
    /// }
    /// ```
    case invalidFileData
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .authenticationFailed:
            return "Authentication failed. Check your API key."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .apiError(let error):
            return error.error.message
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingFailed(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .clientError(let statusCode):
            return "Client error with status code: \(statusCode)"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .unknownError(let statusCode):
            return "Unknown error with status code: \(statusCode)"
        case .streamingNotSupported:
            return "Streaming is not supported for this request"
        case .invalidFileData:
            return "Invalid file data provided"
        }
    }
}

/// A structured error response from the OpenAI API.
///
/// When the OpenAI API encounters an error, it returns a structured JSON response
/// containing detailed information about what went wrong. This struct represents
/// the top-level error container.
///
/// ## Structure
///
/// The API returns errors in the following format:
/// ```json
/// {
///   "error": {
///     "message": "Invalid API key provided",
///     "type": "invalid_request_error",
///     "param": null,
///     "code": "invalid_api_key"
///   }
/// }
/// ```
///
/// ## Usage
///
/// ```swift
/// do {
///     let completion = try await openAI.completions.create(...)
/// } catch OpenAIError.apiError(let apiError) {
///     // Access the detailed error information
///     let errorDetail = apiError.error
///     print("Error: \(errorDetail.message)")
///     
///     if let errorType = errorDetail.type {
///         print("Type: \(errorType)")
///     }
/// }
/// ```
///
/// - SeeAlso: ``APIErrorDetail``, ``OpenAIError/apiError(_:)``
public struct APIError: Codable, Sendable {
    /// The detailed error information from the API.
    ///
    /// Contains the actual error message, type, and other metadata
    /// that helps identify and resolve the issue.
    public let error: APIErrorDetail
}

/// Detailed error information from the OpenAI API.
///
/// This struct contains the specific details about an API error, including
/// the error message, type classification, affected parameter, and error code.
///
/// ## Error Types
///
/// OpenAI categorizes errors into several types:
/// - `invalid_request_error`: The request was malformed or missing required parameters
/// - `authentication_error`: API key issues or permission problems
/// - `rate_limit_error`: Too many requests in a given time period
/// - `server_error`: Issues on OpenAI's servers
/// - `engine_error`: Problems with the specific model/engine
///
/// ## Examples
///
/// ### Invalid Request
/// ```swift
/// // Error when max_tokens exceeds model limit
/// APIErrorDetail(
///     message: "max_tokens is too large: 10000. Maximum for this model is 4096.",
///     type: "invalid_request_error",
///     param: "max_tokens",
///     code: nil
/// )
/// ```
///
/// ### Authentication Error
/// ```swift
/// // Error with invalid API key
/// APIErrorDetail(
///     message: "Incorrect API key provided",
///     type: "authentication_error",
///     param: nil,
///     code: "invalid_api_key"
/// )
/// ```
///
/// ### Rate Limit Error
/// ```swift
/// // Error when exceeding rate limits
/// APIErrorDetail(
///     message: "Rate limit exceeded for requests",
///     type: "rate_limit_error",
///     param: nil,
///     code: "rate_limit_exceeded"
/// )
/// ```
///
/// ## Error Handling Best Practices
///
/// ```swift
/// func handleAPIError(_ error: APIErrorDetail) {
///     switch error.type {
///     case "invalid_request_error":
///         // Check the param field to identify the problematic parameter
///         if let param = error.param {
///             print("Invalid parameter: \(param)")
///         }
///         
///     case "authentication_error":
///         // Prompt user to check their API key
///         print("Authentication failed: \(error.message)")
///         
///     case "rate_limit_error":
///         // Implement retry logic with exponential backoff
///         print("Rate limited. Wait before retrying.")
///         
///     case "server_error":
///         // Retry after a delay, as these are usually transient
///         print("Server error. Please try again later.")
///         
///     default:
///         // Log unexpected error types
///         print("Unexpected error: \(error.message)")
///     }
/// }
/// ```
///
/// - SeeAlso: ``APIError``, ``OpenAIError/apiError(_:)``
public struct APIErrorDetail: Codable, Sendable {
    /// The human-readable error message.
    ///
    /// This message provides a clear description of what went wrong
    /// and often includes suggestions for how to fix the issue.
    ///
    /// ## Examples
    /// - "Invalid API key provided"
    /// - "Rate limit exceeded for requests"
    /// - "The model `gpt-4` does not exist"
    public let message: String
    
    /// The type of error that occurred.
    ///
    /// Common error types include:
    /// - `invalid_request_error`: Problem with request format or parameters
    /// - `authentication_error`: API key or permission issues
    /// - `rate_limit_error`: Too many requests
    /// - `server_error`: OpenAI server issues
    /// - `engine_error`: Model-specific problems
    public let type: String?
    
    /// The parameter that caused the error, if applicable.
    ///
    /// This field helps identify which specific parameter in your request
    /// caused the error. For example, if `max_tokens` is too large,
    /// this field will contain `"max_tokens"`.
    ///
    /// ## Example
    /// ```swift
    /// if let param = error.param {
    ///     switch param {
    ///     case "max_tokens":
    ///         print("Adjust the max_tokens parameter")
    ///     case "temperature":
    ///         print("Temperature must be between 0 and 2")
    ///     default:
    ///         print("Issue with parameter: \(param)")
    ///     }
    /// }
    /// ```
    public let param: String?
    
    /// A machine-readable error code.
    ///
    /// Some errors include specific codes that can be used for
    /// programmatic error handling. Examples include:
    /// - `invalid_api_key`: The provided API key is invalid
    /// - `rate_limit_exceeded`: Rate limit has been exceeded
    /// - `model_not_found`: The specified model doesn't exist
    ///
    /// ## Usage
    /// ```swift
    /// if let code = error.code {
    ///     switch code {
    ///     case "invalid_api_key":
    ///         // Prompt for new API key
    ///     case "rate_limit_exceeded":
    ///         // Implement backoff strategy
    ///     case "model_not_found":
    ///         // Use fallback model
    ///     default:
    ///         // Handle other codes
    ///     }
    /// }
    /// ```
    public let code: String?
}