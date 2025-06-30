import Foundation

/// The main entry point for interacting with the OpenAI API.
///
/// `OpenAIKit` is your gateway to OpenAI's powerful AI models. It provides a modern, type-safe
/// Swift interface that handles all the complexity of API communication, letting you focus on
/// building amazing AI-powered features.
///
/// ## Overview
///
/// OpenAIKit follows a simple, intuitive design:
/// 1. Create a client with your API key
/// 2. Access endpoints through descriptive properties
/// 3. Make requests with strongly-typed models
/// 4. Handle responses with comprehensive error information
///
/// ## Quick Start
///
/// ```swift
/// import OpenAIKit
/// 
/// // Initialize the client
/// let openAI = OpenAIKit(apiKey: "your-api-key")
/// 
/// // Generate text
/// let response = try await openAI.chat.completions(
///     ChatCompletionRequest(
///         messages: [ChatMessage(role: .user, content: "Hello!")],
///         model: Models.Chat.gpt4o
///     )
/// )
/// 
/// // Generate images
/// let image = try await openAI.images.generations(
///     ImageGenerationRequest(
///         prompt: "A serene landscape",
///         model: Models.Images.dallE3
///     )
/// )
/// 
/// // Create embeddings
/// let embedding = try await openAI.embeddings.create(
///     EmbeddingRequest(
///         input: "OpenAI is amazing",
///         model: Models.Embeddings.textEmbedding3Small
///     )
/// )
/// ```
///
/// ## Topics
///
/// ### Initialization
///
/// - ``init(apiKey:organization:project:)``
/// - ``init(configuration:)``
/// - ``Configuration``
///
/// ### Core Endpoints
///
/// - ``chat`` - Text generation and conversations
/// - ``images`` - Image generation and manipulation
/// - ``audio`` - Speech synthesis and transcription
/// - ``embeddings`` - Text embeddings for semantic search
///
/// ### Advanced Endpoints
///
/// - ``assistants`` - Persistent AI assistants
/// - ``threads`` - Conversation threads
/// - ``fineTuning`` - Custom model training
/// - ``vectorStores`` - Vector storage for retrieval
/// - ``batches`` - Batch processing
///
/// ### Utility Endpoints
///
/// - ``models`` - Available models
/// - ``moderations`` - Content moderation
/// - ``files`` - File management
///
/// ## Thread Safety
///
/// OpenAIKit is designed to be thread-safe. The client and all endpoints conform to `Sendable`,
/// making them safe to use across concurrent contexts in your Swift applications.
public final class OpenAIKit: @unchecked Sendable {
    
    private let configuration: Configuration
    private let networkClient: NetworkClient
    
    /// Creates a new OpenAI API client with the specified API key.
    ///
    /// This is the simplest way to get started with OpenAIKit. The client will use
    /// default settings suitable for most applications.
    ///
    /// - Parameters:
    ///   - apiKey: Your OpenAI API key from [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
    ///   - organization: Optional organization ID to scope requests to a specific organization
    ///   - project: Optional project ID to further scope requests within an organization
    ///
    /// - Important: Never hardcode API keys in your source code. Use environment variables
    ///   or secure storage mechanisms like Keychain (iOS/macOS) or AWS Secrets Manager.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Load from environment variable
    /// guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
    ///     fatalError("Missing OPENAI_API_KEY environment variable")
    /// }
    /// 
    /// let openAI = OpenAIKit(apiKey: apiKey)
    /// 
    /// // With organization scoping
    /// let openAI = OpenAIKit(
    ///     apiKey: apiKey,
    ///     organization: "org-abc123"
    /// )
    /// ```
    public init(apiKey: String, organization: String? = nil, project: String? = nil) {
        self.configuration = Configuration(apiKey: apiKey, organization: organization, project: project)
        self.networkClient = NetworkClient(configuration: configuration)
    }
    
