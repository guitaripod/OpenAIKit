import Foundation

/// A batch object that represents a collection of API requests to be processed asynchronously.
///
/// The Batch API allows you to send multiple requests in a single file and receive
/// the results asynchronously. This is useful for large-scale operations that don't
/// require immediate responses.
///
/// ## Overview
///
/// Batches are processed within a 24-hour window and support up to 50,000 requests
/// per batch with a maximum file size of 200 MB.
///
/// ## Example Usage
///
/// ```swift
/// // First, upload a file containing batch requests
/// let fileData = // ... your JSONL data
/// let file = try await openAI.files.upload(
///     file: fileData,
///     purpose: "batch"
/// )
///
/// // Create a batch
/// let batch = try await openAI.batches.create(
///     inputFileId: file.id,
///     endpoint: "/v1/chat/completions",
///     completionWindow: "24h"
/// )
///
/// // Check batch status
/// let status = try await openAI.batches.retrieve(batch.id)
/// print("Batch status: \(status.status)")
///
/// // When completed, download results
/// if let outputFileId = status.outputFileId {
///     let results = try await openAI.files.content(outputFileId)
/// }
/// ```
public struct Batch: Codable, Sendable {
    /// The unique identifier for the batch.
    public let id: String
    
    /// The object type, always "batch".
    public let object: String
    
    /// The OpenAI API endpoint used by the batch.
    public let endpoint: String
    
    /// Error information if the batch failed.
    public let errors: BatchErrors?
    
    /// The ID of the input file for the batch.
    public let inputFileId: String
    
    /// The time frame within which the batch should be processed.
    public let completionWindow: String
    
    /// The current status of the batch.
    public let status: BatchStatus
    
    /// The ID of the file containing outputs of successfully executed requests.
    public let outputFileId: String?
    
    /// The ID of the file containing outputs of requests with errors.
    public let errorFileId: String?
    
    /// Unix timestamp of when the batch was created.
    public let createdAt: Int
    
    /// Unix timestamp of when the batch started processing.
    public let inProgressAt: Int?
    
    /// Unix timestamp of when the batch will expire.
    public let expiresAt: Int?
    
    /// Unix timestamp of when the batch started finalizing.
    public let finalizingAt: Int?
    
    /// Unix timestamp of when the batch was completed.
    public let completedAt: Int?
    
    /// Unix timestamp of when the batch failed.
    public let failedAt: Int?
    
    /// Unix timestamp of when the batch expired.
    public let expiredAt: Int?
    
    /// Unix timestamp of when the batch started cancelling.
    public let cancellingAt: Int?
    
    /// Unix timestamp of when the batch was cancelled.
    public let cancelledAt: Int?
    
    /// Request counts for different statuses.
    public let requestCounts: RequestCounts
    
    /// Set of key-value pairs attached to the object.
    public let metadata: [String: String]?
}

/// The status of a batch.
public enum BatchStatus: String, Codable, Sendable {
    /// The batch has been created but not yet started processing.
    case validating
    
    /// The batch has failed validation.
    case failed
    
    /// The batch is currently being processed.
    case inProgress = "in_progress"
    
    /// The batch is being finalized.
    case finalizing
    
    /// The batch has been completed successfully.
    case completed
    
    /// The batch has expired.
    case expired
    
    /// The batch is being cancelled.
    case cancelling
    
    /// The batch has been cancelled.
    case cancelled
}

/// Error information for a batch.
public struct BatchErrors: Codable, Sendable {
    /// The object type, always "list".
    public let object: String?
    
    /// Array of error details.
    public let data: [BatchError]?
}

/// Individual error in a batch.
public struct BatchError: Codable, Sendable {
    /// Error code.
    public let code: String?
    
    /// Error message.
    public let message: String?
    
    /// Parameter that caused the error.
    public let param: String?
    
    /// Line number in the input file where the error occurred.
    public let line: Int?
}

/// Request counts for different statuses in a batch.
public struct RequestCounts: Codable, Sendable {
    /// Total number of requests in the batch.
    public let total: Int
    
    /// Number of requests that have been completed successfully.
    public let completed: Int
    
    /// Number of requests that failed.
    public let failed: Int
}

// MARK: - Requests

/// Request to create a new batch.
public struct CreateBatchRequest: Encodable, Sendable {
    /// The ID of an uploaded file that contains requests for the new batch.
    ///
    /// The file must be uploaded with purpose "batch".
    public let inputFileId: String
    
    /// The endpoint to be used for all requests in the batch.
    ///
    /// Currently only `/v1/chat/completions`, `/v1/embeddings`, and `/v1/completions` are supported.
    public let endpoint: String
    
    /// The time frame within which the batch should be processed.
    ///
    /// Currently only "24h" is supported.
    public let completionWindow: String
    
    /// Optional custom metadata for the batch.
    public let metadata: [String: String]?
    
