import Foundation

// Type alias to disambiguate from the Request protocol's Response associatedtype
typealias ResponsesAPIResponse = Response


/// An endpoint for interacting with OpenAI's Responses API.
///
/// The `ResponsesEndpoint` class provides methods to create responses with enhanced capabilities
/// including deep research, web search, MCP tool integration, and code interpretation. It supports
/// both regular and streaming responses, as well as management of existing responses.
///
/// ## Overview
///
/// The Responses API offers advanced features beyond standard chat completions:
/// - Deep research mode for comprehensive information gathering
/// - Web search integration for up-to-date information
/// - MCP (Model Context Protocol) tool support for external integrations
/// - Code interpreter for executing and analyzing code
/// - Inline citations and source annotations
///
/// ## Example Usage
///
/// ```swift
/// let client = OpenAIKit(apiKey: "your-api-key")
///
/// // Create a simple response
/// let request = ResponseRequest(
///     messages: [
///         ChatMessage(role: .user, content: "Research the latest AI developments")
///     ],
///     model: "gpt-4o"
/// )
///
/// do {
///     let response = try await client.responses.create(request)
///     print(response.content)
///     
///     // Check for web search results
///     if let outputs = response.outputs {
///         for output in outputs {
///             if case .webSearchCall(let search) = output {
///                 print("Searched for: \(search.query ?? "")")
///             }
///         }
///     }
/// } catch {
///     print("Error: \(error)")
/// }
/// ```
///
/// ## Deep Research Example
///
/// ```swift
/// // Create a deep research response with tools
/// let researchRequest = ResponseRequest(
///     messages: [
///         ChatMessage(role: .user, content: "Analyze recent quantum computing breakthroughs")
///     ],
///     model: "gpt-4o",
///     tools: [
///         .webSearchPreview(WebSearchPreviewTool()),
///         .codeInterpreter(CodeInterpreterTool())
///     ]
/// )
///
/// let response = try await client.responses.create(researchRequest)
/// ```
///
/// ## Streaming Example
///
/// ```swift
/// // Stream a response for real-time updates
/// let streamRequest = ResponseRequest(
///     messages: [ChatMessage(role: .user, content: "Explain machine learning")],
///     model: "gpt-4o"
/// )
///
/// for try await chunk in client.responses.createStream(streamRequest) {
///     if let content = chunk.delta?.content {
///         print(content, terminator: "")
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Creating Responses
/// - ``create(_:)``
/// - ``createStream(_:)``
///
/// ### Managing Responses
/// - ``get(id:)``
/// - ``delete(id:)``
/// - ``cancel(id:)``
public final class ResponsesEndpoint: Sendable {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    /// Creates a response for the provided messages and parameters.
    ///
    /// This method sends a request to OpenAI's Responses API and returns a complete response
    /// with enhanced capabilities including research, tool usage, and inline citations.
    ///
    /// - Parameter request: A ``ResponseRequest`` containing the messages and configuration.
    ///
    /// - Returns: A ``Response`` containing the generated content and metadata.
    ///
    /// - Throws: An error if the network request fails or if the API returns an error response.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let request = ResponseRequest(
    ///     messages: [
    ///         ChatMessage(role: .system, content: "You are a helpful research assistant."),
    ///         ChatMessage(role: .user, content: "What are the latest developments in renewable energy?")
    ///     ],
    ///     model: "gpt-4o",
    ///     tools: [.webSearchPreview(WebSearchPreviewTool())],
    ///     temperature: 0.7,
    ///     maxTokens: 2000
    /// )
    ///
    /// do {
    ///     let response = try await responses.create(request)
    ///     print("Response: \(response.content)")
    ///     
    ///     // Process annotations for citations
    ///     if let annotations = response.annotations {
    ///         for annotation in annotations {
    ///             if annotation.type == "citation" {
    ///                 print("Citation at [\(annotation.startIndex)-\(annotation.endIndex)]")
    ///             }
    ///         }
    ///     }
    /// } catch {
    ///     print("Response creation failed: \(error)")
    /// }
    /// ```
    ///
    /// ## Tool Usage
    ///
    /// The response may include tool outputs that were used during generation:
    ///
    /// ```swift
    /// if let outputs = response.outputs {
    ///     for output in outputs {
    ///         switch output {
    ///         case .webSearchCall(let search):
    ///             print("Web search: \(search.query ?? "")")
    ///             if let results = search.results {
    ///                 for result in results {
    ///                     print("- \(result.title): \(result.url)")
    ///                 }
    ///             }
    ///         case .mcpToolCall(let mcp):
    ///             print("MCP tool: \(mcp.toolName) on \(mcp.serverLabel)")
    ///         case .codeInterpreterCall(let code):
    ///             print("Code executed: \(code.language)")
    ///             print("Output: \(code.output ?? "No output")")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - SeeAlso: ``createStream(_:)`` for streaming responses
    public func create(_ request: ResponseRequest) async throws -> Response {
        let apiRequest = CreateResponseAPIRequest(request: request)
        return try await networkClient.execute(apiRequest)
    }
    
