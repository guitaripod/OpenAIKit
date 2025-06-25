import Foundation

/// Provides access to OpenAI's audio-related API endpoints.
///
/// The `AudioEndpoint` class handles text-to-speech generation, audio transcription,
/// and audio translation operations. It provides a clean interface for working with
/// OpenAI's Whisper model for speech recognition and TTS models for speech synthesis.
///
/// ## Overview
///
/// This endpoint supports three main audio operations:
/// - **Speech Generation**: Convert text to lifelike spoken audio
/// - **Transcription**: Convert audio to text in the same language
/// - **Translation**: Convert audio in any language to English text
///
/// ## Topics
///
/// ### Creating Speech from Text
/// - ``speech(_:)``
/// - ``SpeechRequest``
/// - ``Voice``
/// - ``AudioFormat``
///
/// ### Transcribing Audio
/// - ``transcriptions(_:)``
/// - ``TranscriptionRequest``
/// - ``TranscriptionResponse``
/// - ``TranscriptionFormat``
/// - ``TimestampGranularity``
///
/// ### Translating Audio
/// - ``translations(_:)``
/// - ``TranslationRequest``
/// - ``TranslationResponse``
public final class AudioEndpoint: Sendable {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    /// Generates audio from text using OpenAI's text-to-speech models.
    ///
    /// This method converts written text into natural-sounding speech using advanced TTS models.
    /// You can customize the voice, speed, and output format to suit your needs.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Generate basic speech
    /// let request = SpeechRequest(
    ///     input: "Hello, welcome to our application!",
    ///     voice: .nova
    /// )
    /// let audioData = try await audioEndpoint.speech(request)
    /// 
    /// // Save to file
    /// try audioData.write(to: URL(fileURLWithPath: "welcome.mp3"))
    /// ```
    ///
    /// ## Advanced Example
    ///
    /// ```swift
    /// // Generate high-quality speech with custom settings
    /// let request = SpeechRequest(
    ///     input: "This is a high-quality audio sample.",
    ///     model: "tts-1-hd",  // Higher quality model
    ///     voice: .alloy,
    ///     responseFormat: .opus,  // Efficient format for streaming
    ///     speed: 0.9  // Slightly slower for clarity
    /// )
    /// let audioData = try await audioEndpoint.speech(request)
    /// ```
    ///
    /// - Parameter request: A ``SpeechRequest`` containing the text and configuration for speech generation.
    ///
    /// - Returns: Raw audio data in the requested format. The data can be saved to a file or played directly.
    ///
    /// - Throws: ``OpenAIError`` if the request fails. Common errors include:
    ///   - ``OpenAIError/authenticationFailed``: Invalid or missing API key
    ///   - ``OpenAIError/rateLimitExceeded``: Too many requests
    ///   - ``OpenAIError/invalidResponse``: Server returned an unexpected response
    ///   - ``OpenAIError/apiError(_:)``: API-specific error with details
    ///
    /// - Important: The input text is limited to 4096 characters. Longer texts should be split into chunks.
    ///
    /// ## See Also
    /// - ``SpeechRequest``
    /// - ``Voice``
    /// - ``AudioFormat``
    public func speech(_ request: SpeechRequest) async throws -> Data {
        let apiRequest = SpeechAPIRequest(request: request)
        return try await networkClient.execute(apiRequest)
    }
    
