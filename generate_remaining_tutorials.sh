#!/bin/bash

# Create the remaining tutorial code files directly

cd Sources/OpenAIKit/OpenAIKit.docc/Resources/code

# Remaining files from Tutorial 5
cat > "persona-01-struct.swift" << 'EOF'
// Persona.swift
import Foundation

struct Persona: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let systemPrompt: String
    let temperature: Double
    let traits: [String]
    let knowledge: [String]
    let examples: [ConversationExample]
    
    static let helpful = Persona(
        name: "Helpful Assistant",
        description: "A friendly and helpful AI assistant",
        systemPrompt: "You are a helpful, friendly, and professional AI assistant. Provide clear and accurate information while being approachable.",
        temperature: 0.7,
        traits: ["friendly", "professional", "clear", "patient"],
        knowledge: [],
        examples: []
    )
    
    static let creative = Persona(
        name: "Creative Writer",
        description: "A creative and imaginative storyteller",
        systemPrompt: "You are a creative writer with a vivid imagination. Help users with creative writing, storytelling, and brainstorming ideas.",
        temperature: 0.9,
        traits: ["imaginative", "descriptive", "engaging", "original"],
        knowledge: ["literature", "storytelling techniques", "creative writing"],
        examples: []
    )
    
    static let technical = Persona(
        name: "Technical Expert",
        description: "A precise technical advisor",
        systemPrompt: "You are a technical expert who provides accurate, detailed technical information. Focus on precision and clarity.",
        temperature: 0.3,
        traits: ["precise", "analytical", "thorough", "logical"],
        knowledge: ["programming", "technology", "engineering", "mathematics"],
        examples: []
    )
}

struct ConversationExample: Codable {
    let userInput: String
    let assistantResponse: String
}
EOF

cat > "persona-02-prompts.swift" << 'EOF'
// PersonaManager.swift
import Foundation

class PersonaManager: ObservableObject {
    @Published var currentPersona: Persona = .helpful
    @Published var customPersonas: [Persona] = []
    
    private let userDefaults = UserDefaults.standard
    private let customPersonasKey = "customPersonas"
    
    init() {
        loadCustomPersonas()
    }
    
    func buildSystemPrompt(for persona: Persona) -> String {
        var prompt = persona.systemPrompt
        
        // Add traits
        if !persona.traits.isEmpty {
            prompt += "\n\nYour personality traits: \(persona.traits.joined(separator: ", "))"
        }
        
        // Add knowledge domains
        if !persona.knowledge.isEmpty {
            prompt += "\n\nYou have expertise in: \(persona.knowledge.joined(separator: ", "))"
        }
        
        // Add examples
        if !persona.examples.isEmpty {
            prompt += "\n\nExample interactions:"
            for example in persona.examples.prefix(3) {
                prompt += "\nUser: \(example.userInput)"
                prompt += "\nAssistant: \(example.assistantResponse)"
            }
        }
        
        return prompt
    }
    
    func createCustomPersona(
        name: String,
        description: String,
        basePrompt: String,
        traits: [String],
        temperature: Double = 0.7
    ) {
        let persona = Persona(
            name: name,
            description: description,
            systemPrompt: basePrompt,
            temperature: temperature,
            traits: traits,
            knowledge: [],
            examples: []
        )
        
        customPersonas.append(persona)
        saveCustomPersonas()
    }
    
    private func loadCustomPersonas() {
        guard let data = userDefaults.data(forKey: customPersonasKey),
              let personas = try? JSONDecoder().decode([Persona].self, from: data) else {
            return
        }
        customPersonas = personas
    }
    
    private func saveCustomPersonas() {
        guard let data = try? JSONEncoder().encode(customPersonas) else { return }
        userDefaults.set(data, forKey: customPersonasKey)
    }
}
EOF

# Tutorial 6: Streaming Responses
cat > "streaming-01-empty.swift" << 'EOF'
// StreamingChat.swift
EOF

cat > "streaming-02-function.swift" << 'EOF'
// StreamingChat.swift
import Foundation
import OpenAIKit

class StreamingChat {
    let openAI = OpenAIManager.shared.client
    
    func streamMessage(_ message: String) async throws {
        // Implementation here
    }
}
EOF

cat > "streaming-03-request.swift" << 'EOF'
// StreamingChat.swift
import Foundation
import OpenAIKit

class StreamingChat {
    let openAI = OpenAIManager.shared.client
    