    /// Creates a new OpenAI API client with a custom configuration.
    ///
    /// Use this initializer when you need advanced control over the client behavior,
    /// such as using a proxy server, custom timeouts, or connecting to a different endpoint.
    ///
    /// - Parameter configuration: A ``Configuration`` object containing all client settings
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Custom configuration for a proxy server
    /// let config = Configuration(
    ///     apiKey: "your-api-key",
    ///     organization: "org-abc123",
    ///     baseURL: URL(string: "https://openai-proxy.company.com")!,
    ///     timeoutInterval: 120  // 2 minutes for long operations
    /// )
    /// 
    /// let openAI = OpenAIKit(configuration: config)
    /// ```
    ///
    /// ## Common Use Cases
    ///
    /// - **Corporate Proxy**: Route requests through a company proxy server
    /// - **Extended Timeouts**: Increase timeout for audio transcription or image generation
    /// - **Custom Endpoints**: Connect to OpenAI-compatible APIs
    /// - **Testing**: Point to a mock server for unit tests
    public init(configuration: Configuration) {
        self.configuration = configuration
        self.networkClient = NetworkClient(configuration: configuration)
    }
    
    /// Provides access to chat completion endpoints.
    ///
    /// The chat endpoint is the primary interface for text generation. It supports:
    /// - Multi-turn conversations with context
    /// - System prompts for behavior customization  
    /// - Function calling for structured outputs
    /// - Vision capabilities for image understanding
    /// - Streaming for real-time responses
    /// - JSON mode for guaranteed valid JSON output
    ///
    /// ## Example
    ///
    /// ```swift
    /// let response = try await openAI.chat.completions(
    ///     ChatCompletionRequest(
    ///         messages: [
    ///             ChatMessage(role: .system, content: "You are a helpful assistant."),
    ///             ChatMessage(role: .user, content: "Explain recursion briefly.")
    ///         ],
    ///         model: Models.Chat.gpt4o,
    ///         temperature: 0.7
    ///     )
    /// )
    /// ```
    ///
    /// - SeeAlso: ``ChatEndpoint``, ``ChatCompletionRequest``, ``ChatMessage``
    public lazy var chat = ChatEndpoint(networkClient: networkClient)
    
    /// Provides access to audio endpoints.
    ///
    /// The audio endpoint enables speech-related capabilities:
    /// - **Text-to-Speech**: Convert text to natural-sounding speech
    /// - **Speech-to-Text**: Transcribe audio files to text
    /// - **Translation**: Translate audio to English text
    ///
    /// ## Supported Formats
    ///
    /// - Input: mp3, mp4, mpeg, mpga, m4a, wav, webm
    /// - Output: mp3, opus, aac, flac, wav, pcm
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Text-to-speech
    /// let speech = try await openAI.audio.speech(
    ///     SpeechRequest(
    ///         input: "Hello, world!",
    ///         model: Models.Audio.tts1,
    ///         voice: .nova
    ///     )
    /// )
    /// 
    /// // Speech-to-text
    /// let transcription = try await openAI.audio.transcriptions(
    ///     TranscriptionRequest(
    ///         file: audioData,
    ///         fileName: "audio.mp3",
    ///         model: Models.Audio.whisper1
    ///     )
    /// )
    /// ```
    ///
    /// - SeeAlso: ``AudioEndpoint``, ``SpeechRequest``, ``TranscriptionRequest``
    public lazy var audio = AudioEndpoint(networkClient: networkClient)
    
    /// Provides access to image generation and manipulation endpoints.
    ///
    /// The images endpoint offers powerful visual AI capabilities:
    /// - **Generation**: Create images from text descriptions
    /// - **Editing**: Modify existing images with prompts
    /// - **Variations**: Generate similar versions of an image
    ///
    /// ## Models
    ///
    /// - **DALL-E 3**: Latest model with best quality and prompt adherence
    /// - **DALL-E 2**: Previous generation, faster and cheaper
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Generate an image
    /// let result = try await openAI.images.generations(
    ///     ImageGenerationRequest(
    ///         prompt: "A futuristic city with flying cars at sunset",
    ///         model: Models.Images.dallE3,
    ///         size: .size1024x1024,
    ///         quality: .hd,
    ///         style: .vivid
    ///     )
    /// )
    /// 
    /// if let imageURL = result.data.first?.url {
    ///     // Download and display the image
    /// }
    /// ```
    ///
    /// - SeeAlso: ``ImagesEndpoint``, ``ImageGenerationRequest``, ``ImageEditRequest``
    public lazy var images = ImagesEndpoint(networkClient: networkClient)
    
