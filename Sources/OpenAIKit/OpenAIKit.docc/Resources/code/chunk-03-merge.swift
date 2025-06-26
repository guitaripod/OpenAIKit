import Foundation
import OpenAIKit

// MARK: - Chunk Merger

class ChunkMerger {
    
    // Merge strategy options
    enum MergeStrategy {
        case simple           // Just concatenate text
        case smart           // Remove duplicates and fix overlaps
        case contextAware    // Use context to improve merging
    }
    
    // Merge transcription chunks intelligently
    func mergeTranscriptions(
        _ results: [ChunkTranscriptionResult],
        strategy: MergeStrategy = .smart
    ) -> MergedTranscription {
        switch strategy {
        case .simple:
            return simpleMerge(results)
        case .smart:
            return smartMerge(results)
        case .contextAware:
            return contextAwareMerge(results)
        }
    }
    
    // Simple concatenation
    private func simpleMerge(_ results: [ChunkTranscriptionResult]) -> MergedTranscription {
        let sortedResults = results.sorted { $0.chunkIndex < $1.chunkIndex }
        
        let fullText = sortedResults
            .filter { $0.error == nil }
            .map { $0.text }
            .joined(separator: " ")
        
        let allSegments = sortedResults
            .compactMap { $0.segments }
            .flatMap { $0 }
        
        return MergedTranscription(
            text: fullText.trimmingCharacters(in: .whitespacesAndNewlines),
            segments: allSegments.isEmpty ? nil : allSegments,
            mergePoints: []
        )
    }
    
    // Smart merge with overlap detection
    private func smartMerge(_ results: [ChunkTranscriptionResult]) -> MergedTranscription {
        let sortedResults = results
            .filter { $0.error == nil }
            .sorted { $0.chunkIndex < $1.chunkIndex }
        
        guard !sortedResults.isEmpty else {
            return MergedTranscription(text: "", segments: nil, mergePoints: [])
        }
        
        var mergedText = ""
        var mergedSegments: [TranscriptionSegment] = []
        var mergePoints: [MergePoint] = []
        
        for (index, result) in sortedResults.enumerated() {
            if index == 0 {
                // First chunk
                mergedText = result.text
                if let segments = result.segments {
                    mergedSegments.append(contentsOf: segments)
                }
            } else {
                // Detect and handle overlap
                let previousResult = sortedResults[index - 1]
                let overlap = detectOverlap(
                    previousText: previousResult.text,
                    currentText: result.text
                )
                
                if let overlap = overlap {
                    // Remove overlapping portion
                    let cleanedText = String(result.text.dropFirst(overlap.overlapLength))
                    
                    // Add merge point
                    let mergePoint = MergePoint(
                        chunkIndex: result.chunkIndex,
                        position: mergedText.count,
                        overlapDetected: true,
                        overlapLength: overlap.overlapLength,
                        confidence: overlap.confidence
                    )
                    mergePoints.append(mergePoint)
                    
                    // Append cleaned text
                    if !mergedText.hasSuffix(" ") && !cleanedText.hasPrefix(" ") {
                        mergedText += " "
                    }
                    mergedText += cleanedText
                    
                    // Merge segments with overlap adjustment
                    if let segments = result.segments {
                        let adjustedSegments = adjustSegmentsForOverlap(
                            segments: segments,
                            overlapDuration: overlap.estimatedDuration
                        )
                        mergedSegments.append(contentsOf: adjustedSegments)
                    }
                } else {
                    // No overlap detected
                    let mergePoint = MergePoint(
                        chunkIndex: result.chunkIndex,
                        position: mergedText.count,
                        overlapDetected: false,
                        overlapLength: 0,
                        confidence: 1.0
                    )
                    mergePoints.append(mergePoint)
                    
                    // Append text with proper spacing
                    if !mergedText.hasSuffix(" ") && !result.text.hasPrefix(" ") {
                        mergedText += " "
                    }
                    mergedText += result.text
                    
                    // Append segments
                    if let segments = result.segments {
                        mergedSegments.append(contentsOf: segments)
                    }
                }
            }
        }
        
        // Post-process to fix common issues
        let processedText = postProcessMergedText(mergedText)
        let processedSegments = postProcessSegments(mergedSegments)
        
        return MergedTranscription(
            text: processedText,
            segments: processedSegments.isEmpty ? nil : processedSegments,
            mergePoints: mergePoints
        )
    }
    
    // Context-aware merge using language model understanding
    private func contextAwareMerge(_ results: [ChunkTranscriptionResult]) -> MergedTranscription {
        // Start with smart merge
        let smartMerged = smartMerge(results)
        
        // Apply context-based improvements
        let improvedText = applyContextualImprovements(
            text: smartMerged.text,
            segments: smartMerged.segments,
            mergePoints: smartMerged.mergePoints
        )
        
        return MergedTranscription(
            text: improvedText,
            segments: smartMerged.segments,
            mergePoints: smartMerged.mergePoints
        )
    }
    
    // Detect overlap between consecutive chunks
    private func detectOverlap(previousText: String, currentText: String) -> OverlapInfo? {
        // Try different overlap lengths
        let maxOverlapLength = min(previousText.count / 2, currentText.count / 2, 200)
        
        for overlapLength in stride(from: maxOverlapLength, to: 10, by: -5) {
            let previousEnd = String(previousText.suffix(overlapLength))
            let currentStart = String(currentText.prefix(overlapLength))
            
            let similarity = calculateSimilarity(previousEnd, currentStart)
            
            if similarity > 0.8 {
                // High confidence overlap found
                return OverlapInfo(
                    overlapLength: overlapLength,
                    confidence: similarity,
                    estimatedDuration: estimateDuration(for: overlapLength)
                )
            }
        }
        
        // Try fuzzy matching for partial overlaps
        return detectFuzzyOverlap(previousText: previousText, currentText: currentText)
    }
    
