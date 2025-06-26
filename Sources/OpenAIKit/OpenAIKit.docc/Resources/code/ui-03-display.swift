import SwiftUI
import OpenAIKit

// MARK: - Image Display View

struct ImageDisplayView: View {
    let imageURL: URL
    @State private var isLoading = true
    @State private var loadedImage: UIImage?
    @State private var error: Error?
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading image...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .shadow(radius: 5)
            } else if error != nil {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("Failed to load image")
                        .font(.headline)
                }
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.loadedImage = image
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Image Grid View

struct ImageGridView: View {
    let images: [URL]
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(images, id: \.self) { imageURL in
                    ImageDisplayView(imageURL: imageURL)
                        .frame(height: 200)
                }
            }
            .padding()
        }
    }
}