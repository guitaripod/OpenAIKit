import Foundation
import Accelerate

// MARK: - K-Nearest Neighbor Search Implementation

/// Optimized KNN search with various distance metrics and algorithms
class KNNSearchEngine {
    enum DistanceMetric {
        case euclidean
        case cosine
        case manhattan
        case dot
        
        func calculate(_ a: [Float], _ b: [Float]) -> Float {
            switch self {
            case .euclidean:
                return euclideanDistance(a, b)
            case .cosine:
                return cosineDistance(a, b)
            case .manhattan:
                return manhattanDistance(a, b)
            case .dot:
                return dotProduct(a, b)
            }
        }
    }
    
    enum SearchAlgorithm {
        case bruteForce
        case approximateNearestNeighbor(numTrees: Int)
        case localitySensitiveHashing(numHashTables: Int)
        case hierarchicalNavigableSmallWorld
    }
    
    private let dimension: Int
    private let metric: DistanceMetric
    private let algorithm: SearchAlgorithm
    private var index: SearchIndex?
    
    init(
        dimension: Int,
        metric: DistanceMetric = .cosine,
        algorithm: SearchAlgorithm = .bruteForce
    ) {
        self.dimension = dimension
        self.metric = metric
        self.algorithm = algorithm
    }
    
    // MARK: - Index Building
    
    func buildIndex(from vectors: [(id: String, vector: [Float])]) async {
        switch algorithm {
        case .bruteForce:
            index = BruteForceIndex(vectors: vectors, metric: metric)
            
        case .approximateNearestNeighbor(let numTrees):
            index = await ANNIndex(
                vectors: vectors,
                metric: metric,
                numTrees: numTrees,
                dimension: dimension
            )
            
        case .localitySensitiveHashing(let numHashTables):
            index = LSHIndex(
                vectors: vectors,
                metric: metric,
                numHashTables: numHashTables,
                dimension: dimension
            )
            
        case .hierarchicalNavigableSmallWorld:
            index = await HNSWIndex(
                vectors: vectors,
                metric: metric,
                dimension: dimension
            )
        }
    }
    
    // MARK: - Search
    
    func search(
        query: [Float],
        k: Int,
        threshold: Float? = nil
    ) async -> [SearchResult] {
        guard let index = index else {
            return []
        }
        
        return await index.search(
            query: query,
            k: k,
            threshold: threshold
        )
    }
    
    // MARK: - Batch Search
    
    func batchSearch(
        queries: [[Float]],
        k: Int,
        threshold: Float? = nil
    ) async -> [[SearchResult]] {
        await withTaskGroup(of: [SearchResult].self) { group in
            for query in queries {
                group.addTask {
                    await self.search(query: query, k: k, threshold: threshold)
                }
            }
            
            var results: [[SearchResult]] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }
}

// MARK: - Search Index Protocol

protocol SearchIndex {
    func search(
        query: [Float],
        k: Int,
        threshold: Float?
    ) async -> [SearchResult]
}

struct SearchResult {
    let id: String
    let distance: Float
    let vector: [Float]?
}

// MARK: - Brute Force Index

class BruteForceIndex: SearchIndex {
    private let vectors: [(id: String, vector: [Float])]
    private let metric: KNNSearchEngine.DistanceMetric
    
    init(
        vectors: [(id: String, vector: [Float])],
        metric: KNNSearchEngine.DistanceMetric
    ) {
        self.vectors = vectors
        self.metric = metric
    }
    
    func search(
        query: [Float],
        k: Int,
        threshold: Float?
    ) async -> [SearchResult] {
        // Calculate distances to all vectors
        let distances = vectors.map { (id, vector) in
            (id: id, distance: metric.calculate(query, vector), vector: vector)
        }
        
        // Filter by threshold if provided
        let filtered = threshold.map { thresh in
            distances.filter { $0.distance <= thresh }
        } ?? distances
        
        // Sort by distance and take top k
        let sorted = filtered.sorted { $0.distance < $1.distance }
        let topK = Array(sorted.prefix(k))
        
        return topK.map { SearchResult(id: $0.id, distance: $0.distance, vector: $0.vector) }
    }
}

// MARK: - Approximate Nearest Neighbor Index

class ANNIndex: SearchIndex {
    private struct RandomProjectionTree {
        let hyperplane: [Float]
        let leftChild: TreeNode
        let rightChild: TreeNode
        
