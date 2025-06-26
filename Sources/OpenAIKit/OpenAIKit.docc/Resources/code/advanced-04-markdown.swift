// MarkdownStreamRenderer.swift
import SwiftUI

struct MarkdownStreamView: View {
    let text: String
    let isComplete: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(parseMarkdown(text), id: \.self) { element in
                    renderElement(element)
                }
                
                if !isComplete {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding()
        }
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownElement] {
        // Simple markdown parser
        var elements: [MarkdownElement] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            if line.hasPrefix("# ") {
                elements.append(.heading(String(line.dropFirst(2))))
            } else if line.hasPrefix("- ") {
                elements.append(.listItem(String(line.dropFirst(2))))
            } else if line.hasPrefix("```") {
                elements.append(.codeBlock(line))
            } else if !line.isEmpty {
                elements.append(.paragraph(line))
            }
        }
        
        return elements
    }
    
    @ViewBuilder
    private func renderElement(_ element: MarkdownElement) -> some View {
        switch element {
        case .heading(let text):
            Text(text)
                .font(.title2)
                .fontWeight(.bold)
        case .paragraph(let text):
            Text(text)
        case .listItem(let text):
            HStack(alignment: .top) {
                Text("•")
                Text(text)
            }
        case .codeBlock(let code):
            Text(code)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
        }
    }
}

enum MarkdownElement: Hashable {
    case heading(String)
    case paragraph(String)
    case listItem(String)
    case codeBlock(String)
}
