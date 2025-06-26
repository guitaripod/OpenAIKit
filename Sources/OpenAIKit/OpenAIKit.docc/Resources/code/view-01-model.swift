// WeatherAssistantView.swift
import SwiftUI

struct WeatherAssistantView: View {
    @StateObject private var assistant: WeatherAssistant
    @State private var inputText = ""
    
    init(openAI: OpenAIKit) {
        _assistant = StateObject(wrappedValue: WeatherAssistant(openAI: openAI))
    }
    
    var body: some View {
        VStack {
            Text("Weather Assistant")
                .font(.title)
        }
    }
}