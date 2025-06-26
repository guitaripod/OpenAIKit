import Foundation
import OpenAIKit

extension SemanticSearchEngine {
    /// Caching system for performance optimization
    class CacheManager {
        private var embeddingCache: LRUCache<String, [Double]>
        private var queryCache: LRUCache<String, [SearchResult]>
        private var ttlCache: TTLCache<String, Any>
        
        init(maxSize: Int = 1000) {
            self.embeddingCache = LRUCache(maxSize: maxSize)
            self.queryCache = LRUCache(maxSize: maxSize / 2)
            self.ttlCache = TTLCache()
        }
        
        /// Cache embedding with content-based key
        func cacheEmbedding(for text: String, embedding: [Double]) {
            let key = generateCacheKey(text)
            embeddingCache.set(key, value: embedding)
        }
        
        /// Retrieve cached embedding
        func getCachedEmbedding(for text: String) -> [Double]? {
            let key = generateCacheKey(text)
            return embeddingCache.get(key)
        }
        
        /// Cache search results
        func cacheSearchResults(query: String, results: [SearchResult], ttl: TimeInterval = 300) {
            let key = generateCacheKey(query)
            queryCache.set(key, value: results)
            ttlCache.set(key, value: results, ttl: ttl)
        }
        
        /// Get cached search results
        func getCachedSearchResults(query: String) -> [SearchResult]? {
            let key = generateCacheKey(query)
            
            // Check if TTL is still valid
            if ttlCache.get(key) != nil {
                return queryCache.get(key)
            }
            
            // TTL expired, remove from query cache
            queryCache.remove(key)
            return nil
        }
        
        /// Generate cache key from text
        private func generateCacheKey(_ text: String) -> String {
            // Simple hash function for demo - use proper hashing in production
            let normalized = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return String(normalized.hashValue)
        }
        
        /// Clear all caches
        func clearAll() {
            embeddingCache.clear()
            queryCache.clear()
            ttlCache.clear()
        }
        
        /// Get cache statistics
        func getStats() -> CacheStats {
            CacheStats(
                embeddingCacheSize: embeddingCache.count,
                queryCacheSize: queryCache.count,
                ttlCacheSize: ttlCache.count,
                embeddingHitRate: embeddingCache.hitRate,
                queryHitRate: queryCache.hitRate
            )
        }
    }
    
    /// LRU (Least Recently Used) Cache implementation
    class LRUCache<Key: Hashable, Value> {
        private var cache: [Key: Node] = [:]
        private var head = Node()
        private var tail = Node()
        private let maxSize: Int
        private var currentSize = 0
        
        private var hits = 0
        private var misses = 0
        
        var count: Int { currentSize }
        var hitRate: Double {
            let total = hits + misses
            return total > 0 ? Double(hits) / Double(total) : 0
        }
        
        private class Node {
            var key: Key?
            var value: Value?
            var prev: Node?
            var next: Node?
        }
        
        init(maxSize: Int) {
            self.maxSize = maxSize
            head.next = tail
            tail.prev = head
        }
        
        func get(_ key: Key) -> Value? {
            if let node = cache[key] {
                hits += 1
                moveToHead(node)
                return node.value
            }
            misses += 1
            return nil
        }
        
        func set(_ key: Key, value: Value) {
            if let node = cache[key] {
                node.value = value
                moveToHead(node)
            } else {
                let newNode = Node()
                newNode.key = key
                newNode.value = value
                
                cache[key] = newNode
                addToHead(newNode)
                currentSize += 1
                
                if currentSize > maxSize {
                    if let tailNode = removeTail() {
                        cache.removeValue(forKey: tailNode.key!)
                        currentSize -= 1
                    }
                }
            }
        }
        
        func remove(_ key: Key) {
            if let node = cache[key] {
                removeNode(node)
                cache.removeValue(forKey: key)
                currentSize -= 1
            }
        }
        
        func clear() {
            cache.removeAll()
            head.next = tail
            tail.prev = head
            currentSize = 0
            hits = 0
            misses = 0
        }
        
