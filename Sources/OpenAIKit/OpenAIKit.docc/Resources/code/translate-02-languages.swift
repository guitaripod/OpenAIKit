import OpenAIKit
import Foundation

// MARK: - Supported Languages

enum WhisperLanguage: String, CaseIterable {
    case afrikaans = "af"
    case arabic = "ar"
    case armenian = "hy"
    case azerbaijani = "az"
    case belarusian = "be"
    case bosnian = "bs"
    case bulgarian = "bg"
    case catalan = "ca"
    case chinese = "zh"
    case croatian = "hr"
    case czech = "cs"
    case danish = "da"
    case dutch = "nl"
    case english = "en"
    case estonian = "et"
    case finnish = "fi"
    case french = "fr"
    case galician = "gl"
    case german = "de"
    case greek = "el"
    case hebrew = "he"
    case hindi = "hi"
    case hungarian = "hu"
    case icelandic = "is"
    case indonesian = "id"
    case italian = "it"
    case japanese = "ja"
    case kannada = "kn"
    case kazakh = "kk"
    case korean = "ko"
    case latvian = "lv"
    case lithuanian = "lt"
    case macedonian = "mk"
    case malay = "ms"
    case marathi = "mr"
    case maori = "mi"
    case nepali = "ne"
    case norwegian = "no"
    case persian = "fa"
    case polish = "pl"
    case portuguese = "pt"
    case romanian = "ro"
    case russian = "ru"
    case serbian = "sr"
    case slovak = "sk"
    case slovenian = "sl"
    case spanish = "es"
    case swahili = "sw"
    case swedish = "sv"
    case tagalog = "tl"
    case tamil = "ta"
    case thai = "th"
    case turkish = "tr"
    case ukrainian = "uk"
    case urdu = "ur"
    case vietnamese = "vi"
    case welsh = "cy"
    
    var displayName: String {
        switch self {
        case .afrikaans: return "Afrikaans"
        case .arabic: return "Arabic"
        case .armenian: return "Armenian"
        case .azerbaijani: return "Azerbaijani"
        case .belarusian: return "Belarusian"
        case .bosnian: return "Bosnian"
        case .bulgarian: return "Bulgarian"
        case .catalan: return "Catalan"
        case .chinese: return "Chinese"
        case .croatian: return "Croatian"
        case .czech: return "Czech"
        case .danish: return "Danish"
        case .dutch: return "Dutch"
        case .english: return "English"
        case .estonian: return "Estonian"
        case .finnish: return "Finnish"
        case .french: return "French"
        case .galician: return "Galician"
        case .german: return "German"
        case .greek: return "Greek"
        case .hebrew: return "Hebrew"
        case .hindi: return "Hindi"
        case .hungarian: return "Hungarian"
        case .icelandic: return "Icelandic"
        case .indonesian: return "Indonesian"
        case .italian: return "Italian"
        case .japanese: return "Japanese"
        case .kannada: return "Kannada"
        case .kazakh: return "Kazakh"
        case .korean: return "Korean"
        case .latvian: return "Latvian"
        case .lithuanian: return "Lithuanian"
        case .macedonian: return "Macedonian"
        case .malay: return "Malay"
        case .marathi: return "Marathi"
        case .maori: return "Māori"
        case .nepali: return "Nepali"
        case .norwegian: return "Norwegian"
        case .persian: return "Persian"
        case .polish: return "Polish"
        case .portuguese: return "Portuguese"
        case .romanian: return "Romanian"
        case .russian: return "Russian"
        case .serbian: return "Serbian"
        case .slovak: return "Slovak"
        case .slovenian: return "Slovenian"
        case .spanish: return "Spanish"
        case .swahili: return "Swahili"
        case .swedish: return "Swedish"
        case .tagalog: return "Tagalog"
        case .tamil: return "Tamil"
        case .thai: return "Thai"
        case .turkish: return "Turkish"
        case .ukrainian: return "Ukrainian"
        case .urdu: return "Urdu"
        case .vietnamese: return "Vietnamese"
        case .welsh: return "Welsh"
        }
    }
    
    var flag: String {
        switch self {
        case .afrikaans: return "🇿🇦"
        case .arabic: return "🇸🇦"
        case .armenian: return "🇦🇲"
        case .azerbaijani: return "🇦🇿"
        case .belarusian: return "🇧🇾"
        case .bosnian: return "🇧🇦"
        case .bulgarian: return "🇧🇬"
        case .catalan: return "🇪🇸"
        case .chinese: return "🇨🇳"
        case .croatian: return "🇭🇷"
        case .czech: return "🇨🇿"
        case .danish: return "🇩🇰"
        case .dutch: return "🇳🇱"
        case .english: return "🇬🇧"
        case .estonian: return "🇪🇪"
        case .finnish: return "🇫🇮"
        case .french: return "🇫🇷"
        case .galician: return "🇪🇸"
        case .german: return "🇩🇪"
        case .greek: return "🇬🇷"
        case .hebrew: return "🇮🇱"
        case .hindi: return "🇮🇳"
        case .hungarian: return "🇭🇺"
        case .icelandic: return "🇮🇸"
        case .indonesian: return "🇮🇩"
        case .italian: return "🇮🇹"
        case .japanese: return "🇯🇵"
        case .kannada: return "🇮🇳"
        case .kazakh: return "🇰🇿"
        case .korean: return "🇰🇷"
        case .latvian: return "🇱🇻"
        case .lithuanian: return "🇱🇹"
        case .macedonian: return "🇲🇰"
        case .malay: return "🇲🇾"
        case .marathi: return "🇮🇳"
        case .maori: return "🇳🇿"
        case .nepali: return "🇳🇵"
        case .norwegian: return "🇳🇴"
        case .persian: return "🇮🇷"
        case .polish: return "🇵🇱"
        case .portuguese: return "🇵🇹"
        case .romanian: return "🇷🇴"
        case .russian: return "🇷🇺"
        case .serbian: return "🇷🇸"
        case .slovak: return "🇸🇰"
        case .slovenian: return "🇸🇮"
        case .spanish: return "🇪🇸"
        case .swahili: return "🇰🇪"
        case .swedish: return "🇸🇪"
        case .tagalog: return "🇵🇭"
        case .tamil: return "🇮🇳"
        case .thai: return "🇹🇭"
        case .turkish: return "🇹🇷"
        case .ukrainian: return "🇺🇦"
        case .urdu: return "🇵🇰"
        case .vietnamese: return "🇻🇳"
        case .welsh: return "🏴󐁧󐁢󐁷󐁬󐁳󐁿"
        }
    }
}