    /// Creates a streaming response for real-time generation.
    ///
    /// This method returns an asynchronous stream that yields response chunks as they are
    /// generated by the model. This provides a more responsive user experience for longer
    /// responses and allows you to process content incrementally.
    ///
    /// - Parameter request: A ``ResponseRequest`` containing the messages and configuration.
    ///
    /// - Returns: An `AsyncThrowingStream` of ``ResponseStreamChunk`` objects.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let request = ResponseRequest(
    ///     messages: [
    ///         ChatMessage(role: .user, content: "Write a detailed analysis of climate change")
    ///     ],
    ///     model: "gpt-4o",
    ///     tools: [.webSearchPreview(WebSearchPreviewTool())]
    /// )
    ///
    /// // Process the stream
    /// var fullContent = ""
    /// do {
    ///     for try await chunk in responses.createStream(request) {
    ///         switch chunk.type {
    ///         case "response.output_item.done":
    ///             if let item = chunk.item, item.type == "message" {
    ///                 if let content = item.content {
    ///                     fullContent += content
    ///                     print(content, terminator: "")
    ///                 }
    ///             }
    ///         case "response.done":
    ///             print("\\nCompleted!")
    ///         default:
    ///             break
    ///         }
    ///     }
    /// } catch {
    ///     print("Streaming error: \\(error)")
    /// }
    /// ```
    ///
    /// ## Stream Events
    ///
    /// The stream may include various event types:
    /// - `response.created` - Initial response metadata
    /// - `response.output_item.added` - New output item started (tool calls, reasoning)
    /// - `response.output_item.done` - Output item completed (messages, tool results)
    /// - `response.done` - Response completed with final usage statistics
    ///
    /// - SeeAlso: ``create(_:)`` for non-streaming responses
    public func createStream(_ request: ResponseRequest) -> AsyncThrowingStream<ResponseStreamChunk, Error> {
        let apiRequest = CreateResponseStreamAPIRequest(request: request)
        return networkClient.stream(apiRequest)
    }
    
    /// Retrieves a specific response by its ID.
    ///
    /// Use this method to fetch details about a previously created response.
    /// This is useful for retrieving stored responses or checking the status of a response.
    ///
    /// - Parameter id: The unique identifier of the response to retrieve.
    ///
    /// - Returns: A ``Response`` containing the complete details of the requested response.
    ///
    /// - Throws: An error if the response is not found or if the request fails.
    ///
    /// ## Example
    ///
    /// ```swift
    /// do {
    ///     let response = try await responses.get(id: "resp_abc123")
    ///     print("Response created at: \(response.created)")
    ///     print("Content: \(response.content)")
    ///     
    ///     // Check tool usage
    ///     if let outputs = response.outputs {
    ///         print("Used \(outputs.count) tools during generation")
    ///     }
    /// } catch {
    ///     print("Failed to retrieve response: \(error)")
    /// }
    /// ```
    ///
    /// - SeeAlso: ``delete(id:)`` to remove a response
    public func get(id: String) async throws -> Response {
        let request = GetResponseRequest(responseId: id)
        return try await networkClient.execute(request)
    }
    
    /// Deletes a specific response.
    ///
    /// Permanently removes a response from your account. This action cannot be undone.
    ///
    /// - Parameter id: The unique identifier of the response to delete.
    ///
    /// - Returns: A ``DeletionResponse`` confirming the deletion status.
    ///
    /// - Throws: An error if the response is not found, if you don't have permission to delete it,
    ///           or if the request fails.
    ///
    /// ## Example
    ///
    /// ```swift
    /// do {
    ///     let deletionResponse = try await responses.delete(id: "resp_abc123")
    ///     
    ///     if deletionResponse.deleted {
    ///         print("Successfully deleted response: \(deletionResponse.id)")
    ///     } else {
    ///         print("Failed to delete response")
    ///     }
    /// } catch {
    ///     print("Deletion error: \(error)")
    /// }
    /// ```
    ///
    /// ## Important Notes
    ///
    /// - Deletion is permanent and cannot be reversed
    /// - You can only delete responses associated with your API key
    /// - Some responses may be protected from deletion based on your plan
    ///
    /// - SeeAlso: ``get(id:)`` to retrieve response details before deletion
    public func delete(id: String) async throws -> DeletionResponse {
        let request = DeleteResponseRequest(responseId: id)
        return try await networkClient.execute(request)
    }
    
