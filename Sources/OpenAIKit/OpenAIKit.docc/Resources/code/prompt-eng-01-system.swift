// PromptEngineering.swift
import Foundation
import OpenAIKit

/// Advanced prompt engineering system with model-specific optimizations
class PromptEngineeringSystem {
    
    private let promptTemplates = PromptTemplateLibrary()
    private let promptValidator = PromptValidator()
    private let promptOptimizer = PromptOptimizer()
    
    /// Enhance a basic prompt with model-specific optimizations
    func enhancePrompt(
        _ basicPrompt: String,
        for model: String,
        options: PromptOptions = PromptOptions()
    ) -> EnhancedPrompt {
        
        // Validate the basic prompt
        let validation = promptValidator.validate(basicPrompt)
        guard validation.isValid else {
            return EnhancedPrompt(
                original: basicPrompt,
                enhanced: basicPrompt,
                model: model,
                issues: validation.issues,
                confidence: 0.0
            )
        }
        
        // Analyze prompt intent
        let analysis = analyzePrompt(basicPrompt)
        
        // Apply model-specific enhancements
        let enhanced = applyModelEnhancements(
            prompt: basicPrompt,
            model: model,
            analysis: analysis,
            options: options
        )
        
        // Optimize for the specific model
        let optimized = promptOptimizer.optimize(
            enhanced,
            for: model,
            targetLength: options.targetLength
        )
        
        // Calculate confidence score
        let confidence = calculateConfidence(
            original: basicPrompt,
            enhanced: optimized,
            model: model
        )
        
        return EnhancedPrompt(
            original: basicPrompt,
            enhanced: optimized,
            model: model,
            additions: extractAdditions(original: basicPrompt, enhanced: optimized),
            modifications: extractModifications(original: basicPrompt, enhanced: optimized),
            confidence: confidence
        )
    }
    
    /// Analyze prompt to understand intent and structure
    private func analyzePrompt(_ prompt: String) -> PromptAnalysis {
        let components = PromptComponents()
        let words = prompt.split(separator: " ").map(String.init)
        
        // Extract subject
        components.subject = extractSubject(from: words)
        
        // Extract descriptors
        components.descriptors = extractDescriptors(from: prompt)
        
        // Extract style hints
        components.styleHints = extractStyleHints(from: prompt)
        
        // Extract technical requirements
        components.technicalRequirements = extractTechnicalRequirements(from: prompt)
        
        // Determine primary intent
        let intent = determineIntent(from: components)
        
        // Calculate complexity
        let complexity = calculateComplexity(prompt: prompt, components: components)
        
        return PromptAnalysis(
            components: components,
            intent: intent,
            complexity: complexity,
            potentialIssues: identifyPotentialIssues(prompt)
        )
    }
    
    /// Apply model-specific enhancements
    private func applyModelEnhancements(
        prompt: String,
        model: String,
        analysis: PromptAnalysis,
        options: PromptOptions
    ) -> String {
        
        var enhancedComponents: [String] = []
        
        // Start with the core subject
        if let subject = analysis.components.subject {
            enhancedComponents.append(subject)
        }
        
        // Add model-specific enhancements
        switch model {
        case Models.Images.dallE2:
            // DALL-E 2 benefits from clear, simple descriptions
            enhancedComponents.append(contentsOf: [
                "digital art",
                "highly detailed",
                "trending on artstation"
            ])
            
        case Models.Images.dallE3:
            // DALL-E 3 understands complex prompts better
            if options.style != .photorealistic {
                enhancedComponents.append(contentsOf: analysis.components.descriptors)
            }
            enhancedComponents.append(contentsOf: [
                "high quality",
                "professional",
                options.style.descriptor
            ])
            
        case Models.Images.gptImage1:
            // gpt-image-1 excels at photorealistic and technical accuracy
            enhancedComponents.append(contentsOf: [
                "photorealistic",
                "professional photography",
                "sharp focus",
                "high resolution"
            ])
            if options.includeTechnicalDetails {
                enhancedComponents.append(contentsOf: [
                    "f/1.4",
                    "85mm lens",
                    "natural lighting"
                ])
            }
            
        default:
            break
        }
        
        // Add style-specific enhancements
        enhancedComponents.append(contentsOf: options.style.additionalDescriptors)
        
        // Add composition hints if specified
        if let composition = options.composition {
            enhancedComponents.append(composition.descriptor)
        }
        
        // Add lighting if specified
        if let lighting = options.lighting {
            enhancedComponents.append(lighting.descriptor)
        }
        
        // Add mood/atmosphere
        if let mood = options.mood {
            enhancedComponents.append(contentsOf: mood.descriptors)
        }
        
        // Remove duplicates and join
        let unique = Array(Set(enhancedComponents))
        return unique.joined(separator: ", ")
    }
    
    // Helper methods
    
