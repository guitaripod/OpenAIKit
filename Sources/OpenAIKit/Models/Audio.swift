import Foundation

/// A request to generate audio from text using OpenAI's text-to-speech models.
///
/// Use this type to convert text into lifelike spoken audio. The API provides multiple voices
/// and supports various audio formats.
///
/// ## Example
/// ```swift
/// let request = SpeechRequest(
///     input: "Hello, welcome to OpenAI!",
///     voice: .nova,
///     responseFormat: .mp3,
///     speed: 1.0
/// )
/// ```
///
/// - Important: The `input` text should be no longer than 4096 characters.
public struct SpeechRequest: Codable, Sendable {
    /// The text to generate audio for.
    ///
    /// Maximum length is 4096 characters.
    public let input: String
    
    /// The TTS model to use.
    ///
    /// Available models:
    /// - `"tts-1"`: Standard quality, lower latency
    /// - `"tts-1-hd"`: Higher quality, higher latency
    public let model: String
    
    /// The voice to use for audio generation.
    ///
    /// See ``Voice`` for available options.
    public let voice: Voice
    
    /// Custom pronunciation instructions for the model.
    ///
    /// Use this to guide the model on specific pronunciations or speaking styles.
    public let instructions: String?
    
    /// The audio format of the output.
    ///
    /// Defaults to mp3 if not specified. See ``AudioFormat`` for available options.
    public let responseFormat: AudioFormat?
    
    /// The speed of the generated audio.
    ///
    /// Valid range is 0.25 to 4.0. Default is 1.0.
    /// - Values below 1.0 slow down the speech
    /// - Values above 1.0 speed up the speech
    public let speed: Double?
    
    /// Creates a new speech generation request.
    ///
    /// - Parameters:
    ///   - input: The text to convert to speech (max 4096 characters)
    ///   - model: The TTS model to use (default: "tts-1")
    ///   - voice: The voice to use for generation
    ///   - instructions: Optional custom pronunciation instructions
    ///   - responseFormat: The desired audio format (default: mp3)
    ///   - speed: Playback speed (0.25-4.0, default: 1.0)
    public init(
        input: String,
        model: String = "tts-1",
        voice: Voice,
        instructions: String? = nil,
        responseFormat: AudioFormat? = nil,
        speed: Double? = nil
    ) {
        self.input = input
        self.model = model
        self.voice = voice
        self.instructions = instructions
        self.responseFormat = responseFormat
        self.speed = speed
    }
}

/// Available voices for text-to-speech generation.
///
/// Each voice has unique characteristics suitable for different use cases.
/// Experiment with different voices to find the one that best fits your needs.
///
/// ## Voice Characteristics
/// - **Alloy, Echo, Fable, Onyx, Nova, Shimmer**: Optimized for English
/// - **Ash, Ballad, Coral, Sage, Verse**: Additional voices with varied tones
///
/// ## Example
/// ```swift
/// let request = SpeechRequest(
///     input: "Hello world!",
///     voice: .nova  // Clear and friendly voice
/// )
/// ```
public enum Voice: String, Codable, Sendable {
    /// A versatile, balanced voice suitable for general use.
    case alloy
    
    /// A smooth, steady voice with consistent pacing.
    case echo
    
    /// A warm, engaging voice ideal for storytelling.
    case fable
    
    /// A deep, authoritative voice with strong presence.
    case onyx
    
    /// A friendly, conversational voice with clear pronunciation.
    case nova
    
    /// A soft, gentle voice with a calming quality.
    case shimmer
    
    /// A youthful, energetic voice.
    case ash
    
    /// A warm, melodic voice suitable for longer content.
    case ballad
    
    /// A bright, cheerful voice with good clarity.
    case coral
    
    /// A mature, professional voice.
    case sage
    
    /// A dynamic voice with good emotional range.
    case verse
}

/// Supported audio formats for speech generation and transcription.
///
/// Choose a format based on your quality, size, and compatibility requirements.
///
/// ## Format Characteristics
/// - **MP3**: Good compression, widely supported (default)
/// - **Opus**: Excellent compression, low latency, ideal for streaming
/// - **AAC**: Good quality and compression, Apple ecosystem friendly
/// - **FLAC**: Lossless compression, larger files
/// - **WAV**: Uncompressed, highest quality, largest files
/// - **PCM**: Raw audio data, 24kHz 16-bit signed little-endian
///
/// ## Example
/// ```swift
/// let request = SpeechRequest(
///     input: "Hello!",
///     voice: .nova,
///     responseFormat: .opus  // Best for streaming
/// )
/// ```
public enum AudioFormat: String, Codable, Sendable {
    /// MP3 format - Good balance of quality and file size.
    case mp3
    
