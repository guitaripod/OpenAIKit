import Foundation
import Accelerate

// MARK: - Similarity Clustering

class SimilarityClustering {
    
    // K-Means clustering for embeddings
    func kMeansClustering(
        embeddings: [[Float]],
        k: Int,
        maxIterations: Int = 100,
        tolerance: Float = 0.001
    ) -> ClusteringResult {
        guard embeddings.count >= k else {
            return ClusteringResult(clusters: [], centroids: [], iterations: 0)
        }
        
        let dimensions = embeddings[0].count
        
        // Initialize centroids using K-Means++
        var centroids = initializeCentroidsKMeansPlusPlus(embeddings: embeddings, k: k)
        var assignments = Array(repeating: 0, count: embeddings.count)
        var previousAssignments = assignments
        var iterations = 0
        
        // Iterate until convergence or max iterations
        while iterations < maxIterations {
            // Assign points to nearest centroid
            for (index, embedding) in embeddings.enumerated() {
                assignments[index] = findNearestCentroid(
                    point: embedding,
                    centroids: centroids
                )
            }
            
            // Check for convergence
            if assignments == previousAssignments {
                break
            }
            
            previousAssignments = assignments
            
            // Update centroids
            centroids = updateCentroids(
                embeddings: embeddings,
                assignments: assignments,
                k: k,
                dimensions: dimensions
            )
            
            iterations += 1
        }
        
        // Create clusters
        var clusters: [[Int]] = Array(repeating: [], count: k)
        for (index, assignment) in assignments.enumerated() {
            clusters[assignment].append(index)
        }
        
        return ClusteringResult(
            clusters: clusters,
            centroids: centroids,
            iterations: iterations
        )
    }
    
    // Hierarchical clustering
    func hierarchicalClustering(
        embeddings: [[Float]],
        threshold: Float,
        linkage: LinkageType = .average
    ) -> HierarchicalClusteringResult {
        let n = embeddings.count
        
        // Initialize each point as its own cluster
        var clusters: [Set<Int>] = (0..<n).map { [Set([$0])] }
        var distances = calculateDistanceMatrix(embeddings: embeddings)
        var mergeHistory: [ClusterMerge] = []
        
        while clusters.count > 1 {
            // Find closest pair of clusters
            var minDistance = Float.infinity
            var mergeIndices = (0, 0)
            
            for i in 0..<clusters.count {
                for j in (i+1)..<clusters.count {
                    let distance = calculateClusterDistance(
                        cluster1: clusters[i],
                        cluster2: clusters[j],
                        distances: distances,
                        linkage: linkage
                    )
                    
                    if distance < minDistance {
                        minDistance = distance
                        mergeIndices = (i, j)
                    }
                }
            }
            
            // Stop if minimum distance exceeds threshold
            if minDistance > threshold {
                break
            }
            
            // Merge clusters
            let (i, j) = mergeIndices
            let merged = clusters[i].union(clusters[j])
            
            mergeHistory.append(ClusterMerge(
                cluster1: clusters[i],
                cluster2: clusters[j],
                distance: minDistance,
                mergedCluster: merged
            ))
            
            // Update clusters array
            clusters[i] = merged
            clusters.remove(at: j)
        }
        
        return HierarchicalClusteringResult(
            clusters: clusters,
            mergeHistory: mergeHistory,
            dendrogram: buildDendrogram(mergeHistory: mergeHistory)
        )
    }
    
