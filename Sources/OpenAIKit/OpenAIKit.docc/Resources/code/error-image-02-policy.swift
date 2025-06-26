// ImageErrorHandling.swift
import Foundation
import OpenAIKit

/// Content policy error handler
class ContentPolicyHandler {
    
    /// Detect and handle content policy violations
    static func handlePolicyError(
        _ error: Error,
        originalPrompt: String
    ) throws -> PolicyRecoveryStrategy {
        
        // Parse the error to understand the violation
        let violation = parsePolicyViolation(from: error)
        
        // Analyze the prompt for problematic content
        let analysis = analyzePrompt(originalPrompt)
        
        // Generate recovery strategies
        let strategies = generateRecoveryStrategies(
            for: violation,
            promptAnalysis: analysis
        )
        
        // Return the best strategy
        return selectBestStrategy(from: strategies)
    }
    
    /// Parse policy violation details from error
    private static func parsePolicyViolation(from error: Error) -> PolicyViolation {
        // Check if it's an OpenAI API error
        if let apiError = error as? OpenAIError,
           case .requestFailed(let statusCode, let message) = apiError,
           statusCode == 400 {
            
            // Parse the error message for policy details
            if let message = message {
                if message.contains("violence") {
                    return .violence(severity: .high)
                } else if message.contains("sexual") {
                    return .sexualContent
                } else if message.contains("hate") {
                    return .hateContent
                } else if message.contains("self-harm") {
                    return .selfHarm
                } else if message.contains("copyright") {
                    return .copyright(details: extractCopyrightDetails(from: message))
                } else if message.contains("deceptive") {
                    return .deceptiveContent
                }
            }
        }
        
        return .unknown
    }
    
    /// Analyze prompt for potential issues
    private static func analyzePrompt(_ prompt: String) -> PromptAnalysis {
        let lowercased = prompt.lowercased()
        var issues: [PromptIssue] = []
        
        // Check for violence indicators
        let violenceKeywords = ["weapon", "gun", "knife", "blood", "gore", "fight", "war"]
        if violenceKeywords.contains(where: lowercased.contains) {
            issues.append(.potentialViolence)
        }
        
        // Check for potentially copyrighted content
        let copyrightPatterns = [
            "disney", "pixar", "marvel", "pokemon", "nintendo",
            "harry potter", "star wars", "batman", "superman"
        ]
        if copyrightPatterns.contains(where: lowercased.contains) {
            issues.append(.potentialCopyright)
        }
        
        // Check for public figures
        if detectsPublicFigure(in: prompt) {
            issues.append(.publicFigure)
        }
        
        // Check for potentially sensitive content
        if lowercased.contains("child") || lowercased.contains("minor") {
            issues.append(.minorDepiction)
        }
        
        return PromptAnalysis(
            originalPrompt: prompt,
            issues: issues,
            problematicTerms: extractProblematicTerms(from: prompt)
        )
    }
    
    /// Generate recovery strategies
    private static func generateRecoveryStrategies(
        for violation: PolicyViolation,
        promptAnalysis: PromptAnalysis
    ) -> [PolicyRecoveryStrategy] {
        
        var strategies: [PolicyRecoveryStrategy] = []
        
        switch violation {
        case .violence:
            strategies.append(.modifyPrompt(
                suggestions: [
                    removeViolentTerms(from: promptAnalysis.originalPrompt),
                    makeAbstract(promptAnalysis.originalPrompt),
                    focusOnPeaceful(promptAnalysis.originalPrompt)
                ]
            ))
            strategies.append(.alternativeApproach(
                "Try depicting the aftermath or emotional impact instead of violence"
            ))
            
        case .copyright:
            strategies.append(.modifyPrompt(
                suggestions: [
                    genericizeCopyrighted(promptAnalysis.originalPrompt),
                    createInspiredVersion(promptAnalysis.originalPrompt),
                    useGenericDescriptors(promptAnalysis.originalPrompt)
                ]
            ))
            strategies.append(.alternativeApproach(
                "Create original characters inspired by the style"
            ))
            
        case .sexualContent:
            strategies.append(.modifyPrompt(
                suggestions: [
                    makeSafeForWork(promptAnalysis.originalPrompt),
                    focusOnArtistic(promptAnalysis.originalPrompt)
                ]
            ))
            
        case .publicFigure:
            strategies.append(.modifyPrompt(
                suggestions: [
                    anonymizePerson(promptAnalysis.originalPrompt),
                    useGenericDescription(promptAnalysis.originalPrompt)
                ]
            ))
            strategies.append(.useAlternativeModel(
                reason: "Consider using a model that supports public figures with proper consent"
            ))
            
        default:
            strategies.append(.generalGuidance(
                "Ensure your prompt follows OpenAI's usage policies"
            ))
        }
        
        return strategies
    }
    