    /// Cancels an in-progress response generation.
    ///
    /// Use this method to stop a response that is currently being generated.
    /// This is particularly useful for long-running deep research responses.
    ///
    /// - Parameter id: The unique identifier of the response to cancel.
    ///
    /// - Returns: A ``Response`` with the partial content generated before cancellation.
    ///
    /// - Throws: An error if the response is not found, already completed, or if the request fails.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Start a long-running research task
    /// let request = ResponseRequest(
    ///     messages: [
    ///         ChatMessage(role: .user, content: "Comprehensive research on quantum computing")
    ///     ],
    ///     model: "gpt-4o",
    ///     tools: [.webSearchPreview(WebSearchPreviewTool())]
    /// )
    ///
    /// // Create the response asynchronously
    /// Task {
    ///     do {
    ///         let response = try await responses.create(request)
    ///         // Store the response ID for potential cancellation
    ///         let responseId = response.id
    ///         
    ///         // Later, if needed, cancel the response
    ///         let cancelledResponse = try await responses.cancel(id: responseId)
    ///         print("Response cancelled. Partial content: \(cancelledResponse.content)")
    ///     } catch {
    ///         print("Error: \(error)")
    ///     }
    /// }
    /// ```
    ///
    /// ## Notes
    ///
    /// - Only in-progress responses can be cancelled
    /// - The returned response contains any content generated before cancellation
    /// - Cancellation may not be immediate for responses in certain stages
    /// - You will be charged for any tokens generated before cancellation
    public func cancel(id: String) async throws -> Response {
        let request = CancelResponseRequest(responseId: id)
        return try await networkClient.execute(request)
    }
}

// MARK: - Private API Request Types

private struct CreateResponseAPIRequest: Request {
    typealias Body = ResponseRequest
    typealias Response = ResponsesAPIResponse
    
    let path = "responses"
    let method: HTTPMethod = .post
    let body: ResponseRequest?
    
    init(request: ResponseRequest) {
        self.body = request
    }
}

private struct CreateResponseStreamAPIRequest: StreamableRequest {
    typealias Body = ResponseRequest
    typealias Response = ResponsesAPIResponse
    typealias StreamResponse = ResponseStreamChunk
    
    let path = "responses"
    let method: HTTPMethod = .post
    let body: ResponseRequest?
    
    init(request: ResponseRequest) {
        // Create a new request with stream set to true
        self.body = ResponseRequest(
            input: request.input,
            model: request.model,
            tools: request.tools,
            temperature: request.temperature,
            maxOutputTokens: request.maxOutputTokens,
            responseFormat: request.responseFormat,
            metadata: request.metadata,
            stream: true
        )
    }
}

private struct GetResponseRequest: Request {
    typealias Body = EmptyBody
    typealias Response = ResponsesAPIResponse
    
    let path: String
    let method: HTTPMethod = .get
    let body: EmptyBody? = nil
    
    init(responseId: String) {
        self.path = "responses/\(responseId)"
    }
}

private struct DeleteResponseRequest: Request {
    typealias Body = EmptyBody
    typealias Response = DeletionResponse
    
    let path: String
    let method: HTTPMethod = .delete
    let body: EmptyBody? = nil
    
    init(responseId: String) {
        self.path = "responses/\(responseId)"
    }
}

private struct CancelResponseRequest: Request {
    typealias Body = EmptyBody
    typealias Response = ResponsesAPIResponse
    
    let path: String
    let method: HTTPMethod = .post
    let body: EmptyBody? = nil
    
    init(responseId: String) {
        self.path = "responses/\(responseId)/cancel"
    }
}

/// A chunk of a streaming response.
///
/// Represents an incremental update in a streaming response, containing
/// partial content and metadata as it's generated.
///
/// ## Example
/// ```swift
/// for try await chunk in responses.createStream(request) {
///     // Process based on event type
///     switch chunk.type {
///     case "response.created":
///         print("Response started: \(chunk.response?.id ?? "")")
///     case "response.output_item.added":
///         if let item = chunk.item {
///             print("New output item: \(item.type)")
///         }
///     case "response.output_item.done":
///         if let item = chunk.item, item.type == "message" {
///             print("Message: \(item.content ?? "")")
///         }
///     default:
///         break
///     }
/// }
/// ```
public struct ResponseStreamChunk: Codable, Sendable {
    /// The type of event (e.g., "response.created", "response.output_item.added")
    public let type: String?
    
    /// Sequence number for ordering events
    public let sequenceNumber: Int?
    
    /// The response object (for response.created events)
    public let response: Response?
    
    /// The output item (for output_item events)
    public let item: ResponseOutputItem?
    
    /// The index of the output item
    public let outputIndex: Int?
    
    private enum CodingKeys: String, CodingKey {
        case type
        case sequenceNumber = "sequence_number"
        case response
        case item
        case outputIndex = "output_index"
    }
}