    /// Provides access to text embedding endpoints.
    ///
    /// Embeddings are numerical representations of text that capture semantic meaning.
    /// Use them for:
    /// - **Semantic Search**: Find similar content
    /// - **Clustering**: Group related texts
    /// - **Recommendations**: Suggest similar items
    /// - **Anomaly Detection**: Identify outliers
    /// - **Classification**: Categorize text
    ///
    /// ## Models
    ///
    /// - **text-embedding-3-large**: Highest quality (3072 dimensions)
    /// - **text-embedding-3-small**: Balanced performance (1536 dimensions)
    /// - **text-embedding-ada-002**: Legacy model (1536 dimensions)
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Create embeddings for similarity comparison
    /// let texts = [
    ///     "The weather is beautiful today",
    ///     "It's a sunny and pleasant day",
    ///     "I love programming in Swift"
    /// ]
    /// 
    /// let response = try await openAI.embeddings.create(
    ///     EmbeddingRequest(
    ///         input: texts,
    ///         model: Models.Embeddings.textEmbedding3Small
    ///     )
    /// )
    /// 
    /// // Compare similarity using cosine distance
    /// let embeddings = response.data.map { $0.embedding }
    /// ```
    ///
    /// - SeeAlso: ``EmbeddingsEndpoint``, ``EmbeddingRequest``, ``Embedding``
    public lazy var embeddings = EmbeddingsEndpoint(networkClient: networkClient)
    
    /// Provides access to model information endpoints.
    ///
    /// Query available models and their capabilities:
    /// - List all accessible models
    /// - Get detailed information about specific models
    /// - Check model permissions and limits
    ///
    /// ## Example
    ///
    /// ```swift
    /// // List all available models
    /// let models = try await openAI.models.list()
    /// 
    /// for model in models.data {
    ///     print("Model: \(model.id)")
    ///     print("Owner: \(model.ownedBy)")
    /// }
    /// 
    /// // Get specific model details
    /// let gpt4 = try await openAI.models.retrieve("gpt-4o")
    /// print("Context window: \(gpt4.contextWindow ?? 0) tokens")
    /// ```
    ///
    /// - SeeAlso: ``ModelsEndpoint``, ``Model``
    public lazy var models = ModelsEndpoint(networkClient: networkClient)
    
    /// Provides access to content moderation endpoints.
    ///
    /// The moderation endpoint helps you identify potentially harmful content:
    /// - **Hate**: Content that expresses hatred
    /// - **Threats**: Threatening language
    /// - **Self-Harm**: Content about self-harm
    /// - **Sexual**: Sexual content
    /// - **Violence**: Violent content
    ///
    /// ## Usage Guidelines
    ///
    /// - Always moderate user-generated content
    /// - Use before sending content to other endpoints
    /// - Implement appropriate handling for flagged content
    ///
    /// ## Example
    ///
    /// ```swift
    /// let moderation = try await openAI.moderations.create(
    ///     ModerationRequest(
    ///         input: userGeneratedText,
    ///         model: Models.Moderation.textModerationLatest
    ///     )
    /// )
    /// 
    /// if let result = moderation.results.first {
    ///     if result.flagged {
    ///         print("Content flagged for: \(result.categories)")
    ///         // Handle inappropriate content
    ///     }
    /// }
    /// ```
    ///
    /// - SeeAlso: ``ModerationsEndpoint``, ``ModerationRequest``, ``ModerationResult``
    public lazy var moderations = ModerationsEndpoint(networkClient: networkClient)
    
