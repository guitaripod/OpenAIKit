import SwiftUI
import OpenAIKit

// MARK: - Image History View

struct ImageHistoryView: View {
    @StateObject private var historyManager = ImageHistoryManager()
    @State private var searchText = ""
    @State private var showingFavoritesOnly = false
    
    var filteredHistory: [ImageHistoryEntry] {
        let items = showingFavoritesOnly ? historyManager.favorites : historyManager.history
        
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { entry in
                entry.prompt.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search and Filter Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search prompts...", text: $searchText)
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    Toggle(isOn: $showingFavoritesOnly) {
                        Image(systemName: showingFavoritesOnly ? "star.fill" : "star")
                            .foregroundColor(showingFavoritesOnly ? .yellow : .gray)
                    }
                    .toggleStyle(ButtonToggleStyle())
                }
                .padding(.horizontal)
                
                // History List
                if filteredHistory.isEmpty {
                    Spacer()
                    EmptyHistoryView(showingFavorites: showingFavoritesOnly)
                    Spacer()
                } else {
                    List {
                        ForEach(filteredHistory) { entry in
                            HistoryRowView(
                                entry: entry,
                                onFavoriteToggle: {
                                    historyManager.toggleFavorite(entry.id)
                                },
                                onReuse: {
                                    reusePrompt(entry)
                                }
                            )
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                historyManager.deleteEntry(filteredHistory[index].id)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All") {
                        historyManager.clearHistory()
                    }
                    .disabled(historyManager.history.isEmpty)
                }
            }
        }
        .onAppear {
            historyManager.loadHistory()
        }
    }
    
    private func reusePrompt(_ entry: ImageHistoryEntry) {
        // Navigate to image generation with pre-filled prompt
        // This would typically trigger navigation or update shared state
        print("Reusing prompt: \(entry.prompt)")
    }
}

// MARK: - History Entry Model

struct ImageHistoryEntry: Identifiable, Codable {
    let id: UUID
    let prompt: String
    let imageURLs: [String]
    let timestamp: Date
    var isFavorite: Bool
    let parameters: ImageParameters
    
    struct ImageParameters: Codable {
        let size: String
        let quality: String
        let style: String?
        let model: String
    }
}

// MARK: - History Manager

class ImageHistoryManager: ObservableObject {
    @Published var history: [ImageHistoryEntry] = []
    
    var favorites: [ImageHistoryEntry] {
        history.filter { $0.isFavorite }
    }
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "imageGenerationHistory"
    
    func addEntry(_ entry: ImageHistoryEntry) {
        history.insert(entry, at: 0)
        saveHistory()
    }
    
    func toggleFavorite(_ id: UUID) {
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].isFavorite.toggle()
            saveHistory()
        }
    }
    
    func deleteEntry(_ id: UUID) {
        history.removeAll { $0.id == id }
        saveHistory()
    }
    
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }
    
    func loadHistory() {
        if let data = userDefaults.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([ImageHistoryEntry].self, from: data) {
            history = decoded
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            userDefaults.set(encoded, forKey: historyKey)
        }
    }
}

// MARK: - Supporting Views

struct HistoryRowView: View {
    let entry: ImageHistoryEntry
    let onFavoriteToggle: () -> Void
    let onReuse: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.prompt)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                Button(action: onFavoriteToggle) {
                    Image(systemName: entry.isFavorite ? "star.fill" : "star")
                        .foregroundColor(entry.isFavorite ? .yellow : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            HStack {
                Label(entry.parameters.size, systemImage: "aspectratio")
                Label(entry.parameters.quality.uppercased(), systemImage: "sparkles")
                if let style = entry.parameters.style {
                    Label(style, systemImage: "paintbrush")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            HStack {
                Text(entry.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Reuse") {
                    onReuse()
                }
                .font(.caption)
                .buttonStyle(BorderedButtonStyle())
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyHistoryView: View {
    let showingFavorites: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: showingFavorites ? "star.slash" : "clock.arrow.circlepath")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(showingFavorites ? "No favorite prompts" : "No history yet")
                .font(.headline)
            
            Text(showingFavorites ? "Star your favorite prompts to see them here" : "Your generated images will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct ButtonToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            configuration.label
        }
        .buttonStyle(PlainButtonStyle())
    }
}