import Foundation

/// The main entry point for interacting with the OpenAI API.
///
/// `OpenAIKit` provides a convenient, type-safe interface to all OpenAI API endpoints.
/// It handles authentication, networking, and response parsing automatically.
///
/// ## Topics
///
/// ### Creating a Client
///
/// - ``init(apiKey:organization:project:)``
/// - ``init(configuration:)``
/// - ``Configuration``
///
/// ### Available Endpoints
///
/// - ``chat``
/// - ``audio``
/// - ``images``
/// - ``embeddings``
/// - ``models``
/// - ``moderations``
/// - ``files``
/// - ``fineTuning``
/// - ``assistants``
/// - ``threads``
/// - ``vectorStores``
/// - ``batch``
///
/// ## Example
///
/// ```swift
/// // Initialize the client
/// let openAI = OpenAIKit(apiKey: "your-api-key")
///
/// // Make a chat completion request
/// let response = try await openAI.chat.completions(
///     ChatCompletionRequest(
///         messages: [
///             ChatMessage(role: .user, content: "Hello!")
///         ],
///         model: "gpt-4o"
///     )
/// )
/// ```
public final class OpenAIKit: @unchecked Sendable {
    
    private let configuration: Configuration
    private let networkClient: NetworkClient
    
    /// Creates a new OpenAI API client with the specified API key.
    ///
    /// - Parameters:
    ///   - apiKey: Your OpenAI API key
    ///   - organization: Optional organization ID for scoping requests
    ///   - project: Optional project ID for scoping requests
    public init(apiKey: String, organization: String? = nil, project: String? = nil) {
        self.configuration = Configuration(apiKey: apiKey, organization: organization, project: project)
        self.networkClient = NetworkClient(configuration: configuration)
    }
    
    /// Creates a new OpenAI API client with a custom configuration.
    ///
    /// Use this initializer when you need to customize the base URL or timeout settings.
    ///
    /// - Parameter configuration: The configuration to use for API requests
    public init(configuration: Configuration) {
        self.configuration = configuration
        self.networkClient = NetworkClient(configuration: configuration)
    }
    
    /// Provides access to chat completion endpoints.
    ///
    /// Use this endpoint to generate text completions, engage in conversations,
    /// and utilize function calling capabilities.
    public lazy var chat = ChatEndpoint(networkClient: networkClient)
    
    /// Provides access to audio endpoints.
    ///
    /// Use this endpoint for text-to-speech generation, audio transcription,
    /// and audio translation.
    public lazy var audio = AudioEndpoint(networkClient: networkClient)
    
    /// Provides access to image generation and manipulation endpoints.
    ///
    /// Use this endpoint to generate images from text prompts, edit existing images,
    /// or create variations of images.
    public lazy var images = ImagesEndpoint(networkClient: networkClient)
    
    /// Provides access to text embedding endpoints.
    ///
    /// Use this endpoint to convert text into numerical vector representations
    /// for semantic search, clustering, and similarity comparisons.
    public lazy var embeddings = EmbeddingsEndpoint(networkClient: networkClient)
    
    /// Provides access to model information endpoints.
    ///
    /// Use this endpoint to list available models and retrieve model details.
    public lazy var models = ModelsEndpoint(networkClient: networkClient)
    
    /// Provides access to content moderation endpoints.
    ///
    /// Use this endpoint to check if text or images contain potentially harmful content.
    public lazy var moderations = ModerationsEndpoint(networkClient: networkClient)
    
    /// Provides access to file management endpoints.
    ///
    /// Use this endpoint to upload, list, retrieve, and delete files
    /// for use with fine-tuning and assistants.
    public lazy var files = FilesEndpoint(networkClient: networkClient)
    
    /// Provides access to fine-tuning endpoints.
    ///
    /// Use this endpoint to create and manage custom fine-tuned models.
    public lazy var fineTuning = FineTuningEndpoint(networkClient: networkClient)
    
    /// Provides access to assistants endpoints.
    ///
    /// Use this endpoint to create and manage AI assistants with persistent instructions
    /// and capabilities.
    public lazy var assistants = AssistantsEndpoint(networkClient: networkClient)
    
    /// Provides access to threads endpoints.
    ///
    /// Use this endpoint to create and manage conversation threads for assistants.
    public lazy var threads = ThreadsEndpoint(networkClient: networkClient)
    
    /// Provides access to vector store endpoints.
    ///
    /// Use this endpoint to create and manage vector stores for semantic search
    /// and retrieval augmented generation.
    public lazy var vectorStores = VectorStoresEndpoint(networkClient: networkClient)
    
    /// Provides access to batch processing endpoints.
    ///
    /// Use this endpoint to process multiple API requests asynchronously in batches.
    public lazy var batch = BatchEndpoint(networkClient: networkClient)
}

/// Configuration options for the OpenAI API client.
///
/// This struct contains all the settings needed to configure API requests,
/// including authentication credentials and network settings.
///
/// ## Topics
///
/// ### Authentication
///
/// - ``apiKey``
/// - ``organization``
/// - ``project``
///
/// ### Network Settings
///
/// - ``baseURL``
/// - ``timeoutInterval``
public struct Configuration: Sendable {
    /// The API key used for authentication.
    ///
    /// You can find your API key at [platform.openai.com/api-keys](https://platform.openai.com/api-keys).
    public let apiKey: String
    
    /// Optional organization ID for scoping requests.
    ///
    /// For users who belong to multiple organizations, you can specify which organization
    /// is used for an API request. Usage will count against the specified organization's quota.
    public let organization: String?
    
    /// Optional project ID for scoping requests.
    ///
    /// For users who belong to multiple projects, you can specify which project
    /// is used for an API request.
    public let project: String?
    
    /// The base URL for API requests.
    ///
    /// Defaults to `https://api.openai.com`. You can customize this for proxy servers
    /// or alternative endpoints.
    public let baseURL: URL
    
    /// The timeout interval for API requests in seconds.
    ///
    /// Defaults to 60 seconds. Increase this value for long-running operations
    /// like audio transcription or image generation.
    public let timeoutInterval: TimeInterval
    
    /// Creates a new configuration with the specified settings.
    ///
    /// - Parameters:
    ///   - apiKey: Your OpenAI API key
    ///   - organization: Optional organization ID for scoping requests
    ///   - project: Optional project ID for scoping requests
    ///   - baseURL: The base URL for API requests (defaults to OpenAI's API)
    ///   - timeoutInterval: The timeout interval in seconds (defaults to 60)
    public init(
        apiKey: String,
        organization: String? = nil,
        project: String? = nil,
        baseURL: URL = URL(string: "https://api.openai.com")!,
        timeoutInterval: TimeInterval = 60
    ) {
        self.apiKey = apiKey
        self.organization = organization
        self.project = project
        self.baseURL = baseURL
        self.timeoutInterval = timeoutInterval
    }
}