        enum TreeNode {
            case leaf(vectors: [(id: String, vector: [Float])])
            case internal(tree: RandomProjectionTree)
        }
    }
    
    private let trees: [RandomProjectionTree]
    private let metric: KNNSearchEngine.DistanceMetric
    
    init(
        vectors: [(id: String, vector: [Float])],
        metric: KNNSearchEngine.DistanceMetric,
        numTrees: Int,
        dimension: Int
    ) async {
        self.metric = metric
        
        // Build multiple random projection trees
        self.trees = await withTaskGroup(of: RandomProjectionTree.self) { group in
            for _ in 0..<numTrees {
                group.addTask {
                    self.buildTree(vectors: vectors, dimension: dimension)
                }
            }
            
            var trees: [RandomProjectionTree] = []
            for await tree in group {
                trees.append(tree)
            }
            return trees
        }
    }
    
    private func buildTree(
        vectors: [(id: String, vector: [Float])],
        dimension: Int,
        maxLeafSize: Int = 10
    ) -> RandomProjectionTree {
        // Base case: create leaf node
        if vectors.count <= maxLeafSize {
            return RandomProjectionTree(
                hyperplane: [],
                leftChild: .leaf(vectors: vectors),
                rightChild: .leaf(vectors: [])
            )
        }
        
        // Generate random hyperplane
        let hyperplane = (0..<dimension).map { _ in Float.random(in: -1...1) }
        
        // Normalize hyperplane
        let norm = sqrt(hyperplane.reduce(0) { $0 + $1 * $1 })
        let normalizedHyperplane = hyperplane.map { $0 / norm }
        
        // Split vectors based on hyperplane
        var leftVectors: [(id: String, vector: [Float])] = []
        var rightVectors: [(id: String, vector: [Float])] = []
        
        for (id, vector) in vectors {
            let dotProduct = zip(normalizedHyperplane, vector).reduce(0) { $0 + $1.0 * $1.1 }
            if dotProduct <= 0 {
                leftVectors.append((id, vector))
            } else {
                rightVectors.append((id, vector))
            }
        }
        
        // Recursively build subtrees
        let leftChild: RandomProjectionTree.TreeNode
        let rightChild: RandomProjectionTree.TreeNode
        
        if leftVectors.isEmpty {
            leftChild = .leaf(vectors: [])
        } else if leftVectors.count <= maxLeafSize {
            leftChild = .leaf(vectors: leftVectors)
        } else {
            leftChild = .internal(tree: buildTree(
                vectors: leftVectors,
                dimension: dimension,
                maxLeafSize: maxLeafSize
            ))
        }
        
        if rightVectors.isEmpty {
            rightChild = .leaf(vectors: [])
        } else if rightVectors.count <= maxLeafSize {
            rightChild = .leaf(vectors: rightVectors)
        } else {
            rightChild = .internal(tree: buildTree(
                vectors: rightVectors,
                dimension: dimension,
                maxLeafSize: maxLeafSize
            ))
        }
        
        return RandomProjectionTree(
            hyperplane: normalizedHyperplane,
            leftChild: leftChild,
            rightChild: rightChild
        )
    }
    
