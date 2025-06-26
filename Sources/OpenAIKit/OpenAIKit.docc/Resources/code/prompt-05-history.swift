import OpenAIKit
import Foundation

// MARK: - Prompt History Manager

class PromptHistoryManager {
    struct PromptEntry: Codable {
        let id: UUID
        let prompt: String
        let timestamp: Date
        let imageURLs: [String]
        var isFavorite: Bool
        let parameters: ImageParameters
        
        struct ImageParameters: Codable {
            let size: String
            let quality: String
            let style: String?
        }
    }
    
    private var history: [PromptEntry] = []
    private let maxHistorySize = 100
    private let storageKey = "prompt_history"
    
    func add(prompt: String, imageURLs: [URL], size: String, quality: String, style: String? = nil) {
        let entry = PromptEntry(
            id: UUID(),
            prompt: prompt,
            timestamp: Date(),
            imageURLs: imageURLs.map { $0.absoluteString },
            isFavorite: false,
            parameters: .init(size: size, quality: quality, style: style)
        )
        
        history.insert(entry, at: 0)
        
        // Maintain max size
        if history.count > maxHistorySize {
            history.removeLast()
        }
        
        saveHistory()
    }
    
    func toggleFavorite(id: UUID) {
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].isFavorite.toggle()
            saveHistory()
        }
    }
    
    func search(query: String) -> [PromptEntry] {
        let lowercasedQuery = query.lowercased()
        return history.filter { entry in
            entry.prompt.lowercased().contains(lowercasedQuery)
        }
    }
    
    func getFavorites() -> [PromptEntry] {
        history.filter { $0.isFavorite }
    }
    
    func getRecent(limit: Int = 10) -> [PromptEntry] {
        Array(history.prefix(limit))
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([PromptEntry].self, from: data) {
            history = decoded
        }
    }
}

// Usage example
let historyManager = PromptHistoryManager()
historyManager.loadHistory()

// After generating an image
historyManager.add(
    prompt: "A futuristic city at night",
    imageURLs: [URL(string: "https://example.com/image.png")!],
    size: "1024x1024",
    quality: "hd"
)