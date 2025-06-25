import Foundation

/// An endpoint for interacting with OpenAI's Chat Completions API.
///
/// The `ChatEndpoint` class provides methods to create chat completions, stream responses,
/// and manage existing completions. It serves as the primary interface for conversational AI
/// interactions using OpenAI's chat models.
///
/// ## Overview
///
/// This endpoint supports both standard and streaming chat completions, allowing you to:
/// - Generate chat completions with various models
/// - Stream responses in real-time for better user experience
/// - Retrieve, list, and delete existing completions
///
/// ## Example Usage
///
/// ```swift
/// let client = OpenAIKit(apiKey: "your-api-key")
///
/// // Create a simple chat completion
/// let request = ChatCompletionRequest(
///     messages: [
///         ChatMessage(role: .system, content: "You are a helpful assistant."),
///         ChatMessage(role: .user, content: "What is Swift?")
///     ],
///     model: "gpt-4"
/// )
///
/// do {
///     let response = try await client.chat.completions(request)
///     print(response.choices.first?.message.content ?? "No response")
/// } catch {
///     print("Error: \(error)")
/// }
/// ```
///
/// ## Streaming Example
///
/// ```swift
/// // Stream a chat completion for real-time responses
/// let streamRequest = ChatCompletionRequest(
///     messages: [ChatMessage(role: .user, content: "Tell me a story")],
///     model: "gpt-4"
/// )
///
/// for try await chunk in client.chat.completionsStream(streamRequest) {
///     if let content = chunk.choices.first?.delta.content {
///         print(content, terminator: "")
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Creating Completions
/// - ``completions(_:)``
/// - ``completionsStream(_:)``
///
/// ### Managing Completions
/// - ``getCompletion(id:)``
/// - ``listCompletions(limit:after:before:)``
/// - ``deleteCompletion(id:)``
///
/// ### Response Types
/// - ``ListResponse``
/// - ``DeletionResponse``
public final class ChatEndpoint: Sendable {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    /// Creates a chat completion for the provided messages and parameters.
    ///
    /// This method sends a request to OpenAI's Chat Completions API and returns a complete response.
    /// Use this for standard chat interactions where you want to receive the full response at once.
    ///
    /// - Parameter request: A ``ChatCompletionRequest`` containing the messages and configuration for the completion.
    ///
    /// - Returns: A ``ChatCompletionResponse`` containing the model's response and metadata.
    ///
    /// - Throws: An error if the network request fails or if the API returns an error response.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let request = ChatCompletionRequest(
    ///     messages: [
    ///         ChatMessage(role: .system, content: "You are a Swift programming expert."),
    ///         ChatMessage(role: .user, content: "How do I use async/await in Swift?")
    ///     ],
    ///     model: "gpt-4",
    ///     temperature: 0.7,
    ///     maxTokens: 500
    /// )
    ///
    /// do {
    ///     let response = try await chat.completions(request)
    ///     if let message = response.choices.first?.message {
    ///         print("Assistant: \(message.content ?? "")")
    ///     }
    /// } catch {
    ///     print("Chat completion failed: \(error)")
    /// }
    /// ```
    ///
    /// ## Common Errors
    ///
    /// - **Invalid API Key**: Ensure your API key is valid and has appropriate permissions
    /// - **Rate Limit**: You may be exceeding your rate limit; implement retry logic
    /// - **Invalid Model**: The specified model may not exist or you may not have access to it
    /// - **Token Limit**: The request may exceed the model's token limit
    ///
    /// - SeeAlso: ``completionsStream(_:)`` for streaming responses
    public func completions(_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        let apiRequest = ChatCompletionAPIRequest(request: request)
        return try await networkClient.execute(apiRequest)
    }
    