    func streamMessage(_ message: String) async throws {
        guard let openAI = openAI else {
            throw OpenAIError.missingAPIKey
        }
        
        let request = ChatCompletionRequest(
            messages: [
                ChatMessage(role: .user, content: message)
            ],
            model: "gpt-4o-mini",
            stream: true
        )
        
        // Stream will be handled next
    }
}
EOF

cat > "streaming-04-stream.swift" << 'EOF'
// StreamingChat.swift
import Foundation
import OpenAIKit

class StreamingChat {
    let openAI = OpenAIManager.shared.client
    
    func streamMessage(_ message: String) async throws -> AsyncThrowingStream<String, Error> {
        guard let openAI = openAI else {
            throw OpenAIError.missingAPIKey
        }
        
        let request = ChatCompletionRequest(
            messages: [
                ChatMessage(role: .user, content: message)
            ],
            model: "gpt-4o-mini",
            stream: true,
            streamOptions: StreamOptions(includeUsage: true)
        )
        
        let stream = try await openAI.chat.completionsStream(request)
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await chunk in stream {
                        if let content = chunk.choices.first?.delta.content {
                            continuation.yield(content)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
EOF

cat > "streaming-05-process.swift" << 'EOF'
// StreamingChat.swift - Processing streamed responses
import Foundation
import OpenAIKit

class StreamingChat: ObservableObject {
    @Published var streamedText = ""
    @Published var isStreaming = false
    
    let openAI = OpenAIManager.shared.client
    private var streamTask: Task<Void, Never>?
    
    func streamMessage(_ message: String) {
        streamTask?.cancel()
        streamedText = ""
        isStreaming = true
        
        streamTask = Task {
            do {
                guard let openAI = openAI else {
                    throw OpenAIError.missingAPIKey
                }
                
                let request = ChatCompletionRequest(
                    messages: [
                        ChatMessage(role: .user, content: message)
                    ],
                    model: "gpt-4o-mini",
                    stream: true
                )
                
                let stream = try await openAI.chat.completionsStream(request)
                
                for try await chunk in stream {
                    guard !Task.isCancelled else { break }
                    
                    if let content = chunk.choices.first?.delta.content {
                        await MainActor.run {
                            streamedText += content
                        }
                    }
                }
            } catch {
                print("Streaming error: \(error)")
            }
            
            await MainActor.run {
                isStreaming = false
            }
        }
    }
    
    func cancelStream() {
        streamTask?.cancel()
        isStreaming = false
    }
}
EOF

# Tutorial 7: Generating Images
cat > "image-01-empty.swift" << 'EOF'
// ImageGeneration.swift
EOF

cat > "image-02-function.swift" << 'EOF'
// ImageGeneration.swift
import Foundation
import OpenAIKit

class ImageGenerator {
    let openAI = OpenAIManager.shared.client
    
    func generateImage(prompt: String) async throws -> URL {
        // Implementation here
        return URL(string: "https://example.com")!
    }
}
EOF

cat > "image-03-request.swift" << 'EOF'
// ImageGeneration.swift
import Foundation
import OpenAIKit

class ImageGenerator {
    let openAI = OpenAIManager.shared.client
    
    func generateImage(prompt: String) async throws -> URL {
        guard let openAI = openAI else {
            throw OpenAIError.missingAPIKey
        }
        
        let request = ImageGenerationRequest(
            prompt: prompt,
            model: "dall-e-3",
            n: 1,
            quality: .standard,
            responseFormat: .url,
            size: .size1024x1024,
            style: .natural,
            user: nil
        )
        
        // Send request next
        return URL(string: "https://example.com")!
    }
}
EOF

cat > "image-04-response.swift" << 'EOF'
// ImageGeneration.swift
import Foundation
import OpenAIKit

class ImageGenerator {
    let openAI = OpenAIManager.shared.client
    
    func generateImage(prompt: String) async throws -> URL {
        guard let openAI = openAI else {
            throw OpenAIError.missingAPIKey
        }
        
        let request = ImageGenerationRequest(
            prompt: prompt,
            model: "dall-e-3",
            n: 1,
            quality: .standard,
            responseFormat: .url,
            size: .size1024x1024,
            style: .natural,
            user: nil
        )
        
        let response = try await openAI.images.generations(request)
        
        guard let imageData = response.data.first,
              let urlString = imageData.url,
              let url = URL(string: urlString) else {
            throw ImageError.noImageGenerated
        }
        
        return url
    }
}

enum ImageError: LocalizedError {
    case noImageGenerated
    
    var errorDescription: String? {
        switch self {
        case .noImageGenerated:
            return "No image was generated"
        }
    }
}
EOF

cat > "image-05-download.swift" << 'EOF'
// ImageGeneration.swift - Downloading generated images
import Foundation
import OpenAIKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

class ImageGenerator {
    let openAI = OpenAIManager.shared.client
    
    func generateImage(prompt: String) async throws -> URL {
        guard let openAI = openAI else {
            throw OpenAIError.missingAPIKey
        }
        
        let request = ImageGenerationRequest(
            prompt: prompt,
            model: "dall-e-3",
            n: 1,
            quality: .standard,
            responseFormat: .url,
            size: .size1024x1024,
            style: .natural,
            user: nil
        )
        
        let response = try await openAI.images.generations(request)
        
        guard let imageData = response.data.first,
              let urlString = imageData.url,
              let url = URL(string: urlString) else {
            throw ImageError.noImageGenerated
        }
        
        return url
    }
    
    func downloadImage(from url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ImageError.downloadFailed
        }
        
        return data
    }
    
    #if canImport(UIKit)
    func generateAndDownloadImage(prompt: String) async throws -> UIImage {
        let url = try await generateImage(prompt: prompt)
        let data = try await downloadImage(from: url)
        
        guard let image = UIImage(data: data) else {
            throw ImageError.invalidImageData
        }
        
        return image
    }
    #elseif canImport(AppKit)
    func generateAndDownloadImage(prompt: String) async throws -> NSImage {
        let url = try await generateImage(prompt: prompt)
        let data = try await downloadImage(from: url)
        
        guard let image = NSImage(data: data) else {
            throw ImageError.invalidImageData
        }
        
        return image
    }
    #endif
}

extension ImageError {
    case downloadFailed
    case invalidImageData
}
EOF

# Tutorial 8: Transcribing Audio
cat > "audio-01-empty.swift" << 'EOF'
// AudioTranscriber.swift
EOF

cat > "audio-02-imports.swift" << 'EOF'
// AudioTranscriber.swift
import Foundation
import OpenAIKit
import AVFoundation
EOF

cat > "audio-03-function.swift" << 'EOF'
// AudioTranscriber.swift
import Foundation
import OpenAIKit
import AVFoundation

class AudioTranscriber {
    let openAI = OpenAIManager.shared.client
    
    func transcribe(audioFileURL: URL) async throws -> String {
        // Implementation here
        return ""
    }
}
EOF

cat > "audio-04-request.swift" << 'EOF'
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
                contentType: "audio/mpeg"
            ),
            model: "whisper-1",
            language: nil,
            prompt: nil,
            responseFormat: .json,
            temperature: nil,
            timestampGranularities: nil
        )
        
