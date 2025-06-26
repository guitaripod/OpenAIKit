// AdvancedFeatures.swift
import Foundation
import OpenAIKit

extension AdvancedImageGenerator {
    
    /// Advanced prompt interpretation and enhancement
    func generateWithInterpretation(
        userIntent: String,
        context: GenerationContext = GenerationContext()
    ) async throws -> InterpretedImageResult {
        
        // Analyze user intent
        let analysis = try await analyzeIntent(userIntent, context: context)
        
        // Build enhanced prompt using gpt-image-1's advanced understanding
        let enhancedPrompt = buildEnhancedPrompt(
            from: analysis,
            style: context.preferredStyle
        )
        
        // Determine optimal parameters
        let parameters = determineOptimalParameters(for: analysis)
        
        let request = ImageGenerationRequest(
            prompt: enhancedPrompt,
            background: analysis.requiresTransparency ? "transparent" : nil,
            model: Models.Images.gptImage1,
            moderation: context.moderationLevel,
            outputCompression: parameters.compression,
            outputFormat: parameters.format,
            quality: parameters.quality,
            responseFormat: .b64Json,
            size: parameters.size,
            style: parameters.style
        )
        
        let startTime = Date()
        let response = try await openAI.images.generations(request)
        let generationTime = Date().timeIntervalSince(startTime)
        
        guard let imageData = response.data.first,
              let base64 = imageData.b64Json else {
            throw AdvancedImageError.generationFailed
        }
        
        // Analyze how well the result matches intent
        let matchScore = try await analyzeResultMatch(
            intent: analysis,
            revisedPrompt: imageData.revisedPrompt,
            generationTime: generationTime
        )
        
        return InterpretedImageResult(
            userIntent: userIntent,
            interpretedIntent: analysis,
            enhancedPrompt: enhancedPrompt,
            revisedPrompt: imageData.revisedPrompt,
            imageData: base64,
            parameters: parameters,
            matchScore: matchScore,
            usage: response.usage,
            generationTime: generationTime
        )
    }
    
    /// Analyze user intent using AI
    private func analyzeIntent(
        _ userIntent: String,
        context: GenerationContext
    ) async throws -> IntentAnalysis {
        
        // In a real implementation, this could use GPT-4 to analyze intent
        // For this example, we'll use pattern matching
        
        let lowercased = userIntent.lowercased()
        
        // Detect subject
        let subject = extractSubject(from: userIntent)
        
        // Detect style preferences
        let detectedStyle = detectStyle(from: lowercased)
        
        // Detect composition
        let composition = detectComposition(from: lowercased)
        
        // Detect special requirements
        let requiresTransparency = lowercased.contains("transparent") ||
                                  lowercased.contains("no background") ||
                                  lowercased.contains("cutout")
        
        let requiresHighDetail = lowercased.contains("detailed") ||
                                lowercased.contains("intricate") ||
                                lowercased.contains("high quality")
        
        // Detect mood/atmosphere
        let mood = detectMood(from: lowercased)
        
        // Detect technical requirements
        let technicalNeeds = detectTechnicalNeeds(from: lowercased)
        
        return IntentAnalysis(
            subject: subject,
            style: detectedStyle ?? context.preferredStyle,
            composition: composition,
            mood: mood,
            technicalNeeds: technicalNeeds,
            requiresTransparency: requiresTransparency,
            requiresHighDetail: requiresHighDetail,
            contextualHints: extractContextualHints(userIntent, context: context)
        )
    }
    
    /// Build enhanced prompt from analysis
    private func buildEnhancedPrompt(
        from analysis: IntentAnalysis,
        style: Style?
    ) -> String {
        
        var components: [String] = []
        
        // Start with subject
        components.append(analysis.subject)
        
        // Add style descriptors
        if let style = analysis.style {
            components.append(contentsOf: style.descriptors)
        }
        
        // Add composition
        components.append(contentsOf: analysis.composition.descriptors)
        
        // Add mood
        if let mood = analysis.mood {
            components.append(contentsOf: mood.descriptors)
        }
        
        // Add technical specifications
        if analysis.requiresHighDetail {
            components.append("highly detailed")
            components.append("4K quality")
            components.append("sharp focus")
        }
        
        // Add transparency requirements
        if analysis.requiresTransparency {
            components.append("isolated on transparent background")
            components.append("clean edges")
            components.append("no background elements")
        }
        
        // Add contextual enhancements
        components.append(contentsOf: analysis.contextualHints)
        
        // Add quality markers for gpt-image-1
        components.append("professional quality")
        components.append("photorealistic rendering")
        
        return components.joined(separator: ", ")
    }
    