    /// Creates a streaming chat completion for real-time response generation.
    ///
    /// This method returns an asynchronous stream that yields response chunks as they are generated
    /// by the model. This is ideal for providing a more responsive user experience, especially for
    /// longer responses.
    ///
    /// - Parameter request: A ``ChatCompletionRequest`` containing the messages and configuration.
    ///                      The `stream` parameter will be automatically set to `true`.
    ///
    /// - Returns: An `AsyncThrowingStream` of ``ChatStreamChunk`` objects, each containing a portion of the response.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let request = ChatCompletionRequest(
    ///     messages: [
    ///         ChatMessage(role: .user, content: "Write a short story about a robot")
    ///     ],
    ///     model: "gpt-4"
    /// )
    ///
    /// // Collect the complete response
    /// var fullResponse = ""
    /// do {
    ///     for try await chunk in chat.completionsStream(request) {
    ///         if let content = chunk.choices.first?.delta.content {
    ///             fullResponse += content
    ///             print(content, terminator: "") // Print as it streams
    ///         }
    ///     }
    /// } catch {
    ///     print("Streaming error: \(error)")
    /// }
    /// ```
    ///
    /// ## Advanced Usage with Function Calls
    ///
    /// ```swift
    /// let request = ChatCompletionRequest(
    ///     messages: messages,
    ///     model: "gpt-4",
    ///     tools: [weatherTool]
    /// )
    ///
    /// for try await chunk in chat.completionsStream(request) {
    ///     // Handle content chunks
    ///     if let content = chunk.choices.first?.delta.content {
    ///         print(content, terminator: "")
    ///     }
    ///     
    ///     // Handle tool calls
    ///     if let toolCalls = chunk.choices.first?.delta.toolCalls {
    ///         // Process streaming tool calls
    ///     }
    /// }
    /// ```
    ///
    /// ## Notes
    ///
    /// - The stream automatically handles the `stream: true` parameter
    /// - Each chunk contains incremental updates to the response
    /// - The stream completes when the model finishes generating
    /// - Errors are thrown through the stream if they occur
    ///
    /// - SeeAlso: ``completions(_:)`` for non-streaming responses
    public func completionsStream(_ request: ChatCompletionRequest) -> AsyncThrowingStream<ChatStreamChunk, Error> {
        var streamRequest = request
        streamRequest = ChatCompletionRequest(
            messages: request.messages,
            model: request.model,
            audio: request.audio,
            frequencyPenalty: request.frequencyPenalty,
            functionCall: request.functionCall,
            functions: request.functions,
            logitBias: request.logitBias,
            logprobs: request.logprobs,
            maxCompletionTokens: request.maxCompletionTokens,
            maxTokens: request.maxTokens,
            metadata: request.metadata,
            modalities: request.modalities,
            n: request.n,
            parallelToolCalls: request.parallelToolCalls,
            prediction: request.prediction,
            presencePenalty: request.presencePenalty,
            reasoningEffort: request.reasoningEffort,
            responseFormat: request.responseFormat,
            seed: request.seed,
            serviceTier: request.serviceTier,
            stop: request.stop,
            store: request.store,
            stream: true,
            streamOptions: request.streamOptions,
            temperature: request.temperature,
            toolChoice: request.toolChoice,
            tools: request.tools,
            topLogprobs: request.topLogprobs,
            topP: request.topP,
            user: request.user,
            webSearchOptions: request.webSearchOptions
        )
        
        let apiRequest = ChatCompletionStreamAPIRequest(request: streamRequest)
        return networkClient.stream(apiRequest)
    }
    
    /// Retrieves a specific chat completion by its ID.
    ///
    /// Use this method to fetch details about a previously created chat completion.
    /// This is useful for retrieving stored completions or checking the status of a completion.
    ///
    /// - Parameter id: The unique identifier of the chat completion to retrieve.
    ///
    /// - Returns: A ``ChatCompletionResponse`` containing the complete details of the requested completion.
    ///
    /// - Throws: An error if the completion is not found or if the request fails.
    ///
    /// ## Example
    ///
    /// ```swift
    /// do {
    ///     let completion = try await chat.getCompletion(id: "chatcmpl-abc123")
    ///     print("Model used: \(completion.model)")
    ///     print("Created at: \(completion.created)")
    ///     if let content = completion.choices.first?.message.content {
    ///         print("Response: \(content)")
    ///     }
    /// } catch {
    ///     print("Failed to retrieve completion: \(error)")
    /// }
    /// ```
    ///
    /// ## Notes
    ///
    /// - The completion ID is returned in the response when you create a completion
    /// - Completions may be stored for a limited time depending on your API plan
    /// - You must have appropriate permissions to access the completion
    ///
    /// - SeeAlso: ``listCompletions(limit:after:before:)`` to list multiple completions
    public func getCompletion(id: String) async throws -> ChatCompletionResponse {
        let request = GetChatCompletionRequest(completionId: id)
        return try await networkClient.execute(request)
    }
    
