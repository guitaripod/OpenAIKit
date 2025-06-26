// ImageGenerator.swift
import Foundation
import OpenAIKit

extension ImageGenerator {
    
    /// Track and analyze token usage for gpt-image-1
    class TokenUsageTracker {
        private var usageHistory: [TokenUsageRecord] = []
        private let maxHistorySize = 1000
        
        /// Add a new usage record
        func recordUsage(
            _ usage: ImageUsage,
            model: String,
            prompt: String,
            imageCount: Int
        ) {
            let record = TokenUsageRecord(
                timestamp: Date(),
                model: model,
                prompt: prompt,
                imageCount: imageCount,
                usage: usage
            )
            
            usageHistory.append(record)
            
            // Keep history size manageable
            if usageHistory.count > maxHistorySize {
                usageHistory.removeFirst()
            }
        }
        
        /// Get usage statistics for a time period
        func getUsageStats(
            since startDate: Date,
            until endDate: Date = Date()
        ) -> UsageStatistics {
            
            let relevantRecords = usageHistory.filter { record in
                record.timestamp >= startDate && record.timestamp <= endDate
            }
            
            var stats = UsageStatistics()
            
            for record in relevantRecords {
                stats.totalRequests += 1
                stats.totalImages += record.imageCount
                
                if let usage = record.usage {
                    stats.totalTokens += usage.totalTokens ?? 0
                    stats.inputTokens += usage.inputTokens ?? 0
                    stats.outputTokens += usage.outputTokens ?? 0
                    
                    if let details = usage.inputTokensDetails {
                        stats.textTokens += details.textTokens ?? 0
                        stats.imageTokens += details.imageTokens ?? 0
                    }
                }
                
                // Track by model
                stats.tokensByModel[record.model, default: 0] += record.usage?.totalTokens ?? 0
            }
            
            // Calculate averages
            if stats.totalRequests > 0 {
                stats.averageTokensPerRequest = Double(stats.totalTokens) / Double(stats.totalRequests)
                stats.averageTokensPerImage = Double(stats.totalTokens) / Double(stats.totalImages)
            }
            
            // Estimate costs (adjust rates based on current pricing)
            stats.estimatedCost = calculateEstimatedCost(stats)
            
            return stats
        }
        
        /// Calculate estimated cost based on token usage
        private func calculateEstimatedCost(_ stats: UsageStatistics) -> Double {
            var totalCost = 0.0
            
            // Example pricing (adjust based on actual rates)
            let gptImage1InputRate = 0.015 // per 1K tokens
            let gptImage1OutputRate = 0.03  // per 1K tokens
            
            // Calculate input costs
            let inputCost = Double(stats.inputTokens) / 1000.0 * gptImage1InputRate
            
            // Calculate output costs
            let outputCost = Double(stats.outputTokens) / 1000.0 * gptImage1OutputRate
            
            totalCost = inputCost + outputCost
            
            return totalCost
        }
        
        /// Get prompt efficiency metrics
        func getPromptEfficiency() -> [PromptEfficiencyMetric] {
            var promptMetrics: [String: PromptEfficiencyMetric] = [:]
            
            for record in usageHistory {
                let promptKey = normalizePrompt(record.prompt)
                
                var metric = promptMetrics[promptKey] ?? PromptEfficiencyMetric(
                    prompt: record.prompt,
                    uses: 0,
                    totalTokens: 0,
                    averageTokens: 0
                )
                
                metric.uses += 1
                metric.totalTokens += record.usage?.totalTokens ?? 0
                metric.averageTokens = metric.totalTokens / metric.uses
                
                promptMetrics[promptKey] = metric
            }
            
            return Array(promptMetrics.values)
                .sorted { $0.uses > $1.uses }
        }
        
        /// Normalize prompt for comparison
        private func normalizePrompt(_ prompt: String) -> String {
            prompt.lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(50)
                .description
        }
    }
    
    /// Generate image with detailed token tracking
    func generateImageWithTokenTracking(
        prompt: String,
        options: ImageOptions = ImageOptions()
    ) async throws -> (image: GeneratedImage, usage: TokenUsageDetails?) {
        
        // Only track tokens for gpt-image-1
        let model = Models.Images.gptImage1
        options.responseFormat = .b64Json // Required for detailed response
        
        let result = try await generateImage(
            prompt: prompt,
            model: model,
            options: options
        )
        
        var tokenDetails: TokenUsageDetails? = nil
        
        if let usage = result.usage {
            tokenDetails = TokenUsageDetails(
                promptTokens: usage.promptTokens ?? 0,
                totalTokens: usage.totalTokens ?? 0,
                inputTokens: usage.inputTokens ?? 0,
                outputTokens: usage.outputTokens ?? 0,
                textTokens: usage.inputTokensDetails?.textTokens ?? 0,
                imageTokens: usage.inputTokensDetails?.imageTokens ?? 0,
                estimatedCost: calculateTokenCost(usage),
                efficiency: calculateEfficiency(prompt: prompt, usage: usage)
            )
            
            // Record for tracking
            tokenTracker.recordUsage(
                usage,
                model: model,
                prompt: prompt,
                imageCount: 1
            )
        }
        
        return (result, tokenDetails)
    }
    
    private let tokenTracker = TokenUsageTracker()
    
    /// Calculate token cost
    private func calculateTokenCost(_ usage: ImageUsage) -> Double {
        let inputRate = 0.015  // per 1K tokens
        let outputRate = 0.03  // per 1K tokens
        
        let inputCost = Double(usage.inputTokens ?? 0) / 1000.0 * inputRate
        let outputCost = Double(usage.outputTokens ?? 0) / 1000.0 * outputRate
        
        return inputCost + outputCost
    }
    
    /// Calculate prompt efficiency
    private func calculateEfficiency(prompt: String, usage: ImageUsage) -> Double {
        let promptLength = prompt.count
        let totalTokens = usage.totalTokens ?? 1
        
        // Higher efficiency = fewer tokens per character
        return Double(promptLength) / Double(totalTokens)
    }
}

/// Record of token usage for a single request
struct TokenUsageRecord {
    let timestamp: Date
    let model: String
    let prompt: String
    let imageCount: Int
    let usage: ImageUsage?
}

/// Aggregated usage statistics
struct UsageStatistics {
    var totalRequests = 0
    var totalImages = 0
    var totalTokens = 0
    var inputTokens = 0
    var outputTokens = 0
    var textTokens = 0
    var imageTokens = 0
    var averageTokensPerRequest = 0.0
    var averageTokensPerImage = 0.0
    var tokensByModel: [String: Int] = [:]
    var estimatedCost = 0.0
}

/// Prompt efficiency metrics
struct PromptEfficiencyMetric {
    let prompt: String
    var uses: Int
    var totalTokens: Int
    var averageTokens: Int
}

/// Detailed token usage information
struct TokenUsageDetails {
    let promptTokens: Int
    let totalTokens: Int
    let inputTokens: Int
    let outputTokens: Int
    let textTokens: Int
    let imageTokens: Int
    let estimatedCost: Double
    let efficiency: Double
    
    var formattedCost: String {
        String(format: "$%.4f", estimatedCost)
    }
    
    var tokensBreakdown: String {
        """
        Total: \(totalTokens) tokens
        Input: \(inputTokens) (Text: \(textTokens), Image: \(imageTokens))
        Output: \(outputTokens)
        Cost: \(formattedCost)
        """
    }
}