    // DBSCAN clustering
    func dbscanClustering(
        embeddings: [[Float]],
        eps: Float,
        minPoints: Int
    ) -> DBSCANResult {
        let n = embeddings.count
        var labels = Array(repeating: -1, count: n)  // -1 = unvisited
        var clusterID = 0
        
        for i in 0..<n {
            if labels[i] != -1 { continue }  // Already processed
            
            // Find neighbors
            let neighbors = findNeighbors(
                pointIndex: i,
                embeddings: embeddings,
                eps: eps
            )
            
            if neighbors.count < minPoints {
                labels[i] = -2  // Mark as noise
            } else {
                // Start new cluster
                expandCluster(
                    pointIndex: i,
                    neighbors: neighbors,
                    clusterID: clusterID,
                    embeddings: embeddings,
                    labels: &labels,
                    eps: eps,
                    minPoints: minPoints
                )
                clusterID += 1
            }
        }
        
        // Organize results
        var clusters: [[Int]] = []
        var noise: [Int] = []
        
        for i in 0..<n {
            if labels[i] == -2 {
                noise.append(i)
            } else if labels[i] >= 0 {
                while clusters.count <= labels[i] {
                    clusters.append([])
                }
                clusters[labels[i]].append(i)
            }
        }
        
        return DBSCANResult(
            clusters: clusters,
            noise: noise,
            corePoints: findCorePoints(embeddings: embeddings, eps: eps, minPoints: minPoints)
        )
    }
    
    // Helper: Initialize centroids using K-Means++
    private func initializeCentroidsKMeansPlusPlus(
        embeddings: [[Float]],
        k: Int
    ) -> [[Float]] {
        var centroids: [[Float]] = []
        
        // Choose first centroid randomly
        let firstIndex = Int.random(in: 0..<embeddings.count)
        centroids.append(embeddings[firstIndex])
        
        // Choose remaining centroids
        for _ in 1..<k {
            var distances: [Float] = []
            
            // Calculate distance to nearest centroid for each point
            for embedding in embeddings {
                let minDistance = centroids.map { centroid in
                    SimilarityCalculator.euclideanDistance(embedding, centroid)
                }.min() ?? 0
                
                distances.append(minDistance * minDistance)  // Square for probability
            }
            
            // Choose next centroid with probability proportional to squared distance
            let totalDistance = distances.reduce(0, +)
            let random = Float.random(in: 0..<totalDistance)
            
            var cumulative: Float = 0
            for (index, distance) in distances.enumerated() {
                cumulative += distance
                if cumulative >= random {
                    centroids.append(embeddings[index])
                    break
                }
            }
        }
        
        return centroids
    }
    
    // Helper: Find nearest centroid
    private func findNearestCentroid(
        point: [Float],
        centroids: [[Float]]
    ) -> Int {
        var minDistance = Float.infinity
        var nearestIndex = 0
        
        for (index, centroid) in centroids.enumerated() {
            let distance = SimilarityCalculator.euclideanDistance(point, centroid)
            if distance < minDistance {
                minDistance = distance
                nearestIndex = index
            }
        }
        
        return nearestIndex
    }
    
    // Helper: Update centroids
    private func updateCentroids(
        embeddings: [[Float]],
        assignments: [Int],
        k: Int,
        dimensions: Int
    ) -> [[Float]] {
        var centroids: [[Float]] = Array(repeating: Array(repeating: 0, count: dimensions), count: k)
        var counts = Array(repeating: 0, count: k)
        
        // Sum points assigned to each centroid
        for (index, assignment) in assignments.enumerated() {
            for dim in 0..<dimensions {
                centroids[assignment][dim] += embeddings[index][dim]
            }
            counts[assignment] += 1
        }
        
        // Calculate mean
        for i in 0..<k {
            if counts[i] > 0 {
                for dim in 0..<dimensions {
                    centroids[i][dim] /= Float(counts[i])
                }
            }
        }
        
        return centroids
    }
    
    // Helper: Calculate distance matrix
    private func calculateDistanceMatrix(embeddings: [[Float]]) -> [[Float]] {
        let n = embeddings.count
        var matrix = Array(repeating: Array(repeating: Float(0), count: n), count: n)
        
        for i in 0..<n {
            for j in (i+1)..<n {
                let distance = SimilarityCalculator.euclideanDistance(
                    embeddings[i],
                    embeddings[j]
                )
                matrix[i][j] = distance
                matrix[j][i] = distance
            }
        }
        
        return matrix
    }
    