    /// Lists chat completions with pagination support.
    ///
    /// Retrieves a paginated list of chat completions associated with your API key.
    /// Use the pagination parameters to navigate through large sets of completions.
    ///
    /// - Parameters:
    ///   - limit: The maximum number of completions to return (defaults to 20, maximum 100).
    ///   - after: A cursor for pagination. Use the `lastId` from a previous response to get the next page.
    ///   - before: A cursor for pagination. Use the `firstId` from a previous response to get the previous page.
    ///
    /// - Returns: A ``ListResponse`` containing an array of ``ChatCompletionResponse`` objects and pagination metadata.
    ///
    /// - Throws: An error if the request fails or if invalid parameters are provided.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // List the first 10 completions
    /// do {
    ///     let response = try await chat.listCompletions(limit: 10)
    ///     
    ///     for completion in response.data {
    ///         print("ID: \(completion.id)")
    ///         print("Model: \(completion.model)")
    ///         print("Created: \(completion.created)")
    ///         print("---")
    ///     }
    ///     
    ///     // Check if there are more pages
    ///     if response.hasMore {
    ///         // Get the next page
    ///         let nextPage = try await chat.listCompletions(
    ///             limit: 10,
    ///             after: response.lastId
    ///         )
    ///     }
    /// } catch {
    ///     print("Failed to list completions: \(error)")
    /// }
    /// ```
    ///
    /// ## Pagination
    ///
    /// The response includes pagination metadata:
    /// - `hasMore`: Indicates if there are more items available
    /// - `firstId`: The ID of the first item in the current page
    /// - `lastId`: The ID of the last item in the current page
    ///
    /// Use these values with the `after` and `before` parameters to navigate through pages.
    ///
    /// - SeeAlso: ``getCompletion(id:)`` to retrieve a specific completion
    public func listCompletions(limit: Int? = nil, after: String? = nil, before: String? = nil) async throws -> ListResponse<ChatCompletionResponse> {
        let request = ListChatCompletionsRequest(limit: limit, after: after, before: before)
        return try await networkClient.execute(request)
    }
    
    /// Deletes a specific chat completion.
    ///
    /// Permanently removes a chat completion from your account. This action cannot be undone.
    ///
    /// - Parameter id: The unique identifier of the chat completion to delete.
    ///
    /// - Returns: A ``DeletionResponse`` confirming the deletion status.
    ///
    /// - Throws: An error if the completion is not found, if you don't have permission to delete it,
    ///           or if the request fails.
    ///
    /// ## Example
    ///
    /// ```swift
    /// do {
    ///     let deletionResponse = try await chat.deleteCompletion(id: "chatcmpl-abc123")
    ///     
    ///     if deletionResponse.deleted {
    ///         print("Successfully deleted completion: \(deletionResponse.id)")
    ///     } else {
    ///         print("Failed to delete completion")
    ///     }
    /// } catch {
    ///     print("Deletion error: \(error)")
    /// }
    /// ```
    ///
    /// ## Important Notes
    ///
    /// - Deletion is permanent and cannot be reversed
    /// - You can only delete completions associated with your API key
    /// - Some completions may be protected from deletion based on your plan
    ///
    /// - SeeAlso: ``listCompletions(limit:after:before:)`` to find completions to delete
    public func deleteCompletion(id: String) async throws -> DeletionResponse {
        let request = DeleteChatCompletionRequest(completionId: id)
        return try await networkClient.execute(request)
    }
}

private struct ChatCompletionAPIRequest: Request {
    typealias Body = ChatCompletionRequest
    typealias Response = ChatCompletionResponse
    
    let path = "chat/completions"
    let method: HTTPMethod = .post
    let body: ChatCompletionRequest?
    
    init(request: ChatCompletionRequest) {
        self.body = request
    }
}

private struct ChatCompletionStreamAPIRequest: StreamableRequest {
    typealias Body = ChatCompletionRequest
    typealias Response = ChatCompletionResponse
    typealias StreamResponse = ChatStreamChunk
    
    let path = "chat/completions"
    let method: HTTPMethod = .post
    let body: ChatCompletionRequest?
    
    init(request: ChatCompletionRequest) {
        self.body = request
    }
}

private struct GetChatCompletionRequest: Request {
    typealias Body = EmptyBody
    typealias Response = ChatCompletionResponse
    
    let path: String
    let method: HTTPMethod = .get
    let body: EmptyBody? = nil
    
