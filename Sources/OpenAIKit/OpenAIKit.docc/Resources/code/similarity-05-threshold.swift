import Foundation

// MARK: - Similarity Threshold Manager

class SimilarityThresholdManager {
    
    // Dynamic threshold calculation based on data distribution
    func calculateDynamicThreshold(
        similarities: [Float],
        method: ThresholdMethod = .percentile(0.8)
    ) -> Float {
        guard !similarities.isEmpty else { return 0.5 }
        
        let sorted = similarities.sorted(by: >)
        
        switch method {
        case .percentile(let p):
            let index = Int(Float(sorted.count - 1) * p)
            return sorted[index]
            
        case .mean:
            return similarities.reduce(0, +) / Float(similarities.count)
            
        case .standardDeviation(let factor):
            let mean = similarities.reduce(0, +) / Float(similarities.count)
            let variance = similarities.map { pow($0 - mean, 2) }.reduce(0, +) / Float(similarities.count)
            let stdDev = sqrt(variance)
            return mean + (factor * stdDev)
            
        case .elbow:
            return findElbowPoint(in: sorted)
            
        case .otsu:
            return calculateOtsuThreshold(similarities)
            
        case .adaptive(let context):
            return calculateAdaptiveThreshold(similarities: similarities, context: context)
        }
    }
    
    // Multi-level thresholding for categorization
    func calculateMultiLevelThresholds(
        similarities: [Float],
        levels: Int = 3
    ) -> [ThresholdLevel] {
        guard levels > 0 && !similarities.isEmpty else { return [] }
        
        let sorted = similarities.sorted(by: >)
        var thresholds: [ThresholdLevel] = []
        
        // Calculate thresholds using quantiles
        for i in 0..<levels {
            let quantile = Float(i + 1) / Float(levels + 1)
            let index = Int(Float(sorted.count - 1) * (1 - quantile))
            let threshold = sorted[index]
            
            let label: String
            let confidence: Float
            
            switch i {
            case 0:
                label = "High Similarity"
                confidence = 0.9
            case 1:
                label = "Medium Similarity"
                confidence = 0.7
            case 2:
                label = "Low Similarity"
                confidence = 0.5
            default:
                label = "Very Low Similarity"
                confidence = 0.3
            }
            
            thresholds.append(ThresholdLevel(
                threshold: threshold,
                label: label,
                confidence: confidence,
                color: ThresholdColor(for: confidence)
            ))
        }
        
        return thresholds
    }
    
    // Validate threshold effectiveness
    func validateThreshold(
        threshold: Float,
        testData: [(similarity: Float, isRelevant: Bool)]
    ) -> ThresholdValidation {
        var truePositives = 0
        var falsePositives = 0
        var trueNegatives = 0
        var falseNegatives = 0
        
        for (similarity, isRelevant) in testData {
            let predicted = similarity >= threshold
            
            if predicted && isRelevant {
                truePositives += 1
            } else if predicted && !isRelevant {
                falsePositives += 1
            } else if !predicted && !isRelevant {
                trueNegatives += 1
            } else {
                falseNegatives += 1
            }
        }
        
        let precision = truePositives > 0 ?
            Float(truePositives) / Float(truePositives + falsePositives) : 0
        
        let recall = truePositives + falseNegatives > 0 ?
            Float(truePositives) / Float(truePositives + falseNegatives) : 0
        
        let f1Score = precision + recall > 0 ?
            2 * (precision * recall) / (precision + recall) : 0
        
        let accuracy = Float(truePositives + trueNegatives) / Float(testData.count)
        
        return ThresholdValidation(
            threshold: threshold,
            precision: precision,
            recall: recall,
            f1Score: f1Score,
            accuracy: accuracy,
            confusionMatrix: ConfusionMatrix(
                truePositives: truePositives,
                falsePositives: falsePositives,
                trueNegatives: trueNegatives,
                falseNegatives: falseNegatives
            )
        )
    }
    
