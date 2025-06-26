import OpenAIKit
import Foundation

// MARK: - Context-Aware Translation

class ContextAwareTranslator {
    private let openAI: OpenAIKit
    private var contextHistory: [TranslationContext] = []
    private let maxContextHistory = 5
    
    init(apiKey: String) {
        self.openAI = OpenAIKit(apiKey: apiKey)
    }
    
    // Translate with domain-specific context
    func translateWithContext(
        audioFile: URL,
        domain: TranslationDomain,
        previousContext: String? = nil
    ) async throws -> ContextualTranslationResult {
        let audioData = try Data(contentsOf: audioFile)
        
        // Build context prompt based on domain and history
        let contextPrompt = buildContextPrompt(
            domain: domain,
            previousContext: previousContext
        )
        
        // Create translation request with context
        let request = AudioTranslationRequest(
            file: audioData,
            model: "whisper-1",
            prompt: contextPrompt,
            responseFormat: .verboseJson,
            temperature: domain.optimalTemperature
        )
        
        let response = try await openAI.createAudioTranslation(request: request)
        
        // Store in context history
        let context = TranslationContext(
            text: response.text,
            domain: domain,
            timestamp: Date(),
            language: response.language ?? "unknown"
        )
        addToHistory(context)
        
        // Post-process translation based on domain
        let processedText = postProcessTranslation(
            text: response.text,
            domain: domain
        )
        
        return ContextualTranslationResult(
            originalText: response.text,
            processedText: processedText,
            domain: domain,
            confidence: calculateDomainConfidence(response: response, domain: domain),
            glossaryTermsUsed: extractGlossaryTerms(text: processedText, domain: domain)
        )
    }
    
    private func buildContextPrompt(
        domain: TranslationDomain,
        previousContext: String?
    ) -> String {
        var prompt = domain.contextPrompt
        
        // Add previous context if available
        if let previous = previousContext {
            prompt += " Previous context: \(previous)."
        }
        
        // Add recent history context
        let recentContext = contextHistory
            .suffix(3)
            .map { $0.text }
            .joined(separator: " ")
        
        if !recentContext.isEmpty {
            prompt += " Recent conversation: \(recentContext)"
        }
        
        return prompt
    }
    
    private func postProcessTranslation(
        text: String,
        domain: TranslationDomain
    ) -> String {
        var processed = text
        
        // Apply domain-specific replacements
        for (original, replacement) in domain.glossary {
            processed = processed.replacingOccurrences(
                of: original,
                with: replacement,
                options: [.caseInsensitive]
            )
        }
        
        // Apply formatting rules
        processed = applyDomainFormatting(text: processed, domain: domain)
        
        return processed
    }
    
    private func applyDomainFormatting(
        text: String,
        domain: TranslationDomain
    ) -> String {
        switch domain {
        case .medical:
            // Capitalize medical terms
            return text // Implementation would capitalize known medical terms
            
        case .legal:
            // Format legal citations
            return text // Implementation would format case citations
            
        case .technical:
            // Format code snippets or technical terms
            return text // Implementation would format technical content
            
        case .business:
            // Format business terms and numbers
            return text // Implementation would format currency, percentages
            
        case .general:
            return text
            
        case .custom:
            return text
        }
    }
    
    private func addToHistory(_ context: TranslationContext) {
        contextHistory.append(context)
        if contextHistory.count > maxContextHistory {
            contextHistory.removeFirst()
        }
    }
    
    private func calculateDomainConfidence(
        response: AudioTranslationResponse,
        domain: TranslationDomain
    ) -> Double {
        // Base confidence from response
        var confidence = 0.8
        
        // Boost confidence if domain terms are found
        let domainTermsFound = domain.glossary.keys.filter { term in
            response.text.localizedCaseInsensitiveContains(term)
        }.count
        
        confidence += Double(domainTermsFound) * 0.02
        
        return min(confidence, 1.0)
    }
    
    private func extractGlossaryTerms(
        text: String,
        domain: TranslationDomain
    ) -> [String] {
        domain.glossary.values.filter { term in
            text.localizedCaseInsensitiveContains(term)
        }
    }
}

// MARK: - Translation Domains

enum TranslationDomain {
    case medical
    case legal
    case technical
    case business
    case general
    case custom(CustomDomain)
    
    var contextPrompt: String {
        switch self {
        case .medical:
            return "Medical context with proper medical terminology."
        case .legal:
            return "Legal context with proper legal terminology and citations."
        case .technical:
            return "Technical context with programming and engineering terms."
        case .business:
            return "Business context with financial and corporate terminology."
        case .general:
            return ""
        case .custom(let domain):
            return domain.prompt
        }
    }
    
    var glossary: [String: String] {
        switch self {
        case .medical:
            return [
                "heart attack": "myocardial infarction",
                "high blood pressure": "hypertension",
                "sugar disease": "diabetes mellitus"
            ]
        case .legal:
            return [
                "guilty": "liable",
                "not guilty": "not liable",
                "judge": "magistrate"
            ]
        case .technical:
            return [
                "bug": "software defect",
                "crash": "system failure",
                "update": "software update"
            ]
        case .business:
            return [
                "money": "capital",
                "buy": "acquire",
                "sell": "divest"
            ]
        case .general:
            return [:]
        case .custom(let domain):
            return domain.glossary
        }
    }
    
    var optimalTemperature: Double {
        switch self {
        case .medical, .legal:
            return 0.1  // Very low for accuracy
        case .technical:
            return 0.2
        case .business:
            return 0.3
        case .general:
            return 0.5
        case .custom(let domain):
            return domain.temperature
        }
    }
}

struct CustomDomain {
    let name: String
    let prompt: String
    let glossary: [String: String]
    let temperature: Double
}

// MARK: - Models

struct TranslationContext {
    let text: String
    let domain: TranslationDomain
    let timestamp: Date
    let language: String
}

struct ContextualTranslationResult {
    let originalText: String
    let processedText: String
    let domain: TranslationDomain
    let confidence: Double
    let glossaryTermsUsed: [String]
}

// MARK: - Session Management

class TranslationSessionManager {
    private var sessions: [UUID: TranslationSession] = [:]
    
    func createSession(
        domain: TranslationDomain,
        sourceLanguage: WhisperLanguage? = nil
    ) -> UUID {
        let sessionId = UUID()
        let session = TranslationSession(
            id: sessionId,
            domain: domain,
            sourceLanguage: sourceLanguage,
            startTime: Date(),
            translations: []
        )
        sessions[sessionId] = session
        return sessionId
    }
    
    func addTranslation(
        to sessionId: UUID,
        translation: ContextualTranslationResult
    ) {
        sessions[sessionId]?.translations.append(translation)
    }
    
    func getSessionContext(_ sessionId: UUID) -> String? {
        guard let session = sessions[sessionId] else { return nil }
        
        // Get last 3 translations for context
        let recentTranslations = session.translations
            .suffix(3)
            .map { $0.processedText }
            .joined(separator: " ")
        
        return recentTranslations.isEmpty ? nil : recentTranslations
    }
    
    func exportSession(_ sessionId: UUID) -> TranslationSession? {
        sessions[sessionId]
    }
}

struct TranslationSession {
    let id: UUID
    let domain: TranslationDomain
    let sourceLanguage: WhisperLanguage?
    let startTime: Date
    var translations: [ContextualTranslationResult]
    
    var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    var wordCount: Int {
        translations.reduce(0) { count, translation in
            count + translation.processedText.split(separator: " ").count
        }
    }
}