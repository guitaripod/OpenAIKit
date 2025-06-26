// PromptEngineering.swift - Style Modifiers
import Foundation
import OpenAIKit

/// Style modifier system for artistic control
extension PromptEngineeringSystem {
    
    /// Apply style modifiers to enhance artistic direction
    func applyStyleModifiers(
        to prompt: String,
        style: ArtisticStyle,
        intensity: StyleIntensity = .medium
    ) -> StyledPrompt {
        
        var modifiers: [String] = []
        
        // Base style descriptors
        modifiers.append(contentsOf: style.baseDescriptors)
        
        // Add intensity-specific modifiers
        modifiers.append(contentsOf: intensity.modifiers(for: style))
        
        // Add technical style elements
        if let technical = style.technicalElements {
            modifiers.append(contentsOf: technical)
        }
        
        // Add color palette if specified
        if let palette = style.colorPalette {
            modifiers.append(contentsOf: palette.descriptors)
        }
        
        // Construct the styled prompt
        let styledPrompt = constructStyledPrompt(
            base: prompt,
            modifiers: modifiers,
            style: style
        )
        
        return StyledPrompt(
            original: prompt,
            styled: styledPrompt,
            style: style,
            intensity: intensity,
            appliedModifiers: modifiers
        )
    }
    
    /// Construct styled prompt with proper formatting
    private func constructStyledPrompt(
        base: String,
        modifiers: [String],
        style: ArtisticStyle
    ) -> String {
        
        switch style.applicationMethod {
        case .prefix:
            return "\(modifiers.joined(separator: ", ")), \(base)"
            
        case .suffix:
            return "\(base), \(modifiers.joined(separator: ", "))"
            
        case .wrap:
            let prefix = modifiers.prefix(modifiers.count / 2)
            let suffix = modifiers.suffix(modifiers.count / 2)
            return "\(prefix.joined(separator: ", ")), \(base), \(suffix.joined(separator: ", "))"
            
        case .integrated:
            // Intelligently integrate modifiers into the prompt
            return integrateModifiers(into: base, modifiers: modifiers)
        }
    }
    
    /// Intelligently integrate modifiers into prompt
    private func integrateModifiers(into base: String, modifiers: [String]) -> String {
        var result = base
        
        // Group modifiers by type
        let colorModifiers = modifiers.filter { isColorModifier($0) }
        let lightingModifiers = modifiers.filter { isLightingModifier($0) }
        let styleModifiers = modifiers.filter { !isColorModifier($0) && !isLightingModifier($0) }
        
        // Insert at appropriate positions
        if !styleModifiers.isEmpty {
            result = "\(styleModifiers.joined(separator: " ")) \(result)"
        }
        
        if !colorModifiers.isEmpty {
            result = "\(result) with \(colorModifiers.joined(separator: " and "))"
        }
        
        if !lightingModifiers.isEmpty {
            result = "\(result), \(lightingModifiers.joined(separator: ", "))"
        }
        
        return result
    }
    
    private func isColorModifier(_ modifier: String) -> Bool {
        let colorKeywords = ["color", "palette", "tone", "hue", "saturation", "vibrant", "muted"]
        return colorKeywords.contains { modifier.lowercased().contains($0) }
    }
    
    private func isLightingModifier(_ modifier: String) -> Bool {
        let lightingKeywords = ["lighting", "light", "shadow", "illuminated", "backlit", "rim light"]
        return lightingKeywords.contains { modifier.lowercased().contains($0) }
    }
}

/// Artistic styles with comprehensive descriptors
enum ArtisticStyle {
    case photorealistic
    case oilPainting
    case watercolor
    case digitalArt
    case anime
    case cartoon
    case minimalist
    case surrealist
    case impressionist
    case cyberpunk
    case steampunk
    case fantasy
    case noir
    case retrowave
    case custom(descriptors: [String])
    
