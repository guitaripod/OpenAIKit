import Foundation

/// Provides access to OpenAI's Files API endpoints.
///
/// The `FilesEndpoint` class manages file operations including uploading, listing,
/// retrieving, and deleting files. Files are used across various OpenAI services
/// for providing training data, documents for assistants, batch processing inputs, and more.
///
/// ## Overview
///
/// Files uploaded to OpenAI can be used for:
/// - Fine-tuning custom models
/// - Providing knowledge to assistants
/// - Batch API processing
/// - Vision understanding tasks
///
/// ## File Size Limits
///
/// - Maximum file size: 512 MB
/// - For fine-tuning: Up to 1 GB (contact OpenAI for larger files)
///
/// ## Example
///
/// ```swift
/// let client = OpenAI(apiKey: "your-api-key")
/// 
/// // Upload a file
/// let data = try Data(contentsOf: fileURL)
/// let request = FileRequest(
///     file: data,
///     fileName: "document.pdf",
///     purpose: .assistants
/// )
/// let uploadedFile = try await client.files.upload(request)
/// 
/// // List files
/// let files = try await client.files.list(purpose: .assistants)
/// for file in files.data {
///     print("\(file.filename): \(file.bytes) bytes")
/// }
/// 
/// // Retrieve file metadata
/// let fileInfo = try await client.files.retrieve(fileId: uploadedFile.id)
/// 
/// // Download file content
/// let content = try await client.files.content(fileId: uploadedFile.id)
/// 
/// // Delete file
/// let deletion = try await client.files.delete(fileId: uploadedFile.id)
/// ```
///
/// ## Topics
///
/// ### Uploading Files
/// - ``upload(_:)``
///
/// ### Listing and Retrieving Files
/// - ``list(purpose:limit:after:)``
/// - ``retrieve(fileId:)``
/// - ``content(fileId:)``
///
/// ### Deleting Files
/// - ``delete(fileId:)``
public final class FilesEndpoint: Sendable {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    /// Uploads a file to OpenAI.
    ///
    /// Upload files that can be used across various endpoints. The file size
    /// can be up to 512 MB. For fine-tuning, larger files up to 1 GB are supported
    /// (contact OpenAI for access).
    ///
    /// - Parameter request: A ``FileRequest`` containing the file data and metadata.
    /// - Returns: A ``FileObject`` representing the uploaded file.
    /// - Throws: An error if the upload fails or the file format is invalid.
    ///
    /// ## Supported Formats by Purpose
    ///
    /// - **Fine-tuning**: `.jsonl`
    /// - **Assistants**: `.txt`, `.md`, `.pdf`, `.docx`, `.json`, `.csv`, and more
    /// - **Batch**: `.jsonl`
    /// - **Vision**: `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Upload a JSONL file for fine-tuning
    /// let trainingData = """
    /// {"messages": [{"role": "system", "content": "You are a helpful assistant."}, {"role": "user", "content": "Hello"}, {"role": "assistant", "content": "Hi! How can I help you?"}]}
    /// {"messages": [{"role": "system", "content": "You are a helpful assistant."}, {"role": "user", "content": "What's the weather?"}, {"role": "assistant", "content": "I'd be happy to help with weather information. Could you tell me your location?"}]}
    /// """.data(using: .utf8)!
    /// 
    /// let request = FileRequest(
    ///     file: trainingData,
    ///     fileName: "training_examples.jsonl",
    ///     purpose: .fineTune
    /// )
    /// 
    /// let file = try await client.files.upload(request)
    /// print("Uploaded file ID: \(file.id)")
    /// ```
    public func upload(_ request: FileRequest) async throws -> FileObject {
        let apiRequest = FileUploadAPIRequest(request: request)
        return try await networkClient.upload(apiRequest)
    }
    
    /// Lists files belonging to the user's organization.
    ///
    /// Returns a paginated list of files that have been uploaded to OpenAI.
    /// You can filter by purpose and control pagination using the limit and after parameters.
    ///
    /// - Parameters:
    ///   - purpose: Filter by file purpose (optional).
    ///   - limit: Maximum number of files to return (1-10000, default 10000).
    ///   - after: Cursor for pagination. Use the ID of the last file from the previous page.
    /// - Returns: A ``FilesListResponse`` containing the list of files.
    /// - Throws: An error if the request fails.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // List all files
    /// let allFiles = try await client.files.list()
    /// print("Total files: \(allFiles.data.count)")
    /// 
    /// // List only fine-tuning files
    /// let fineTuneFiles = try await client.files.list(purpose: .fineTune)
    /// 
    /// // Paginate through files
    /// var hasMore = true
    /// var after: String? = nil
    /// 
    /// while hasMore {
    ///     let response = try await client.files.list(limit: 100, after: after)
    ///     for file in response.data {
    ///         print("File: \(file.filename)")
    ///     }
    ///     hasMore = response.hasMore
    ///     after = response.data.last?.id
    /// }
    /// ```
    public func list(purpose: FilePurpose? = nil, limit: Int? = nil, after: String? = nil) async throws -> FilesListResponse {
        let request = ListFilesRequest(purpose: purpose, limit: limit, after: after)
        return try await networkClient.execute(request)
    }
    