    /// Select the best recovery strategy
    private static func selectBestStrategy(
        from strategies: [PolicyRecoveryStrategy]
    ) -> PolicyRecoveryStrategy {
        
        // Prioritize modification strategies
        if let modifyStrategy = strategies.first(where: {
            if case .modifyPrompt = $0 { return true }
            return false
        }) {
            return modifyStrategy
        }
        
        // Return first available strategy
        return strategies.first ?? .generalGuidance(
            "Please review and modify your prompt to comply with content policies"
        )
    }
    
    // Helper methods for prompt modification
    
    private static func removeViolentTerms(from prompt: String) -> String {
        var modified = prompt
        let violentTerms = ["weapon", "gun", "knife", "blood", "gore", "fight", "violent"]
        
        for term in violentTerms {
            modified = modified.replacingOccurrences(
                of: term,
                with: "",
                options: .caseInsensitive
            )
        }
        
        return modified.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func makeAbstract(_ prompt: String) -> String {
        "Abstract representation of: \(prompt)"
    }
    
    private static func focusOnPeaceful(_ prompt: String) -> String {
        "Peaceful and serene version of: \(prompt)"
    }
    
    private static func genericizeCopyrighted(_ prompt: String) -> String {
        var modified = prompt
        let copyrightedTerms = [
            ("Mickey Mouse", "cartoon mouse character"),
            ("Pokemon", "cute creature"),
            ("Harry Potter", "young wizard"),
            ("Batman", "masked vigilante"),
            ("Star Wars", "space opera scene")
        ]
        
        for (copyrighted, generic) in copyrightedTerms {
            modified = modified.replacingOccurrences(
                of: copyrighted,
                with: generic,
                options: .caseInsensitive
            )
        }
        
        return modified
    }
    
    private static func createInspiredVersion(_ prompt: String) -> String {
        "Original character inspired by the style of: \(prompt)"
    }
    
    private static func useGenericDescriptors(_ prompt: String) -> String {
        "Generic version in the style of: \(prompt)"
    }
    
    private static func makeSafeForWork(_ prompt: String) -> String {
        "Professional and appropriate version of: \(prompt)"
    }
    
    private static func focusOnArtistic(_ prompt: String) -> String {
        "Artistic and tasteful interpretation of: \(prompt)"
    }
    
    private static func anonymizePerson(_ prompt: String) -> String {
        "Anonymous person in the style of: \(prompt)"
    }
    
    private static func useGenericDescription(_ prompt: String) -> String {
        "Generic professional portrait"
    }
    
    private static func detectsPublicFigure(in prompt: String) -> Bool {
        // Simplified detection - in production, use more sophisticated NER
        let patterns = ["president", "celebrity", "actor", "politician", "ceo"]
        return patterns.contains(where: prompt.lowercased().contains)
    }
    
    private static func extractProblematicTerms(from prompt: String) -> [String] {
        // Simplified extraction
        let problematicPatterns = [
            "weapon", "violence", "copyright", "trademark",
            "brand", "logo", "celebrity"
        ]
        
        return problematicPatterns.filter { prompt.lowercased().contains($0) }
    }
    
    private static func extractCopyrightDetails(from message: String) -> String {
        // Extract specific copyright concern from error message
        if message.contains("character") {
            return "Copyrighted character detected"
        } else if message.contains("logo") {
            return "Copyrighted logo or brand detected"
        }
        return "Potential copyright infringement"
    }
}

/// Types of policy violations
enum PolicyViolation {
    case violence(severity: Severity)
    case sexualContent
    case hateContent
    case selfHarm
    case copyright(details: String)
    case deceptiveContent
    case publicFigure
    case minorSafety
    case unknown
    
    enum Severity {
        case low, medium, high
    }
}

/// Prompt analysis results
struct PromptAnalysis {
    let originalPrompt: String
    let issues: [PromptIssue]
    let problematicTerms: [String]
}

/// Potential prompt issues
enum PromptIssue {
    case potentialViolence
    case potentialCopyright
    case publicFigure
    case minorDepiction
    case ambiguous
}

/// Recovery strategies for policy violations
enum PolicyRecoveryStrategy {
    case modifyPrompt(suggestions: [String])
    case alternativeApproach(String)
    case useAlternativeModel(reason: String)
    case generalGuidance(String)
    
    var description: String {
        switch self {
        case .modifyPrompt(let suggestions):
            return "Try these modified prompts:\n" + suggestions.enumerated()
                .map { "  \($0.offset + 1). \($0.element)" }
                .joined(separator: "\n")
            
        case .alternativeApproach(let approach):
            return "Alternative approach: \(approach)"
            
        case .useAlternativeModel(let reason):
            return "Consider a different model: \(reason)"
            
        case .generalGuidance(let guidance):
            return guidance
        }
    }
}