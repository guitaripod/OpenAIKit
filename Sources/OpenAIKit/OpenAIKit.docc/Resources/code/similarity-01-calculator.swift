import Foundation
import Accelerate

// MARK: - Similarity Calculator

struct SimilarityCalculator {
    
    // Calculate cosine similarity between two vectors
    static func cosineSimilarity(_ vectorA: [Float], _ vectorB: [Float]) -> Float {
        guard vectorA.count == vectorB.count else {
            print("Warning: Vector dimensions don't match")
            return 0
        }
        
        // Use Accelerate framework for optimized computation
        var dotProduct: Float = 0
        var magnitudeA: Float = 0
        var magnitudeB: Float = 0
        
        vDSP_dotpr(vectorA, 1, vectorB, 1, &dotProduct, vDSP_Length(vectorA.count))
        vDSP_svesq(vectorA, 1, &magnitudeA, vDSP_Length(vectorA.count))
        vDSP_svesq(vectorB, 1, &magnitudeB, vDSP_Length(vectorB.count))
        
        let magnitude = sqrt(magnitudeA) * sqrt(magnitudeB)
        
        guard magnitude > 0 else { return 0 }
        
        return dotProduct / magnitude
    }
    
    // Calculate Euclidean distance
    static func euclideanDistance(_ vectorA: [Float], _ vectorB: [Float]) -> Float {
        guard vectorA.count == vectorB.count else {
            print("Warning: Vector dimensions don't match")
            return Float.infinity
        }
        
        var result: Float = 0
        var difference = [Float](repeating: 0, count: vectorA.count)
        
        // Calculate difference
        vDSP_vsub(vectorB, 1, vectorA, 1, &difference, 1, vDSP_Length(vectorA.count))
        
        // Calculate squared sum
        vDSP_svesq(difference, 1, &result, vDSP_Length(difference.count))
        
        return sqrt(result)
    }
    
    // Calculate Manhattan distance
    static func manhattanDistance(_ vectorA: [Float], _ vectorB: [Float]) -> Float {
        guard vectorA.count == vectorB.count else {
            print("Warning: Vector dimensions don't match")
            return Float.infinity
        }
        
        var result: Float = 0
        var difference = [Float](repeating: 0, count: vectorA.count)
        var absoluteDifference = [Float](repeating: 0, count: vectorA.count)
        
        // Calculate difference
        vDSP_vsub(vectorB, 1, vectorA, 1, &difference, 1, vDSP_Length(vectorA.count))
        
        // Take absolute values
        vDSP_vabs(difference, 1, &absoluteDifference, 1, vDSP_Length(difference.count))
        
        // Sum all values
        vDSP_sve(absoluteDifference, 1, &result, vDSP_Length(absoluteDifference.count))
        
        return result
    }
    
    // Calculate dot product similarity
    static func dotProduct(_ vectorA: [Float], _ vectorB: [Float]) -> Float {
        guard vectorA.count == vectorB.count else {
            print("Warning: Vector dimensions don't match")
            return 0
        }
        
        var result: Float = 0
        vDSP_dotpr(vectorA, 1, vectorB, 1, &result, vDSP_Length(vectorA.count))
        
        return result
    }
    
    // Normalize similarity score to 0-1 range
    static func normalizeSimilarity(_ score: Float, metric: SimilarityMetric) -> Float {
        switch metric {
        case .cosine:
            // Cosine similarity is already in [-1, 1], normalize to [0, 1]
            return (score + 1) / 2
            
        case .euclidean(let maxDistance):
            // Convert distance to similarity
            return 1 - min(score / maxDistance, 1)
            
        case .manhattan(let maxDistance):
            // Convert distance to similarity
            return 1 - min(score / maxDistance, 1)
            
        case .dotProduct(let maxValue):
            // Normalize based on expected maximum
            return min(max(score / maxValue, 0), 1)
        }
    }
}

// MARK: - Similarity Metrics

enum SimilarityMetric {
    case cosine
    case euclidean(maxDistance: Float)
    case manhattan(maxDistance: Float)
    case dotProduct(maxValue: Float)
    
    func calculate(_ vectorA: [Float], _ vectorB: [Float]) -> Float {
        switch self {
        case .cosine:
            return SimilarityCalculator.cosineSimilarity(vectorA, vectorB)
        case .euclidean:
            return SimilarityCalculator.euclideanDistance(vectorA, vectorB)
        case .manhattan:
            return SimilarityCalculator.manhattanDistance(vectorA, vectorB)
        case .dotProduct:
            return SimilarityCalculator.dotProduct(vectorA, vectorB)
        }
    }
    
    var name: String {
        switch self {
        case .cosine:
            return "Cosine Similarity"
        case .euclidean:
            return "Euclidean Distance"
        case .manhattan:
            return "Manhattan Distance"
        case .dotProduct:
            return "Dot Product"
        }
    }
}

// MARK: - Batch Similarity Calculator

class BatchSimilarityCalculator {
    private let metric: SimilarityMetric
    private let queue = DispatchQueue(label: "similarity.calculation", attributes: .concurrent)
    
    init(metric: SimilarityMetric = .cosine) {
        self.metric = metric
    }
    
    // Calculate similarity between one vector and multiple vectors
    func calculateSimilarities(
        queryVector: [Float],
        targetVectors: [[Float]],
        completion: @escaping ([SimilarityResult]) -> Void
    ) {
        let group = DispatchGroup()
        var results = [SimilarityResult]()
        let lock = NSLock()
        
        for (index, targetVector) in targetVectors.enumerated() {
            group.enter()
            queue.async {
                let score = self.metric.calculate(queryVector, targetVector)
                let result = SimilarityResult(
                    index: index,
                    score: score,
                    normalizedScore: SimilarityCalculator.normalizeSimilarity(score, metric: self.metric)
                )
                
                lock.lock()
                results.append(result)
                lock.unlock()
                
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // Sort by normalized score (descending)
            let sorted = results.sorted { $0.normalizedScore > $1.normalizedScore }
            completion(sorted)
        }
    }
    
    // Calculate similarity matrix for all pairs
    func calculateSimilarityMatrix(
        vectors: [[Float]],
        completion: @escaping ([[Float]]) -> Void
    ) {
        let count = vectors.count
        var matrix = Array(repeating: Array(repeating: Float(0), count: count), count: count)
        
        queue.async {
            for i in 0..<count {
                for j in i..<count {
                    if i == j {
                        matrix[i][j] = 1.0  // Self-similarity
                    } else {
                        let score = self.metric.calculate(vectors[i], vectors[j])
                        let normalized = SimilarityCalculator.normalizeSimilarity(score, metric: self.metric)
                        matrix[i][j] = normalized
                        matrix[j][i] = normalized  // Symmetric
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(matrix)
            }
        }
    }
}

// MARK: - Models

struct SimilarityResult {
    let index: Int
    let score: Float
    let normalizedScore: Float
    
    var percentage: Float {
        normalizedScore * 100
    }
    
    var isHighSimilarity: Bool {
        normalizedScore > 0.8
    }
    
    var isMediumSimilarity: Bool {
        normalizedScore > 0.6 && normalizedScore <= 0.8
    }
    
    var isLowSimilarity: Bool {
        normalizedScore <= 0.6
    }
}