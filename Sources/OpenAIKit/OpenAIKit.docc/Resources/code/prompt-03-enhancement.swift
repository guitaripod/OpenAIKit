import OpenAIKit

// MARK: - Prompt Enhancement

class PromptEnhancer {
    private let qualityModifiers = [
        "highly detailed",
        "professional quality",
        "award-winning",
        "masterpiece"
    ]
    
    private let lightingOptions = [
        "golden hour lighting",
        "dramatic lighting",
        "soft natural light",
        "studio lighting"
    ]
    
    func enhance(_ basePrompt: String, quality: Bool = true, lighting: Bool = false) -> String {
        var enhanced = basePrompt
        
        if quality {
            let modifier = qualityModifiers.randomElement() ?? ""
            enhanced += ", \(modifier)"
        }
        
        if lighting {
            let light = lightingOptions.randomElement() ?? ""
            enhanced += ", \(light)"
        }
        
        return enhanced
    }
    
    func addArtStyle(_ prompt: String, style: String) -> String {
        "\(prompt), in the style of \(style)"
    }
    
    func addNegativePrompt(_ prompt: String, avoid: [String]) -> (prompt: String, negative: String) {
        let negativePrompt = avoid.joined(separator: ", ")
        return (prompt, negativePrompt)
    }
}

// Usage example
let enhancer = PromptEnhancer()
let enhanced = enhancer.enhance("A serene lake at dawn", quality: true, lighting: true)
let styled = enhancer.addArtStyle(enhanced, style: "Claude Monet")