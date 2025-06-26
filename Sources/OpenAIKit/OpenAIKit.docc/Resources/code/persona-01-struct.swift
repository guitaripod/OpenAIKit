// Persona.swift
import Foundation

struct Persona: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let systemPrompt: String
    let temperature: Double
    let traits: [String]
    let knowledge: [String]
    let examples: [ConversationExample]
    
    static let helpful = Persona(
        name: "Helpful Assistant",
        description: "A friendly and helpful AI assistant",
        systemPrompt: "You are a helpful, friendly, and professional AI assistant. Provide clear and accurate information while being approachable.",
        temperature: 0.7,
        traits: ["friendly", "professional", "clear", "patient"],
        knowledge: [],
        examples: []
    )
    
    static let creative = Persona(
        name: "Creative Writer",
        description: "A creative and imaginative storyteller",
        systemPrompt: "You are a creative writer with a vivid imagination. Help users with creative writing, storytelling, and brainstorming ideas.",
        temperature: 0.9,
        traits: ["imaginative", "descriptive", "engaging", "original"],
        knowledge: ["literature", "storytelling techniques", "creative writing"],
        examples: []
    )
    
    static let technical = Persona(
        name: "Technical Expert",
        description: "A precise technical advisor",
        systemPrompt: "You are a technical expert who provides accurate, detailed technical information. Focus on precision and clarity.",
        temperature: 0.3,
        traits: ["precise", "analytical", "thorough", "logical"],
        knowledge: ["programming", "technology", "engineering", "mathematics"],
        examples: []
    )
}

struct ConversationExample: Codable {
    let userInput: String
    let assistantResponse: String
}
