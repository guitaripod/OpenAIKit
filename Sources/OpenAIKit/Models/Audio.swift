import Foundation

/// A request to generate audio from text using OpenAI's text-to-speech models.
///
/// `SpeechRequest` enables you to convert text into natural-sounding speech with multiple voice options
/// and audio formats. Perfect for accessibility features, audio content creation, and voice interfaces.
///
/// ## Overview
///
/// OpenAI's TTS models produce lifelike speech from text, supporting multiple languages and voices.
/// Choose between standard quality for real-time applications or HD quality for premium audio content.
///
/// ## Basic Example
///
/// ```swift
/// // Simple speech generation
/// let request = SpeechRequest(
///     input: "Hello, welcome to our application!",
///     voice: .nova
/// )
///
/// // With customization
/// let request = SpeechRequest(
///     input: "The quick brown fox jumps over the lazy dog.",
///     model: Models.Audio.tts1HD,  // Higher quality
///     voice: .alloy,
///     responseFormat: .opus,       // Optimized for streaming
///     speed: 0.9                   // Slightly slower for clarity
/// )
/// ```
///
/// ## Use Cases
///
/// - **Accessibility**: Screen readers and audio descriptions
/// - **Content Creation**: Podcasts, audiobooks, videos
/// - **Voice Interfaces**: IVR systems, voice assistants
/// - **Education**: Language learning, pronunciation guides
/// - **Notifications**: Audio alerts and announcements
///
/// - Important: Input text is limited to 4096 characters per request
public struct SpeechRequest: Codable, Sendable {
    /// The text to generate audio for.
    ///
    /// The input text will be converted to speech. For best results:
    /// - Use clear, grammatically correct text
    /// - Include punctuation for natural pauses
    /// - Spell out numbers and abbreviations as needed
    /// - Use phonetic spelling for unusual names
    ///
    /// ## Examples
    ///
    /// ```swift
    /// // Clear narration
    /// "Welcome to Chapter 1. Today we'll explore the fundamentals of Swift programming."
    ///
    /// // With emphasis (using punctuation)
    /// "This is important! Please pay careful attention to the following instructions."
    ///
    /// // Phonetic guidance
    /// "The CEO, John Doe (pronounced 'doh'), will speak at 3 PM."
    /// ```
    ///
    /// - Maximum: 4096 characters
    /// - Tip: For longer content, split into multiple requests
    public let input: String
    
    /// The TTS model to use.
    ///
    /// Choose based on your quality and latency requirements.
    ///
    /// ## Available Models
    ///
    /// **TTS-1** (`tts-1`) - Standard Quality
    /// - Lower latency (~1 second)
    /// - Good for real-time applications
    /// - Slightly more robotic sound
    /// - Lower cost per character
    /// - Use for: Chat responses, notifications
    ///
    /// **TTS-1-HD** (`tts-1-hd`) - High Definition
    /// - Higher latency (~2-3 seconds)
    /// - Superior audio quality
    /// - More natural intonation
    /// - Higher cost per character
    /// - Use for: Audiobooks, podcasts, premium content
    ///
    /// ## Example
    ///
    /// ```swift
    /// // For real-time response
    /// model: Models.Audio.tts1
    ///
    /// // For production content
    /// model: Models.Audio.tts1HD
    /// ```
    public let model: String
    
