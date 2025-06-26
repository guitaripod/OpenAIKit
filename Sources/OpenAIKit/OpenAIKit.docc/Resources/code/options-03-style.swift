// ImageStyleOptions.swift
import Foundation
import OpenAIKit

class ImageStyleManager {
    func applyStyle(_ style: ImageStyle, to prompt: String) -> String {
        switch style {
        case .natural:
            return prompt
        case .vivid:
            return "\(prompt), vivid colors, high contrast, dramatic lighting"
        }
    }
    
    func enhancePrompt(_ prompt: String, with modifiers: [String]) -> String {
        let enhancedPrompt = ([prompt] + modifiers).joined(separator: ", ")
        return enhancedPrompt
    }
    
    func suggestModifiers(for category: ImageCategory) -> [String] {
        switch category {
        case .portrait:
            return ["professional lighting", "sharp focus", "detailed"]
        case .landscape:
            return ["wide angle", "cinematic", "high resolution"]
        case .abstract:
            return ["geometric", "modern", "vibrant colors"]
        case .illustration:
            return ["digital art", "stylized", "clean lines"]
        }
    }
}

enum ImageCategory {
    case portrait
    case landscape
    case abstract
    case illustration
}