        // Send request next
        return ""
    }
}
EOF

cat > "audio-05-response.swift" << 'EOF'
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
EOF

# Tutorial 9: Building Semantic Search
cat > "embeddings-01-empty.swift" << 'EOF'
// EmbeddingGenerator.swift
EOF

cat > "embeddings-02-function.swift" << 'EOF'
// EmbeddingGenerator.swift
import Foundation
import OpenAIKit

class EmbeddingGenerator {
    let openAI = OpenAIManager.shared.client
    
    func generateEmbedding(for text: String) async throws -> [Float] {
        // Implementation here
        return []
    }
}
EOF

cat > "embeddings-03-request.swift" << 'EOF'
// EmbeddingGenerator.swift
import Foundation
import OpenAIKit

class EmbeddingGenerator {
    let openAI = OpenAIManager.shared.client
    
    func generateEmbedding(for text: String) async throws -> [Float] {
        guard let openAI = openAI else {
            throw OpenAIError.missingAPIKey
        }
        
        let request = EmbeddingRequest(
            input: text,
            model: "text-embedding-3-small",
            dimensions: nil,
            encodingFormat: .float,
            user: nil
        )
        
        // Send request next
        return []
    }
}
EOF

cat > "embeddings-04-response.swift" << 'EOF'
// EmbeddingGenerator.swift
import Foundation
import OpenAIKit

class EmbeddingGenerator {
    let openAI = OpenAIManager.shared.client
    
