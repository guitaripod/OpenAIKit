import SwiftUI
import OpenAIKit

// MARK: - Image Gallery View

struct ImageGalleryView: View {
    @StateObject private var viewModel = ImageGalleryViewModel()
    @State private var selectedImage: GeneratedImage?
    @State private var showingDetail = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.images.isEmpty {
                    EmptyStateView()
                } else {
                    ImageCollectionView(
                        images: viewModel.images,
                        onSelect: { image in
                            selectedImage = image
                            showingDetail = true
                        },
                        onDelete: viewModel.deleteImage
                    )
                }
            }
            .navigationTitle("Image Gallery")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Sort by Date") {
                            viewModel.sortBy(.date)
                        }
                        Button("Sort by Favorites") {
                            viewModel.sortBy(.favorites)
                        }
                        Divider()
                        Button("Clear All", role: .destructive) {
                            viewModel.clearAll()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingDetail) {
                if let image = selectedImage {
                    ImageDetailView(image: image)
                }
            }
        }
    }
}

// MARK: - Generated Image Model

struct GeneratedImage: Identifiable {
    let id = UUID()
    let url: URL
    let prompt: String
    let createdAt: Date
    var isFavorite: Bool = false
    let size: String
    let style: String?
}

// MARK: - Gallery View Model

class ImageGalleryViewModel: ObservableObject {
    @Published var images: [GeneratedImage] = []
    
    enum SortOption {
        case date, favorites
    }
    
    func addImage(_ image: GeneratedImage) {
        images.insert(image, at: 0)
    }
    
    func deleteImage(_ image: GeneratedImage) {
        images.removeAll { $0.id == image.id }
    }
    
    func toggleFavorite(_ image: GeneratedImage) {
        if let index = images.firstIndex(where: { $0.id == image.id }) {
            images[index].isFavorite.toggle()
        }
    }
    
    func sortBy(_ option: SortOption) {
        switch option {
        case .date:
            images.sort { $0.createdAt > $1.createdAt }
        case .favorites:
            images.sort { $0.isFavorite && !$1.isFavorite }
        }
    }
    
    func clearAll() {
        images.removeAll()
    }
}

// MARK: - Supporting Views

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No images yet")
                .font(.headline)
            Text("Generate some images to see them here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
}

struct ImageCollectionView: View {
    let images: [GeneratedImage]
    let onSelect: (GeneratedImage) -> Void
    let onDelete: (GeneratedImage) -> Void
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(images) { image in
                ImageThumbnailView(
                    image: image,
                    onTap: { onSelect(image) },
                    onDelete: { onDelete(image) }
                )
            }
        }
        .padding()
    }
}