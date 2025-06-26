// StreamCache.swift
import Foundation

class StreamCache {
    private var cache: [String: CachedStream] = [:]
    private let maxCacheSize = 100
    private let cacheLifetime: TimeInterval = 3600 // 1 hour
    
    struct CachedStream {
        let content: String
        let timestamp: Date
        let metadata: [String: Any]
    }
    
    func store(key: String, content: String, metadata: [String: Any] = [:]) {
        cache[key] = CachedStream(
            content: content,
            timestamp: Date(),
            metadata: metadata
        )
        
        // Clean old entries if cache is too large
        if cache.count > maxCacheSize {
            cleanOldEntries()
        }
    }
    
    func retrieve(key: String) -> String? {
        guard let cached = cache[key] else { return nil }
        
        // Check if cache is still valid
        if Date().timeIntervalSince(cached.timestamp) > cacheLifetime {
            cache.removeValue(forKey: key)
            return nil
        }
        
        return cached.content
    }
    
    private func cleanOldEntries() {
        let cutoffDate = Date().addingTimeInterval(-cacheLifetime)
        cache = cache.filter { $0.value.timestamp > cutoffDate }
    }
}
