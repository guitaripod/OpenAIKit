import Foundation

/// Constants for OpenAI model identifiers.
///
/// `Models` provides type-safe access to all OpenAI model identifiers, eliminating error-prone
/// string literals and providing autocomplete support. Models are organized by capability
/// (chat, embeddings, audio, etc.) with convenient aliases for common selections.
///
/// ## Overview
///
/// OpenAI offers various models optimized for different tasks:
/// - **Chat Models**: Conversational AI and text generation
/// - **Embedding Models**: Semantic search and similarity
/// - **Audio Models**: Speech-to-text and text-to-speech
/// - **Image Models**: Image generation and editing
/// - **Moderation Models**: Content safety checks
///
/// ## Basic Usage
///
/// ```swift
/// // Using specific models
/// let request = ChatCompletionRequest(
///     messages: messages,
///     model: Models.Chat.gpt4o  // Latest GPT-4o
/// )
///
/// // Using convenience aliases
/// let request = ChatCompletionRequest(
///     messages: messages,
///     model: Models.latest  // Always the newest model
/// )
///
/// // Checking model capabilities
/// if let info = Models.info(for: Models.Chat.gpt4o) {
///     print("Context window: \(info.contextWindow) tokens")
///     print("Supports vision: \(info.capabilities.contains(.vision))")
/// }
/// ```
///
/// ## Model Selection Guide
///
/// - **Performance**: `gpt-4o` > `gpt-4-turbo` > `gpt-3.5-turbo`
/// - **Cost**: `gpt-3.5-turbo` < `gpt-4o-mini` < `gpt-4o`
/// - **Speed**: `gpt-3.5-turbo` > `gpt-4o-mini` > `gpt-4o`
/// - **Reasoning**: `o1` > `o1-mini` > `gpt-4o`
public struct Models: Sendable {
    
    /// Chat completion models for conversational AI and text generation.
    ///
    /// Models are listed from newest to oldest within each family.
    /// Check availability as older models may be deprecated.
    public struct Chat: Sendable {
        // MARK: - GPT-4o Family
        
        /// GPT-4o - Latest multimodal model (Recommended)
        /// - Context: 128K tokens
        /// - Output: 16K tokens
        /// - Features: Vision, function calling, JSON mode
        /// - Best for: General use, complex tasks
        public static let gpt4o = "gpt-4o"
        public static let gpt4oMini = "gpt-4o-mini"
        public static let gpt4oAudio = "gpt-4o-audio-preview"
        public static let gpt4oAudioPreview20241201 = "gpt-4o-audio-preview-2024-12-17"
        public static let gpt4oMini20240718 = "gpt-4o-mini-2024-07-18"
        public static let gpt4o20240513 = "gpt-4o-2024-05-13"
        public static let gpt4o20240806 = "gpt-4o-2024-08-06"
        public static let gpt4o20241120 = "gpt-4o-2024-11-20"
        
        // MARK: - GPT-4 Turbo Family
        
        /// GPT-4 Turbo - Previous generation high-performance model
        /// - Context: 128K tokens
        /// - Output: 4K tokens  
        /// - Features: Vision, function calling, JSON mode
        /// - Best for: When GPT-4o unavailable
        public static let gpt4Turbo = "gpt-4-turbo"
        public static let gpt4TurboPreview = "gpt-4-turbo-preview"
        public static let gpt4Turbo20240409 = "gpt-4-turbo-2024-04-09"
        public static let gpt40125Preview = "gpt-4-0125-preview"
        public static let gpt41106Preview = "gpt-4-1106-preview"
        
        // MARK: - GPT-4 Family
        
        /// Original GPT-4 models (Legacy)
        /// - Context: 8K tokens
        /// - Features: Function calling, JSON mode
        /// - Note: Consider using GPT-4o instead
        public static let gpt4 = "gpt-4"
        public static let gpt40314 = "gpt-4-0314"
        public static let gpt40613 = "gpt-4-0613"
        
        // MARK: - GPT-3.5 Turbo Family
        
        /// GPT-3.5 Turbo - Fast, cost-effective model
        /// - Context: 16K tokens
        /// - Features: Function calling, JSON mode
        /// - Best for: Simple tasks, high volume
        public static let gpt35Turbo = "gpt-3.5-turbo"
        public static let gpt35Turbo0125 = "gpt-3.5-turbo-0125"
        public static let gpt35Turbo1106 = "gpt-3.5-turbo-1106"
        public static let gpt35Turbo0613 = "gpt-3.5-turbo-0613"
        public static let gpt35Turbo16k = "gpt-3.5-turbo-16k"
        public static let gpt35Turbo16k0613 = "gpt-3.5-turbo-16k-0613"
        public static let gpt35Turbo0301 = "gpt-3.5-turbo-0301"
        
        // MARK: - O1 Reasoning Models
        