    /// Transcribes audio into text in the original language.
    ///
    /// This method uses OpenAI's Whisper model to convert audio files into accurate transcriptions.
    /// It supports multiple languages, various audio formats, and can provide detailed timing information.
    ///
    /// ## Basic Example
    ///
    /// ```swift
    /// // Simple transcription
    /// let audioData = try Data(contentsOf: audioFileURL)
    /// let request = TranscriptionRequest(
    ///     file: audioData,
    ///     fileName: "interview.mp3"
    /// )
    /// let response = try await audioEndpoint.transcriptions(request)
    /// print(response.text)
    /// ```
    ///
    /// ## Advanced Example with Timestamps
    ///
    /// ```swift
    /// // Detailed transcription with word-level timestamps
    /// let request = TranscriptionRequest(
    ///     file: audioData,
    ///     fileName: "podcast.mp3",
    ///     language: "en",  // Hint for better accuracy
    ///     prompt: "Technical podcast about Swift programming",
    ///     responseFormat: .verboseJson,
    ///     timestampGranularities: [.word, .segment]
    /// )
    /// 
    /// let response = try await audioEndpoint.transcriptions(request)
    /// 
    /// // Access detailed information
    /// print("Detected language: \(response.language ?? "unknown")")
    /// print("Duration: \(response.duration ?? 0) seconds")
    /// 
    /// // Process word-level timestamps
    /// for word in response.words ?? [] {
    ///     print("\(word.word) at \(word.start)s")
    /// }
    /// ```
    ///
    /// ## Creating Subtitles
    ///
    /// ```swift
    /// // Generate SRT subtitles
    /// let request = TranscriptionRequest(
    ///     file: videoAudioData,
    ///     fileName: "video_audio.mp3",
    ///     responseFormat: .srt
    /// )
    /// let response = try await audioEndpoint.transcriptions(request)
    /// try response.text.write(to: subtitlesURL, atomically: true, encoding: .utf8)
    /// ```
    ///
    /// - Parameter request: A ``TranscriptionRequest`` containing the audio file and configuration options.
    ///
    /// - Returns: A ``TranscriptionResponse`` containing the transcribed text and optional metadata.
    ///
    /// - Throws: ``OpenAIError`` if the transcription fails. Common errors include:
    ///   - ``OpenAIError/invalidFileData``: Audio file is corrupted or in an unsupported format
    ///   - ``OpenAIError/apiError(_:)``: File too large (>25MB) or other API errors
    ///   - ``OpenAIError/rateLimitExceeded``: Too many concurrent requests
    ///
    /// - Note: Supported audio formats include: flac, mp3, mp4, mpeg, mpga, m4a, ogg, wav, and webm.
    ///         File uploads are limited to 25 MB.
    ///
    /// ## See Also
    /// - ``TranscriptionRequest``
    /// - ``TranscriptionResponse``
    /// - ``TranscriptionFormat``
    /// - ``TimestampGranularity``
    public func transcriptions(_ request: TranscriptionRequest) async throws -> TranscriptionResponse {
        let apiRequest = TranscriptionAPIRequest(request: request)
        return try await networkClient.upload(apiRequest)
    }
    
    /// Translates audio from any language into English text.
    ///
    /// This method uses the Whisper model to automatically detect the source language
    /// and translate the audio content into English. It's ideal for creating English
    /// transcripts from foreign language audio.
    ///
    /// ## Basic Example
    ///
    /// ```swift
    /// // Translate Spanish audio to English
    /// let audioData = try Data(contentsOf: spanishAudioURL)
    /// let request = TranslationRequest(
    ///     file: audioData,
    ///     fileName: "spanish_interview.mp3"
    /// )
    /// let response = try await audioEndpoint.translations(request)
    /// print("English translation: \(response.text)")
    /// ```
    ///
    /// ## Advanced Example with Style Guidance
    ///
    /// ```swift
    /// // Translate with context for better accuracy
    /// let request = TranslationRequest(
    ///     file: audioData,
    ///     fileName: "technical_presentation.mp3",
    ///     prompt: "Technical presentation about machine learning and AI",
    ///     responseFormat: .text,
    ///     temperature: 0.2  // More deterministic output
    /// )
    /// 
    /// let response = try await audioEndpoint.translations(request)
    /// // Save the translation
    /// try response.text.write(
    ///     to: URL(fileURLWithPath: "translation.txt"),
    ///     atomically: true,
    ///     encoding: .utf8
    /// )
    /// ```
    ///
    /// ## Translating for Subtitles
    ///
    /// ```swift
    /// // Create English subtitles from foreign language video
    /// let request = TranslationRequest(
    ///     file: extractedAudio,
    ///     fileName: "french_movie_audio.mp3",
    ///     responseFormat: .srt  // Subtitle format with timestamps
    /// )
    /// let response = try await audioEndpoint.translations(request)
    /// // response.text contains SRT-formatted English subtitles
    /// ```
    ///
    /// - Parameter request: A ``TranslationRequest`` containing the audio file and configuration options.
    ///
    /// - Returns: A ``TranslationResponse`` containing the English translation of the audio.
    ///
    /// - Throws: ``OpenAIError`` if the translation fails. Common errors include:
    ///   - ``OpenAIError/invalidFileData``: Audio file is corrupted or in an unsupported format
    ///   - ``OpenAIError/apiError(_:)``: File too large (>25MB) or processing error
    ///   - ``OpenAIError/rateLimitExceeded``: API rate limit exceeded
    ///
    /// - Important: The output is always in English, regardless of the input language.
    ///              The source language is automatically detected by the model.
    ///
    /// - Note: Unlike transcription, translation doesn't support word-level timestamps
    ///         or verbose JSON format with detailed metadata.
    ///
    /// ## See Also
    /// - ``TranslationRequest``
    /// - ``TranslationResponse``
    /// - ``transcriptions(_:)`` - For same-language transcription
    public func translations(_ request: TranslationRequest) async throws -> TranslationResponse {
        let apiRequest = TranslationAPIRequest(request: request)
        return try await networkClient.upload(apiRequest)
    }
}