    func search(
        query: [Float],
        k: Int,
        threshold: Float?
    ) async -> [SearchResult] {
        // Collect candidates from all trees
        var candidates: Set<String> = []
        var candidateVectors: [(id: String, vector: [Float])] = []
        
        for tree in trees {
            let treeResults = searchTree(tree: tree, query: query, k: k * 2)
            for (id, vector) in treeResults {
                if !candidates.contains(id) {
                    candidates.insert(id)
                    candidateVectors.append((id, vector))
                }
            }
        }
        
        // Calculate exact distances for candidates
        let distances = candidateVectors.map { (id, vector) in
            (id: id, distance: metric.calculate(query, vector), vector: vector)
        }
        
        // Filter and sort
        let filtered = threshold.map { thresh in
            distances.filter { $0.distance <= thresh }
        } ?? distances
        
        let sorted = filtered.sorted { $0.distance < $1.distance }
        let topK = Array(sorted.prefix(k))
        
        return topK.map { SearchResult(id: $0.id, distance: $0.distance, vector: $0.vector) }
    }
    
    private func searchTree(
        tree: RandomProjectionTree,
        query: [Float],
        k: Int
    ) -> [(id: String, vector: [Float])] {
        var results: [(id: String, vector: [Float])] = []
        var nodesToVisit: [RandomProjectionTree.TreeNode] = []
        
        // Determine which side of hyperplane query falls on
        if !tree.hyperplane.isEmpty {
            let dotProduct = zip(tree.hyperplane, query).reduce(0) { $0 + $1.0 * $1.1 }
            
            // Visit the side containing the query first
            if dotProduct <= 0 {
                nodesToVisit.append(tree.leftChild)
                nodesToVisit.append(tree.rightChild)
            } else {
                nodesToVisit.append(tree.rightChild)
                nodesToVisit.append(tree.leftChild)
            }
        } else {
            nodesToVisit.append(tree.leftChild)
        }
        
        // Traverse tree
        while !nodesToVisit.isEmpty && results.count < k * 2 {
            let node = nodesToVisit.removeFirst()
            
            switch node {
            case .leaf(let vectors):
                results.append(contentsOf: vectors)
                
            case .internal(let subtree):
                let subtreeResults = searchTree(tree: subtree, query: query, k: k)
                results.append(contentsOf: subtreeResults)
            }
        }
        
        return Array(results.prefix(k * 2))
    }
}

// MARK: - Locality Sensitive Hashing Index

class LSHIndex: SearchIndex {
    private struct HashTable {
        let hashFunctions: [[Float]]
        var buckets: [Int: [(id: String, vector: [Float])]] = [:]
    }
    
    private var hashTables: [HashTable]
    private let metric: KNNSearchEngine.DistanceMetric
    private let dimension: Int
    
    init(
        vectors: [(id: String, vector: [Float])],
        metric: KNNSearchEngine.DistanceMetric,
        numHashTables: Int,
        dimension: Int
    ) {
        self.metric = metric
        self.dimension = dimension
        
        // Initialize hash tables
        self.hashTables = (0..<numHashTables).map { _ in
            let numHashFunctions = Int(log2(Double(dimension))) + 1
            let hashFunctions = (0..<numHashFunctions).map { _ in
                // Random projection vector
                (0..<dimension).map { _ in Float.random(in: -1...1) }
            }
            return HashTable(hashFunctions: hashFunctions)
        }
        
        // Insert all vectors
        for (id, vector) in vectors {
            insert(id: id, vector: vector)
        }
    }
    
    private func insert(id: String, vector: [Float]) {
        for i in 0..<hashTables.count {
            let hashValue = computeHash(
                vector: vector,
                hashFunctions: hashTables[i].hashFunctions
            )
            
            if hashTables[i].buckets[hashValue] == nil {
                hashTables[i].buckets[hashValue] = []
            }
            hashTables[i].buckets[hashValue]?.append((id, vector))
        }
    }
    
    private func computeHash(vector: [Float], hashFunctions: [[Float]]) -> Int {
        var hash = 0
        
        for (i, hashFunction) in hashFunctions.enumerated() {
            let dotProduct = zip(vector, hashFunction).reduce(0) { $0 + $1.0 * $1.1 }
            if dotProduct > 0 {
                hash |= (1 << i)
            }
        }
        
        return hash
    }
    