    /// Opus format - Excellent for low-latency applications and streaming.
    case opus
    
    /// AAC format - High quality, efficient compression.
    case aac
    
    /// FLAC format - Lossless compression, preserves original quality.
    case flac
    
    /// WAV format - Uncompressed, highest quality but largest file size.
    case wav
    
    /// PCM format - Raw 24kHz 16-bit signed little-endian audio.
    case pcm
}

/// A request to transcribe audio into text using OpenAI's Whisper model.
///
/// Transcribes audio files in various formats and languages into text.
/// Supports timestamps, different output formats, and streaming responses.
///
/// ## Supported File Formats
/// flac, mp3, mp4, mpeg, mpga, m4a, ogg, wav, or webm
///
/// ## Example
/// ```swift
/// let audioData = try Data(contentsOf: audioFileURL)
/// let request = TranscriptionRequest(
///     file: audioData,
///     fileName: "audio.mp3",
///     language: "en",
///     responseFormat: .verboseJson,
///     timestampGranularities: [.word, .segment]
/// )
/// ```
public struct TranscriptionRequest: Sendable {
    /// The audio file data to transcribe.
    ///
    /// File uploads are limited to 25 MB.
    public let file: Data
    
    /// The name of the audio file including extension.
    ///
    /// Example: "audio.mp3", "recording.wav"
    public let fileName: String
    
    /// The model to use for transcription.
    ///
    /// Currently only "whisper-1" is available.
    public let model: String
    
    /// Strategy for chunking long audio files.
    ///
    /// See ``ChunkingStrategy`` for options.
    public let chunkingStrategy: ChunkingStrategy?
    
    /// Additional information to include in the response.
    ///
    /// Currently supports ["usage"] to include token usage information.
    public let include: [String]?
    
    /// The language of the audio in ISO-639-1 format.
    ///
    /// Supplying the language can improve accuracy and latency.
    /// Example: "en" for English, "es" for Spanish.
    public let language: String?
    
    /// Optional text to guide the model's style or continue a previous segment.
    ///
    /// The prompt should match the audio language. Use to provide context
    /// or correct specific words/phrases.
    public let prompt: String?
    
    /// The format of the transcript output.
    ///
    /// See ``TranscriptionFormat`` for available options.
    public let responseFormat: TranscriptionFormat?
    
    /// Whether to stream the transcription response.
    ///
    /// When true, responses are streamed as they become available.
    public let stream: Bool?
    
    /// Sampling temperature between 0 and 1.
    ///
    /// Higher values (e.g., 0.8) make output more random.
    /// Lower values (e.g., 0.2) make it more deterministic.
    /// Default is 0.
    public let temperature: Double?
    
    /// The timestamp granularities to populate.
    ///
    /// Must be used with ``responseFormat`` set to `.verboseJson`.
    /// See ``TimestampGranularity`` for options.
    public let timestampGranularities: [TimestampGranularity]?
    
    /// Creates a new transcription request.
    ///
    /// - Parameters:
    ///   - file: Audio file data (max 25 MB)
    ///   - fileName: Name of the file with extension
    ///   - model: Model to use (default: "whisper-1")
    ///   - chunkingStrategy: Strategy for processing long audio files
    ///   - include: Additional information to include (e.g., ["usage"])
    ///   - language: ISO-639-1 language code (e.g., "en")
    ///   - prompt: Optional context or style guide
    ///   - responseFormat: Output format for the transcription
    ///   - stream: Whether to stream the response
    ///   - temperature: Sampling temperature (0-1)
    ///   - timestampGranularities: Timestamp detail levels when using verbose_json
    public init(
        file: Data,
        fileName: String,
        model: String = "whisper-1",
        chunkingStrategy: ChunkingStrategy? = nil,
        include: [String]? = nil,
        language: String? = nil,
        prompt: String? = nil,
        responseFormat: TranscriptionFormat? = nil,
        stream: Bool? = nil,
        temperature: Double? = nil,
        timestampGranularities: [TimestampGranularity]? = nil
    ) {
        self.file = file
        self.fileName = fileName
        self.model = model
        self.chunkingStrategy = chunkingStrategy
        self.include = include
        self.language = language
        self.prompt = prompt
        self.responseFormat = responseFormat
        self.stream = stream
        self.temperature = temperature
        self.timestampGranularities = timestampGranularities
    }
}