    /// Provides access to file management endpoints.
    ///
    /// Files are used for:
    /// - **Fine-Tuning**: Training data for custom models
    /// - **Assistants**: Knowledge base documents
    /// - **Batch Processing**: Input files for batch jobs
    ///
    /// ## Supported Formats
    ///
    /// - **Fine-Tuning**: JSONL format with prompt-completion pairs
    /// - **Assistants**: PDF, TXT, MD, and various code formats
    /// - **Batch**: JSONL with request objects
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Upload a file for fine-tuning
    /// let fileData = trainingData.data(using: .utf8)!
    /// 
    /// let file = try await openAI.files.upload(
    ///     FileUploadRequest(
    ///         file: fileData,
    ///         fileName: "training.jsonl",
    ///         purpose: .fineTune
    ///     )
    /// )
    /// 
    /// print("File ID: \(file.id)")
    /// print("Size: \(file.bytes) bytes")
    /// 
    /// // List all files
    /// let files = try await openAI.files.list()
    /// ```
    ///
    /// - SeeAlso: ``FilesEndpoint``, ``FileUploadRequest``, ``FileObject``
    public lazy var files = FilesEndpoint(networkClient: networkClient)
    
    /// Provides access to fine-tuning endpoints.
    ///
    /// Fine-tuning allows you to customize models for your specific use case:
    /// - Improve performance on specialized tasks
    /// - Reduce prompt length by encoding instructions
    /// - Teach new knowledge or writing styles
    ///
    /// ## Process
    ///
    /// 1. Prepare training data in JSONL format
    /// 2. Upload training file
    /// 3. Create fine-tuning job
    /// 4. Monitor training progress
    /// 5. Use your custom model
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Create a fine-tuning job
    /// let job = try await openAI.fineTuning.create(
    ///     FineTuningRequest(
    ///         model: "gpt-3.5-turbo",
    ///         trainingFile: fileId,
    ///         hyperparameters: Hyperparameters(
    ///             nEpochs: .auto,
    ///             batchSize: .auto,
    ///             learningRateMultiplier: .auto
    ///         )
    ///     )
    /// )
    /// 
    /// // Monitor progress
    /// let status = try await openAI.fineTuning.retrieve(job.id)
    /// print("Status: \(status.status)")
    /// 
    /// // Use the fine-tuned model
    /// let response = try await openAI.chat.completions(
    ///     ChatCompletionRequest(
    ///         messages: messages,
    ///         model: status.fineTunedModel ?? ""
    ///     )
    /// )
    /// ```
    ///
    /// - SeeAlso: ``FineTuningEndpoint``, ``FineTuningRequest``, ``FineTuningJob``
    public lazy var fineTuning = FineTuningEndpoint(networkClient: networkClient)
    
    /// Provides access to assistants endpoints.
    ///
    /// Assistants are persistent AI agents with:
    /// - **Instructions**: Define behavior and personality
    /// - **Tools**: Code interpreter, retrieval, functions
    /// - **Files**: Access to uploaded documents
    /// - **Threads**: Maintain conversation history
    ///
    /// ## Capabilities
    ///
    /// - **Code Interpreter**: Execute Python code
    /// - **Retrieval**: Search through uploaded files
    /// - **Functions**: Call your custom functions
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Create an assistant
    /// let assistant = try await openAI.assistants.create(
    ///     AssistantRequest(
    ///         model: Models.Chat.gpt4o,
    ///         name: "Data Analyst",
    ///         instructions: """You are a data analyst. Use code interpreter 
    ///                         to analyze data and create visualizations.""",
    ///         tools: [
    ///             AssistantTool(type: .codeInterpreter),
    ///             AssistantTool(type: .retrieval)
    ///         ]
    ///     )
    /// )
    /// 
    /// // Create a thread and run
    /// let thread = try await openAI.threads.create()
    /// 
    /// let run = try await openAI.threads.runs.create(
    ///     threadId: thread.id,
    ///     RunRequest(assistantId: assistant.id)
    /// )
    /// ```
    ///
    /// - SeeAlso: ``AssistantsEndpoint``, ``Assistant``, ``AssistantTool``
    public lazy var assistants = AssistantsEndpoint(networkClient: networkClient)
    