    func search(
        query: [Float],
        k: Int,
        threshold: Float?
    ) async -> [SearchResult] {
        var candidates: Set<String> = []
        var candidateVectors: [(id: String, vector: [Float])] = []
        
        // Query all hash tables
        for hashTable in hashTables {
            let hashValue = computeHash(
                vector: query,
                hashFunctions: hashTable.hashFunctions
            )
            
            // Check bucket and neighboring buckets
            for offset in -1...1 {
                if let bucket = hashTable.buckets[hashValue + offset] {
                    for (id, vector) in bucket {
                        if !candidates.contains(id) {
                            candidates.insert(id)
                            candidateVectors.append((id, vector))
                        }
                    }
                }
            }
        }
        
        // Calculate exact distances
        let distances = candidateVectors.map { (id, vector) in
            (id: id, distance: metric.calculate(query, vector), vector: vector)
        }
        
        // Filter and sort
        let filtered = threshold.map { thresh in
            distances.filter { $0.distance <= thresh }
        } ?? distances
        
        let sorted = filtered.sorted { $0.distance < $1.distance }
        let topK = Array(sorted.prefix(k))
        
        return topK.map { SearchResult(id: $0.id, distance: $0.distance, vector: $0.vector) }
    }
}

// MARK: - HNSW Index (Simplified)

class HNSWIndex: SearchIndex {
    private struct Node {
        let id: String
        let vector: [Float]
        var neighbors: [Int: Set<Int>] = [:]  // level -> neighbor indices
    }
    
    private var nodes: [Node] = []
    private let metric: KNNSearchEngine.DistanceMetric
    private let M = 16  // Max connections per layer
    private let efConstruction = 200  // Size of dynamic candidate list
    
    init(
        vectors: [(id: String, vector: [Float])],
        metric: KNNSearchEngine.DistanceMetric,
        dimension: Int
    ) async {
        self.metric = metric
        
        // Build HNSW graph
        for (id, vector) in vectors {
            await insert(id: id, vector: vector)
        }
    }
    
    private func insert(id: String, vector: [Float]) async {
        let newNode = Node(id: id, vector: vector)
        let nodeIndex = nodes.count
        nodes.append(newNode)
        
        if nodeIndex == 0 {
            return  // First node, nothing to connect
        }
        
        // Determine layer for new node
        let level = Int(-log(Float.random(in: 0..<1)) * Double(M))
        
        // Find nearest neighbors at each layer
        for layer in 0...level {
            let neighbors = await searchLayer(
                query: vector,
                entryPoint: 0,
                numClosest: M,
                layer: layer
            )
            
            // Add bidirectional connections
            nodes[nodeIndex].neighbors[layer] = Set(neighbors.prefix(M).map { $0.0 })
            
            for (neighborIndex, _) in neighbors.prefix(M) {
                if nodes[neighborIndex].neighbors[layer] == nil {
                    nodes[neighborIndex].neighbors[layer] = Set()
                }
                nodes[neighborIndex].neighbors[layer]?.insert(nodeIndex)
                
                // Prune connections if necessary
                if let neighborConnections = nodes[neighborIndex].neighbors[layer],
                   neighborConnections.count > M {
                    await pruneConnections(
                        nodeIndex: neighborIndex,
                        layer: layer,
                        maxConnections: M
                    )
                }
            }
        }
    }
    
    private func searchLayer(
        query: [Float],
        entryPoint: Int,
        numClosest: Int,
        layer: Int
    ) async -> [(Int, Float)] {
        var visited = Set<Int>()
        var candidates = [(index: entryPoint, distance: metric.calculate(query, nodes[entryPoint].vector))]
        var w = candidates
        
        visited.insert(entryPoint)
        
        while !candidates.isEmpty {
            let current = candidates.removeFirst()
            
            if current.distance > w.last!.distance {
                break
            }
            
            // Check neighbors
            if let neighbors = nodes[current.index].neighbors[layer] {
                for neighborIndex in neighbors {
                    if !visited.contains(neighborIndex) {
                        visited.insert(neighborIndex)
                        
                        let distance = metric.calculate(query, nodes[neighborIndex].vector)
                        
                        if distance < w.last!.distance || w.count < numClosest {
                            candidates.append((index: neighborIndex, distance: distance))
                            w.append((index: neighborIndex, distance: distance))
                            
                            // Sort and keep top numClosest
                            w.sort { $0.distance < $1.distance }
                            if w.count > numClosest {
                                w.removeLast()
                            }
                        }
                    }
                }
            }
            
            candidates.sort { $0.distance < $1.distance }
        }
        
        return w.map { ($0.index, $0.distance) }
    }
    