    private func extractSubject(from words: [String]) -> String? {
        // Look for noun phrases after articles
        for (index, word) in words.enumerated() {
            if ["a", "an", "the"].contains(word.lowercased()) && index < words.count - 1 {
                // Get next 2-3 words as potential subject
                let endIndex = min(index + 4, words.count)
                return words[index + 1..<endIndex].joined(separator: " ")
            }
        }
        
        // Fallback: use first few words
        return words.prefix(3).joined(separator: " ")
    }
    
    private func extractDescriptors(from prompt: String) -> [String] {
        let descriptorPatterns = [
            "beautiful", "stunning", "amazing", "detailed", "intricate",
            "colorful", "vibrant", "dramatic", "ethereal", "mystical"
        ]
        
        return descriptorPatterns.filter { prompt.lowercased().contains($0) }
    }
    
    private func extractStyleHints(from prompt: String) -> [String] {
        let stylePatterns = [
            "realistic", "cartoon", "anime", "abstract", "minimalist",
            "vintage", "retro", "modern", "futuristic", "fantasy"
        ]
        
        return stylePatterns.filter { prompt.lowercased().contains($0) }
    }
    
    private func extractTechnicalRequirements(from prompt: String) -> [String] {
        var requirements: [String] = []
        
        if prompt.lowercased().contains("transparent") {
            requirements.append("transparent background")
        }
        if prompt.lowercased().contains("high res") || prompt.lowercased().contains("4k") {
            requirements.append("high resolution")
        }
        if prompt.lowercased().contains("detailed") {
            requirements.append("highly detailed")
        }
        
        return requirements
    }
    
    private func determineIntent(from components: PromptComponents) -> PromptIntent {
        if components.technicalRequirements.contains("transparent background") {
            return .productImage
        } else if components.styleHints.contains("realistic") {
            return .photorealistic
        } else if components.styleHints.contains(where: { ["cartoon", "anime"].contains($0) }) {
            return .illustration
        } else if components.styleHints.contains("abstract") {
            return .artisticExpression
        }
        
        return .general
    }
    
    private func calculateComplexity(prompt: String, components: PromptComponents) -> PromptComplexity {
        let wordCount = prompt.split(separator: " ").count
        let descriptorCount = components.descriptors.count
        let requirementCount = components.technicalRequirements.count
        
        let score = wordCount + descriptorCount * 2 + requirementCount * 3
        
        if score < 10 {
            return .simple
        } else if score < 20 {
            return .moderate
        } else {
            return .complex
        }
    }
    
    private func identifyPotentialIssues(_ prompt: String) -> [String] {
        var issues: [String] = []
        
        if prompt.count < 10 {
            issues.append("Prompt may be too short")
        }
        if prompt.count > 500 {
            issues.append("Prompt may be too long")
        }
        if prompt.filter({ $0 == "," }).count > 10 {
            issues.append("Too many descriptors may confuse the model")
        }
        
        return issues
    }
    
    private func calculateConfidence(original: String, enhanced: String, model: String) -> Double {
        // Simple confidence calculation based on enhancement quality
        let originalWords = Set(original.split(separator: " ").map(String.init))
        let enhancedWords = Set(enhanced.split(separator: " ").map(String.init))
        
        let preserved = originalWords.intersection(enhancedWords).count
        let added = enhancedWords.subtracting(originalWords).count
        
        let preservationScore = Double(preserved) / Double(originalWords.count)
        let enhancementScore = min(Double(added) / 10.0, 1.0)
        
        return (preservationScore * 0.7 + enhancementScore * 0.3) * 100
    }
    
    private func extractAdditions(original: String, enhanced: String) -> [String] {
        let originalWords = Set(original.split(separator: " ").map(String.init))
        let enhancedWords = Set(enhanced.split(separator: " ").map(String.init))
        
        return Array(enhancedWords.subtracting(originalWords))
    }
    
    private func extractModifications(original: String, enhanced: String) -> [String] {
        // Simplified - in production, use more sophisticated diff algorithm
        return []
    }
}

/// Prompt components breakdown
class PromptComponents {
    var subject: String?
    var descriptors: [String] = []
    var styleHints: [String] = []
    var technicalRequirements: [String] = []
}

/// Prompt analysis results
struct PromptAnalysis {
    let components: PromptComponents
    let intent: PromptIntent
    let complexity: PromptComplexity
    let potentialIssues: [String]
}

/// Prompt intent categories
enum PromptIntent {
    case general
    case photorealistic
    case illustration
    case productImage
    case artisticExpression
    case technical
}

/// Prompt complexity levels
enum PromptComplexity {
    case simple
    case moderate
    case complex
}

/// Enhanced prompt result
struct EnhancedPrompt {
    let original: String
    let enhanced: String
    let model: String
    var additions: [String] = []
    var modifications: [String] = []
    var issues: [String] = []
    let confidence: Double
    
    var summary: String {
        """
        Original: \(original)
        Enhanced: \(enhanced)
        Model: \(model)
        Confidence: \(String(format: "%.1f%%", confidence))
        Additions: \(additions.joined(separator: ", "))
        """
    }
}