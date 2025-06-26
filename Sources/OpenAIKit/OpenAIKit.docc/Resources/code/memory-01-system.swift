// MemorySystem.swift
import Foundation

protocol MemoryStore {
    func store(key: String, value: Any) async
    func retrieve(key: String) async -> Any?
    func search(query: String) async -> [MemoryItem]
    func clear() async
}

struct MemoryItem: Identifiable {
    let id = UUID()
    let key: String
    let value: String
    let timestamp: Date
    let metadata: [String: Any]
    let relevanceScore: Double?
}

class SimpleMemoryStore: MemoryStore {
    private var memories: [String: MemoryItem] = [:]
    
    func store(key: String, value: Any) async {
        let item = MemoryItem(
            key: key,
            value: String(describing: value),
            timestamp: Date(),
            metadata: [:],
            relevanceScore: nil
        )
        memories[key] = item
    }
    
    func retrieve(key: String) async -> Any? {
        memories[key]?.value
    }
    
    func search(query: String) async -> [MemoryItem] {
        memories.values.filter { item in
            item.key.localizedCaseInsensitiveContains(query) ||
            item.value.localizedCaseInsensitiveContains(query)
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    func clear() async {
        memories.removeAll()
    }
}