    private func pruneConnections(
        nodeIndex: Int,
        layer: Int,
        maxConnections: Int
    ) async {
        guard let connections = nodes[nodeIndex].neighbors[layer] else { return }
        
        // Get distances to all connected nodes
        let distances = connections.map { neighborIndex in
            (index: neighborIndex, distance: metric.calculate(
                nodes[nodeIndex].vector,
                nodes[neighborIndex].vector
            ))
        }
        
        // Keep only closest connections
        let sorted = distances.sorted { $0.distance < $1.distance }
        let keep = Set(sorted.prefix(maxConnections).map { $0.index })
        
        nodes[nodeIndex].neighbors[layer] = keep
    }
    
    func search(
        query: [Float],
        k: Int,
        threshold: Float?
    ) async -> [SearchResult] {
        guard !nodes.isEmpty else { return [] }
        
        // Multi-layer search starting from top layer
        var entryPoint = 0
        let topLayer = nodes[0].neighbors.keys.max() ?? 0
        
        // Search through layers
        for layer in stride(from: topLayer, to: 0, by: -1) {
            let layerResults = await searchLayer(
                query: query,
                entryPoint: entryPoint,
                numClosest: 1,
                layer: layer
            )
            
            if let closest = layerResults.first {
                entryPoint = closest.0
            }
        }
        
        // Final search at layer 0
        let results = await searchLayer(
            query: query,
            entryPoint: entryPoint,
            numClosest: k,
            layer: 0
        )
        
        // Convert to SearchResult
        let searchResults = results.compactMap { (index, distance) -> SearchResult? in
            if let threshold = threshold, distance > threshold {
                return nil
            }
            
            return SearchResult(
                id: nodes[index].id,
                distance: distance,
                vector: nodes[index].vector
            )
        }
        
        return Array(searchResults.prefix(k))
    }
}

// MARK: - Distance Functions

private func euclideanDistance(_ a: [Float], _ b: [Float]) -> Float {
    var sum: Float = 0
    vDSP_distancesq(a, 1, b, 1, &sum, vDSP_Length(min(a.count, b.count)))
    return sqrt(sum)
}

private func cosineDistance(_ a: [Float], _ b: [Float]) -> Float {
    var dotProduct: Float = 0
    var normA: Float = 0
    var normB: Float = 0
    
    vDSP_dotpr(a, 1, b, 1, &dotProduct, vDSP_Length(min(a.count, b.count)))
    vDSP_svesq(a, 1, &normA, vDSP_Length(a.count))
    vDSP_svesq(b, 1, &normB, vDSP_Length(b.count))
    
    normA = sqrt(normA)
    normB = sqrt(normB)
    
    guard normA > 0 && normB > 0 else { return 1.0 }
    
    let similarity = dotProduct / (normA * normB)
    return 1.0 - similarity
}

private func manhattanDistance(_ a: [Float], _ b: [Float]) -> Float {
    var diff = [Float](repeating: 0, count: min(a.count, b.count))
    vDSP_vsub(b, 1, a, 1, &diff, 1, vDSP_Length(diff.count))
    vDSP_vabs(diff, 1, &diff, 1, vDSP_Length(diff.count))
    
    var sum: Float = 0
    vDSP_sve(diff, 1, &sum, vDSP_Length(diff.count))
    
    return sum
}

private func dotProduct(_ a: [Float], _ b: [Float]) -> Float {
    var result: Float = 0
    vDSP_dotpr(a, 1, b, 1, &result, vDSP_Length(min(a.count, b.count)))
    return -result  // Negative because we want higher dot product = smaller distance
}