    /// Determine optimal parameters based on analysis
    private func determineOptimalParameters(
        for analysis: IntentAnalysis
    ) -> OptimalParameters {
        
        // Size selection
        let size: String
        switch analysis.composition {
        case .landscape:
            size = "1792x1024"
        case .portrait:
            size = "1024x1792"
        case .square:
            size = analysis.requiresHighDetail ? "2048x2048" : "1024x1024"
        case .panoramic:
            size = "1792x1024" // Closest available
        }
        
        // Quality selection
        let quality = analysis.requiresHighDetail ? "hd" : "standard"
        
        // Format selection
        let format: String
        if analysis.requiresTransparency {
            format = "png"
        } else if analysis.technicalNeeds.contains(.webOptimized) {
            format = "webp"
        } else {
            format = "jpeg"
        }
        
        // Compression selection
        let compression: Int
        if analysis.requiresHighDetail {
            compression = 95
        } else if analysis.technicalNeeds.contains(.smallFileSize) {
            compression = 75
        } else {
            compression = 85
        }
        
        // Style selection
        let style = analysis.style?.apiValue ?? "natural"
        
        return OptimalParameters(
            size: size,
            quality: quality,
            format: format,
            compression: compression,
            style: style
        )
    }
    
    /// Analyze how well result matches intent
    private func analyzeResultMatch(
        intent: IntentAnalysis,
        revisedPrompt: String?,
        generationTime: TimeInterval
    ) async throws -> MatchScore {
        
        var score = 100.0
        var factors: [String] = []
        
        // Check if prompt was revised (indicates potential issues)
        if revisedPrompt != nil {
            score -= 10
            factors.append("Prompt was revised for safety/clarity")
        }
        
        // Check generation time (longer might indicate complexity)
        if generationTime > 15 {
            score -= 5
            factors.append("Complex generation took extra time")
        }
        
        // Assess based on requirements
        if intent.requiresHighDetail && generationTime < 5 {
            score -= 5
            factors.append("Quick generation might lack detail")
        }
        
        return MatchScore(
            score: max(0, min(100, score)),
            factors: factors,
            confidence: score > 80 ? .high : score > 60 ? .medium : .low
        )
    }
    
    // Helper methods for intent analysis
    private func extractSubject(from text: String) -> String {
        // Simplified - in production, use NLP
        let words = text.split(separator: " ")
        if let aIndex = words.firstIndex(of: "a") ?? words.firstIndex(of: "an") {
            let afterA = words[(aIndex + 1)...]
            return afterA.prefix(3).joined(separator: " ")
        }
        return text
    }
    
    private func detectStyle(from text: String) -> Style? {
        for style in Style.allCases {
            if text.contains(style.rawValue.lowercased()) {
                return style
            }
        }
        return nil
    }
    
    private func detectComposition(from text: String) -> Composition {
        if text.contains("landscape") || text.contains("wide") {
            return .landscape
        } else if text.contains("portrait") || text.contains("tall") {
            return .portrait
        } else if text.contains("panoram") {
            return .panoramic
        }
        return .square
    }
    
    private func detectMood(from text: String) -> Mood? {
        for mood in Mood.allCases {
            if text.contains(mood.rawValue.lowercased()) {
                return mood
            }
        }
        return nil
    }
    
    private func detectTechnicalNeeds(from text: String) -> Set<TechnicalNeed> {
        var needs = Set<TechnicalNeed>()
        if text.contains("web") || text.contains("website") {
            needs.insert(.webOptimized)
        }
        if text.contains("print") || text.contains("high res") {
            needs.insert(.printQuality)
        }
        if text.contains("small") || text.contains("compressed") {
            needs.insert(.smallFileSize)
        }
        return needs
    }
    