    var baseDescriptors: [String] {
        switch self {
        case .photorealistic:
            return ["photorealistic", "hyperrealistic", "lifelike", "detailed"]
            
        case .oilPainting:
            return ["oil painting", "brushstrokes visible", "canvas texture", "traditional art"]
            
        case .watercolor:
            return ["watercolor painting", "soft edges", "translucent", "paper texture"]
            
        case .digitalArt:
            return ["digital art", "digital painting", "concept art", "highly detailed"]
            
        case .anime:
            return ["anime style", "manga art", "cel shaded", "Japanese animation"]
            
        case .cartoon:
            return ["cartoon style", "animated", "colorful", "simplified forms"]
            
        case .minimalist:
            return ["minimalist", "simple", "clean lines", "negative space"]
            
        case .surrealist:
            return ["surrealist", "dreamlike", "impossible geometry", "Salvador Dali inspired"]
            
        case .impressionist:
            return ["impressionist", "loose brushwork", "light and color", "Monet inspired"]
            
        case .cyberpunk:
            return ["cyberpunk", "neon lights", "futuristic", "high tech low life"]
            
        case .steampunk:
            return ["steampunk", "Victorian era", "brass and copper", "mechanical gears"]
            
        case .fantasy:
            return ["fantasy art", "magical", "ethereal", "otherworldly"]
            
        case .noir:
            return ["film noir", "high contrast", "dramatic shadows", "monochromatic"]
            
        case .retrowave:
            return ["retrowave", "80s aesthetic", "neon colors", "synthwave", "Miami Vice"]
            
        case .custom(let descriptors):
            return descriptors
        }
    }
    
    var technicalElements: [String]? {
        switch self {
        case .photorealistic:
            return ["8K resolution", "ray tracing", "depth of field", "subsurface scattering"]
            
        case .oilPainting:
            return ["impasto technique", "glazing", "alla prima", "chiaroscuro"]
            
        case .watercolor:
            return ["wet on wet", "color bleeding", "granulation", "lifting technique"]
            
        case .digitalArt:
            return ["digital brushes", "layers", "blend modes", "color grading"]
            
        case .anime:
            return ["clean line art", "flat colors", "speed lines", "chibi proportions"]
            
        case .cyberpunk:
            return ["holographic displays", "circuit patterns", "glitch effects", "chrome reflections"]
            
        default:
            return nil
        }
    }
    
    var colorPalette: ColorPalette? {
        switch self {
        case .watercolor:
            return .soft
            
        case .cyberpunk:
            return .neon
            
        case .noir:
            return .monochrome
            
        case .retrowave:
            return .vaporwave
            
        case .fantasy:
            return .mystical
            
        default:
            return nil
        }
    }
    
    var applicationMethod: ApplicationMethod {
        switch self {
        case .photorealistic, .digitalArt:
            return .suffix
            
        case .minimalist:
            return .integrated
            
        default:
            return .prefix
        }
    }
}

/// Style intensity levels
enum StyleIntensity {
    case subtle
    case medium
    case strong
    case extreme
    
    func modifiers(for style: ArtisticStyle) -> [String] {
        switch (self, style) {
        case (.subtle, _):
            return ["subtle", "hint of", "touch of"]
            
        case (.medium, _):
            return ["clearly", "defined", "noticeable"]
            
        case (.strong, _):
            return ["highly", "very", "extremely", "bold"]
            
        case (.extreme, .photorealistic):
            return ["ultra-photorealistic", "indistinguishable from reality", "perfect detail"]
            
        case (.extreme, .anime):
            return ["pure anime aesthetic", "100% anime style", "full manga treatment"]
            
        case (.extreme, _):
            return ["maximum", "pure", "completely", "absolutely"]
        }
    }
}

/// Color palettes for style enhancement
enum ColorPalette {
    case vibrant
    case muted
    case monochrome
    case pastel
    case earth
    case neon
    case vaporwave
    case soft
    case mystical
    
    var descriptors: [String] {
        switch self {
        case .vibrant:
            return ["vibrant colors", "high saturation", "bold color choices"]
            
        case .muted:
            return ["muted colors", "desaturated", "subtle tones"]
            
        case .monochrome:
            return ["black and white", "grayscale", "monochromatic"]
            
        case .pastel:
            return ["pastel colors", "soft hues", "gentle tones"]
            
        case .earth:
            return ["earth tones", "natural colors", "browns and greens"]
            
        case .neon:
            return ["neon colors", "fluorescent", "electric blue and pink"]
            
        case .vaporwave:
            return ["vaporwave palette", "pink and purple", "teal accents"]
            
        case .soft:
            return ["soft colors", "gentle gradients", "harmonious palette"]
            
        case .mystical:
            return ["mystical colors", "purple and gold", "ethereal glow"]
        }
    }
}

/// How to apply style modifiers
enum ApplicationMethod {
    case prefix    // Add before main prompt
    case suffix    // Add after main prompt
    case wrap      // Split and wrap around prompt
    case integrated // Intelligently integrate
}

/// Styled prompt result
struct StyledPrompt {
    let original: String
    let styled: String
    let style: ArtisticStyle
    let intensity: StyleIntensity
    let appliedModifiers: [String]
    
    var description: String {
        """
        Style: \(String(describing: style))
        Intensity: \(String(describing: intensity))
        Applied: \(appliedModifiers.joined(separator: ", "))
        Result: \(styled)
        """
    }
}