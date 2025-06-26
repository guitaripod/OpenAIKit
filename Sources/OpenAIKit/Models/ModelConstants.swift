import Foundation

/// Constants for OpenAI model identifiers.
///
/// This struct provides type-safe access to OpenAI model names,
/// avoiding string literals throughout the codebase.
///
/// ## Usage
/// ```swift
/// let request = ChatCompletionRequest(
///     messages: messages,
///     model: Models.Chat.gpt4o
/// )
/// ```
public struct Models: Sendable {
    
    /// Chat completion models
    public struct Chat: Sendable {
        /// GPT-4o models
        public static let gpt4o = "gpt-4o"
        public static let gpt4oMini = "gpt-4o-mini"
        public static let gpt4oAudio = "gpt-4o-audio-preview"
        public static let gpt4oAudioPreview20241201 = "gpt-4o-audio-preview-2024-12-17"
        public static let gpt4oMini20240718 = "gpt-4o-mini-2024-07-18"
        public static let gpt4o20240513 = "gpt-4o-2024-05-13"
        public static let gpt4o20240806 = "gpt-4o-2024-08-06"
        public static let gpt4o20241120 = "gpt-4o-2024-11-20"
        
        /// GPT-4 Turbo models
        public static let gpt4Turbo = "gpt-4-turbo"
        public static let gpt4TurboPreview = "gpt-4-turbo-preview"
        public static let gpt4Turbo20240409 = "gpt-4-turbo-2024-04-09"
        public static let gpt40125Preview = "gpt-4-0125-preview"
        public static let gpt41106Preview = "gpt-4-1106-preview"
        
        /// GPT-4 models
        public static let gpt4 = "gpt-4"
        public static let gpt40314 = "gpt-4-0314"
        public static let gpt40613 = "gpt-4-0613"
        
        /// GPT-3.5 Turbo models
        public static let gpt35Turbo = "gpt-3.5-turbo"
        public static let gpt35Turbo0125 = "gpt-3.5-turbo-0125"
        public static let gpt35Turbo1106 = "gpt-3.5-turbo-1106"
        public static let gpt35Turbo0613 = "gpt-3.5-turbo-0613"
        public static let gpt35Turbo16k = "gpt-3.5-turbo-16k"
        public static let gpt35Turbo16k0613 = "gpt-3.5-turbo-16k-0613"
        public static let gpt35Turbo0301 = "gpt-3.5-turbo-0301"
        
        /// O1 models (reasoning models)
        public static let o1 = "o1"
        public static let o1Mini = "o1-mini"
        public static let o1Preview = "o1-preview"
        public static let o1Preview20240912 = "o1-preview-2024-09-12"
        public static let o1Mini20240912 = "o1-mini-2024-09-12"
        public static let o120241205 = "o1-2024-12-05"
        public static let o120241217 = "o1-2024-12-17"
    }
    
    /// Embedding models
    public struct Embeddings: Sendable {
        /// Text embedding models
        public static let textEmbedding3Small = "text-embedding-3-small"
        public static let textEmbedding3Large = "text-embedding-3-large"
        public static let textEmbeddingAda002 = "text-embedding-ada-002"
    }
    
    /// Audio models
    public struct Audio: Sendable {
        /// Whisper models for transcription/translation
        public static let whisper1 = "whisper-1"
        
        /// TTS models
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
    
    /// Moderation models
    public struct Moderation: Sendable {
        public static let textModerationLatest = "text-moderation-latest"
        public static let textModerationStable = "text-moderation-stable"
        public static let textModeration007 = "text-moderation-007"
        public static let omniModerationLatest = "omni-moderation-latest"
        public static let omniModeration20241025 = "omni-moderation-2024-10-25"
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

/// Convenience type aliases for common model selections
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
}

/// Model capabilities and metadata
public extension Models {
    struct ModelInfo: Sendable {
        public let id: String
        public let contextWindow: Int
        public let maxOutputTokens: Int?
        public let trainingDataCutoff: String?
        public let capabilities: Set<Capability>
        
        public enum Capability: String, Sendable {
            case chat
            case functionCalling
            case vision
            case jsonMode
            case streaming
            case audio
            case reasoning
        }
    }
    
    /// Get detailed information about a model
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