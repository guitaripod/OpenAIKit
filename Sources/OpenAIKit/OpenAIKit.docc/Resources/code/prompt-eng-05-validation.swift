// PromptEngineering.swift - Validation and Safety
import Foundation
import OpenAIKit

/// Prompt validator for safety and quality
class PromptValidator {
    
    private let prohibitedPatterns = ProhibitedContentDetector()
    private let qualityChecker = PromptQualityChecker()
    
    /// Validate prompt for safety and quality
    func validate(_ prompt: String) -> ValidationResult {
        var issues: [ValidationIssue] = []
        var warnings: [ValidationWarning] = []
        
        // Check for prohibited content
        let safetyCheck = prohibitedPatterns.check(prompt)
        if !safetyCheck.isSafe {
            issues.append(contentsOf: safetyCheck.issues)
        }
        warnings.append(contentsOf: safetyCheck.warnings)
        
        // Check prompt quality
        let qualityCheck = qualityChecker.check(prompt)
        issues.append(contentsOf: qualityCheck.issues)
        warnings.append(contentsOf: qualityCheck.warnings)
        
        // Check length constraints
        if prompt.count < 3 {
            issues.append(.tooShort(minimum: 3))
        } else if prompt.count > 1000 {
            issues.append(.tooLong(maximum: 1000))
        }
        
        // Calculate safety score
        let safetyScore = calculateSafetyScore(prompt, issues: issues)
        
        return ValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            warnings: warnings,
            safetyScore: safetyScore,
            suggestions: generateSuggestions(for: issues)
        )
    }
    
    /// Calculate safety score (0-100)
    private func calculateSafetyScore(_ prompt: String, issues: [ValidationIssue]) -> Double {
        var score = 100.0
        
        // Deduct points for issues
        for issue in issues {
            switch issue {
            case .prohibitedContent:
                score -= 50
            case .copyrightConcern:
                score -= 30
            case .ambiguousContent:
                score -= 20
            case .tooShort, .tooLong:
                score -= 10
            case .qualityIssue:
                score -= 15
            }
        }
        
        return max(0, score)
    }
    
    /// Generate suggestions for fixing issues
    private func generateSuggestions(for issues: [ValidationIssue]) -> [String] {
        var suggestions: [String] = []
        
        for issue in issues {
            switch issue {
            case .prohibitedContent(let type):
                suggestions.append("Remove or rephrase content related to \(type)")
                
            case .copyrightConcern(let item):
                suggestions.append("Replace '\(item)' with generic description")
                
            case .ambiguousContent(let detail):
                suggestions.append("Clarify: \(detail)")
                
            case .tooShort:
                suggestions.append("Add more descriptive details")
                
            case .tooLong:
                suggestions.append("Simplify and focus on key elements")
                
            case .qualityIssue(let problem):
                suggestions.append("Fix: \(problem)")
            }
        }
        
        return suggestions
    }
}

/// Prohibited content detector
class ProhibitedContentDetector {
    
    struct SafetyCheckResult {
        let isSafe: Bool
        let issues: [ValidationIssue]
        let warnings: [ValidationWarning]
    }
    
    func check(_ prompt: String) -> SafetyCheckResult {
        var issues: [ValidationIssue] = []
        var warnings: [ValidationWarning] = []
        
        let lowercased = prompt.lowercased()
        
        // Check for violence
        if containsViolence(lowercased) {
            issues.append(.prohibitedContent(type: "violence"))
        }
        
        // Check for inappropriate content
        if containsInappropriate(lowercased) {
            issues.append(.prohibitedContent(type: "inappropriate content"))
        }
        
        // Check for copyright
        let copyrightItems = detectCopyright(prompt)
        for item in copyrightItems {
            warnings.append(.potentialCopyright(item: item))
        }
        
        // Check for public figures
        if detectsPublicFigure(prompt) {
            warnings.append(.publicFigureDetected)
        }
        
        // Check for potentially sensitive topics
        if containsSensitive(lowercased) {
            warnings.append(.sensitiveTopic)
        }
        
        return SafetyCheckResult(
            isSafe: issues.isEmpty,
            issues: issues,
            warnings: warnings
        )
    }
    
    private func containsViolence(_ text: String) -> Bool {
        let violenceKeywords = [
            "gore", "blood", "violence", "kill", "murder", "torture",
            "mutilation", "decapitation", "dismember"
        ]
        return violenceKeywords.contains { text.contains($0) }
    }
    
    private func containsInappropriate(_ text: String) -> Bool {
        // Simplified check - in production, use more sophisticated filters
        let inappropriate = ["nsfw", "nude", "explicit"]
        return inappropriate.contains { text.contains($0) }
    }
    
    private func detectCopyright(_ text: String) -> [String] {
        let copyrightedItems = [
            "Mickey Mouse", "Pokemon", "Pikachu", "Mario", "Batman",
            "Superman", "Spider-Man", "Harry Potter", "Star Wars",
            "Disney", "Pixar", "Marvel", "DC Comics"
        ]
        
        return copyrightedItems.filter { text.contains($0) }
    }
    
    private func detectsPublicFigure(_ text: String) -> Bool {
        // Look for patterns that might indicate public figures
        let patterns = [
            "president", "celebrity", "famous", "politician",
            "actor", "actress", "singer", "athlete"
        ]
        return patterns.contains { text.lowercased().contains($0) }
    }
    
    private func containsSensitive(_ text: String) -> Bool {
        let sensitiveTopics = [
            "religion", "politics", "war", "disease", "death"
        ]
        return sensitiveTopics.contains { text.contains($0) }
    }
}

/// Prompt quality checker
class PromptQualityChecker {
    
