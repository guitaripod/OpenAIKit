import Foundation
import OpenAIKit

struct AudioTests {
    let output = ConsoleOutput()
    
    func runAll(openAI: OpenAIKit) async {
        await testAudioTranscription(openAI: openAI)
        await testTextToSpeech(openAI: openAI)
    }
    
    func testAudioTranscription(openAI: OpenAIKit) async {
        output.startTest("🎤 Testing Audio Transcription...")
        
        do {
            // Create a simple test audio file if it doesn't exist
            let audioURL = URL(fileURLWithPath: "test_audio.wav")
            
            if !FileManager.default.fileExists(atPath: audioURL.path) {
                // Create a simple sine wave audio file using the shell
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/ffmpeg")
                process.arguments = [
                    "-f", "lavfi",
                    "-i", "sine=frequency=440:duration=2",
                    "-ac", "1",
                    "-ar", "16000",
                    audioURL.path
                ]
                try process.run()
                process.waitUntilExit()
            }
            
            let audioData = try Data(contentsOf: audioURL)
            
            let request = TranscriptionRequest(
                file: audioData,
                fileName: "test_audio.wav",
                model: Models.Audio.whisper1
            )
            
            let response = try await openAI.audio.transcriptions(request)
            
            output.success("Audio transcription successful!")
            output.info("Text: \(response.text)")
            if let language = response.language {
                output.info("Detected language: \(language)")
            }
            if let duration = response.duration {
                output.info("Duration: \(duration) seconds")
            }
            
            // Clean up
            try? FileManager.default.removeItem(at: audioURL)
        } catch {
            output.failure("Audio transcription failed", error: error)
        }
    }
    
    func testTextToSpeech(openAI: OpenAIKit) async {
        output.startTest("🔊 Testing Text-to-Speech...")
        
        do {
            let request = SpeechRequest(
                input: "Hello, this is a test of OpenAIKit text to speech.",
                model: Models.Audio.tts1,
                voice: .alloy,
                responseFormat: .mp3,
                speed: 1.0
            )
            
            let audioData = try await openAI.audio.speech(request)
            
            output.success("TTS successful!")
            output.info("Audio data size: \(audioData.count) bytes")
            
            // Save to file for verification
            let url = URL(fileURLWithPath: "test_speech.mp3")
            try audioData.write(to: url)
            output.info("Audio saved to: test_speech.mp3")
        } catch {
            output.failure("TTS failed", error: error)
        }
    }
}