    // Optimize threshold for specific metric
    func optimizeThreshold(
        testData: [(similarity: Float, isRelevant: Bool)],
        optimizeFor: OptimizationMetric = .f1Score,
        searchRange: ClosedRange<Float> = 0...1,
        steps: Int = 100
    ) -> OptimalThreshold {
        var bestThreshold: Float = 0.5
        var bestScore: Float = 0
        var validations: [ThresholdValidation] = []
        
        let stepSize = (searchRange.upperBound - searchRange.lowerBound) / Float(steps)
        
        for i in 0...steps {
            let threshold = searchRange.lowerBound + Float(i) * stepSize
            let validation = validateThreshold(threshold: threshold, testData: testData)
            validations.append(validation)
            
            let score: Float
            switch optimizeFor {
            case .precision:
                score = validation.precision
            case .recall:
                score = validation.recall
            case .f1Score:
                score = validation.f1Score
            case .accuracy:
                score = validation.accuracy
            case .custom(let scorer):
                score = scorer(validation)
            }
            
            if score > bestScore {
                bestScore = score
                bestThreshold = threshold
            }
        }
        
        return OptimalThreshold(
            value: bestThreshold,
            score: bestScore,
            metric: optimizeFor,
            validationCurve: validations
        )
    }
    
    // Helper: Find elbow point in sorted similarities
    private func findElbowPoint(in sortedSimilarities: [Float]) -> Float {
        guard sortedSimilarities.count > 2 else {
            return sortedSimilarities.isEmpty ? 0.5 : sortedSimilarities[sortedSimilarities.count / 2]
        }
        
        // Calculate line from first to last point
        let x1: Float = 0
        let y1 = sortedSimilarities.first!
        let x2 = Float(sortedSimilarities.count - 1)
        let y2 = sortedSimilarities.last!
        
        // Find point with maximum distance to line
        var maxDistance: Float = 0
        var elbowIndex = 0
        
        for (index, similarity) in sortedSimilarities.enumerated() {
            let x = Float(index)
            let y = similarity
            
            // Distance from point to line
            let distance = abs((y2 - y1) * x - (x2 - x1) * y + x2 * y1 - y2 * x1) /
                          sqrt(pow(y2 - y1, 2) + pow(x2 - x1, 2))
            
            if distance > maxDistance {
                maxDistance = distance
                elbowIndex = index
            }
        }
        
        return sortedSimilarities[elbowIndex]
    }
    
    // Helper: Otsu's method for threshold
    private func calculateOtsuThreshold(_ similarities: [Float]) -> Float {
        let histogram = createHistogram(similarities, bins: 100)
        var bestThreshold: Float = 0.5
        var maxVariance: Float = 0
        
        for i in 1..<histogram.count {
            let threshold = Float(i) / Float(histogram.count)
            
            // Calculate class weights and means
            var w0: Float = 0, w1: Float = 0
            var sum0: Float = 0, sum1: Float = 0
            
            for (j, count) in histogram.enumerated() {
                let value = Float(j) / Float(histogram.count)
                if j < i {
                    w0 += Float(count)
                    sum0 += Float(count) * value
                } else {
                    w1 += Float(count)
                    sum1 += Float(count) * value
                }
            }
            
            if w0 > 0 && w1 > 0 {
                let mean0 = sum0 / w0
                let mean1 = sum1 / w1
                let variance = w0 * w1 * pow(mean0 - mean1, 2)
                
                if variance > maxVariance {
                    maxVariance = variance
                    bestThreshold = threshold
                }
            }
        }
        
        return bestThreshold
    }
    
    // Helper: Create histogram
    private func createHistogram(_ values: [Float], bins: Int) -> [Int] {
        var histogram = Array(repeating: 0, count: bins)
        
        for value in values {
            let bin = Int(value * Float(bins - 1))
            histogram[min(bin, bins - 1)] += 1
        }
        
        return histogram
    }
    
    // Helper: Adaptive threshold based on context
    private func calculateAdaptiveThreshold(
        similarities: [Float],
        context: AdaptiveContext
    ) -> Float {
        let baseThreshold = calculateDynamicThreshold(similarities, method: .percentile(0.8))
        
        var adjustedThreshold = baseThreshold
        
        // Adjust based on query complexity
        adjustedThreshold *= context.queryComplexityFactor
        
        // Adjust based on domain
        adjustedThreshold *= context.domainSpecificityFactor
        
        // Adjust based on user feedback
        if let feedbackAdjustment = context.userFeedbackAdjustment {
            adjustedThreshold += feedbackAdjustment
        }
        
        // Ensure within valid range
        return max(0, min(1, adjustedThreshold))
    }
}

