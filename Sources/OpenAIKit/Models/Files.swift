import Foundation

/// Represents a file stored in OpenAI's system.
///
/// Files are used to provide input data for various OpenAI services including
/// fine-tuning, assistants, and batch processing. Once uploaded, files can be
/// referenced by their ID in API requests.
///
/// ## Example
///
/// ```swift
/// // Upload a file
/// let fileData = try Data(contentsOf: trainingDataURL)
/// let request = FileRequest(
///     file: fileData,
///     fileName: "training_data.jsonl",
///     purpose: .fineTune
/// )
/// let file = try await client.files.upload(request)
/// print("Uploaded file ID: \(file.id)")
/// ```
///
/// ## Topics
///
/// ### File Properties
/// - ``id``
/// - ``object``
/// - ``bytes``
/// - ``createdAt``
/// - ``filename``
/// - ``purpose``
public struct FileObject: Codable, Sendable {
    /// The unique identifier for the file.
    ///
    /// Use this ID to reference the file in other API calls.
    public let id: String
    
    /// The object type, which is always "file".
    public let object: String
    
    /// The size of the file in bytes.
    public let bytes: Int
    
    /// The Unix timestamp (in seconds) when the file was created.
    public let createdAt: Int
    
    /// The name of the file.
    public let filename: String
    
    /// The intended purpose of the file.
    ///
    /// See ``FilePurpose`` for available purposes.
    public let purpose: String
}

/// A request to upload a file to OpenAI.
///
/// Files must be in a format appropriate for their intended purpose.
/// For example, fine-tuning requires JSONL format, while assistants
/// can work with various document formats.
///
/// ## Supported Formats
///
/// The supported file formats vary by purpose:
/// - **Fine-tuning**: `.jsonl`
/// - **Assistants**: `.txt`, `.md`, `.pdf`, `.docx`, `.json`, `.csv`, etc.
/// - **Batch**: `.jsonl`
/// - **Vision**: `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`
///
/// ## Example
///
/// ```swift
/// // Upload training data for fine-tuning
/// let jsonlData = """
/// {"messages": [{"role": "user", "content": "Hello"}, {"role": "assistant", "content": "Hi there!"}]}
/// {"messages": [{"role": "user", "content": "How are you?"}, {"role": "assistant", "content": "I'm doing well!"}]}
/// """.data(using: .utf8)!
/// 
/// let request = FileRequest(
///     file: jsonlData,
///     fileName: "conversations.jsonl",
///     purpose: .fineTune
/// )
/// 
/// let file = try await client.files.upload(request)
/// ```
public struct FileRequest: Sendable {
    /// The file data to upload.
    public let file: Data
    
    /// The name of the file including extension.
    ///
    /// The extension helps determine the MIME type for upload.
    public let fileName: String
    
    /// The intended purpose for the uploaded file.
    public let purpose: FilePurpose
    
    /// Creates a file upload request.
    ///
    /// - Parameters:
    ///   - file: The file data to upload.
    ///   - fileName: The name of the file including extension.
    ///   - purpose: The intended purpose for the file.
    public init(file: Data, fileName: String, purpose: FilePurpose) {
        self.file = file
        self.fileName = fileName
        self.purpose = purpose
    }
}

/// The intended purpose for an uploaded file.
///
/// Different purposes have different requirements for file format and content.
/// Choose the appropriate purpose based on how you plan to use the file.
public enum FilePurpose: String, Codable, Sendable {
    /// Files for use with Assistants API.
    ///
    /// Supports various formats including text, PDF, and Office documents.
    case assistants
    
    /// Files for batch API processing.
    ///
    /// Must be in JSONL format with each line containing a valid batch request.
    case batch
    
    /// Files for fine-tuning models.
    ///
    /// Must be in JSONL format with training examples.
    case fineTune = "fine-tune"
    
    /// Files for vision understanding.
    ///
    /// Supports image formats like PNG, JPEG, GIF, and WebP.
    case vision
    
    /// Files containing user data for analysis.
    case userData = "user_data"
    
    /// Files for model evaluation.
    case evals
}

/// The response from listing files.
///
/// Contains a paginated list of files associated with your organization.
///
/// ## Example
///
/// ```swift
/// // List all files
/// let response = try await client.files.list()
/// print("Total files: \(response.data.count)")
/// 
/// // List files for a specific purpose
/// let fineTuneFiles = try await client.files.list(purpose: .fineTune)
/// for file in fineTuneFiles.data {
///     print("Fine-tune file: \(file.filename) (\(file.bytes) bytes)")
/// }
/// ```
///
/// ## Topics
///
/// ### Response Properties
/// - ``object``
/// - ``data``
/// - ``hasMore``
public struct FilesListResponse: Codable, Sendable {
    /// The object type, which is always "list".
    public let object: String
    
    /// Array of file objects.
    public let data: [FileObject]
    
    /// Whether there are more files available.
    ///
    /// If true, you can retrieve more files by making another request
    /// with the `after` parameter set to the ID of the last file in this list.
    public let hasMore: Bool
}