    /// Provides access to threads endpoints.
    ///
    /// Threads represent conversations with assistants:
    /// - Persistent message history
    /// - Automatic context management
    /// - Support for file attachments
    /// - Run multiple assistants in one thread
    ///
    /// ## Thread Lifecycle
    ///
    /// 1. Create a thread
    /// 2. Add messages
    /// 3. Run an assistant
    /// 4. Retrieve responses
    /// 5. Continue conversation
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Create a thread with initial message
    /// let thread = try await openAI.threads.create(
    ///     ThreadRequest(
    ///         messages: [
    ///             ThreadMessage(
    ///                 role: .user,
    ///                 content: "Analyze this sales data and identify trends.",
    ///                 fileIds: [uploadedFileId]
    ///             )
    ///         ]
    ///     )
    /// )
    /// 
    /// // Run assistant on the thread
    /// let run = try await openAI.threads.runs.create(
    ///     threadId: thread.id,
    ///     RunRequest(
    ///         assistantId: assistantId,
    ///         instructions: "Focus on year-over-year growth."
    ///     )
    /// )
    /// 
    /// // Poll for completion
    /// while run.status == "in_progress" {
    ///     try await Task.sleep(nanoseconds: 1_000_000_000)
    ///     run = try await openAI.threads.runs.retrieve(
    ///         threadId: thread.id,
    ///         runId: run.id
    ///     )
    /// }
    /// 
    /// // Get messages
    /// let messages = try await openAI.threads.messages.list(threadId: thread.id)
    /// ```
    ///
    /// - SeeAlso: ``ThreadsEndpoint``, ``Thread``, ``Run``, ``ThreadMessage``
    public lazy var threads = ThreadsEndpoint(networkClient: networkClient)
    
    /// Provides access to vector store endpoints.
    ///
    /// Vector stores enable semantic search and retrieval:
    /// - Store document embeddings
    /// - Semantic similarity search
    /// - Integration with assistants
    /// - Automatic chunking and embedding
    ///
    /// ## Use Cases
    ///
    /// - **Knowledge Base**: Store company documentation
    /// - **RAG**: Retrieval-augmented generation
    /// - **Semantic Search**: Find similar content
    /// - **Context Enhancement**: Provide relevant context to assistants
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Create a vector store
    /// let store = try await openAI.vectorStores.create(
    ///     VectorStoreRequest(
    ///         name: "Product Documentation",
    ///         metadata: ["version": "2.0"]
    ///     )
    /// )
    /// 
    /// // Add files to the store
    /// let file = try await openAI.vectorStores.files.create(
    ///     vectorStoreId: store.id,
    ///     VectorStoreFileRequest(fileId: uploadedFileId)
    /// )
    /// 
    /// // Wait for processing
    /// while file.status == "in_progress" {
    ///     try await Task.sleep(nanoseconds: 2_000_000_000)
    ///     file = try await openAI.vectorStores.files.retrieve(
    ///         vectorStoreId: store.id,
    ///         fileId: file.id
    ///     )
    /// }
    /// 
    /// // Use with assistant
    /// let assistant = try await openAI.assistants.update(
    ///     assistantId: assistantId,
    ///     AssistantUpdateRequest(
    ///         toolResources: ToolResources(
    ///             fileSearch: FileSearchResources(
    ///                 vectorStoreIds: [store.id]
    ///             )
    ///         )
    ///     )
    /// )
    /// ```
    ///
    /// - SeeAlso: ``VectorStoresEndpoint``, ``VectorStore``, ``VectorStoreFile``
    public lazy var vectorStores = VectorStoresEndpoint(networkClient: networkClient)
    
