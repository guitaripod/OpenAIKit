// PersonaSwitching.swift
import SwiftUI
import OpenAIKit

struct PersonaChatView: View {
    @StateObject private var chat: PersonaChat
    @State private var inputText = ""
    @State private var showPersonaPicker = false
    
    let availablePersonas: [Persona] = [.helpful, .creative, .technical]
    
    init(openAI: OpenAIKit) {
        _chat = StateObject(wrappedValue: PersonaChat(openAI: openAI))
    }
    
    var body: some View {
        VStack {
            // Header with persona selector
            HStack {
                Button(action: { showPersonaPicker.toggle() }) {
                    HStack {
                        Image(systemName: "person.circle")
                        Text(chat.currentPersona.name)
                    }
                }
                Spacer()
            }
            .padding()
            
            // Messages
            ScrollView {
                ForEach(chat.messages.filter { $0.role != .system }, id: \.content) { message in
                    MessageBubble(message: message)
                }
            }
            
            // Input
            HStack {
                TextField("Type a message...", text: $inputText)
                Button("Send") {
                    Task {
                        _ = try await chat.sendMessage(inputText)
                        inputText = ""
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showPersonaPicker) {
            PersonaPicker(
                personas: availablePersonas,
                selected: chat.currentPersona
            ) { persona in
                chat.switchPersona(to: persona)
                showPersonaPicker = false
            }
        }
    }
}

struct PersonaPicker: View {
    let personas: [Persona]
    let selected: Persona
    let onSelect: (Persona) -> Void
    
    var body: some View {
        NavigationView {
            List(personas) { persona in
                Button(action: { onSelect(persona) }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(persona.name)
                                .font(.headline)
                            Text(persona.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if persona.id == selected.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .navigationTitle("Choose Persona")
        }
    }
}
