// ImageApp.swift - Professional Architecture
import SwiftUI
import OpenAIKit
import Combine

/// Main app architecture with proper separation of concerns
@main
struct ImageGeneratorApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var imageService = ImageGenerationService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(imageService)
                .onAppear {
                    imageService.configure(with: appState.configuration)
                }
        }
    }
}

/// Centralized app state management
class AppState: ObservableObject {
    @Published var configuration = AppConfiguration()
    @Published var currentUser: User?
    @Published var navigationPath = NavigationPath()
    
    // Persistent storage
    private let userDefaults = UserDefaults.standard
    private let keychain = KeychainService()
    
    init() {
        loadConfiguration()
        loadUserSession()
    }
    
    private func loadConfiguration() {
        if let apiKey = keychain.retrieve(key: "openai_api_key") {
            configuration.apiKey = apiKey
        }
        
        configuration.preferredModel = userDefaults.string(forKey: "preferred_model") ?? Models.Images.dallE3
        configuration.defaultQuality = userDefaults.string(forKey: "default_quality") ?? "standard"
    }
    
    private func loadUserSession() {
        // Load user session from secure storage
    }
    
    func saveConfiguration() {
        if !configuration.apiKey.isEmpty {
            keychain.store(key: "openai_api_key", value: configuration.apiKey)
        }
        
        userDefaults.set(configuration.preferredModel, forKey: "preferred_model")
        userDefaults.set(configuration.defaultQuality, forKey: "default_quality")
    }
}

/// App configuration
struct AppConfiguration {
    var apiKey: String = ""
    var preferredModel: String = Models.Images.dallE3
    var defaultQuality: String = "standard"
    var defaultSize: String = "1024x1024"
    var enableAutoSave: Bool = true
    var enablePromptHistory: Bool = true
    var maxHistoryItems: Int = 100
}

/// Image generation service with clean architecture
class ImageGenerationService: ObservableObject {
    @Published var isGenerating = false
    @Published var currentProgress: GenerationProgress?
    @Published var generatedImages: [GeneratedImageModel] = []
    @Published var error: ImageGenerationError?
    
    private var openAI: OpenAIKit?
    private let imageStorage = ImageStorageService()
    private let promptHistory = PromptHistoryService()
    private let analytics = AnalyticsService()
    
    private var cancellables = Set<AnyCancellable>()
    private var currentTask: Task<Void, Never>?
    
    func configure(with configuration: AppConfiguration) {
        guard !configuration.apiKey.isEmpty else { return }
        self.openAI = OpenAIKit(apiKey: configuration.apiKey)
    }
    
    /// Generate image with comprehensive handling
    func generateImage(
        prompt: String,
        model: String,
        options: GenerationOptions
    ) {
        guard let openAI = openAI else {
            self.error = .invalidAPIKey
            return
        }
        
        // Cancel any existing generation
        currentTask?.cancel()
        
        currentTask = Task { @MainActor in
            self.isGenerating = true
            self.currentProgress = GenerationProgress(stage: .preparing)
            self.error = nil
            
            do {
                // Save to history
                await promptHistory.save(prompt)
                
                // Track analytics
                analytics.trackGenerationStarted(model: model)
                
                // Update progress
                self.currentProgress?.stage = .generating
                
                // Build request
                let request = buildRequest(
                    prompt: prompt,
                    model: model,
                    options: options
                )
                
                // Generate image
                let response = try await openAI.images.generations(request)
                
                // Process response
                self.currentProgress?.stage = .processing
                let processedImages = try await processResponse(
                    response,
                    model: model,
                    prompt: prompt
                )
                
                // Update UI
                self.generatedImages.append(contentsOf: processedImages)
                
                // Save if enabled
                if options.autoSave {
                    self.currentProgress?.stage = .saving
                    for image in processedImages {
                        try await imageStorage.save(image)
                    }
                }
                
                // Track success
                analytics.trackGenerationCompleted(
                    model: model,
                    count: processedImages.count
                )
                
            } catch {
                self.error = error as? ImageGenerationError ?? .networkError(underlying: error)
                analytics.trackGenerationFailed(error: error)
            }
            
            self.isGenerating = false
            self.currentProgress = nil
        }
    }
    
    /// Cancel current generation
    func cancelGeneration() {
        currentTask?.cancel()
        currentTask = nil
        isGenerating = false
        currentProgress = nil
    }
    