    // Fuzzy overlap detection for imperfect matches
    private func detectFuzzyOverlap(previousText: String, currentText: String) -> OverlapInfo? {
        let words1 = previousText.split(separator: " ").suffix(20).map(String.init)
        let words2 = currentText.split(separator: " ").prefix(20).map(String.init)
        
        // Find longest common subsequence
        var maxOverlap = 0
        var overlapStart = 0
        
        for i in 0..<words1.count {
            for j in 0..<words2.count {
                var k = 0
                while i + k < words1.count && 
                      j + k < words2.count && 
                      words1[i + k].lowercased() == words2[j + k].lowercased() {
                    k += 1
                }
                
                if k > maxOverlap && k >= 3 {  // Minimum 3 words
                    maxOverlap = k
                    overlapStart = j
                }
            }
        }
        
        if maxOverlap > 0 {
            let overlapWords = words2[overlapStart..<(overlapStart + maxOverlap)].joined(separator: " ")
            return OverlapInfo(
                overlapLength: overlapWords.count,
                confidence: Double(maxOverlap) / Double(min(words1.count, words2.count)),
                estimatedDuration: estimateDuration(for: overlapWords.count)
            )
        }
        
        return nil
    }
    
    // Calculate text similarity
    private func calculateSimilarity(_ text1: String, _ text2: String) -> Double {
        let set1 = Set(text1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let set2 = Set(text2.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = set1.intersection(set2)
        let union = set1.union(set2)
        
        guard !union.isEmpty else { return 0 }
        return Double(intersection.count) / Double(union.count)
    }
    
    // Estimate duration based on text length
    private func estimateDuration(for textLength: Int) -> TimeInterval {
        // Rough estimate: 150 words per minute
        let words = Double(textLength) / 5.0  // Average 5 characters per word
        return (words / 150.0) * 60.0
    }
    
    // Adjust segment timestamps for overlap
    private func adjustSegmentsForOverlap(
        segments: [TranscriptionSegment],
        overlapDuration: TimeInterval
    ) -> [TranscriptionSegment] {
        return segments.map { segment in
            var adjusted = segment
            if let start = segment.start {
                adjusted.start = max(0, start - overlapDuration)
            }
            if let end = segment.end {
                adjusted.end = max(0, end - overlapDuration)
            }
            return adjusted
        }
    }
    
    // Post-process merged text
    private func postProcessMergedText(_ text: String) -> String {
        var processed = text
        
        // Fix multiple spaces
        processed = processed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Fix sentence boundaries
        processed = fixSentenceBoundaries(processed)
        
        // Remove duplicate sentences
        processed = removeDuplicateSentences(processed)
        
        return processed.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Fix sentence boundaries
    private func fixSentenceBoundaries(_ text: String) -> String {
        var fixed = text
        
        // Ensure space after punctuation
        fixed = fixed.replacingOccurrences(of: "([.!?])([A-Z])", with: "$1 $2", options: .regularExpression)
        
        // Fix common issues
        fixed = fixed.replacingOccurrences(of: " .", with: ".")
        fixed = fixed.replacingOccurrences(of: " ,", with: ",")
        
        return fixed
    }
    
    // Remove duplicate sentences
    private func removeDuplicateSentences(_ text: String) -> String {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var seen = Set<String>()
        var unique: [String] = []
        
        for sentence in sentences {
            let normalized = sentence.lowercased()
            if !seen.contains(normalized) {
                seen.insert(normalized)
                unique.append(sentence)
            }
        }
        
        return unique.joined(separator: ". ") + "."
    }
    
    // Post-process segments
    private func postProcessSegments(_ segments: [TranscriptionSegment]) -> [TranscriptionSegment] {
        guard !segments.isEmpty else { return [] }
        
        // Sort by start time
        let sorted = segments.sorted { 
            ($0.start ?? 0) < ($1.start ?? 0)
        }
        
        // Remove overlapping segments
        var processed: [TranscriptionSegment] = []
        
        for segment in sorted {
            if let lastSegment = processed.last,
               let lastEnd = lastSegment.end,
               let currentStart = segment.start,
               currentStart < lastEnd {
                // Skip overlapping segment
                continue
            }
            processed.append(segment)
        }
        
        return processed
    }
    
    // Apply contextual improvements
    private func applyContextualImprovements(
        text: String,
        segments: [TranscriptionSegment]?,
        mergePoints: [MergePoint]
    ) -> String {
        var improved = text
        
        // Fix common transcription errors at merge points
        for mergePoint in mergePoints {
            // This would use more sophisticated NLP in production
            improved = fixMergePointErrors(improved, at: mergePoint)
        }
        
        return improved
    }
    
    private func fixMergePointErrors(_ text: String, at mergePoint: MergePoint) -> String {
        // Placeholder for more sophisticated error correction
        return text
    }
}

// MARK: - Models

struct MergedTranscription {
    let text: String
    let segments: [TranscriptionSegment]?
    let mergePoints: [MergePoint]
    
    var wordCount: Int {
        text.split(separator: " ").count
    }
    
    var duration: TimeInterval? {
        guard let segments = segments,
              let first = segments.first?.start,
              let last = segments.last?.end else {
            return nil
        }
        return last - first
    }
}

struct MergePoint {
    let chunkIndex: Int
    let position: Int  // Character position in merged text
    let overlapDetected: Bool
    let overlapLength: Int
    let confidence: Double
}

struct OverlapInfo {
    let overlapLength: Int
    let confidence: Double
    let estimatedDuration: TimeInterval
}