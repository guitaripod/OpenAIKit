import OpenAIKit

// MARK: - Prompt Validation

struct PromptValidator {
    enum ValidationError: Error {
        case tooShort
        case tooLong
        case containsProhibitedContent
        case invalidCharacters
    }
    
    private let minLength = 3
    private let maxLength = 1000
    private let prohibitedWords = ["offensive", "inappropriate"] // Example list
    
    func validate(_ prompt: String) throws {
        // Check length
        guard prompt.count >= minLength else {
            throw ValidationError.tooShort
        }
        
        guard prompt.count <= maxLength else {
            throw ValidationError.tooLong
        }
        
        // Check for prohibited content
        let lowercased = prompt.lowercased()
        for word in prohibitedWords {
            if lowercased.contains(word) {
                throw ValidationError.containsProhibitedContent
            }
        }
        
        // Check for valid characters
        let allowedCharacters = CharacterSet.alphanumerics.union(.punctuationCharacters).union(.whitespaces)
        guard prompt.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            throw ValidationError.invalidCharacters
        }
    }
    
    func sanitize(_ prompt: String) -> String {
        // Remove extra whitespace
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Ensure proper punctuation
        return normalized.hasSuffix(".") || normalized.hasSuffix("!") || normalized.hasSuffix("?") 
            ? normalized 
            : normalized + "."
    }
}

// Usage example
let validator = PromptValidator()
do {
    try validator.validate("A beautiful sunset over the ocean")
    let sanitized = validator.sanitize("A  beautiful   sunset   ")
} catch {
    print("Validation error: \(error)")
}