    private func extractContextualHints(_ text: String, context: GenerationContext) -> [String] {
        var hints: [String] = []
        
        // Add time-based hints
        if context.timeOfDay == "evening" {
            hints.append("golden hour lighting")
        }
        
        // Add seasonal hints
        if let season = context.season {
            hints.append("\(season) atmosphere")
        }
        
        // Add brand hints
        if let brand = context.brandGuidelines {
            hints.append(contentsOf: brand.styleKeywords)
        }
        
        return hints
    }
}

// Supporting types
struct GenerationContext {
    var preferredStyle: Style?
    var moderationLevel: String?
    var timeOfDay: String?
    var season: String?
    var brandGuidelines: BrandGuidelines?
}

struct BrandGuidelines {
    let primaryColors: [String]
    let styleKeywords: [String]
    let avoidKeywords: [String]
}

struct IntentAnalysis {
    let subject: String
    let style: Style?
    let composition: Composition
    let mood: Mood?
    let technicalNeeds: Set<TechnicalNeed>
    let requiresTransparency: Bool
    let requiresHighDetail: Bool
    let contextualHints: [String]
}

enum Style: String, CaseIterable {
    case photorealistic, cartoon, abstract, minimalist, vintage, modern, artistic
    
    var descriptors: [String] {
        switch self {
        case .photorealistic: return ["photorealistic", "lifelike", "detailed"]
        case .cartoon: return ["cartoon style", "animated", "colorful"]
        case .abstract: return ["abstract", "artistic", "non-representational"]
        case .minimalist: return ["minimalist", "simple", "clean"]
        case .vintage: return ["vintage", "retro", "nostalgic"]
        case .modern: return ["modern", "contemporary", "sleek"]
        case .artistic: return ["artistic", "painterly", "expressive"]
        }
    }
    
    var apiValue: String {
        switch self {
        case .photorealistic, .modern, .minimalist: return "natural"
        case .cartoon, .abstract, .vintage, .artistic: return "vivid"
        }
    }
}

enum Composition {
    case landscape, portrait, square, panoramic
    
    var descriptors: [String] {
        switch self {
        case .landscape: return ["landscape orientation", "wide composition"]
        case .portrait: return ["portrait orientation", "vertical composition"]
        case .square: return ["square composition", "balanced framing"]
        case .panoramic: return ["panoramic view", "ultra-wide composition"]
        }
    }
}

enum Mood: String, CaseIterable {
    case cheerful, dramatic, serene, mysterious, energetic
    
    var descriptors: [String] {
        switch self {
        case .cheerful: return ["cheerful", "bright", "optimistic"]
        case .dramatic: return ["dramatic lighting", "high contrast", "intense"]
        case .serene: return ["serene", "peaceful", "calm"]
        case .mysterious: return ["mysterious", "enigmatic", "atmospheric"]
        case .energetic: return ["energetic", "dynamic", "vibrant"]
        }
    }
}

enum TechnicalNeed {
    case webOptimized, printQuality, smallFileSize
}

struct OptimalParameters {
    let size: String
    let quality: String
    let format: String
    let compression: Int
    let style: String
}

struct MatchScore {
    let score: Double
    let factors: [String]
    let confidence: Confidence
    
    enum Confidence {
        case low, medium, high
    }
}

struct InterpretedImageResult {
    let userIntent: String
    let interpretedIntent: IntentAnalysis
    let enhancedPrompt: String
    let revisedPrompt: String?
    let imageData: String
    let parameters: OptimalParameters
    let matchScore: MatchScore
    let usage: ImageUsage?
    let generationTime: TimeInterval
    
    var summary: String {
        """
        User Intent: \(userIntent)
        Enhanced Prompt: \(enhancedPrompt)
        Match Score: \(matchScore.score)% (\(matchScore.confidence))
        Parameters: \(parameters.size), \(parameters.quality), \(parameters.format)
        Generation Time: \(String(format: "%.2f", generationTime))s
        """
    }
}