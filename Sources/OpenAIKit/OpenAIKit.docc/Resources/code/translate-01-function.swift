import OpenAIKit
import Foundation

// MARK: - Audio Translation Function

func translateAudio(from audioURL: URL) async throws -> String {
    let openAI = OpenAIKit(apiKey: "your-api-key")
    
    // Load audio file data
    let audioData = try Data(contentsOf: audioURL)
    
    // Create translation request
    let translationRequest = AudioTranslationRequest(
        file: audioData,
        model: "whisper-1",
        prompt: nil,  // Optional: context to help translation
        responseFormat: .json,
        temperature: 0  // Lower temperature for more consistent translations
    )
    
    // Send the request
    let response = try await openAI.createAudioTranslation(request: translationRequest)
    
    // Return the translated text
    return response.text
}

// MARK: - Translation Manager

class AudioTranslationManager {
    private let openAI: OpenAIKit
    
    init(apiKey: String) {
        self.openAI = OpenAIKit(apiKey: apiKey)
    }
    
    func translate(
        audioFile: URL,
        contextPrompt: String? = nil
    ) async throws -> TranslationResult {
        let startTime = Date()
        
        // Load and validate audio
        let audioData = try Data(contentsOf: audioFile)
        
        // Check file size (max 25MB)
        let maxSize = 25 * 1024 * 1024
        guard audioData.count <= maxSize else {
            throw TranslationError.fileTooLarge
        }
        
        // Create request with context
        let request = AudioTranslationRequest(
            file: audioData,
            model: "whisper-1",
            prompt: contextPrompt,
            responseFormat: .verboseJson
        )
        
        // Perform translation
        let response = try await openAI.createAudioTranslation(request: request)
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        return TranslationResult(
            text: response.text,
            sourceLanguage: response.language ?? "unknown",
            duration: response.duration ?? 0,
            processingTime: processingTime,
            segments: response.segments ?? []
        )
    }
    
    // Translate with automatic language detection
    func translateWithDetection(
        audioFile: URL
    ) async throws -> (translation: String, detectedLanguage: String) {
        // First transcribe to detect language
        let transcriptionRequest = AudioTranscriptionRequest(
            file: try Data(contentsOf: audioFile),
            model: "whisper-1",
            responseFormat: .verboseJson
        )
        
        let transcriptionResponse = try await openAI.createAudioTranscription(
            request: transcriptionRequest
        )
        
        let detectedLanguage = transcriptionResponse.language ?? "unknown"
        
        // If already in English, return transcription
        if detectedLanguage.lowercased() == "en" || detectedLanguage.lowercased() == "english" {
            return (transcriptionResponse.text, detectedLanguage)
        }
        
        // Otherwise, translate to English
        let translationRequest = AudioTranslationRequest(
            file: try Data(contentsOf: audioFile),
            model: "whisper-1"
        )
        
        let translationResponse = try await openAI.createAudioTranslation(
            request: translationRequest
        )
        
        return (translationResponse.text, detectedLanguage)
    }
}

// MARK: - Models

struct TranslationResult {
    let text: String
    let sourceLanguage: String
    let duration: Double
    let processingTime: TimeInterval
    let segments: [TranscriptionSegment]
    
    var averageConfidence: Double {
        guard !segments.isEmpty else { return 0 }
        let totalConfidence = segments.reduce(0) { $0 + ($1.avgLogprob ?? 0) }
        return totalConfidence / Double(segments.count)
    }
}

struct TranscriptionSegment: Codable {
    let id: Int
    let start: Double
    let end: Double
    let text: String
    let avgLogprob: Double?
}

enum TranslationError: Error {
    case fileTooLarge
    case unsupportedFormat
    case processingFailed
    case languageNotSupported
}