        /// O1 models - Advanced reasoning capabilities
        /// - Specialty: Multi-step reasoning, complex problem solving
        /// - Note: No streaming, function calling, or system messages
        /// - Best for: Math, coding, scientific analysis
        public static let o1 = "o1"
        public static let o1Mini = "o1-mini"
        public static let o1Preview = "o1-preview"
        public static let o1Preview20240912 = "o1-preview-2024-09-12"
        public static let o1Mini20240912 = "o1-mini-2024-09-12"
        public static let o120241205 = "o1-2024-12-05"
        public static let o120241217 = "o1-2024-12-17"
    }
    
    /// Embedding models for semantic search and similarity.
    ///
    /// Convert text to numerical vectors for ML applications.
    public struct Embeddings: Sendable {
        /// Text Embedding 3 Small - Balanced performance
        /// - Dimensions: 1536 (reducible)
        /// - Best for: Most applications
        public static let textEmbedding3Small = "text-embedding-3-small"
        public static let textEmbedding3Large = "text-embedding-3-large"
        public static let textEmbeddingAda002 = "text-embedding-ada-002"
    }
    
    /// Audio models for speech recognition and synthesis.
    ///
    /// Handle speech-to-text and text-to-speech conversions.
    public struct Audio: Sendable {
        /// Whisper - Universal speech recognition
        /// - Languages: 50+
        /// - Features: Transcription, translation to English
        /// - Formats: mp3, mp4, mpeg, mpga, m4a, wav, webm
        public static let whisper1 = "whisper-1"
        
        /// Text-to-Speech models
        /// - Voices: 6 options (nova, alloy, echo, fable, onyx, shimmer)
        /// - Languages: Multiple
        /// - Formats: mp3, opus, aac, flac, wav
        public static let tts1 = "tts-1"
        public static let tts1HD = "tts-1-hd"
    }
    
    /// Image generation models
    public struct Images: Sendable {
        /// DALL-E 2 - Classic image generation model
        /// - Resolution: 256x256, 512x512, or 1024x1024
        /// - Supports: n parameter for multiple images (1-10)
        /// - Returns: URLs to generated images
        public static let dallE2 = "dall-e-2"
        
        /// DALL-E 3 - Advanced image generation with better prompt adherence
        /// - Resolution: 1024x1024, 1024x1792, or 1792x1024
        /// - Supports: quality (standard/hd), style (vivid/natural)
        /// - Returns: URLs to generated images
        /// - Note: n parameter must be 1
        public static let dallE3 = "dall-e-3"
        
        /// GPT Image 1 - Latest multimodal image generation model
        /// - Advanced features: Better instruction following, photorealistic results
        /// - Supports: Image editing with masks, up to 10 input images
        /// - Parameters: outputCompression (0-100), outputFormat (jpeg/png/webp)
        /// - Special: Can generate transparent backgrounds
        /// - Returns: Base64-encoded images with detailed usage statistics
        /// - Requirements: Requires organization verification for access
        public static let gptImage1 = "gpt-image-1"
    }
    
    /// Moderation models for content safety.
    ///
    /// Detect potentially harmful content across multiple categories.
    public struct Moderation: Sendable {
        public static let textModerationLatest = "text-moderation-latest"
        public static let textModerationStable = "text-moderation-stable"
        public static let textModeration007 = "text-moderation-007"
        public static let omniModerationLatest = "omni-moderation-latest"
        public static let omniModeration20241025 = "omni-moderation-2024-10-25"
    }
    
    /// DeepResearch models for advanced research and analysis
    public struct DeepResearch: Sendable {
        /// O3 Deep Research - Most capable research model
        /// - Capabilities: Web search, MCP tools, code interpreter
        /// - Use cases: Complex analysis, scientific research, market analysis
        /// - Note: Can take tens of minutes to complete
        public static let o3DeepResearch = "o3-deep-research"
        
        /// O4 Mini Deep Research - Faster research model
        /// - Capabilities: Web search, MCP tools, code interpreter
        /// - Use cases: Quicker research tasks, summaries
        /// - Note: Faster but potentially less comprehensive than o3
        public static let o4MiniDeepResearch = "o4-mini-deep-research"
    }
    
    /// Legacy completion models (deprecated)
    @available(*, deprecated, message: "Use chat models instead")
    public struct Completions: Sendable {
        public static let gpt3TextDavinci003 = "text-davinci-003"
        public static let gpt3TextDavinci002 = "text-davinci-002"
        public static let gpt3TextCurie001 = "text-curie-001"
        public static let gpt3TextBabbage001 = "text-babbage-001"
        public static let gpt3TextAda001 = "text-ada-001"
    }
}

// MARK: - Convenience Aliases

/// Convenience type aliases for common model selections.
///
/// These aliases make it easier to select appropriate models without
/// memorizing specific model names. They're updated as new models release.
public extension Models {
    /// The latest and most capable GPT-4o model
    static let latest = Chat.gpt4o
    
    /// The most cost-effective model for most use cases
    static let costEffective = Chat.gpt4oMini
    
