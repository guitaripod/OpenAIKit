// PromptBuilderView.swift
import SwiftUI

struct PromptBuilderView: View {
    @Binding var prompt: String
    @State private var selectedCategory: ImageCategory = .portrait
    @State private var selectedModifiers: Set<String> = []
    
    let styleManager = ImageStyleManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Build Your Prompt")
                .font(.headline)
            
            TextEditor(text: $prompt)
                .frame(height: 100)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            // Category selector
            Picker("Category", selection: $selectedCategory) {
                Text("Portrait").tag(ImageCategory.portrait)
                Text("Landscape").tag(ImageCategory.landscape)
                Text("Abstract").tag(ImageCategory.abstract)
                Text("Illustration").tag(ImageCategory.illustration)
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedCategory) { _ in
                updateModifiers()
            }
            
            // Modifier chips
            Text("Suggested Modifiers")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            FlowLayout {
                ForEach(styleManager.suggestModifiers(for: selectedCategory), id: \.self) { modifier in
                    ModifierChip(
                        text: modifier,
                        isSelected: selectedModifiers.contains(modifier)
                    ) {
                        toggleModifier(modifier)
                    }
                }
            }
            
            Button("Apply Modifiers") {
                applyModifiers()
            }
            .disabled(selectedModifiers.isEmpty)
        }
        .padding()
    }
    
    private func updateModifiers() {
        selectedModifiers.removeAll()
    }
    
    private func toggleModifier(_ modifier: String) {
        if selectedModifiers.contains(modifier) {
            selectedModifiers.remove(modifier)
        } else {
            selectedModifiers.insert(modifier)
        }
    }
    
    private func applyModifiers() {
        prompt = styleManager.enhancePrompt(prompt, with: Array(selectedModifiers))
    }
}

struct ModifierChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

struct FlowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // Simple flow layout implementation
        .zero
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // Simple flow layout implementation
    }
}
