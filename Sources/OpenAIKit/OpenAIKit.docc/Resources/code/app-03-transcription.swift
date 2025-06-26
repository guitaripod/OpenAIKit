import SwiftUI
import OpenAIKit

// MARK: - Transcription View

struct TranscriptionView: View {
    let recording: Recording
    @ObservedObject var recorder: AudioRecorder
    @StateObject private var transcriber = AudioTranscriber()
    @State private var transcriptionText = ""
    @State private var isTranscribing = false
    @State private var transcriptionOptions = TranscriptionOptions()
    @State private var showingOptions = false
    @State private var transcriptionError: Error?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Recording Info Header
                RecordingInfoHeader(recording: recording)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                
                // Transcription Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Options Section
                        TranscriptionOptionsView(options: $transcriptionOptions)
                            .padding(.horizontal)
                        
                        Divider()
                        
                        // Transcription Area
                        if isTranscribing {
                            TranscribingView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if !transcriptionText.isEmpty {
                            TranscriptionResultView(
                                text: transcriptionText,
                                onCopy: copyTranscription,
                                onShare: shareTranscription
                            )
                            .padding()
                        } else {
                            EmptyTranscriptionView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: startTranscription) {
                        Label(
                            isTranscribing ? "Transcribing..." : "Transcribe Audio",
                            systemImage: isTranscribing ? "waveform" : "text.bubble"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isTranscribing)
                    
                    if !transcriptionText.isEmpty {
                        HStack(spacing: 12) {
                            Button(action: saveTranscription) {
                                Label("Save", systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: copyTranscription) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: shareTranscription) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Transcription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingOptions.toggle() }) {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .alert("Transcription Error", isPresented: .constant(transcriptionError != nil)) {
                Button("OK") {
                    transcriptionError = nil
                }
            } message: {
                Text(transcriptionError?.localizedDescription ?? "Unknown error")
            }
            .sheet(isPresented: $showingOptions) {
                TranscriptionSettingsView(options: $transcriptionOptions)
            }
        }
    }
    
    private func startTranscription() {
        isTranscribing = true
        transcriptionError = nil
        
        Task {
            do {
                let result = try await transcriber.transcribe(
                    audioURL: recording.url,
                    options: transcriptionOptions
                )
                
                await MainActor.run {
                    self.transcriptionText = result.text
                    self.isTranscribing = false
                    
                    // Update recording with transcription
                    if let index = recorder.recordings.firstIndex(where: { $0.id == recording.id }) {
                        recorder.recordings[index].transcription = result.text
                    }
                }
            } catch {
                await MainActor.run {
                    self.transcriptionError = error
                    self.isTranscribing = false
                }
            }
        }
    }
    
    private func saveTranscription() {
        // Save transcription to recording
        if let index = recorder.recordings.firstIndex(where: { $0.id == recording.id }) {
            recorder.recordings[index].transcription = transcriptionText
        }
        dismiss()
    }
    
    private func copyTranscription() {
        UIPasteboard.general.string = transcriptionText
    }
    
    private func shareTranscription() {
        let activityController = UIActivityViewController(
            activityItems: [transcriptionText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityController, animated: true)
        }
    }
}

// MARK: - Audio Transcriber

class AudioTranscriber: ObservableObject {
    private let openAI: OpenAIKit
    
    init() {
        // In production, get API key from secure storage
        self.openAI = OpenAIKit(apiKey: "your-api-key")
    }
    
    func transcribe(
        audioURL: URL,
        options: TranscriptionOptions
    ) async throws -> TranscriptionResult {
        let audioData = try Data(contentsOf: audioURL)
        
        let request = AudioTranscriptionRequest(
            file: audioData,
            model: "whisper-1",
            prompt: options.prompt,
            responseFormat: options.includeTimestamps ? .verboseJson : .json,
            temperature: options.temperature,
            language: options.language?.rawValue
        )
        
        let startTime = Date()
        let response = try await openAI.createAudioTranscription(request: request)
        let processingTime = Date().timeIntervalSince(startTime)
        
        return TranscriptionResult(
            text: response.text,
            language: response.language,
            duration: response.duration,
            segments: response.segments,
            processingTime: processingTime
        )
    }
}

// MARK: - Transcription Options

struct TranscriptionOptions {
    var language: WhisperLanguage?
    var prompt: String?
    var temperature: Double = 0
    var includeTimestamps = false
    var includePunctuation = true
}

// MARK: - Supporting Views

struct RecordingInfoHeader: View {
    let recording: Recording
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.name)
                    .font(.headline)
                
                HStack {
                    Label(recording.formattedDuration, systemImage: "timer")
                    Label(recording.formattedDate, systemImage: "calendar")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "waveform")
                .font(.title2)
                .foregroundColor(.blue)
        }
    }
}

struct TranscriptionOptionsView: View {
    @Binding var options: TranscriptionOptions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Options")
                .font(.headline)
            
            Toggle("Include Timestamps", isOn: $options.includeTimestamps)
            Toggle("Include Punctuation", isOn: $options.includePunctuation)
            
            if let language = options.language {
                HStack {
                    Text("Language:")
                    Text("\(language.flag) \(language.displayName)")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct TranscribingView: View {
    @State private var dots = 0
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("Transcribing\(String(repeating: ".", count: dots))")
                .font(.headline)
                .onAppear {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                            dots = (dots + 1) % 4
                        }
                    }
                }
        }
        .frame(height: 200)
    }
}

struct TranscriptionResultView: View {
    let text: String
    let onCopy: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Transcription")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                    }
                    
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            
            Text(text)
                .font(.body)
                .textSelection(.enabled)
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(12)
        }
    }
}

struct EmptyTranscriptionView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.bubble")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No transcription yet")
                .font(.headline)
            
            Text("Tap the button below to transcribe this recording")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
    }
}

// MARK: - Models

struct TranscriptionResult {
    let text: String
    let language: String?
    let duration: Double?
    let segments: [TranscriptionSegment]?
    let processingTime: TimeInterval
}