    /// The best model for complex reasoning tasks
    static let reasoning = Chat.o1
    
    /// The best model for fast reasoning tasks
    static let reasoningFast = Chat.o1Mini
    
    /// The default embedding model
    static let embedding = Embeddings.textEmbedding3Small
    
    /// The default audio transcription model
    static let transcription = Audio.whisper1
    
    /// The default TTS model
    static let tts = Audio.tts1
    
    /// The default image generation model
    static let imageGeneration = Images.dallE3
    
    /// The default moderation model
    static let moderation = Moderation.textModerationLatest
    
    /// The default deep research model
    static let deepResearch = DeepResearch.o3DeepResearch
    
    /// The fast deep research model
    static let deepResearchFast = DeepResearch.o4MiniDeepResearch
}

// MARK: - Model Information

/// Model capabilities and metadata.
///
/// Query detailed information about model capabilities, limits, and features.
public extension Models {
    /// Detailed information about a model's capabilities and limits.
    struct ModelInfo: Sendable {
        /// The model identifier
        public let id: String
        
        /// Maximum input context size in tokens
        public let contextWindow: Int
        
        /// Maximum output tokens (if limited)
        public let maxOutputTokens: Int?
        
        /// Training data cutoff date (YYYY-MM format)
        public let trainingDataCutoff: String?
        
        /// Set of capabilities this model supports
        public let capabilities: Set<Capability>
        
        /// Model capabilities
        public enum Capability: String, Sendable {
            /// Standard chat completions
            case chat
            /// Function/tool calling
            case functionCalling
            /// Image understanding
            case vision
            /// Structured JSON output
            case jsonMode
            /// Server-sent events streaming
            case streaming
            /// Audio input/output
            case audio
            /// Advanced reasoning (O1 models)
            case reasoning
        }
    }
    
    /// Get detailed information about a model.
    ///
    /// Returns nil for unknown models. Information includes context limits,
    /// capabilities, and training data cutoff.
    ///
    /// - Parameter modelId: The model identifier to query
    /// - Returns: Model information if available
    ///
    /// ## Example
    ///
    /// ```swift
    /// if let info = Models.info(for: "gpt-4o") {
    ///     print("Max input: \(info.contextWindow) tokens")
    ///     print("Max output: \(info.maxOutputTokens ?? 0) tokens")
    ///     
    ///     if info.capabilities.contains(.vision) {
    ///         print("Supports image inputs")
    ///     }
    /// }
    /// ```
    static func info(for modelId: String) -> ModelInfo? {
        switch modelId {
        case Chat.gpt4o, Chat.gpt4o20241120:
            return ModelInfo(
                id: modelId,
                contextWindow: 128_000,
                maxOutputTokens: 16_384,
                trainingDataCutoff: "2023-10",
                capabilities: [.chat, .functionCalling, .vision, .jsonMode, .streaming]
            )
            
        case Chat.gpt4oMini:
            return ModelInfo(
                id: modelId,
                contextWindow: 128_000,
                maxOutputTokens: 16_384,
                trainingDataCutoff: "2023-10",
                capabilities: [.chat, .functionCalling, .vision, .jsonMode, .streaming]
            )
            
        case Chat.gpt4Turbo:
            return ModelInfo(
                id: modelId,
                contextWindow: 128_000,
                maxOutputTokens: 4_096,
                trainingDataCutoff: "2023-12",
                capabilities: [.chat, .functionCalling, .vision, .jsonMode, .streaming]
            )
            
        case Chat.gpt4:
            return ModelInfo(
                id: modelId,
                contextWindow: 8_192,
                maxOutputTokens: 8_192,
                trainingDataCutoff: "2021-09",
                capabilities: [.chat, .functionCalling, .jsonMode, .streaming]
            )
            
        case Chat.gpt35Turbo:
            return ModelInfo(
                id: modelId,
                contextWindow: 16_385,
                maxOutputTokens: 4_096,
                trainingDataCutoff: "2021-09",
                capabilities: [.chat, .functionCalling, .jsonMode, .streaming]
            )
            
        case Chat.o1, Chat.o120241217:
            return ModelInfo(
                id: modelId,
                contextWindow: 200_000,
                maxOutputTokens: 100_000,
                trainingDataCutoff: "2023-10",
                capabilities: [.chat, .reasoning]
            )
            
        case Chat.o1Mini:
            return ModelInfo(
                id: modelId,
                contextWindow: 128_000,
                maxOutputTokens: 65_536,
                trainingDataCutoff: "2023-10",
                capabilities: [.chat, .reasoning]
            )
            
        case Chat.gpt4oAudio, Chat.gpt4oAudioPreview20241201:
            return ModelInfo(
                id: modelId,
                contextWindow: 128_000,
                maxOutputTokens: 16_384,
                trainingDataCutoff: "2023-10",
                capabilities: [.chat, .functionCalling, .vision, .jsonMode, .streaming, .audio]
            )
            
        default:
            return nil
        }
    }
}