// AudioTranscriber.swift
import Foundation
import OpenAIKit
import AVFoundation

class AudioTranscriber {
    let openAI = OpenAIManager.shared.client
    
    func transcribe(audioFileURL: URL) async throws -> String {
        guard let openAI = openAI else {
            throw OpenAIError.missingAPIKey
        }
        
        // Read audio file data
        let audioData = try Data(contentsOf: audioFileURL)
        
        let request = TranscriptionRequest(
            file: FileUpload(
                data: audioData,
                filename: audioFileURL.lastPathComponent,
                contentType: contentType(for: audioFileURL)
            ),
            model: "whisper-1",
            language: nil,
            prompt: nil,
            responseFormat: .json,
            temperature: nil,
            timestampGranularities: nil
        )
        
        let response = try await openAI.audio.transcriptions(request)
        return response.text
    }
    
    private func contentType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "mp3":
            return "audio/mpeg"
        case "mp4", "m4a":
            return "audio/mp4"
        case "wav":
            return "audio/wav"
        case "webm":
            return "audio/webm"
        default:
            return "audio/mpeg"
        }
    }
}
