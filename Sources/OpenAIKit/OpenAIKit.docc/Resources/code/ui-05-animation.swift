// StreamingAnimation.swift
import SwiftUI

struct AnimatedStreamText: View {
    let text: String
    @State private var visibleCharacters = 0
    
    var body: some View {
        Text(String(text.prefix(visibleCharacters)))
            .onAppear {
                animateText()
            }
            .onChange(of: text) { _ in
                animateText()
            }
    }
    
    private func animateText() {
        visibleCharacters = 0
        
        for (index, _) in text.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.02) {
                if index < text.count {
                    visibleCharacters = index + 1
                }
            }
        }
    }
}

struct StreamingTextView: View {
    @Binding var text: String
    let isComplete: Bool
    
    var body: some View {
        HStack(alignment: .bottom) {
            if isComplete {
                Text(text)
            } else {
                AnimatedStreamText(text: text)
                
                // Blinking cursor
                Text("|")
                    .opacity(isComplete ? 0 : 1)
                    .animation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true))
            }
        }
    }
}