    func generateEmbedding(for text: String) async throws -> [Float] {
        guard let openAI = openAI else {
            throw OpenAIError.missingAPIKey
        }
        
        let request = EmbeddingRequest(
            input: text,
            model: "text-embedding-3-small",
            dimensions: nil,
            encodingFormat: .float,
            user: nil
        )
        
        let response = try await openAI.embeddings.create(request)
        
        guard let embedding = response.data.first?.embedding,
              let floatValues = embedding.floatValues else {
            throw EmbeddingError.noEmbeddingGenerated
        }
        
        return floatValues
    }
}

enum EmbeddingError: LocalizedError {
    case noEmbeddingGenerated
    
    var errorDescription: String? {
        switch self {
        case .noEmbeddingGenerated:
            return "No embedding was generated"
        }
    }
}
EOF

cat > "embeddings-05-batch.swift" << 'EOF'
// EmbeddingGenerator.swift - Batch processing
import Foundation
import OpenAIKit

class EmbeddingGenerator {
    let openAI = OpenAIManager.shared.client
    private let maxBatchSize = 100
    
    func generateEmbedding(for text: String) async throws -> [Float] {
        guard let openAI = openAI else {
            throw OpenAIError.missingAPIKey
        }
        
        let request = EmbeddingRequest(
            input: text,
            model: "text-embedding-3-small",
            dimensions: nil,
            encodingFormat: .float,
            user: nil
        )
        
        let response = try await openAI.embeddings.create(request)
        
        guard let embedding = response.data.first?.embedding,
              let floatValues = embedding.floatValues else {
            throw EmbeddingError.noEmbeddingGenerated
        }
        
        return floatValues
    }
    
    func generateEmbeddings(for texts: [String]) async throws -> [[Float]] {
        guard let openAI = openAI else {
            throw OpenAIError.missingAPIKey
        }
        
        var allEmbeddings: [[Float]] = []
        
        // Process in batches
        for chunk in texts.chunked(into: maxBatchSize) {
            let request = EmbeddingRequest(
                input: chunk,
                model: "text-embedding-3-small",
                dimensions: nil,
                encodingFormat: .float,
                user: nil
            )
            
            let response = try await openAI.embeddings.create(request)
            
            let embeddings = response.data.compactMap { data -> [Float]? in
                guard let embedding = data.embedding,
                      let floatValues = embedding.floatValues else {
                    return nil
                }
                return floatValues
            }
            
            allEmbeddings.append(contentsOf: embeddings)
        }
        
        return allEmbeddings
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
EOF

# Create remaining tutorial files for advanced sections
echo "Created core tutorial files. Creating additional UI and advanced files..."

# More files for streaming UI
cat > "ui-01-viewmodel.swift" << 'EOF'
// StreamingViewModel.swift
import Foundation
import OpenAIKit
import SwiftUI

@MainActor
class StreamingViewModel: ObservableObject {
    @Published var messages: [StreamMessage] = []
    @Published var currentStreamText = ""
    @Published var isStreaming = false
    
    private let openAI = OpenAIManager.shared.client
    private var streamTask: Task<Void, Never>?
    
    struct StreamMessage: Identifiable {
        let id = UUID()
        let role: ChatRole
        let content: String
        let timestamp = Date()
        var isComplete = true
    }
}
EOF

cat > "ui-02-property.swift" << 'EOF'
// StreamingViewModel.swift - Property wrapper for streaming
import Foundation
import OpenAIKit
import SwiftUI

@MainActor
class StreamingViewModel: ObservableObject {
    @Published var messages: [StreamMessage] = []
    @Published var currentStreamText = ""
    @Published var isStreaming = false
    @Published var error: Error?
    
    private let openAI = OpenAIManager.shared.client
    private var streamTask: Task<Void, Never>?
    
    struct StreamMessage: Identifiable {
        let id = UUID()
        let role: ChatRole
        var content: String
        let timestamp = Date()
        var isComplete = true
    }
    
    func sendMessage(_ text: String) {
        // Add user message
        messages.append(StreamMessage(
            role: .user,
            content: text,
            isComplete: true
        ))
        
        // Start streaming response
        streamResponse(for: text)
    }
    
    private func streamResponse(for prompt: String) {
        streamTask?.cancel()
        currentStreamText = ""
        isStreaming = true
        error = nil
        
        // Add placeholder for assistant message
        let assistantMessage = StreamMessage(
            role: .assistant,
            content: "",
            isComplete: false
        )
        messages.append(assistantMessage)
        
        streamTask = Task {
            // Implementation next
        }
    }
}
EOF

# Create more tutorial files as needed...
echo "Tutorial code files generation completed!"