    /// Provides access to batch processing endpoints.
    ///
    /// Batch processing enables cost-effective bulk operations:
    /// - **50% Cost Reduction**: Compared to synchronous requests
    /// - **Higher Rate Limits**: Separate quotas for batch processing
    /// - **24-Hour Window**: Flexible processing timeline
    /// - **Large Scale**: Process thousands of requests
    ///
    /// ## Use Cases
    ///
    /// - **Data Processing**: Analyze large datasets
    /// - **Content Generation**: Create bulk content
    /// - **Classification**: Categorize many items
    /// - **Embeddings**: Generate embeddings at scale
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Prepare batch file (JSONL format)
    /// let requests = [
    ///     BatchRequest(
    ///         customId: "req-1",
    ///         method: "POST",
    ///         url: "/v1/chat/completions",
    ///         body: ChatCompletionRequest(
    ///             messages: [ChatMessage(role: .user, content: "Hello")],
    ///             model: Models.Chat.gpt4oMini
    ///         )
    ///     ),
    ///     // ... more requests
    /// ]
    /// 
    /// // Upload batch file
    /// let batchFile = try await openAI.files.upload(
    ///     FileUploadRequest(
    ///         file: batchData,
    ///         fileName: "batch.jsonl",
    ///         purpose: .batch
    ///     )
    /// )
    /// 
    /// // Create batch job
    /// let batch = try await openAI.batches.create(
    ///     BatchCreateRequest(
    ///         inputFileId: batchFile.id,
    ///         endpoint: "/v1/chat/completions",
    ///         completionWindow: .hours24
    ///     )
    /// )
    /// 
    /// // Monitor progress
    /// let status = try await openAI.batches.retrieve(batch.id)
    /// print("Progress: \(status.requestCounts.completed)/\(status.requestCounts.total)")
    /// ```
    ///
    /// - SeeAlso: ``BatchesEndpoint``, ``Batch``, ``BatchRequest``
    public lazy var batches = BatchesEndpoint(networkClient: networkClient)
    
    /// Provides access to responses endpoints.
    ///
    /// Use this endpoint to interact with API responses.
    public lazy var responses = ResponsesEndpoint(networkClient: networkClient)
}