private struct SpeechAPIRequest: Request {
    typealias Body = SpeechRequest
    typealias Response = Data
    
    let path = "audio/speech"
    let method: HTTPMethod = .post
    let body: SpeechRequest?
    
    init(request: SpeechRequest) {
        self.body = request
    }
}

private struct TranscriptionAPIRequest: UploadRequest {
    typealias Response = TranscriptionResponse
    
    let path = "audio/transcriptions"
    private let request: TranscriptionRequest
    
    init(request: TranscriptionRequest) {
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
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(request.model)\r\n".data(using: .utf8)!)
        
        if let language = request.language {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(language)\r\n".data(using: .utf8)!)
        }
        
        if let prompt = request.prompt {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(prompt)\r\n".data(using: .utf8)!)
        }
        
        if let responseFormat = request.responseFormat {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(responseFormat.rawValue)\r\n".data(using: .utf8)!)
        }
        
        if let temperature = request.temperature {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"temperature\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(temperature)\r\n".data(using: .utf8)!)
        }
        
        if let timestampGranularities = request.timestampGranularities {
            for granularity in timestampGranularities {
                data.append("--\(boundary)\r\n".data(using: .utf8)!)
                data.append("Content-Disposition: form-data; name=\"timestamp_granularities[]\"\r\n\r\n".data(using: .utf8)!)
                data.append("\(granularity.rawValue)\r\n".data(using: .utf8)!)
            }
        }
        
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return data
    }
    
    private func mimeType(for fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "flac": return "audio/flac"
        case "mp3": return "audio/mpeg"
        case "mp4": return "audio/mp4"
        case "mpeg", "mpga": return "audio/mpeg"
        case "m4a": return "audio/m4a"
        case "ogg": return "audio/ogg"
        case "wav": return "audio/wav"
        case "webm": return "audio/webm"
        default: return "application/octet-stream"
        }
    }
}

private struct TranslationAPIRequest: UploadRequest {
    typealias Response = TranslationResponse
    
    let path = "audio/translations"
    private let request: TranslationRequest
    
    init(request: TranslationRequest) {
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
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(request.model)\r\n".data(using: .utf8)!)
        
        if let prompt = request.prompt {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(prompt)\r\n".data(using: .utf8)!)
        }
        
        if let responseFormat = request.responseFormat {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(responseFormat.rawValue)\r\n".data(using: .utf8)!)
        }
        
        if let temperature = request.temperature {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"temperature\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(temperature)\r\n".data(using: .utf8)!)
        }
        
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return data
    }
    
    private func mimeType(for fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "flac": return "audio/flac"
        case "mp3": return "audio/mpeg"
        case "mp4": return "audio/mp4"
        case "mpeg", "mpga": return "audio/mpeg"
        case "m4a": return "audio/m4a"
        case "ogg": return "audio/ogg"
        case "wav": return "audio/wav"
        case "webm": return "audio/webm"
        default: return "application/octet-stream"
        }
    }
}