    /// The voice to use for audio generation.
    ///
    /// Each voice has unique characteristics. Experiment to find the best match
    /// for your content and audience.
    ///
    /// ## Voice Selection Guide
    ///
    /// - **nova**: Friendly and conversational (recommended for most uses)
    /// - **alloy**: Balanced and versatile
    /// - **echo**: Smooth and steady
    /// - **fable**: Warm storytelling voice
    /// - **onyx**: Deep and authoritative
    /// - **shimmer**: Soft and gentle
    ///
    /// ## Example
    ///
    /// ```swift
    /// // For customer service
    /// voice: .nova
    ///
    /// // For audiobooks
    /// voice: .fable
    ///
    /// // For announcements
    /// voice: .onyx
    /// ```
    ///
    /// - SeeAlso: ``Voice``
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
    /// Adjust playback speed without affecting pitch.
    ///
    /// ## Speed Scale
    ///
    /// - `0.25`: Very slow (25% speed) - Language learning
    /// - `0.5`: Half speed - Complex instructions
    /// - `0.75`: Slightly slow - Clear enunciation
    /// - `1.0`: Normal speed (default)
    /// - `1.25`: Slightly fast - Efficient listening
    /// - `1.5`: Fast - Quick updates
    /// - `2.0`: Double speed - Rapid playback
    /// - `4.0`: Maximum speed - Testing only
    ///
    /// ## Use Cases
    ///
    /// ```swift
    /// // For elderly users
    /// speed: 0.85
    ///
    /// // For technical content
    /// speed: 0.9
    ///
    /// // For quick notifications
    /// speed: 1.2
    /// ```
    ///
    /// - Range: 0.25 to 4.0
    /// - Default: 1.0
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
        model: String = Models.Audio.tts1,
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
/// OpenAI offers a diverse set of voices, each with distinct characteristics. All voices
/// support multiple languages, though they're optimized for English.
///
/// ## Voice Selection Guide
///
/// ### Primary Voices (Most Popular)
///
/// - **nova**: Clear, friendly, conversational - Great for assistants
/// - **alloy**: Balanced, neutral - Versatile for any content
/// - **echo**: Smooth, consistent - Professional narration
/// - **fable**: Warm, engaging - Storytelling and long content
/// - **onyx**: Deep, authoritative - News and announcements  
/// - **shimmer**: Soft, calming - Meditation and relaxation
///
/// ### Additional Voices
///
/// - **ash**: Youthful and energetic
/// - **ballad**: Melodic and expressive
/// - **coral**: Bright and cheerful
/// - **sage**: Mature and wise
/// - **verse**: Dynamic and versatile
///
/// ## Usage Examples
///
/// ```swift
/// // Customer service bot
/// voice: .nova
///
/// // News reader
/// voice: .onyx
///
/// // Children's stories
/// voice: .fable
///
/// // Meditation app
/// voice: .shimmer
/// ```
///
/// ## Language Support
///
/// All voices support multiple languages with automatic detection.
/// Quality is best for English but good for major languages.
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
/// Choose the optimal format based on your use case, balancing quality, file size, and compatibility.
///
/// ## Format Comparison
///
/// | Format | Quality | Size | Use Case |
/// |--------|---------|------|----------|
/// | MP3    | Good    | Small | General use, web |
/// | Opus   | Good    | Smallest | Streaming, VoIP |
/// | AAC    | Better  | Small | Apple devices |
/// | FLAC   | Perfect | Large | Archival |
/// | WAV    | Perfect | Largest | Pro audio |
/// | PCM    | Raw     | Large | Processing |
///
/// ## Format Details
///
/// **MP3** - MPEG Audio Layer 3
/// - Bitrate: 128-320 kbps
/// - Universal compatibility
/// - Best for: Web playback, downloads
///
/// **Opus** - Modern codec
/// - Bitrate: 6-510 kbps
/// - Excellent at low bitrates
/// - Best for: Real-time streaming, mobile
///
/// **AAC** - Advanced Audio Coding
/// - Better than MP3 at same bitrate
/// - Native Apple support
/// - Best for: iOS/macOS apps
///
/// **FLAC** - Free Lossless Audio Codec
/// - Lossless compression (~50% of WAV)
/// - Preserves full quality
/// - Best for: Archival, high-quality needs
///
/// **WAV** - Waveform Audio
/// - Uncompressed PCM
/// - No quality loss
/// - Best for: Audio editing, maximum quality
///
/// **PCM** - Pulse Code Modulation
/// - Raw 24kHz 16-bit little-endian
/// - Direct audio samples
/// - Best for: Custom processing
///
/// ## Examples
///
/// ```swift
/// // For web streaming
/// responseFormat: .opus
///
/// // For iOS app
/// responseFormat: .aac
///
/// // For highest quality
/// responseFormat: .wav
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
/// `TranscriptionRequest` converts speech to text with high accuracy across multiple languages.
/// Whisper is a state-of-the-art speech recognition model that handles accents, background noise,
/// and technical terminology exceptionally well.
///
/// ## Overview
///
/// Whisper can:
/// - Transcribe in 50+ languages
/// - Add punctuation and capitalization
/// - Handle multiple speakers
/// - Work with noisy audio
/// - Provide word-level timestamps
/// - Output in various formats
///
/// ## Supported File Formats
///
/// - **Compressed**: mp3, mp4, mpeg, mpga, m4a, ogg, webm
/// - **Uncompressed**: wav, flac
/// - **Maximum size**: 25 MB
/// - **Recommended**: mp3 or m4a for balance of quality and size
///
/// ## Basic Examples
///
/// ```swift
/// // Simple transcription
/// let audioData = try Data(contentsOf: audioFileURL)
/// let request = TranscriptionRequest(
///     file: audioData,
///     fileName: "interview.mp3"
/// )
///
/// // With language and timestamps
/// let request = TranscriptionRequest(
///     file: audioData,
///     fileName: "podcast.mp3",
///     language: "en",
///     responseFormat: .verboseJson,
///     timestampGranularities: [.word, .segment]
/// )
///
/// // For translation to English
/// let request = TranscriptionRequest(
///     file: audioData,
///     fileName: "speech_spanish.mp3",
///     language: "es",
///     responseFormat: .text
/// )
/// ```
///
/// ## Best Practices
///
/// - **Audio Quality**: Higher quality audio produces better results
/// - **File Size**: Split long audio into <25MB chunks
/// - **Language**: Specify if known for better accuracy
/// - **Format**: Use verboseJson for detailed output with confidence scores
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
        model: String = Models.Audio.whisper1,
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

/// Token usage information for audio endpoints.
///
/// Audio endpoints return different usage information than chat endpoints.
/// This structure captures the audio-specific usage data.
public struct AudioUsage: Codable, Sendable {
    /// Total number of tokens used.
    public let totalTokens: Int?
    
    /// Prompt tokens used (if applicable).
    public let promptTokens: Int?
    
    /// Completion tokens used (if applicable).
    public let completionTokens: Int?
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
    public let usage: AudioUsage?
    
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
        model: String = Models.Audio.whisper1,
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
    public let usage: AudioUsage?
}