    struct QualityCheckResult {
        let issues: [ValidationIssue]
        let warnings: [ValidationWarning]
        let score: Double
    }
    
    func check(_ prompt: String) -> QualityCheckResult {
        var issues: [ValidationIssue] = []
        var warnings: [ValidationWarning] = []
        var score = 100.0
        
        // Check for typos and spelling
        if hasLikelyTypos(prompt) {
            warnings.append(.possibleTypo)
            score -= 5
        }
        
        // Check for contradictions
        if hasContradictions(prompt) {
            issues.append(.qualityIssue(problem: "Contains contradictory descriptions"))
            score -= 20
        }
        
        // Check for excessive repetition
        if hasExcessiveRepetition(prompt) {
            warnings.append(.repetitiveContent)
            score -= 10
        }
        
        // Check for ambiguous descriptions
        if isAmbiguous(prompt) {
            issues.append(.ambiguousContent(detail: "Unclear subject or description"))
            score -= 15
        }
        
        // Check for overloaded descriptions
        if isOverloaded(prompt) {
            warnings.append(.tooManyDescriptors)
            score -= 10
        }
        
        return QualityCheckResult(
            issues: issues,
            warnings: warnings,
            score: max(0, score)
        )
    }
    
    private func hasLikelyTypos(_ prompt: String) -> Bool {
        // Simple check for common typo patterns
        let typoPatterns = ["teh ", " si ", " fo ", " ot ", "  "]
        return typoPatterns.contains { prompt.contains($0) }
    }
    
    private func hasContradictions(_ prompt: String) -> Bool {
        let contradictions = [
            ("dark", "bright"),
            ("small", "large"),
            ("old", "young"),
            ("ancient", "modern"),
            ("realistic", "cartoon")
        ]
        
        let lowercased = prompt.lowercased()
        return contradictions.contains { pair in
            lowercased.contains(pair.0) && lowercased.contains(pair.1)
        }
    }
    
    private func hasExcessiveRepetition(_ prompt: String) -> Bool {
        let words = prompt.split(separator: " ").map { $0.lowercased() }
        let wordCounts = Dictionary(grouping: words, by: { $0 }).mapValues { $0.count }
        
        // Check if any word appears too many times
        return wordCounts.values.contains { $0 > 3 }
    }
    
    private func isAmbiguous(_ prompt: String) -> Bool {
        let ambiguousTerms = ["thing", "stuff", "something", "whatever", "etc"]
        return ambiguousTerms.contains { prompt.lowercased().contains($0) }
    }
    
    private func isOverloaded(_ prompt: String) -> Bool {
        // Count descriptors (commas as a proxy)
        let commaCount = prompt.filter { $0 == "," }.count
        return commaCount > 15
    }
}

// Validation types
enum ValidationIssue {
    case prohibitedContent(type: String)
    case copyrightConcern(item: String)
    case ambiguousContent(detail: String)
    case tooShort(minimum: Int)
    case tooLong(maximum: Int)
    case qualityIssue(problem: String)
}

enum ValidationWarning {
    case potentialCopyright(item: String)
    case publicFigureDetected
    case sensitiveTopic
    case possibleTypo
    case repetitiveContent
    case tooManyDescriptors
}

struct ValidationResult {
    let isValid: Bool
    let issues: [ValidationIssue]
    let warnings: [ValidationWarning]
    let safetyScore: Double
    let suggestions: [String]
    
    var summary: String {
        if isValid {
            return "✅ Prompt is valid (Safety: \(Int(safetyScore))%)"
        } else {
            return "❌ Prompt has \(issues.count) issues (Safety: \(Int(safetyScore))%)"
        }
    }
}

// Prompt safety enhancer
extension PromptValidator {
    
    /// Make prompt safer while preserving intent
    func makeSafe(_ prompt: String) -> SafePromptResult {
        var safePrompt = prompt
        var modifications: [String] = []
        
        // Replace problematic terms
        let replacements = [
            ("weapon", "tool"),
            ("blood", "red liquid"),
            ("fight", "confrontation"),
            ("kill", "defeat"),
            ("nude", "figure"),
            ("violent", "intense")
        ]
        
        for (unsafe, safe) in replacements {
            if safePrompt.lowercased().contains(unsafe) {
                safePrompt = safePrompt.replacingOccurrences(
                    of: unsafe,
                    with: safe,
                    options: .caseInsensitive
                )
                modifications.append("Replaced '\(unsafe)' with '\(safe)'")
            }
        }
        
        // Remove copyright terms
        let copyrightTerms = detectCopyright(prompt)
        for term in copyrightTerms {
            let generic = genericize(term)
            safePrompt = safePrompt.replacingOccurrences(of: term, with: generic)
            modifications.append("Replaced '\(term)' with '\(generic)'")
        }
        
        return SafePromptResult(
            original: prompt,
            safe: safePrompt,
            modifications: modifications,
            wasModified: !modifications.isEmpty
        )
    }
    
    private func genericize(_ copyrighted: String) -> String {
        let generics = [
            "Mickey Mouse": "cartoon mouse character",
            "Pokemon": "cute creature",
            "Pikachu": "yellow electric creature",
            "Batman": "masked hero",
            "Superman": "caped hero",
            "Harry Potter": "young wizard"
        ]
        
        return generics[copyrighted] ?? "character"
    }
    
    private func detectCopyright(_ text: String) -> [String] {
        let copyrightedItems = [
            "Mickey Mouse", "Pokemon", "Pikachu", "Mario", "Batman",
            "Superman", "Spider-Man", "Harry Potter", "Star Wars"
        ]
        
        return copyrightedItems.filter { text.contains($0) }
    }
}

struct SafePromptResult {
    let original: String
    let safe: String
    let modifications: [String]
    let wasModified: Bool
}