    private func buildRequest(
        prompt: String,
        model: String,
        options: GenerationOptions
    ) -> ImageGenerationRequest {
        
        ImageGenerationRequest(
            prompt: prompt,
            background: options.transparentBackground ? "transparent" : nil,
            model: model,
            n: options.count,
            outputCompression: options.compression,
            outputFormat: options.format,
            quality: options.quality,
            responseFormat: options.responseFormat,
            size: options.size,
            style: options.style
        )
    }
    
    private func processResponse(
        _ response: ImageResponse,
        model: String,
        prompt: String
    ) async throws -> [GeneratedImageModel] {
        
        var models: [GeneratedImageModel] = []
        
        for imageData in response.data {
            let imageModel = GeneratedImageModel(
                id: UUID(),
                prompt: prompt,
                revisedPrompt: imageData.revisedPrompt,
                model: model,
                imageData: imageData,
                metadata: ImageMetadata(
                    createdAt: Date(),
                    usage: response.usage,
                    size: extractSize(from: imageData)
                )
            )
            
            models.append(imageModel)
        }
        
        return models
    }
    
    private func extractSize(from imageData: ImageObject) -> CGSize {
        // Extract size from image data if possible
        return CGSize(width: 1024, height: 1024) // Default
    }
}

/// Image storage service
class ImageStorageService {
    private let documentsDirectory = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    ).first!
    
    func save(_ image: GeneratedImageModel) async throws {
        let imageDirectory = documentsDirectory.appendingPathComponent("GeneratedImages")
        try FileManager.default.createDirectory(
            at: imageDirectory,
            withIntermediateDirectories: true
        )
        
        let fileName = "\(image.id.uuidString).json"
        let fileURL = imageDirectory.appendingPathComponent(fileName)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(image)
        
        try data.write(to: fileURL)
    }
    
    func load() async throws -> [GeneratedImageModel] {
        let imageDirectory = documentsDirectory.appendingPathComponent("GeneratedImages")
        
        guard FileManager.default.fileExists(atPath: imageDirectory.path) else {
            return []
        }
        
        let files = try FileManager.default.contentsOfDirectory(
            at: imageDirectory,
            includingPropertiesForKeys: nil
        )
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try await withThrowingTaskGroup(of: GeneratedImageModel?.self) { group in
            for file in files where file.pathExtension == "json" {
                group.addTask {
                    let data = try Data(contentsOf: file)
                    return try decoder.decode(GeneratedImageModel.self, from: data)
                }
            }
            
            var images: [GeneratedImageModel] = []
            for try await image in group {
                if let image = image {
                    images.append(image)
                }
            }
            
            return images.sorted { $0.metadata.createdAt > $1.metadata.createdAt }
        }
    }
}

/// Models and supporting types
struct GeneratedImageModel: Identifiable, Codable {
    let id: UUID
    let prompt: String
    let revisedPrompt: String?
    let model: String
    let imageData: ImageObject
    let metadata: ImageMetadata
}

struct ImageMetadata: Codable {
    let createdAt: Date
    let usage: ImageUsage?
    let size: CGSize
}

struct GenerationOptions {
    var count: Int = 1
    var size: String = "1024x1024"
    var quality: String = "standard"
    var style: String? = nil
    var format: String = "png"
    var compression: Int? = nil
    var responseFormat: ImageResponseFormat = .url
    var transparentBackground: Bool = false
    var autoSave: Bool = true
}

struct GenerationProgress {
    enum Stage {
        case preparing
        case generating
        case processing
        case saving
        case complete
    }
    
    var stage: Stage
    var message: String {
        switch stage {
        case .preparing: return "Preparing your request..."
        case .generating: return "Generating image..."
        case .processing: return "Processing results..."
        case .saving: return "Saving image..."
        case .complete: return "Complete!"
        }
    }
}

struct User: Codable {
    let id: String
    let name: String
    let email: String
    let subscription: SubscriptionTier
}

enum SubscriptionTier: String, Codable {
    case free
    case pro
    case enterprise
}

// Services
class PromptHistoryService {
    private let maxItems = 100
    private var history: [String] = []
    
    func save(_ prompt: String) {
        history.insert(prompt, at: 0)
        if history.count > maxItems {
            history.removeLast()
        }
    }
    
    func getHistory() -> [String] {
        return history
    }
}

class AnalyticsService {
    func trackGenerationStarted(model: String) {
        // Track event
    }
    
    func trackGenerationCompleted(model: String, count: Int) {
        // Track event
    }
    
    func trackGenerationFailed(error: Error) {
        // Track event
    }
}

class KeychainService {
    func store(key: String, value: String) {
        // Store in keychain
    }
    
    func retrieve(key: String) -> String? {
        // Retrieve from keychain
        return nil
    }
}