    /// Initialize a create batch request.
    ///
    /// - Parameters:
    ///   - inputFileId: The ID of the uploaded file containing batch requests
    ///   - endpoint: The API endpoint to use (e.g., "/v1/chat/completions")
    ///   - completionWindow: Time window for processing (default: "24h")
    ///   - metadata: Optional metadata
    public init(
        inputFileId: String,
        endpoint: String,
        completionWindow: String = "24h",
        metadata: [String: String]? = nil
    ) {
        self.inputFileId = inputFileId
        self.endpoint = endpoint
        self.completionWindow = completionWindow
        self.metadata = metadata
    }
}

/// Response containing a list of batches.
public struct ListBatchesResponse: Decodable, Sendable {
    /// Array of batch objects.
    public let data: [Batch]
    
    /// The object type, always "list".
    public let object: String
    
    /// The ID of the first batch in the list.
    public let firstId: String?
    
    /// The ID of the last batch in the list.
    public let lastId: String?
    
    /// Whether there are more batches available.
    public let hasMore: Bool
}

// MARK: - Batch Request File Format

/// Represents a single request in a batch file.
///
/// Batch files must be in JSONL format with each line containing a request like this:
/// ```json
/// {"custom_id": "request-1", "method": "POST", "url": "/v1/chat/completions", "body": {...}}
/// ```
public struct BatchRequest: Codable, Sendable {
    /// A unique identifier for the request within the batch.
    public let customId: String
    
    /// The HTTP method (currently only "POST" is supported).
    public let method: String
    
    /// The API endpoint URL (e.g., "/v1/chat/completions").
    public let url: String
    
    /// The request body containing endpoint-specific parameters.
    public let body: [String: JSONValue]
    
    /// Initialize a batch request.
    ///
    /// - Parameters:
    ///   - customId: Unique identifier for this request
    ///   - method: HTTP method (default: "POST")
    ///   - url: API endpoint URL
    ///   - body: Request body parameters
    public init(
        customId: String,
        method: String = "POST",
        url: String,
        body: [String: JSONValue]
    ) {
        self.customId = customId
        self.method = method
        self.url = url
        self.body = body
    }
}

/// Represents the response for a single request in a batch results file.
public struct BatchResponse: Codable, Sendable {
    /// The unique identifier from the original request.
    public let customId: String
    
    /// The response data if the request succeeded.
    public let response: ResponseData?
    
    /// Error information if the request failed.
    public let error: BatchError?
    
    /// Response data for a successful request.
    public struct ResponseData: Codable, Sendable {
        /// HTTP status code.
        public let statusCode: Int
        
        /// The API endpoint that was called.
        public let requestId: String?
        
        /// The response body.
        public let body: [String: JSONValue]?
    }
}

// MARK: - Helper Extensions

extension Batch {
    /// Whether the batch has completed processing (successfully or not).
    public var isFinished: Bool {
        switch status {
        case .completed, .failed, .expired, .cancelled:
            return true
        default:
            return false
        }
    }
    
    /// Whether the batch is currently being processed.
    public var isProcessing: Bool {
        switch status {
        case .inProgress, .finalizing:
            return true
        default:
            return false
        }
    }
    
    /// The completion percentage based on request counts.
    public var completionPercentage: Double {
        guard requestCounts.total > 0 else { return 0 }
        return Double(requestCounts.completed + requestCounts.failed) / Double(requestCounts.total) * 100
    }
}

// MARK: - Batch File Creation Helpers

/// Helper to create a batch file from multiple requests.
public struct BatchFileBuilder {
    /// Create JSONL data from an array of batch requests.
    ///
    /// - Parameter requests: Array of batch requests
    /// - Returns: JSONL formatted data ready for upload
    public static func createBatchFile(from requests: [BatchRequest]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        var lines: [String] = []
        
        for request in requests {
            let data = try encoder.encode(request)
            if let line = String(data: data, encoding: .utf8) {
                lines.append(line)
            }
        }
        
        let jsonl = lines.joined(separator: "\n")
        guard let data = jsonl.data(using: .utf8) else {
            throw OpenAIError.encodingFailed(NSError(domain: "BatchFileBuilder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to encode JSONL data"]))
        }
        
        return data
    }
    
    /// Parse batch results from JSONL data.
    ///
    /// - Parameter data: JSONL formatted data from batch results
    /// - Returns: Array of batch responses
    public static func parseBatchResults(from data: Data) throws -> [BatchResponse] {
        guard let jsonl = String(data: data, encoding: .utf8) else {
            throw OpenAIError.decodingFailed(NSError(domain: "BatchFileBuilder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to decode JSONL data"]))
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        var responses: [BatchResponse] = []
        
        for line in jsonl.components(separatedBy: .newlines) {
            guard !line.isEmpty else { continue }
            
            guard let lineData = line.data(using: .utf8) else { continue }
            
            let response = try decoder.decode(BatchResponse.self, from: lineData)
            responses.append(response)
        }
        
        return responses
    }
}