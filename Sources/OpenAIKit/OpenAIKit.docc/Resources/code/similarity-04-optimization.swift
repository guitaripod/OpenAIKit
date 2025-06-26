import Foundation
import Accelerate
import simd

// MARK: - Similarity Optimization

class SimilarityOptimizer {
    
    // Optimized batch cosine similarity using SIMD
    static func batchCosineSimilaritySIMD(
        query: [Float],
        candidates: [[Float]]
    ) -> [Float] {
        let queryNorm = sqrt(vDSP.sum(vDSP.multiply(query, query)))
        let normalizedQuery = vDSP.divide(query, queryNorm)
        
        var similarities = [Float](repeating: 0, count: candidates.count)
        
        candidates.enumerated().forEach { index, candidate in
            let candidateNorm = sqrt(vDSP.sum(vDSP.multiply(candidate, candidate)))
            let normalizedCandidate = vDSP.divide(candidate, candidateNorm)
            
            similarities[index] = vDSP.dot(normalizedQuery, normalizedCandidate)
        }
        
        return similarities
    }
    
    // Approximate nearest neighbor search using LSH
    class LSHIndex {
        private let numHashTables: Int
        private let numHashFunctions: Int
        private let dimensions: Int
        private var hashTables: [[Int: [Int]]]
        private var randomVectors: [[[Float]]]
        
        init(dimensions: Int, numHashTables: Int = 10, numHashFunctions: Int = 8) {
            self.dimensions = dimensions
            self.numHashTables = numHashTables
            self.numHashFunctions = numHashFunctions
            self.hashTables = Array(repeating: [:], count: numHashTables)
            self.randomVectors = []
            
            // Generate random projection vectors
            for _ in 0..<numHashTables {
                var tableVectors: [[Float]] = []
                for _ in 0..<numHashFunctions {
                    let vector = (0..<dimensions).map { _ in Float.random(in: -1...1) }
                    tableVectors.append(vector)
                }
                randomVectors.append(tableVectors)
            }
        }
        
        func index(vectors: [[Float]]) {
            for (idx, vector) in vectors.enumerated() {
                for tableIdx in 0..<numHashTables {
                    let hashValue = computeHash(vector: vector, tableIndex: tableIdx)
                    if hashTables[tableIdx][hashValue] == nil {
                        hashTables[tableIdx][hashValue] = []
                    }
                    hashTables[tableIdx][hashValue]?.append(idx)
                }
            }
        }
        
        func query(vector: [Float], maxCandidates: Int = 100) -> [Int] {
            var candidates = Set<Int>()
            
            for tableIdx in 0..<numHashTables {
                let hashValue = computeHash(vector: vector, tableIndex: tableIdx)
                if let bucket = hashTables[tableIdx][hashValue] {
                    candidates.formUnion(bucket)
                }
                
                if candidates.count >= maxCandidates {
                    break
                }
            }
            
            return Array(candidates)
        }
        
        private func computeHash(vector: [Float], tableIndex: Int) -> Int {
            var hashBits = 0
            let projectionVectors = randomVectors[tableIndex]
            
            for (i, projVector) in projectionVectors.enumerated() {
                let dotProduct = vDSP.dot(vector, projVector)
                if dotProduct > 0 {
                    hashBits |= (1 << i)
                }
            }
            
            return hashBits
        }
    }
    
    // Product quantization for memory-efficient similarity search
    class ProductQuantizer {
        private let numSubvectors: Int
        private let numCentroids: Int
        private var codebooks: [[[Float]]]
        private let subvectorSize: Int
        
        init(dimensions: Int, numSubvectors: Int = 8, numCentroids: Int = 256) {
            self.numSubvectors = numSubvectors
            self.numCentroids = numCentroids
            self.subvectorSize = dimensions / numSubvectors
            self.codebooks = []
        }
        
        func train(vectors: [[Float]]) {
            codebooks = []
            
            for i in 0..<numSubvectors {
                // Extract subvectors
                let subvectors = vectors.map { vector in
                    Array(vector[i*subvectorSize..<(i+1)*subvectorSize])
                }
                
                // Run k-means on subvectors
                let clustering = SimilarityClustering()
                let result = clustering.kMeansClustering(
                    embeddings: subvectors,
                    k: numCentroids
                )
                
                codebooks.append(result.centroids)
            }
        }
        
        func encode(vector: [Float]) -> [Int] {
            var codes: [Int] = []
            
            for i in 0..<numSubvectors {
                let subvector = Array(vector[i*subvectorSize..<(i+1)*subvectorSize])
                
                // Find nearest centroid
                var minDistance = Float.infinity
                var bestCode = 0
                
                for (j, centroid) in codebooks[i].enumerated() {
                    let distance = SimilarityCalculator.euclideanDistance(subvector, centroid)
                    if distance < minDistance {
                        minDistance = distance
                        bestCode = j
                    }
                }
                
                codes.append(bestCode)
            }
            
            return codes
        }
        
        func decode(codes: [Int]) -> [Float] {
            var vector: [Float] = []
            
            for (i, code) in codes.enumerated() {
                vector.append(contentsOf: codebooks[i][code])
            }
            
            return vector
        }
        
        func approximateDistance(codes1: [Int], codes2: [Int]) -> Float {
            var distance: Float = 0
            
            for i in 0..<numSubvectors {
                let centroid1 = codebooks[i][codes1[i]]
                let centroid2 = codebooks[i][codes2[i]]
                distance += SimilarityCalculator.euclideanDistance(centroid1, centroid2)
            }
            
            return distance
        }
    }
    
