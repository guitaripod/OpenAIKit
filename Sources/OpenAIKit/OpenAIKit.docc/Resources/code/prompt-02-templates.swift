import OpenAIKit

// MARK: - Prompt Templates

enum PromptTemplate {
    case landscape(String)
    case portrait(String, String)
    case abstract(String)
    case photorealistic(String)
    
    var prompt: String {
        switch self {
        case .landscape(let scene):
            return "A beautiful landscape of \(scene), highly detailed, 4k resolution"
        case .portrait(let subject, let style):
            return "A portrait of \(subject) in \(style) style, professional lighting"
        case .abstract(let concept):
            return "An abstract representation of \(concept), vibrant colors, modern art"
        case .photorealistic(let description):
            return "A photorealistic image of \(description), ultra detailed, professional photography"
        }
    }
}

// Usage examples
let landscapePrompt = PromptTemplate.landscape("misty forest").prompt
let portraitPrompt = PromptTemplate.portrait("elderly wizard", "fantasy art").prompt
let abstractPrompt = PromptTemplate.abstract("time and space").prompt