/// Output formats for audio transcription.
///
/// Choose a format based on your application's needs.
///
/// ## Format Details
/// - **json**: Basic JSON with text field
/// - **text**: Plain text transcript
/// - **srt**: SubRip subtitle format with timestamps
/// - **verbose_json**: Detailed JSON with segments, words, and metadata
/// - **vtt**: WebVTT subtitle format
///
/// ## Example
/// ```swift
/// // For detailed word-level timestamps
/// let request = TranscriptionRequest(
///     file: audioData,
///     fileName: "audio.mp3",
///     responseFormat: .verboseJson,
///     timestampGranularities: [.word]
/// )
/// ```
public enum TranscriptionFormat: String, Codable, Sendable {
    /// JSON format with the transcript in a "text" field.
    case json
    
    /// Plain text format containing only the transcript.
    case text
    
    /// SubRip (.srt) subtitle format with timestamps.
    case srt
    
    /// Detailed JSON including segments, words, and language detection.
    case verboseJson = "verbose_json"
    
    /// WebVTT (.vtt) subtitle format.
    case vtt
}

/// Granularity levels for timestamps in transcription responses.
///
/// Used with ``TranscriptionFormat.verboseJson`` to include detailed timing information.
///
/// ## Example
/// ```swift
/// let request = TranscriptionRequest(
///     file: audioData,
///     fileName: "audio.mp3",
///     responseFormat: .verboseJson,
///     timestampGranularities: [.word, .segment]
/// )
/// ```
public enum TimestampGranularity: String, Codable, Sendable {
    /// Provides start and end times for each individual word.
    case word
    
    /// Provides start and end times for each transcript segment.
    case segment
}

/// Strategy for processing long audio files in chunks.
///
/// Use this to control how large audio files are split for processing.
///
/// ## Example
/// ```swift
/// // Automatic chunking
/// let autoStrategy = ChunkingStrategy.auto
///
/// // Custom chunking with 1024 chunk length and 128 overlap
/// let customStrategy = ChunkingStrategy.staticStrategy(
///     .init(chunkLength: 1024, chunkOverlap: 128)
/// )
/// ```
public enum ChunkingStrategy: Codable, Sendable {
    /// Automatically determine optimal chunk size.
    case auto
    
    /// Use a fixed chunk size with specified overlap.
    case staticStrategy(Static)
    
    /// Configuration for static chunking strategy.
    ///
    /// Defines fixed chunk sizes for processing audio.
    public struct Static: Codable, Sendable {
        /// The length of each chunk in tokens.
        public let chunkLength: Int
        
        /// The number of overlapping tokens between chunks.
        ///
        /// Overlap helps maintain context between chunks.
        public let chunkOverlap: Int
        
        /// Creates a static chunking configuration.
        ///
        /// - Parameters:
        ///   - chunkLength: Length of each chunk in tokens
        ///   - chunkOverlap: Overlap between consecutive chunks
        public init(chunkLength: Int, chunkOverlap: Int) {
            self.chunkLength = chunkLength
            self.chunkOverlap = chunkOverlap
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self), string == "auto" {
            self = .auto
        } else if let staticStrategy = try? container.decode(Static.self) {
            self = .staticStrategy(staticStrategy)
        } else {
            throw DecodingError.typeMismatch(
                ChunkingStrategy.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or Static object")
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .auto:
            try container.encode("auto")
        case .staticStrategy(let staticStrategy):
            try container.encode(staticStrategy)
        }
    }
}

/// The response from an audio transcription request.
///
/// Contains the transcribed text and optional detailed information
/// depending on the requested format.
///
/// ## Example
/// ```swift
/// // Basic response
/// print(response.text)
///
/// // Detailed response with verbose_json format
/// if let segments = response.segments {
///     for segment in segments {
///         print("\(segment.start)-\(segment.end): \(segment.text)")
///     }
/// }
/// ```
public struct TranscriptionResponse: Codable, Sendable {
    /// The transcribed text.
    public let text: String
    
    /// Token usage information if requested via `include` parameter.
    public let usage: Usage?
    
    /// Detected language of the audio in ISO-639-1 format.
    ///
    /// Only available with ``TranscriptionFormat.verboseJson``.
    public let language: String?
    
    /// Duration of the audio file in seconds.
    ///
    /// Only available with ``TranscriptionFormat.verboseJson``.
    public let duration: Double?
    
    /// Detailed segment information including timestamps.
    ///
    /// Only available with ``TranscriptionFormat.verboseJson``.
    public let segments: [TranscriptionSegment]?
    