    /// Retrieves information about a specific file.
    ///
    /// Get metadata about a file including its size, purpose, and creation date.
    /// This doesn't download the file content - use ``content(fileId:)`` for that.
    ///
    /// - Parameter fileId: The ID of the file to retrieve.
    /// - Returns: A ``FileObject`` containing the file's metadata.
    /// - Throws: An error if the file doesn't exist or access is denied.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let fileInfo = try await client.files.retrieve(fileId: "file-abc123")
    /// print("File: \(fileInfo.filename)")
    /// print("Size: \(fileInfo.bytes) bytes")
    /// print("Purpose: \(fileInfo.purpose)")
    /// print("Created: \(Date(timeIntervalSince1970: TimeInterval(fileInfo.createdAt)))")
    /// ```
    public func retrieve(fileId: String) async throws -> FileObject {
        let request = RetrieveFileRequest(fileId: fileId)
        return try await networkClient.execute(request)
    }
    
    /// Deletes a file.
    ///
    /// Permanently removes a file from your organization. This action cannot be undone.
    /// Files that are actively being used (e.g., in an ongoing fine-tuning job) cannot be deleted.
    ///
    /// - Parameter fileId: The ID of the file to delete.
    /// - Returns: A ``DeletionResponse`` confirming the deletion.
    /// - Throws: An error if the file doesn't exist, is in use, or access is denied.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let response = try await client.files.delete(fileId: "file-abc123")
    /// if response.deleted {
    ///     print("Successfully deleted file: \(response.id)")
    /// }
    /// ```
    ///
    /// - Important: Files cannot be deleted if they are being used by:
    ///   - Active fine-tuning jobs
    ///   - Assistants that reference the file
    ///   - Pending batch jobs
    public func delete(fileId: String) async throws -> DeletionResponse {
        let request = DeleteFileRequest(fileId: fileId)
        return try await networkClient.execute(request)
    }
    
    /// Downloads the content of a file.
    ///
    /// Retrieves the actual file content as raw data. Use this to download files
    /// you've previously uploaded or files generated by OpenAI (e.g., fine-tuning results).
    ///
    /// - Parameter fileId: The ID of the file to download.
    /// - Returns: The file content as `Data`.
    /// - Throws: An error if the file doesn't exist or access is denied.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Download file content
    /// let fileData = try await client.files.content(fileId: "file-abc123")
    /// 
    /// // Save to disk
    /// let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    /// let filePath = documentsPath.appendingPathComponent("downloaded_file.pdf")
    /// try fileData.write(to: filePath)
    /// 
    /// // Or process in memory
    /// if let text = String(data: fileData, encoding: .utf8) {
    ///     print("File content: \(text)")
    /// }
    /// ```
    ///
    /// - Note: Be mindful of memory usage when downloading large files.
    ///   Consider streaming or chunked processing for very large files.
    public func content(fileId: String) async throws -> Data {
        let request = FileContentRequest(fileId: fileId)
        return try await networkClient.execute(request)
    }
}

private struct FileUploadAPIRequest: UploadRequest {
    typealias Response = FileObject
    
    let path = "files"
    private let request: FileRequest
    
    init(request: FileRequest) {
        self.request = request
    }
    
    func multipartData(boundary: String) async throws -> Data {
        var data = Data()
        
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(request.fileName)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(mimeType(for: request.fileName))\r\n\r\n".data(using: .utf8)!)
        data.append(request.file)
        data.append("\r\n".data(using: .utf8)!)
        
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"purpose\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(request.purpose.rawValue)\r\n".data(using: .utf8)!)
        
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return data
    }
    
    private func mimeType(for fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "json", "jsonl": return "application/json"
        case "pdf": return "application/pdf"
        case "txt", "md": return "text/plain"
        case "csv": return "text/csv"
        case "xlsx": return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "pptx": return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        default: return "application/octet-stream"
        }
    }
}

private struct ListFilesRequest: Request {
    typealias Body = EmptyBody
    typealias Response = FilesListResponse
    
    let path: String
    let method: HTTPMethod = .get
    let body: EmptyBody? = nil
    
    init(purpose: FilePurpose?, limit: Int?, after: String?) {
        var queryItems: [URLQueryItem] = []
        if let purpose = purpose {
            queryItems.append(URLQueryItem(name: "purpose", value: purpose.rawValue))
        }
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let after = after {
            queryItems.append(URLQueryItem(name: "after", value: after))
        }
        
        if !queryItems.isEmpty {
            var components = URLComponents()
            components.queryItems = queryItems
            self.path = "files\(components.url?.query.map { "?\($0)" } ?? "")"
        } else {
            self.path = "files"
        }
    }
}

private struct RetrieveFileRequest: Request {
    typealias Body = EmptyBody
    typealias Response = FileObject
    
    let path: String
    let method: HTTPMethod = .get
    let body: EmptyBody? = nil
    
    init(fileId: String) {
        self.path = "files/\(fileId)"
    }
}

private struct DeleteFileRequest: Request {
    typealias Body = EmptyBody
    typealias Response = DeletionResponse
    
    let path: String
    let method: HTTPMethod = .delete
    let body: EmptyBody? = nil
    
    init(fileId: String) {
        self.path = "files/\(fileId)"
    }
}

private struct FileContentRequest: Request {
    typealias Body = EmptyBody
    typealias Response = Data
    
    let path: String
    let method: HTTPMethod = .get
    let body: EmptyBody? = nil
    
    init(fileId: String) {
        self.path = "files/\(fileId)/content"
    }
}