    init(completionId: String) {
        self.path = "chat/completions/\(completionId)"
    }
}

private struct ListChatCompletionsRequest: Request {
    typealias Body = EmptyBody
    typealias Response = ListResponse<ChatCompletionResponse>
    
    let path: String
    let method: HTTPMethod = .get
    let body: EmptyBody? = nil
    
    init(limit: Int?, after: String?, before: String?) {
        var queryItems: [URLQueryItem] = []
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let after = after {
            queryItems.append(URLQueryItem(name: "after", value: after))
        }
        if let before = before {
            queryItems.append(URLQueryItem(name: "before", value: before))
        }
        
        if !queryItems.isEmpty {
            var components = URLComponents()
            components.queryItems = queryItems
            self.path = "chat/completions\(components.url?.query.map { "?\($0)" } ?? "")"
        } else {
            self.path = "chat/completions"
        }
    }
}

private struct DeleteChatCompletionRequest: Request {
    typealias Body = EmptyBody
    typealias Response = DeletionResponse
    
    let path: String
    let method: HTTPMethod = .delete
    let body: EmptyBody? = nil
    
    init(completionId: String) {
        self.path = "chat/completions/\(completionId)"
    }
}

/// A paginated response containing a list of items.
///
/// `ListResponse` is a generic container used by various list endpoints to return
/// paginated results along with metadata for navigation through large datasets.
///
/// ## Overview
///
/// This structure provides a consistent interface for paginated API responses,
/// making it easy to implement pagination in your applications. It includes
/// the requested data items along with cursor information for fetching
/// additional pages.
///
/// ## Example Usage
///
/// ```swift
/// func fetchAllCompletions() async throws -> [ChatCompletionResponse] {
///     var allCompletions: [ChatCompletionResponse] = []
///     var hasMore = true
///     var afterCursor: String? = nil
///     
///     while hasMore {
///         let response = try await chat.listCompletions(
///             limit: 50,
///             after: afterCursor
///         )
///         
///         allCompletions.append(contentsOf: response.data)
///         hasMore = response.hasMore
///         afterCursor = response.lastId
///     }
///     
///     return allCompletions
/// }
/// ```
///
/// ## Generic Type
///
/// The generic type `T` represents the type of items in the list. For chat completions,
/// this would be ``ChatCompletionResponse``.
public struct ListResponse<T: Codable & Sendable>: Codable, Sendable {
    /// The object type, typically "list".
    public let object: String
    
    /// An array of items returned in this page of results.
    ///
    /// The number of items is determined by the `limit` parameter in the request,
    /// up to the maximum allowed by the API.
    public let data: [T]
    
    /// The ID of the first item in the current page.
    ///
    /// Use this with the `before` parameter to fetch the previous page of results.
    /// Will be `nil` if the list is empty.
    public let firstId: String?
    
    /// The ID of the last item in the current page.
    ///
    /// Use this with the `after` parameter to fetch the next page of results.
    /// Will be `nil` if the list is empty.
    public let lastId: String?
    
    /// Indicates whether more items are available beyond this page.
    ///
    /// When `true`, you can use the `lastId` with the `after` parameter
    /// to fetch the next page of results.
    public let hasMore: Bool
}

/// A response confirming the deletion of a resource.
///
/// `DeletionResponse` is returned when successfully deleting a chat completion
/// or other resources through the API. It provides confirmation of the deletion
/// and the ID of the deleted resource.
///
/// ## Example
///
/// ```swift
/// do {
///     let response = try await chat.deleteCompletion(id: "chatcmpl-abc123")
///     
///     if response.deleted {
///         print("Successfully deleted \(response.object) with ID: \(response.id)")
///         // Output: "Successfully deleted chat.completion with ID: chatcmpl-abc123"
///     }
/// } catch {
///     print("Failed to delete completion: \(error)")
/// }
/// ```
public struct DeletionResponse: Codable, Sendable {
    /// The unique identifier of the deleted resource.
    ///
    /// This matches the ID that was provided in the deletion request.
    public let id: String
    
    /// The type of object that was deleted.
    ///
    /// For chat completions, this will be "chat.completion".
    public let object: String
    
    /// Indicates whether the deletion was successful.
    ///
    /// This will be `true` when the resource was successfully deleted,
    /// or `false` if the deletion failed (though typically a failed
    /// deletion will throw an error instead).
    public let deleted: Bool
}