    /// Word-level timestamp information.
    ///
    /// Only available when using ``TimestampGranularity.word``.
    public let words: [TranscriptionWord]?
}

/// A segment of transcribed audio with detailed metadata.
///
/// Segments represent logical chunks of the transcription with
/// timing and confidence information.
///
/// ## Example
/// ```swift
/// for segment in response.segments ?? [] {
///     print("[\(segment.start)s - \(segment.end)s]")
///     print("Text: \(segment.text)")
///     print("Confidence: \(1 - segment.noSpeechProb)")
/// }
/// ```
public struct TranscriptionSegment: Codable, Sendable {
    /// Unique identifier for this segment.
    public let id: Int
    
    /// Seek position in the audio file.
    public let seek: Int
    
    /// Start time of the segment in seconds.
    public let start: Double
    
    /// End time of the segment in seconds.
    public let end: Double
    
    /// The transcribed text for this segment.
    public let text: String
    
    /// Token IDs for the segment.
    public let tokens: [Int]
    
    /// Temperature used for this segment.
    public let temperature: Double
    
    /// Average log probability of the tokens.
    ///
    /// Lower values indicate higher confidence.
    public let avgLogprob: Double
    
    /// Compression ratio of the segment.
    ///
    /// Higher values might indicate repetitive content.
    public let compressionRatio: Double
    
    /// Probability that this segment contains no speech.
    ///
    /// Values close to 1.0 indicate likely non-speech audio.
    public let noSpeechProb: Double
}

/// Word-level timing information in a transcription.
///
/// Provides precise timestamps for individual words when
/// ``TimestampGranularity.word`` is requested.
///
/// ## Example
/// ```swift
/// // Create subtitles with word-level precision
/// for word in response.words ?? [] {
///     print("\(word.word) appears at \(word.start)s")
/// }
/// ```
public struct TranscriptionWord: Codable, Sendable {
    /// The transcribed word.
    public let word: String
    
    /// Start time of the word in seconds.
    public let start: Double
    
    /// End time of the word in seconds.
    public let end: Double
}

/// A request to translate audio into English text.
///
/// Translates audio from any supported language into English text.
/// Uses the same Whisper model as transcription but always outputs English.
///
/// ## Supported Languages
/// Supports all languages that Whisper can transcribe, automatically
/// detecting the source language.
///
/// ## Example
/// ```swift
/// let audioData = try Data(contentsOf: spanishAudioURL)
/// let request = TranslationRequest(
///     file: audioData,
///     fileName: "spanish_audio.mp3",
///     responseFormat: .text
/// )
/// // Result will be English translation of the Spanish audio
/// ```
public struct TranslationRequest: Sendable {
    /// The audio file data to translate.
    ///
    /// File uploads are limited to 25 MB.
    public let file: Data
    
    /// The name of the audio file including extension.
    ///
    /// Example: "audio.mp3", "recording.wav"
    public let fileName: String
    
    /// The model to use for translation.
    ///
    /// Currently only "whisper-1" is available.
    public let model: String
    
    /// Optional text to guide the model's style.
    ///
    /// Should be in English as the output is always English.
    public let prompt: String?
    
    /// The format of the translation output.
    ///
    /// See ``TranscriptionFormat`` for available options.
    public let responseFormat: TranscriptionFormat?
    
    /// Sampling temperature between 0 and 1.
    ///
    /// Higher values make output more random.
    /// Lower values make it more deterministic.
    public let temperature: Double?
    
    /// Creates a new translation request.
    ///
    /// - Parameters:
    ///   - file: Audio file data to translate (max 25 MB)
    ///   - fileName: Name of the file with extension
    ///   - model: Model to use (default: "whisper-1")
    ///   - prompt: Optional English text to guide style
    ///   - responseFormat: Output format for the translation
    ///   - temperature: Sampling temperature (0-1)
    public init(
        file: Data,
        fileName: String,
        model: String = "whisper-1",
        prompt: String? = nil,
        responseFormat: TranscriptionFormat? = nil,
        temperature: Double? = nil
    ) {
        self.file = file
        self.fileName = fileName
        self.model = model
        self.prompt = prompt
        self.responseFormat = responseFormat
        self.temperature = temperature
    }
}

/// The response from an audio translation request.
///
/// Contains the English translation of the audio content.
///
/// ## Example
/// ```swift
/// // Translate Spanish audio to English
/// let response = try await openAI.translate(request)
/// print("English translation: \(response.text)")
///
/// if let usage = response.usage {
///     print("Tokens used: \(usage.totalTokens)")
/// }
/// ```
public struct TranslationResponse: Codable, Sendable {
    /// The translated text in English.
    public let text: String
    
    /// Token usage information if requested via `include` parameter.
    public let usage: Usage?
}