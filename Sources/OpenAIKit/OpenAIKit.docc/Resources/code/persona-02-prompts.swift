// PersonaManager.swift
import Foundation

class PersonaManager: ObservableObject {
    @Published var currentPersona: Persona = .helpful
    @Published var customPersonas: [Persona] = []
    
    private let userDefaults = UserDefaults.standard
    private let customPersonasKey = "customPersonas"
    
    init() {
        loadCustomPersonas()
    }
    
    func buildSystemPrompt(for persona: Persona) -> String {
        var prompt = persona.systemPrompt
        
        // Add traits
        if !persona.traits.isEmpty {
            prompt += "\n\nYour personality traits: \(persona.traits.joined(separator: ", "))"
        }
        
        // Add knowledge domains
        if !persona.knowledge.isEmpty {
            prompt += "\n\nYou have expertise in: \(persona.knowledge.joined(separator: ", "))"
        }
        
        // Add examples
        if !persona.examples.isEmpty {
            prompt += "\n\nExample interactions:"
            for example in persona.examples.prefix(3) {
                prompt += "\nUser: \(example.userInput)"
                prompt += "\nAssistant: \(example.assistantResponse)"
            }
        }
        
        return prompt
    }
    
    func createCustomPersona(
        name: String,
        description: String,
        basePrompt: String,
        traits: [String],
        temperature: Double = 0.7
    ) {
        let persona = Persona(
            name: name,
            description: description,
            systemPrompt: basePrompt,
            temperature: temperature,
            traits: traits,
            knowledge: [],
            examples: []
        )
        
        customPersonas.append(persona)
        saveCustomPersonas()
    }
    
    private func loadCustomPersonas() {
        guard let data = userDefaults.data(forKey: customPersonasKey),
              let personas = try? JSONDecoder().decode([Persona].self, from: data) else {
            return
        }
        customPersonas = personas
    }
    
    private func saveCustomPersonas() {
        guard let data = try? JSONEncoder().encode(customPersonas) else { return }
        userDefaults.set(data, forKey: customPersonasKey)
    }
}