// MARK: - Language Detection Helper

class LanguageDetectionHelper {
    
    // Common phrases in different languages for better detection
    static let languageHints: [WhisperLanguage: [String]] = [
        .spanish: ["hola", "gracias", "por favor", "buenos días"],
        .french: ["bonjour", "merci", "s'il vous plaît", "au revoir"],
        .german: ["guten tag", "danke", "bitte", "auf wiedersehen"],
        .italian: ["ciao", "grazie", "per favore", "arrivederci"],
        .portuguese: ["olá", "obrigado", "por favor", "tchau"],
        .russian: ["привет", "спасибо", "пожалуйста", "до свидания"],
        .japanese: ["こんにちは", "ありがとう", "さようなら"],
        .chinese: ["你好", "谢谢", "再见"],
        .korean: ["안녕하세요", "감사합니다", "안녕히 가세요"]
    ]
    
    // Get a hint prompt for better language detection
    static func getLanguageHint(for language: WhisperLanguage) -> String? {
        guard let hints = languageHints[language] else { return nil }
        return hints.randomElement()
    }
    
    // Group languages by script type
    enum ScriptType {
        case latin
        case cyrillic
        case arabic
        case cjk  // Chinese, Japanese, Korean
        case devanagari
        case other
    }
    
    static func scriptType(for language: WhisperLanguage) -> ScriptType {
        switch language {
        case .russian, .ukrainian, .belarusian, .bulgarian, .macedonian, .serbian:
            return .cyrillic
        case .arabic, .persian, .urdu:
            return .arabic
        case .chinese, .japanese, .korean:
            return .cjk
        case .hindi, .marathi, .nepali:
            return .devanagari
        case .hebrew, .thai:
            return .other
        default:
            return .latin
        }
    }
}

// MARK: - Multi-Language Translation Pipeline

class MultiLanguageTranslator {
    private let openAI: OpenAIKit
    
    init(apiKey: String) {
        self.openAI = OpenAIKit(apiKey: apiKey)
    }
    
    func translateBatch(
        audioFiles: [(url: URL, expectedLanguage: WhisperLanguage?)]
    ) async throws -> [BatchTranslationResult] {
        var results: [BatchTranslationResult] = []
        
        for (audioURL, expectedLanguage) in audioFiles {
            do {
                let audioData = try Data(contentsOf: audioURL)
                
                // Add language hint if provided
                var prompt: String? = nil
                if let language = expectedLanguage {
                    prompt = LanguageDetectionHelper.getLanguageHint(for: language)
                }
                
                let request = AudioTranslationRequest(
                    file: audioData,
                    model: "whisper-1",
                    prompt: prompt,
                    responseFormat: .verboseJson
                )
                
                let response = try await openAI.createAudioTranslation(request: request)
                
                let result = BatchTranslationResult(
                    originalFile: audioURL,
                    translatedText: response.text,
                    detectedLanguage: response.language,
                    expectedLanguage: expectedLanguage?.rawValue,
                    confidence: calculateConfidence(response: response),
                    duration: response.duration ?? 0
                )
                
                results.append(result)
                
            } catch {
                let errorResult = BatchTranslationResult(
                    originalFile: audioURL,
                    translatedText: "",
                    detectedLanguage: nil,
                    expectedLanguage: expectedLanguage?.rawValue,
                    confidence: 0,
                    duration: 0,
                    error: error
                )
                results.append(errorResult)
            }
            
            // Rate limiting
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        return results
    }
    
    private func calculateConfidence(response: AudioTranslationResponse) -> Double {
        // Calculate confidence based on segments if available
        guard let segments = response.segments, !segments.isEmpty else { return 0.8 }
        
        let avgLogprobs = segments.compactMap { $0.avgLogprob }
        guard !avgLogprobs.isEmpty else { return 0.8 }
        
        let avgLogprob = avgLogprobs.reduce(0, +) / Double(avgLogprobs.count)
        // Convert log probability to confidence score (0-1)
        return min(max(exp(avgLogprob), 0), 1)
    }
}

// MARK: - Models

struct BatchTranslationResult {
    let originalFile: URL
    let translatedText: String
    let detectedLanguage: String?
    let expectedLanguage: String?
    let confidence: Double
    let duration: Double
    let error: Error?
    
    var languageMatch: Bool {
        guard let detected = detectedLanguage,
              let expected = expectedLanguage else { return false }
        return detected.lowercased() == expected.lowercased()
    }
}