    // Helper: Calculate cluster distance
    private func calculateClusterDistance(
        cluster1: Set<Int>,
        cluster2: Set<Int>,
        distances: [[Float]],
        linkage: LinkageType
    ) -> Float {
        var clusterDistances: [Float] = []
        
        for i in cluster1 {
            for j in cluster2 {
                clusterDistances.append(distances[i][j])
            }
        }
        
        switch linkage {
        case .single:
            return clusterDistances.min() ?? Float.infinity
        case .complete:
            return clusterDistances.max() ?? 0
        case .average:
            return clusterDistances.reduce(0, +) / Float(clusterDistances.count)
        }
    }
    
    // Helper: Find neighbors within eps distance
    private func findNeighbors(
        pointIndex: Int,
        embeddings: [[Float]],
        eps: Float
    ) -> [Int] {
        var neighbors: [Int] = []
        
        for (i, embedding) in embeddings.enumerated() {
            if i != pointIndex {
                let distance = SimilarityCalculator.euclideanDistance(
                    embeddings[pointIndex],
                    embedding
                )
                if distance <= eps {
                    neighbors.append(i)
                }
            }
        }
        
        return neighbors
    }
    
    // Helper: Expand cluster in DBSCAN
    private func expandCluster(
        pointIndex: Int,
        neighbors: [Int],
        clusterID: Int,
        embeddings: [[Float]],
        labels: inout [Int],
        eps: Float,
        minPoints: Int
    ) {
        labels[pointIndex] = clusterID
        var seeds = neighbors
        var i = 0
        
        while i < seeds.count {
            let currentPoint = seeds[i]
            
            if labels[currentPoint] == -2 {  // Was noise
                labels[currentPoint] = clusterID
            } else if labels[currentPoint] == -1 {  // Unvisited
                labels[currentPoint] = clusterID
                
                let currentNeighbors = findNeighbors(
                    pointIndex: currentPoint,
                    embeddings: embeddings,
                    eps: eps
                )
                
                if currentNeighbors.count >= minPoints {
                    seeds.append(contentsOf: currentNeighbors)
                }
            }
            
            i += 1
        }
    }
    
    // Helper: Find core points
    private func findCorePoints(
        embeddings: [[Float]],
        eps: Float,
        minPoints: Int
    ) -> [Int] {
        var corePoints: [Int] = []
        
        for i in 0..<embeddings.count {
            let neighbors = findNeighbors(
                pointIndex: i,
                embeddings: embeddings,
                eps: eps
            )
            if neighbors.count >= minPoints {
                corePoints.append(i)
            }
        }
        
        return corePoints
    }
    
    // Helper: Build dendrogram
    private func buildDendrogram(mergeHistory: [ClusterMerge]) -> Dendrogram {
        // Simplified dendrogram construction
        return Dendrogram(merges: mergeHistory)
    }
}

// MARK: - Models

struct ClusteringResult {
    let clusters: [[Int]]  // Indices of points in each cluster
    let centroids: [[Float]]
    let iterations: Int
    
    var clusterSizes: [Int] {
        clusters.map { $0.count }
    }
    
    var silhouetteScore: Float {
        // Calculate average silhouette coefficient
        // Implementation would calculate intra-cluster and inter-cluster distances
        return 0.0
    }
}

struct HierarchicalClusteringResult {
    let clusters: [Set<Int>]
    let mergeHistory: [ClusterMerge]
    let dendrogram: Dendrogram
}

struct DBSCANResult {
    let clusters: [[Int]]
    let noise: [Int]
    let corePoints: [Int]
    
    var clusterCount: Int {
        clusters.count
    }
    
    var noiseRatio: Float {
        let total = clusters.flatMap { $0 }.count + noise.count
        return Float(noise.count) / Float(total)
    }
}

struct ClusterMerge {
    let cluster1: Set<Int>
    let cluster2: Set<Int>
    let distance: Float
    let mergedCluster: Set<Int>
}

struct Dendrogram {
    let merges: [ClusterMerge]
    
    func cut(at height: Float) -> [Set<Int>] {
        // Return clusters at given height
        // Implementation would traverse merge history
        return []
    }
}

enum LinkageType {
    case single    // Minimum distance
    case complete  // Maximum distance
    case average   // Average distance
}