    // Inverted index for efficient similarity search
    class InvertedIndex {
        private var index: [String: Set<Int>] = [:]
        private var documentVectors: [[Float]] = []
        private var documentTokens: [[String]] = []
        
        func addDocument(id: Int, tokens: [String], vector: [Float]) {
            if id >= documentVectors.count {
                documentVectors.append(vector)
                documentTokens.append(tokens)
            } else {
                documentVectors[id] = vector
                documentTokens[id] = tokens
            }
            
            for token in tokens {
                if index[token] == nil {
                    index[token] = Set<Int>()
                }
                index[token]?.insert(id)
            }
        }
        
        func search(
            queryTokens: [String],
            queryVector: [Float],
            topK: Int = 10,
            hybridWeight: Float = 0.5
        ) -> [(id: Int, score: Float)] {
            // Get candidate documents using inverted index
            var candidates = Set<Int>()
            for token in queryTokens {
                if let docs = index[token] {
                    candidates.formUnion(docs)
                }
            }
            
            // Score candidates using hybrid approach
            var scores: [(id: Int, score: Float)] = []
            
            for candidateId in candidates {
                // BM25 score
                let bm25Score = calculateBM25Score(
                    queryTokens: queryTokens,
                    documentId: candidateId
                )
                
                // Vector similarity score
                let vectorScore = SimilarityCalculator.cosineSimilarity(
                    queryVector,
                    documentVectors[candidateId]
                )
                
                // Hybrid score
                let hybridScore = hybridWeight * vectorScore + (1 - hybridWeight) * bm25Score
                scores.append((candidateId, hybridScore))
            }
            
            // Sort and return top K
            return scores
                .sorted { $0.score > $1.score }
                .prefix(topK)
                .map { $0 }
        }
        
        private func calculateBM25Score(
            queryTokens: [String],
            documentId: Int
        ) -> Float {
            let k1: Float = 1.2
            let b: Float = 0.75
            let avgDocLength = Float(documentTokens.map { $0.count }.reduce(0, +)) / Float(documentTokens.count)
            let docLength = Float(documentTokens[documentId].count)
            
            var score: Float = 0
            
            for queryToken in queryTokens {
                let tf = Float(documentTokens[documentId].filter { $0 == queryToken }.count)
                let df = Float(index[queryToken]?.count ?? 0)
                let idf = log((Float(documentTokens.count) - df + 0.5) / (df + 0.5))
                
                let numerator = tf * (k1 + 1)
                let denominator = tf + k1 * (1 - b + b * docLength / avgDocLength)
                
                score += idf * numerator / denominator
            }
            
            return score
        }
    }
    
    // Caching layer for similarity computations
    class SimilarityCache {
        private var cache: [String: Float] = [:]
        private let maxSize: Int
        private var accessOrder: [String] = []
        
        init(maxSize: Int = 10000) {
            self.maxSize = maxSize
        }
        
        func get(key1: String, key2: String) -> Float? {
            let cacheKey = [key1, key2].sorted().joined(separator: ":")
            
            if let value = cache[cacheKey] {
                // Update access order
                accessOrder.removeAll { $0 == cacheKey }
                accessOrder.append(cacheKey)
                return value
            }
            
            return nil
        }
        
        func set(key1: String, key2: String, similarity: Float) {
            let cacheKey = [key1, key2].sorted().joined(separator: ":")
            
            // Evict if necessary
            if cache.count >= maxSize && cache[cacheKey] == nil {
                if let oldestKey = accessOrder.first {
                    cache.removeValue(forKey: oldestKey)
                    accessOrder.removeFirst()
                }
            }
            
            cache[cacheKey] = similarity
            accessOrder.append(cacheKey)
        }
        
        func clear() {
            cache.removeAll()
            accessOrder.removeAll()
        }
    }
}

// MARK: - Performance Monitoring

class SimilarityPerformanceMonitor {
    private var metrics: [PerformanceMetric] = []
    
    struct PerformanceMetric {
        let operation: String
        let itemCount: Int
        let dimensionCount: Int
        let executionTime: TimeInterval
        let memoryUsed: Int64
        
        var throughput: Double {
            Double(itemCount) / executionTime
        }
    }
    
    func measure<T>(
        operation: String,
        itemCount: Int,
        dimensionCount: Int,
        block: () throws -> T
    ) rethrows -> T {
        let startTime = Date()
        let startMemory = reportMemory()
        
        let result = try block()
        
        let executionTime = Date().timeIntervalSince(startTime)
        let memoryUsed = reportMemory() - startMemory
        
        let metric = PerformanceMetric(
            operation: operation,
            itemCount: itemCount,
            dimensionCount: dimensionCount,
            executionTime: executionTime,
            memoryUsed: memoryUsed
        )
        
        metrics.append(metric)
        
        return result
    }
    
    func generateReport() -> String {
        var report = "Similarity Performance Report\n"
        report += "============================\n\n"
        
        for metric in metrics.suffix(10) {  // Last 10 operations
            report += "Operation: \(metric.operation)\n"
            report += "Items: \(metric.itemCount), Dimensions: \(metric.dimensionCount)\n"
            report += "Time: \(String(format: "%.3f", metric.executionTime))s\n"
            report += "Throughput: \(String(format: "%.0f", metric.throughput)) items/s\n"
            report += "Memory: \(ByteCountFormatter.string(fromByteCount: metric.memoryUsed, countStyle: .memory))\n"
            report += "---\n"
        }
        
        return report
    }
    
    private func reportMemory() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}