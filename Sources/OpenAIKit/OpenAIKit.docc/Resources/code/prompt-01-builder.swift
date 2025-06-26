import OpenAIKit

// MARK: - Prompt Builder

struct PromptBuilder {
    private var components: [String] = []
    
    mutating func add(_ text: String) {
        components.append(text)
    }
    
    mutating func addStyle(_ style: String) {
        components.append("in \(style) style")
    }
    
    mutating func addModifier(_ modifier: String) {
        components.append(modifier)
    }
    
    func build() -> String {
        components.joined(separator: ", ")
    }
}

// Usage example
var builder = PromptBuilder()
builder.add("A majestic mountain landscape")
builder.addStyle("impressionist")
builder.addModifier("during sunset")
let prompt = builder.build()