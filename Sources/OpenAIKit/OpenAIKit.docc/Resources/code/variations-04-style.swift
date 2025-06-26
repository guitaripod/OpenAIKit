import OpenAIKit
import UIKit
import CoreImage

// MARK: - Style Transfer for Variations

class StyleVariationGenerator {
    let openAI: OpenAIKit
    private let imageProcessor = ImageProcessor()
    
    init(apiKey: String) {
        self.openAI = OpenAIKit(apiKey: apiKey)
    }
    
    // Generate variations with different artistic styles
    func generateStyledVariations(
        from originalImage: UIImage,
        styles: [ArtisticStyle]
    ) async throws -> [StyledVariation] {
        var styledVariations: [StyledVariation] = []
        
        // First, get base variations
        guard let imageData = originalImage.pngData() else {
            throw ImageError.invalidImageData
        }
        
        let baseRequest = ImageVariationRequest(
            image: imageData,
            n: styles.count,
            size: .size1024x1024
        )
        
        let response = try await openAI.createImageVariation(request: baseRequest)
        
        // Then apply style descriptions to each variation
        for (index, style) in styles.enumerated() {
            if index < response.data.count,
               case .url(let urlString) = response.data[index],
               let url = URL(string: urlString) {
                
                let variation = StyledVariation(
                    id: UUID(),
                    url: url,
                    style: style,
                    originalPrompt: nil,
                    timestamp: Date()
                )
                
                styledVariations.append(variation)
            }
        }
        
        return styledVariations
    }
    
    // Generate variations with edit instructions
    func generateEditedVariations(
        from originalImage: UIImage,
        editInstructions: [String]
    ) async throws -> [EditedVariation] {
        var editedVariations: [EditedVariation] = []
        
        // Process each edit instruction
        for instruction in editInstructions {
            guard let imageData = originalImage.pngData() else {
                continue
            }
            
            // Create edit request (using variations as a proxy)
            let request = ImageVariationRequest(
                image: imageData,
                n: 1,
                size: .size1024x1024
            )
            
            do {
                let response = try await openAI.createImageVariation(request: request)
                
                if case .url(let urlString) = response.data.first,
                   let url = URL(string: urlString) {
                    
                    let variation = EditedVariation(
                        id: UUID(),
                        url: url,
                        editInstruction: instruction,
                        timestamp: Date()
                    )
                    
                    editedVariations.append(variation)
                }
            } catch {
                print("Failed to create variation for instruction '\(instruction)': \(error)")
            }
            
            // Rate limiting
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        return editedVariations
    }
}

// MARK: - Artistic Styles

enum ArtisticStyle: String, CaseIterable {
    case impressionist = "Impressionist"
    case cubist = "Cubist"
    case surrealist = "Surrealist"
    case minimalist = "Minimalist"
    case abstract = "Abstract"
    case photorealistic = "Photorealistic"
    case watercolor = "Watercolor"
    case oilPainting = "Oil Painting"
    case pencilSketch = "Pencil Sketch"
    case digitalArt = "Digital Art"
    
    var description: String {
        switch self {
        case .impressionist:
            return "Soft brushstrokes, emphasis on light and color"
        case .cubist:
            return "Geometric shapes, multiple perspectives"
        case .surrealist:
            return "Dreamlike, unexpected juxtapositions"
        case .minimalist:
            return "Simple forms, limited color palette"
        case .abstract:
            return "Non-representational, focus on form and color"
        case .photorealistic:
            return "Highly detailed, lifelike appearance"
        case .watercolor:
            return "Fluid, translucent colors"
        case .oilPainting:
            return "Rich textures, bold colors"
        case .pencilSketch:
            return "Black and white, detailed line work"
        case .digitalArt:
            return "Modern, crisp digital aesthetic"
        }
    }
    
    var colorProfile: ColorProfile {
        switch self {
        case .impressionist:
            return .vibrant
        case .cubist:
            return .muted
        case .surrealist:
            return .dreamlike
        case .minimalist:
            return .monochrome
        case .abstract:
            return .bold
        case .photorealistic:
            return .natural
        case .watercolor:
            return .soft
        case .oilPainting:
            return .rich
        case .pencilSketch:
            return .grayscale
        case .digitalArt:
            return .neon
        }
    }
}

// MARK: - Color Profiles

enum ColorProfile {
    case vibrant
    case muted
    case dreamlike
    case monochrome
    case bold
    case natural
    case soft
    case rich
    case grayscale
    case neon
    
    var adjustments: (brightness: Float, contrast: Float, saturation: Float) {
        switch self {
        case .vibrant:
            return (0.1, 1.2, 1.5)
        case .muted:
            return (-0.1, 0.8, 0.5)
        case .dreamlike:
            return (0.2, 0.9, 1.1)
        case .monochrome:
            return (0, 1.1, 0)
        case .bold:
            return (0, 1.3, 1.3)
        case .natural:
            return (0, 1.0, 1.0)
        case .soft:
            return (0.1, 0.9, 0.8)
        case .rich:
            return (-0.1, 1.2, 1.2)
        case .grayscale:
            return (0, 1.0, 0)
        case .neon:
            return (0.2, 1.4, 1.6)
        }
    }
}

// MARK: - Models

struct StyledVariation: Identifiable {
    let id: UUID
    let url: URL
    let style: ArtisticStyle
    let originalPrompt: String?
    let timestamp: Date
}

struct EditedVariation: Identifiable {
    let id: UUID
    let url: URL
    let editInstruction: String
    let timestamp: Date
}

// MARK: - Style Preset Manager

class StylePresetManager {
    static let shared = StylePresetManager()
    
    private let userDefaults = UserDefaults.standard
    private let presetsKey = "stylePresets"
    
    struct StylePreset: Codable, Identifiable {
        let id: UUID
        let name: String
        let styles: [String]  // ArtisticStyle raw values
        let isFavorite: Bool
        let createdAt: Date
    }
    
    func savePreset(name: String, styles: [ArtisticStyle]) {
        var presets = loadPresets()
        
        let preset = StylePreset(
            id: UUID(),
            name: name,
            styles: styles.map { $0.rawValue },
            isFavorite: false,
            createdAt: Date()
        )
        
        presets.append(preset)
        
        if let encoded = try? JSONEncoder().encode(presets) {
            userDefaults.set(encoded, forKey: presetsKey)
        }
    }
    
    func loadPresets() -> [StylePreset] {
        guard let data = userDefaults.data(forKey: presetsKey),
              let presets = try? JSONDecoder().decode([StylePreset].self, from: data) else {
            return defaultPresets()
        }
        return presets
    }
    
    private func defaultPresets() -> [StylePreset] {
        [
            StylePreset(
                id: UUID(),
                name: "Classic Art",
                styles: [ArtisticStyle.impressionist.rawValue, .oilPainting.rawValue],
                isFavorite: true,
                createdAt: Date()
            ),
            StylePreset(
                id: UUID(),
                name: "Modern Digital",
                styles: [ArtisticStyle.digitalArt.rawValue, .abstract.rawValue],
                isFavorite: false,
                createdAt: Date()
            )
        ]
    }
}