// MARK: - Models

enum ThresholdMethod {
    case percentile(Float)
    case mean
    case standardDeviation(factor: Float)
    case elbow
    case otsu
    case adaptive(context: AdaptiveContext)
}

struct ThresholdLevel {
    let threshold: Float
    let label: String
    let confidence: Float
    let color: ThresholdColor
    
    func categorize(_ similarity: Float) -> Bool {
        similarity >= threshold
    }
}

struct ThresholdColor {
    let red: Float
    let green: Float
    let blue: Float
    
    static func color(for confidence: Float) -> ThresholdColor {
        if confidence > 0.8 {
            return ThresholdColor(red: 0, green: 0.8, blue: 0)
        } else if confidence > 0.6 {
            return ThresholdColor(red: 1, green: 0.8, blue: 0)
        } else {
            return ThresholdColor(red: 1, green: 0, blue: 0)
        }
    }
}

struct ThresholdValidation {
    let threshold: Float
    let precision: Float
    let recall: Float
    let f1Score: Float
    let accuracy: Float
    let confusionMatrix: ConfusionMatrix
}

struct ConfusionMatrix {
    let truePositives: Int
    let falsePositives: Int
    let trueNegatives: Int
    let falseNegatives: Int
    
    var total: Int {
        truePositives + falsePositives + trueNegatives + falseNegatives
    }
}

enum OptimizationMetric {
    case precision
    case recall
    case f1Score
    case accuracy
    case custom((ThresholdValidation) -> Float)
}

struct OptimalThreshold {
    let value: Float
    let score: Float
    let metric: OptimizationMetric
    let validationCurve: [ThresholdValidation]
}

struct AdaptiveContext {
    let queryComplexityFactor: Float
    let domainSpecificityFactor: Float
    let userFeedbackAdjustment: Float?
    let timeOfDay: Date?
    let userProfile: UserProfile?
}

struct UserProfile {
    let preferredPrecision: Float
    let historicalThresholds: [Float]
}

// MARK: - Threshold Recommender

class ThresholdRecommender {
    private let manager = SimilarityThresholdManager()
    
    func recommendThreshold(
        for useCase: UseCase,
        similarities: [Float],
        additionalContext: [String: Any]? = nil
    ) -> ThresholdRecommendation {
        let method: ThresholdMethod
        let rationale: String
        
        switch useCase {
        case .duplicateDetection:
            method = .percentile(0.95)
            rationale = "High threshold for duplicate detection to minimize false positives"
            
        case .similaritySearch:
            method = .percentile(0.8)
            rationale = "Balanced threshold for general similarity search"
            
        case .clustering:
            method = .elbow
            rationale = "Elbow method finds natural separation in data"
            
        case .recommendation:
            method = .standardDeviation(factor: 0.5)
            rationale = "Include items within 0.5 standard deviations of mean similarity"
            
        case .anomalyDetection:
            method = .percentile(0.1)
            rationale = "Low threshold to identify dissimilar/anomalous items"
        }
        
        let threshold = manager.calculateDynamicThreshold(
            similarities: similarities,
            method: method
        )
        
        return ThresholdRecommendation(
            value: threshold,
            method: method,
            useCase: useCase,
            rationale: rationale,
            confidence: calculateConfidence(for: useCase, dataSize: similarities.count)
        )
    }
    
    private func calculateConfidence(for useCase: UseCase, dataSize: Int) -> Float {
        let baseConfidence: Float = 0.7
        let sizeBonus = min(Float(dataSize) / 1000, 0.2)
        
        return min(baseConfidence + sizeBonus, 0.95)
    }
}

enum UseCase {
    case duplicateDetection
    case similaritySearch
    case clustering
    case recommendation
    case anomalyDetection
}

struct ThresholdRecommendation {
    let value: Float
    let method: ThresholdMethod
    let useCase: UseCase
    let rationale: String
    let confidence: Float
}