        private func addToHead(_ node: Node) {
            node.prev = head
            node.next = head.next
            head.next?.prev = node
            head.next = node
        }
        
        private func removeNode(_ node: Node) {
            node.prev?.next = node.next
            node.next?.prev = node.prev
        }
        
        private func moveToHead(_ node: Node) {
            removeNode(node)
            addToHead(node)
        }
        
        private func removeTail() -> Node? {
            guard let node = tail.prev, node !== head else { return nil }
            removeNode(node)
            return node
        }
    }
    
    /// TTL (Time To Live) Cache
    class TTLCache<Key: Hashable, Value> {
        private var cache: [Key: (value: Value, expiry: Date)] = [:]
        private let queue = DispatchQueue(label: "ttl-cache", attributes: .concurrent)
        
        var count: Int {
            queue.sync { cache.count }
        }
        
        func set(_ key: Key, value: Value, ttl: TimeInterval) {
            let expiry = Date().addingTimeInterval(ttl)
            queue.async(flags: .barrier) {
                self.cache[key] = (value, expiry)
            }
            
            // Schedule cleanup
            DispatchQueue.global().asyncAfter(deadline: .now() + ttl) { [weak self] in
                self?.removeIfExpired(key)
            }
        }
        
        func get(_ key: Key) -> Value? {
            queue.sync {
                guard let item = cache[key] else { return nil }
                
                if item.expiry > Date() {
                    return item.value
                } else {
                    return nil
                }
            }
        }
        
        func clear() {
            queue.async(flags: .barrier) {
                self.cache.removeAll()
            }
        }
        
        private func removeIfExpired(_ key: Key) {
            queue.async(flags: .barrier) {
                if let item = self.cache[key], item.expiry <= Date() {
                    self.cache.removeValue(forKey: key)
                }
            }
        }
    }
    
    struct CacheStats {
        let embeddingCacheSize: Int
        let queryCacheSize: Int
        let ttlCacheSize: Int
        let embeddingHitRate: Double
        let queryHitRate: Double
    }
}

// Extension to integrate caching with search engine
extension SemanticSearchEngine {
    /// Search with caching enabled
    func searchWithCache(
        query: String,
        limit: Int = 10,
        useCache: Bool = true
    ) async throws -> [SearchResult] {
        let cacheManager = CacheManager()
        
        // Check query cache first
        if useCache, let cachedResults = cacheManager.getCachedSearchResults(query: query) {
            print("Cache hit for query: \(query)")
            return cachedResults
        }
        
        // Check embedding cache for query
        let queryEmbedding: [Double]
        if useCache, let cachedEmbedding = cacheManager.getCachedEmbedding(for: query) {
            print("Cache hit for query embedding")
            queryEmbedding = cachedEmbedding
        } else {
            queryEmbedding = try await generateEmbedding(for: query)
            if useCache {
                cacheManager.cacheEmbedding(for: query, embedding: queryEmbedding)
            }
        }
        
        // Perform search
        let results = try await search(query: query, limit: limit)
        
        // Cache results
        if useCache {
            cacheManager.cacheSearchResults(query: query, results: results)
        }
        
        return results
    }
}

// Example usage
Task {
    let engine = SemanticSearchEngine(apiKey: "your-api-key")
    let cacheManager = SemanticSearchEngine.CacheManager(maxSize: 100)
    
    // First search - will miss cache
    let results1 = try await engine.searchWithCache(
        query: "machine learning tutorials",
        useCache: true
    )
    
    // Second search with same query - will hit cache
    let results2 = try await engine.searchWithCache(
        query: "machine learning tutorials",
        useCache: true
    )
    
    // Get cache statistics
    let stats = cacheManager.getStats()
    print("Cache Stats:")
    print("  Embedding cache size: \(stats.embeddingCacheSize)")
    print("  Query cache size: \(stats.queryCacheSize)")
    print("  Embedding hit rate: \(stats.embeddingHitRate * 100)%")
    print("  Query hit rate: \(stats.queryHitRate * 100)%")
}