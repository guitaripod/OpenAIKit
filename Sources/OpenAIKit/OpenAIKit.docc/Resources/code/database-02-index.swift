import Foundation
import CoreData

// MARK: - Vector Index Management

/// Index structure for efficient vector similarity search
class VectorIndex {
    private var indexMap: [String: IndexNode] = [:]
    private let dimension: Int
    private let maxPointsPerNode: Int
    private let queue = DispatchQueue(label: "vectordb.index", attributes: .concurrent)
    
    struct IndexNode {
        let centroid: [Float]
        var documentIds: Set<String>
        var children: [IndexNode]?
        let depth: Int
        
        var isLeaf: Bool {
            children == nil
        }
    }
    
    init(dimension: Int, maxPointsPerNode: Int = 100) {
        self.dimension = dimension
        self.maxPointsPerNode = maxPointsPerNode
    }
    
    // MARK: - Index Building
    
    func buildIndex(from documents: [(id: String, embedding: [Float])]) async {
        await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                // Clear existing index
                self.indexMap.removeAll()
                
                // Group documents by similarity for hierarchical indexing
                let rootNode = self.buildHierarchicalIndex(
                    documents: documents,
                    depth: 0
                )
                
                // Store nodes in flat map for fast access
                self.traverseAndStore(node: rootNode, prefix: "root")
                
                continuation.resume()
            }
        }
    }
    
    private func buildHierarchicalIndex(
        documents: [(id: String, embedding: [Float])],
        depth: Int
    ) -> IndexNode {
        // Calculate centroid of all documents
        let centroid = calculateCentroid(embeddings: documents.map { $0.embedding })
        
        // If few enough documents, create leaf node
        if documents.count <= maxPointsPerNode {
            return IndexNode(
                centroid: centroid,
                documentIds: Set(documents.map { $0.id }),
                children: nil,
                depth: depth
            )
        }
        
        // Otherwise, partition documents using k-means clustering
        let clusters = kMeansClustering(
            documents: documents,
            k: min(4, documents.count / maxPointsPerNode + 1)
        )
        
        // Recursively build child nodes
        let children = clusters.map { cluster in
            buildHierarchicalIndex(documents: cluster, depth: depth + 1)
        }
        
        return IndexNode(
            centroid: centroid,
            documentIds: Set(documents.map { $0.id }),
            children: children,
            depth: depth
        )
    }
    
    // MARK: - Search
    
    func search(
        queryVector: [Float],
        k: Int,
        pruningFactor: Float = 2.0
    ) async -> [String] {
        await withCheckedContinuation { continuation in
            queue.async {
                var candidates: [(id: String, distance: Float)] = []
                
                // Start from root and traverse index
                if let rootNode = self.indexMap["root"] {
                    self.searchNode(
                        node: rootNode,
                        queryVector: queryVector,
                        k: k,
                        pruningFactor: pruningFactor,
                        candidates: &candidates
                    )
                }
                
                // Sort by distance and return top k
                candidates.sort { $0.distance < $1.distance }
                let results = Array(candidates.prefix(k).map { $0.id })
                
                continuation.resume(returning: results)
            }
        }
    }
    
    private func searchNode(
        node: IndexNode,
        queryVector: [Float],
        k: Int,
        pruningFactor: Float,
        candidates: inout [(id: String, distance: Float)]
    ) {
        // Calculate distance to node centroid
        let centroidDistance = euclideanDistance(queryVector, node.centroid)
        
        if let children = node.children {
            // Internal node: search relevant children
            let childDistances = children.map { child in
                (child: child, distance: euclideanDistance(queryVector, child.centroid))
            }
            
            // Sort children by distance
            let sortedChildren = childDistances.sorted { $0.distance < $1.distance }
            
            // Search closest children first
            let searchLimit = Int(ceil(Double(children.count) / Double(pruningFactor)))
            for i in 0..<min(searchLimit, sortedChildren.count) {
                searchNode(
                    node: sortedChildren[i].child,
                    queryVector: queryVector,
                    k: k,
                    pruningFactor: pruningFactor,
                    candidates: &candidates
                )
            }
        } else {
            // Leaf node: add all documents as candidates
            for docId in node.documentIds {
                candidates.append((id: docId, distance: centroidDistance))
            }
        }
    }
    
    // MARK: - Index Persistence
    
    func saveIndex(to url: URL) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(IndexData(indexMap: indexMap))
        try data.write(to: url)
    }
    
    func loadIndex(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let indexData = try decoder.decode(IndexData.self, from: data)
        
        queue.async(flags: .barrier) {
            self.indexMap = indexData.indexMap
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateCentroid(embeddings: [[Float]]) -> [Float] {
        guard !embeddings.isEmpty else { return Array(repeating: 0, count: dimension) }
        
        var centroid = Array(repeating: Float(0), count: dimension)
        
        for embedding in embeddings {
            for i in 0..<dimension {
                centroid[i] += embedding[i]
            }
        }
        
        let count = Float(embeddings.count)
        for i in 0..<dimension {
            centroid[i] /= count
        }
        
        return centroid
    }
    
    private func euclideanDistance(_ a: [Float], _ b: [Float]) -> Float {
        var sum: Float = 0
        for i in 0..<min(a.count, b.count) {
            let diff = a[i] - b[i]
            sum += diff * diff
        }
        return sqrt(sum)
    }
    
    private func kMeansClustering(
        documents: [(id: String, embedding: [Float])],
        k: Int
    ) -> [[(id: String, embedding: [Float])]] {
        guard documents.count >= k else { return [documents] }
        
        // Initialize centroids randomly
        var centroids = Array(documents.shuffled().prefix(k).map { $0.embedding })
        var clusters: [[(id: String, embedding: [Float])]] = Array(repeating: [], count: k)
        
        // Run k-means iterations
        for _ in 0..<10 {
            // Clear clusters
            clusters = Array(repeating: [], count: k)
            
            // Assign documents to nearest centroid
            for doc in documents {
                var minDistance = Float.infinity
                var nearestCluster = 0
                
                for (i, centroid) in centroids.enumerated() {
                    let distance = euclideanDistance(doc.embedding, centroid)
                    if distance < minDistance {
                        minDistance = distance
                        nearestCluster = i
                    }
                }
                
                clusters[nearestCluster].append(doc)
            }
            
            // Update centroids
            for i in 0..<k {
                if !clusters[i].isEmpty {
                    centroids[i] = calculateCentroid(embeddings: clusters[i].map { $0.embedding })
                }
            }
        }
        
        return clusters.filter { !$0.isEmpty }
    }
    
    private func traverseAndStore(node: IndexNode, prefix: String) {
        indexMap[prefix] = node
        
        if let children = node.children {
            for (i, child) in children.enumerated() {
                traverseAndStore(node: child, prefix: "\(prefix).\(i)")
            }
        }
    }
}

// MARK: - Codable Support

extension VectorIndex.IndexNode: Codable {
    enum CodingKeys: String, CodingKey {
        case centroid, documentIds, children, depth
    }
}

struct IndexData: Codable {
    let indexMap: [String: VectorIndex.IndexNode]
}

// MARK: - Indexed Vector Database

class IndexedVectorDatabase: CoreDataVectorDatabase {
    private var index: VectorIndex?
    private let indexQueue = DispatchQueue(label: "vectordb.indexing")
    
    override init(modelName: String = "VectorDB") {
        super.init(modelName: modelName)
        setupIndexing()
    }
    
    private func setupIndexing() {
        // Initialize index based on first document's dimension
        indexQueue.async {
            self.rebuildIndexIfNeeded()
        }
    }
    
    override func insertBatch(documents: [VectorDocumentInput]) async throws -> [String] {
        let ids = try await super.insertBatch(documents: documents)
        
        // Rebuild index asynchronously
        indexQueue.async {
            self.rebuildIndexIfNeeded()
        }
        
        return ids
    }
    
    override func search(query: VectorQuery) async throws -> [VectorSearchResult] {
        // Use index for initial candidate selection if available
        if let index = index, let limit = query.limit {
            let candidateIds = await index.search(
                queryVector: query.vector,
                k: limit * 3,  // Get more candidates for final filtering
                pruningFactor: 2.0
            )
            
            // Fetch and score only candidate documents
            return try await fetchAndScore(
                candidateIds: candidateIds,
                query: query
            )
        }
        
        // Fall back to linear search
        return try await super.search(query: query)
    }
    
    private func fetchAndScore(
        candidateIds: [String],
        query: VectorQuery
    ) async throws -> [VectorSearchResult] {
        return try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    let request = VectorDocument.fetchRequest()
                    request.predicate = NSPredicate(
                        format: "id IN %@",
                        candidateIds
                    )
                    
                    let documents = try context.fetch(request)
                    
                    var results: [VectorSearchResult] = []
                    
                    for doc in documents {
                        let similarity = SimilarityCalculator.cosineSimilarity(
                            query.vector,
                            doc.embedding
                        )
                        
                        if similarity >= query.threshold {
                            results.append(VectorSearchResult(
                                id: doc.id,
                                content: doc.content,
                                similarity: similarity,
                                metadata: doc.metadataDict,
                                embedding: doc.embedding
                            ))
                        }
                    }
                    
                    results.sort { $0.similarity > $1.similarity }
                    if let limit = query.limit {
                        results = Array(results.prefix(limit))
                    }
                    
                    continuation.resume(returning: results)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func rebuildIndexIfNeeded() {
        // This method would be called periodically or after significant changes
        // Implementation would fetch all documents and rebuild the index
    }
}