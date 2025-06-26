import SwiftUI
import OpenAIKit

// MARK: - Variation Comparison View

struct VariationComparisonView: View {
    let originalImage: UIImage
    @State private var variations: [VariationResult] = []
    @State private var isGenerating = false
    @State private var selectedVariation: VariationResult?
    @State private var comparisonMode: ComparisonMode = .sideBySide
    
    enum ComparisonMode {
        case sideBySide
        case overlay
        case grid
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Comparison Mode Picker
                Picker("View Mode", selection: $comparisonMode) {
                    Text("Side by Side").tag(ComparisonMode.sideBySide)
                    Text("Overlay").tag(ComparisonMode.overlay)
                    Text("Grid").tag(ComparisonMode.grid)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Comparison View
                Group {
                    switch comparisonMode {
                    case .sideBySide:
                        SideBySideView(
                            original: originalImage,
                            variations: variations,
                            selected: $selectedVariation
                        )
                    case .overlay:
                        OverlayComparisonView(
                            original: originalImage,
                            variations: variations,
                            selected: $selectedVariation
                        )
                    case .grid:
                        GridComparisonView(
                            original: originalImage,
                            variations: variations,
                            selected: $selectedVariation
                        )
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Action Bar
                HStack {
                    Button(action: generateVariations) {
                        Label("Generate Variations", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isGenerating)
                    
                    if let selected = selectedVariation {
                        Button(action: { saveVariation(selected) }) {
                            Label("Save", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle("Image Variations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        shareVariations()
                    }
                    .disabled(variations.isEmpty)
                }
            }
        }
    }
    
    private func generateVariations() {
        isGenerating = true
        
        Task {
            do {
                // Generate variations using OpenAIKit
                let results = try await createVariations(from: originalImage)
                
                await MainActor.run {
                    self.variations = results
                    self.isGenerating = false
                    
                    // Auto-select first variation
                    if let first = results.first {
                        self.selectedVariation = first
                    }
                }
            } catch {
                await MainActor.run {
                    self.isGenerating = false
                    // Handle error
                }
            }
        }
    }
    
    private func saveVariation(_ variation: VariationResult) {
        // Save to photo library
        UIImageWriteToSavedPhotosAlbum(variation.image, nil, nil, nil)
    }
    
    private func shareVariations() {
        let images = [originalImage] + variations.map { $0.image }
        let activityController = UIActivityViewController(
            activityItems: images,
            applicationActivities: nil
        )
        
        // Present the activity controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityController, animated: true)
        }
    }
}

// MARK: - Variation Result Model

struct VariationResult: Identifiable {
    let id = UUID()
    let image: UIImage
    let similarity: Double  // Similarity score to original
    let metadata: VariationMetadata
    
    struct VariationMetadata {
        let generatedAt: Date
        let processingTime: TimeInterval
        let size: CGSize
    }
}

// MARK: - Comparison Views

struct SideBySideView: View {
    let original: UIImage
    let variations: [VariationResult]
    @Binding var selected: VariationResult?
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 16) {
                // Original Image
                VStack {
                    Text("Original")
                        .font(.headline)
                    Image(uiImage: original)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(8)
                }
                .frame(width: geometry.size.width / 2 - 20)
                
                // Selected Variation
                if let selected = selected {
                    VStack {
                        Text("Variation")
                            .font(.headline)
                        Image(uiImage: selected.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(8)
                        
                        Text("Similarity: \(selected.similarity, specifier: "%.1f")%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: geometry.size.width / 2 - 20)
                }
            }
            .padding()
        }
    }
}

struct OverlayComparisonView: View {
    let original: UIImage
    let variations: [VariationResult]
    @Binding var selected: VariationResult?
    @State private var opacity: Double = 0.5
    
    var body: some View {
        VStack {
            ZStack {
                Image(uiImage: original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                
                if let selected = selected {
                    Image(uiImage: selected.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .opacity(opacity)
                }
            }
            .cornerRadius(12)
            .padding()
            
            // Opacity Slider
            VStack {
                Text("Variation Opacity")
                    .font(.headline)
                Slider(value: $opacity, in: 0...1)
                    .padding(.horizontal)
            }
            .padding()
        }
    }
}

struct GridComparisonView: View {
    let original: UIImage
    let variations: [VariationResult]
    @Binding var selected: VariationResult?
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                // Original
                VStack {
                    Image(uiImage: original)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 3)
                        )
                    Text("Original")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                
                // Variations
                ForEach(variations) { variation in
                    VStack {
                        Image(uiImage: variation.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        selected?.id == variation.id ? Color.green : Color.clear,
                                        lineWidth: 3
                                    )
                            )
                            .onTapGesture {
                                selected = variation
                            }
                        Text("Var \(variations.firstIndex(where: { $0.id == variation.id })! + 1)")
                            .font(.caption)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Helper Functions

private func createVariations(from image: UIImage) async throws -> [VariationResult] {
    // This would use the actual OpenAIKit implementation
    // Placeholder for demonstration
    return []
}