/// Configuration options for the OpenAI API client.
///
/// `Configuration` provides fine-grained control over how OpenAIKit interacts with the API.
/// While most applications can use the default settings, this struct allows customization
/// for advanced scenarios like corporate proxies, custom endpoints, or specialized networking requirements.
///
/// ## Example
///
/// ```swift
/// // Basic configuration
/// let config = Configuration(apiKey: "your-api-key")
///
/// // Advanced configuration
/// let config = Configuration(
///     apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "",
///     organization: "org-abc123",
///     project: "proj-xyz789",
///     baseURL: URL(string: "https://openai-proxy.company.com")!,
///     timeoutInterval: 120
/// )
///
/// let openAI = OpenAIKit(configuration: config)
/// ```
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
    /// Your API key is a secret credential that identifies and authorizes your application.
    /// 
    /// ## Obtaining an API Key
    ///
    /// 1. Visit [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
    /// 2. Click "Create new secret key"
    /// 3. Name your key (e.g., "Production iOS App")
    /// 4. Copy immediately - you won't see it again
    ///
    /// ## Security Best Practices
    ///
    /// - **Never** hardcode keys in source code
    /// - **Never** commit keys to version control  
    /// - **Never** expose keys in client-side code
    /// - **Always** use environment variables or secure storage
    /// - **Rotate** keys regularly
    /// - **Monitor** usage for unauthorized access
    ///
    /// ## Example
    ///
    /// ```swift
    /// // ❌ Bad: Hardcoded key
    /// let config = Configuration(apiKey: "sk-abc123...")
    ///
    /// // ✅ Good: Environment variable
    /// guard let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
    ///     fatalError("Missing API key")
    /// }
    /// let config = Configuration(apiKey: key)
    /// ```
    public let apiKey: String
    
    /// Optional organization ID for scoping requests.
    ///
    /// If you belong to multiple organizations, use this to specify which organization
    /// should be billed for API usage. This is particularly important for:
    ///
    /// - **Consultants**: Working with multiple client organizations
    /// - **Enterprises**: Separating departments or projects
    /// - **Developers**: Switching between personal and work accounts
    ///
    /// ## Finding Your Organization ID
    ///
    /// 1. Log in to [platform.openai.com](https://platform.openai.com)
    /// 2. Click on your organization name (top-left)
    /// 3. Go to Settings → Organization
    /// 4. Copy the Organization ID (format: `org-xxxxxxxxxxxxx`)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let config = Configuration(
    ///     apiKey: apiKey,
    ///     organization: "org-mycompany123",
    ///     project: "proj-mobileapp"
    /// )
    /// ```
    ///
    /// - Note: If not specified, defaults to your default organization.
    public let organization: String?
    
    /// Optional project ID for scoping requests.
    ///
    /// Projects provide an additional layer of organization within an organization.
    /// Use projects to:
    ///
    /// - **Track Costs**: Monitor API usage per project
    /// - **Set Limits**: Apply rate limits and budgets
    /// - **Access Control**: Restrict API keys to specific projects
    /// - **Audit Usage**: Detailed analytics per project
    ///
    /// ## Project Hierarchy
    ///
    /// ```
    /// Organization (org-company123)
    /// ├── Project: Mobile App (proj-mobile)
    /// ├── Project: Web Dashboard (proj-web)  
    /// └── Project: Internal Tools (proj-tools)
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Scope requests to mobile app project
    /// let config = Configuration(
    ///     apiKey: apiKey,
    ///     organization: "org-company123",
    ///     project: "proj-mobile"
    /// )
    /// ```
    public let project: String?
    
    /// The base URL for API requests.
    ///
    /// While this defaults to OpenAI's official API endpoint, you can customize it for:
    ///
    /// - **Corporate Proxies**: Route through company infrastructure
    /// - **Regional Endpoints**: Use geographically closer servers
    /// - **Compatible APIs**: Connect to OpenAI-compatible services
    /// - **Development/Testing**: Point to mock or staging servers
    ///
    /// ## Examples
    ///
    /// ```swift
    /// // Default OpenAI endpoint
    /// let config = Configuration(apiKey: apiKey)
    /// // baseURL is https://api.openai.com
    ///
    /// // Corporate proxy
    /// let config = Configuration(
    ///     apiKey: apiKey,
    ///     baseURL: URL(string: "https://openai-proxy.company.com")!
    /// )
    ///
    /// // Local development server
    /// let config = Configuration(
    ///     apiKey: "test-key",
    ///     baseURL: URL(string: "http://localhost:8080")!
    /// )
    /// ```
    ///
    /// - Important: The URL should not include version paths like `/v1`
    public let baseURL: URL
    
    /// The timeout interval for API requests in seconds.
    ///
    /// Different operations require different timeout considerations:
    ///
    /// ## Recommended Timeouts
    ///
    /// - **Chat Completions**: 30-60 seconds (default)
    /// - **Audio Transcription**: 120-300 seconds for long files
    /// - **Image Generation**: 60-120 seconds
    /// - **Fine-Tuning**: Not applicable (async operation)
    /// - **Embeddings**: 30 seconds
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Standard configuration
    /// let chatConfig = Configuration(apiKey: apiKey)
    /// // Uses default 60 second timeout
    ///
    /// // Audio transcription configuration  
    /// let audioConfig = Configuration(
    ///     apiKey: apiKey,
    ///     timeoutInterval: 300  // 5 minutes for large audio files
    /// )
    ///
    /// // Quick requests configuration
    /// let quickConfig = Configuration(
    ///     apiKey: apiKey,
    ///     timeoutInterval: 30  // Fail fast for responsive UIs
    /// )
    /// ```
    ///
    /// - Note: This is the total time for the entire request/response cycle
    public let timeoutInterval: TimeInterval
    
    /// Creates a new configuration with the specified settings.
    ///
    /// Most applications only need to provide an API key. The other parameters are
    /// for advanced use cases.
    ///
    /// - Parameters:
    ///   - apiKey: Your OpenAI API key (required)
    ///   - organization: Organization ID for billing and access control
    ///   - project: Project ID for granular usage tracking
    ///   - baseURL: Custom API endpoint (defaults to `https://api.openai.com`)
    ///   - timeoutInterval: Request timeout in seconds (defaults to 60)
    ///
    /// ## Examples
    ///
    /// ```swift
    /// // Minimal configuration
    /// let config = Configuration(apiKey: "your-api-key")
    ///
    /// // Organization-scoped
    /// let config = Configuration(
    ///     apiKey: "your-api-key",
    ///     organization: "org-abc123"
    /// )
    ///
    /// // Full configuration
    /// let config = Configuration(
    ///     apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "",
    ///     organization: "org-abc123",
    ///     project: "proj-mobile",
    ///     baseURL: URL(string: "https://api.openai.com")!,
    ///     timeoutInterval: 120
    /// )
    /// ```
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