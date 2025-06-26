import Foundation

/// Provides access to the OpenAI Batch API endpoints.
///
/// The Batch API allows you to send asynchronous groups of requests with:
/// - 50% lower costs compared to synchronous APIs
/// - A separate pool of significantly higher rate limits
/// - A clear 24-hour turnaround time
///
/// ## Overview
///
/// The Batch API is ideal for processing jobs that don't require immediate responses,
/// such as:
/// - Running evaluations
/// - Classifying large datasets
/// - Embedding content repositories
///
/// ## Example Usage
///
/// ```swift
/// // 1. Prepare batch requests
/// let requests = [
///     BatchRequest(
///         customId: "request-1",
///         url: "/v1/chat/completions",
///         body: [
///             "model": .string(Models.Chat.gpt4oMini),
///             "messages": .array([
///                 .object([
///                     "role": .string("user"),
///                     "content": .string("Hello!")
///                 ])
///             ])
///         ]
///     )
/// ]
///
/// // 2. Create and upload batch file
/// let batchData = try BatchFileBuilder.createBatchFile(from: requests)
/// let file = try await openAI.files.upload(file: batchData, purpose: "batch")
///
/// // 3. Create batch
/// let batch = try await openAI.batches.create(
///     inputFileId: file.id,
///     endpoint: "/v1/chat/completions"
/// )
///
/// // 4. Check status
/// let status = try await openAI.batches.retrieve(batch.id)
/// print("Batch status: \(status.status)")
///
/// // 5. Retrieve results when complete
/// if let outputFileId = status.outputFileId {
///     let results = try await openAI.files.content(outputFileId)
///     let responses = try BatchFileBuilder.parseBatchResults(from: results)
/// }
/// ```
public struct BatchesEndpoint: Sendable {
    private let networkClient: NetworkClientProtocol
    
    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }
    
    /// Creates a batch from an uploaded file.
    ///
    /// The input file must be uploaded with purpose "batch" and contain
    /// requests in JSONL format. Each batch can include up to 50,000 requests
    /// and the input file can be up to 200 MB in size.
    ///
    /// - Parameters:
    ///   - inputFileId: The ID of the uploaded file containing batch requests
    ///   - endpoint: The API endpoint to use (e.g., "/v1/chat/completions")
    ///   - completionWindow: Time window for processing (currently only "24h" is supported)
    ///   - metadata: Optional metadata to attach to the batch
    /// - Returns: The created batch object
    /// - Throws: `OpenAIError` if the request fails
    ///
    /// ## Supported Endpoints
    /// - `/v1/chat/completions` - Chat Completions API
    /// - `/v1/embeddings` - Embeddings API
    /// - `/v1/completions` - Completions API
    /// - `/v1/responses` - Responses API
    public func create(
        inputFileId: String,
        endpoint: String,
        completionWindow: String = "24h",
        metadata: [String: String]? = nil
    ) async throws -> Batch {
        let request = CreateBatchRequest(
            inputFileId: inputFileId,
            endpoint: endpoint,
            completionWindow: completionWindow,
            metadata: metadata
        )
        
        return try await networkClient.execute(
            BatchRequest.Create(body: request)
        )
    }
    
    /// Retrieves a batch by ID.
    ///
    /// Use this to check the status of a batch and get information about
    /// its progress, completion, or any errors.
    ///
    /// - Parameter batchId: The ID of the batch to retrieve
    /// - Returns: The batch object
    /// - Throws: `OpenAIError` if the request fails
    ///
    /// ## Batch Statuses
    /// - `validating`: Input file is being validated
    /// - `failed`: Input file validation failed
    /// - `inProgress`: Batch is currently being processed
    /// - `finalizing`: Batch completed, results being prepared
    /// - `completed`: Batch completed, results ready
    /// - `expired`: Batch not completed within 24-hour window
    /// - `cancelling`: Batch is being cancelled
    /// - `cancelled`: Batch was cancelled
    public func retrieve(_ batchId: String) async throws -> Batch {
        return try await networkClient.execute(
            BatchRequest.Retrieve(batchId: batchId)
        )
    }
    
    /// Cancels an in-progress batch.
    ///
    /// The batch's status will change to `cancelling` until in-flight
    /// requests are complete (up to 10 minutes), after which the status
    /// will change to `cancelled`.
    ///
    /// - Parameter batchId: The ID of the batch to cancel
    /// - Returns: The cancelled batch object
    /// - Throws: `OpenAIError` if the request fails
    public func cancel(_ batchId: String) async throws -> Batch {
        return try await networkClient.execute(
            BatchRequest.Cancel(batchId: batchId)
        )
    }
    
    /// Lists all batches for the organization.
    ///
    /// For organizations with many batches, use the `limit` and `after`
    /// parameters to paginate results.
    ///
    /// - Parameters:
    ///   - after: A cursor for pagination (batch ID to start after)
    ///   - limit: Maximum number of batches to return (default: 20, max: 100)
    /// - Returns: A paginated list of batches
    /// - Throws: `OpenAIError` if the request fails
    public func list(
        after: String? = nil,
        limit: Int? = nil
    ) async throws -> ListBatchesResponse {
        return try await networkClient.execute(
            BatchRequest.List(after: after, limit: limit)
        )
    }
    
    /// Waits for a batch to complete, checking status periodically.
    ///
    /// This is a convenience method that polls the batch status until
    /// it reaches a terminal state (completed, failed, expired, or cancelled).
    ///
    /// - Parameters:
    ///   - batchId: The ID of the batch to wait for
    ///   - checkInterval: How often to check status in seconds (default: 30)
    ///   - timeout: Maximum time to wait in seconds (default: 86400 = 24 hours)
    /// - Returns: The final batch object
    /// - Throws: `OpenAIError` if the request fails or timeout is reached
    public func waitForCompletion(
        _ batchId: String,
        checkInterval: TimeInterval = 30,
        timeout: TimeInterval = 86400
    ) async throws -> Batch {
        let startTime = Date()
        
        while true {
            let batch = try await retrieve(batchId)
            
            if batch.isFinished {
                return batch
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= timeout {
                throw OpenAIError.unknownError(statusCode: 0)
            }
            
            try await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
        }
    }
}

// MARK: - Request Types

extension BatchRequest {
    struct Create: Request {
        typealias Body = CreateBatchRequest
        typealias Response = Batch
        
        let body: CreateBatchRequest?
        
        var path: String { "batches" }
        var method: HTTPMethod { .post }
    }
    
    struct Retrieve: Request {
        typealias Body = EmptyBody
        typealias Response = Batch
        
        let batchId: String
        
        var path: String { "batches/\(batchId)" }
        var method: HTTPMethod { .get }
        var body: EmptyBody? { nil }
    }
    
    struct Cancel: Request {
        typealias Body = EmptyBody
        typealias Response = Batch
        
        let batchId: String
        
        var path: String { "batches/\(batchId)/cancel" }
        var method: HTTPMethod { .post }
        var body: EmptyBody? { nil }
    }
    
    struct List: Request {
        typealias Body = EmptyBody
        typealias Response = ListBatchesResponse
        
        let after: String?
        let limit: Int?
        
        var path: String {
            var components = URLComponents()
            components.path = "batches"
            
            var queryItems: [URLQueryItem] = []
            if let after = after {
                queryItems.append(URLQueryItem(name: "after", value: after))
            }
            if let limit = limit {
                queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
            }
            
            if !queryItems.isEmpty {
                components.queryItems = queryItems
            }
            
            return components.string ?? "batches"
        }
        
        var method: HTTPMethod { .get }
        var body: EmptyBody? { nil }
    }
}