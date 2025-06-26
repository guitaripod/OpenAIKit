// Request statistical analysis with code execution
import Foundation
import OpenAIKit

let openAI = OpenAIKit(
    apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
)

// Statistical analysis types
enum StatisticalAnalysis {
    case descriptive
    case correlation
    case regression
    case timeSeries
    case hypothesis(test: HypothesisTest)
    case anova
    case clustering(method: ClusteringMethod)
    
    enum HypothesisTest {
        case tTest
        case chiSquare
        case mannWhitney
        case kolmogorovSmirnov
    }
    
    enum ClusteringMethod {
        case kMeans(clusters: Int)
        case hierarchical
        case dbscan
    }
    
    var prompt: String {
        switch self {
        case .descriptive:
            return """
            Perform comprehensive descriptive statistics:
            - Calculate mean, median, mode, std deviation, variance
            - Generate quartiles and percentiles
            - Check for outliers using IQR method
            - Create distribution plots (histogram, box plot)
            - Test for normality (Shapiro-Wilk test)
            """
            
        case .correlation:
            return """
            Perform correlation analysis:
            - Calculate Pearson and Spearman correlations
            - Create correlation matrix heatmap
            - Identify significant correlations (p < 0.05)
            - Generate scatter plots for top correlations
            - Provide interpretation of relationships
            """
            
        case .regression:
            return """
            Perform regression analysis:
            - Build linear regression model
            - Check assumptions (linearity, normality, homoscedasticity)
            - Calculate R-squared and adjusted R-squared
            - Generate residual plots
            - Provide coefficient interpretation
            - Test for multicollinearity if multiple predictors
            """
            
        case .timeSeries:
            return """
            Perform time series analysis:
            - Plot time series with trend line
            - Decompose into trend, seasonal, and residual components
            - Test for stationarity (ADF test)
            - Calculate autocorrelation (ACF) and partial autocorrelation (PACF)
            - Identify patterns and anomalies
            - Forecast future values if appropriate
            """
            
        case .hypothesis(let test):
            return hypothesisTestPrompt(for: test)
            
        case .anova:
            return """
            Perform ANOVA analysis:
            - Test assumptions (normality, homogeneity of variance)
            - Calculate F-statistic and p-value
            - Perform post-hoc tests if significant
            - Create box plots by group
            - Provide interpretation of results
            """
            
        case .clustering(let method):
            return clusteringPrompt(for: method)
        }
    }
    
    private func hypothesisTestPrompt(for test: HypothesisTest) -> String {
        switch test {
        case .tTest:
            return "Perform t-test analysis with effect size calculation"
        case .chiSquare:
            return "Perform chi-square test of independence"
        case .mannWhitney:
            return "Perform Mann-Whitney U test for non-parametric data"
        case .kolmogorovSmirnov:
            return "Perform Kolmogorov-Smirnov test for distribution comparison"
        }
    }
    
    private func clusteringPrompt(for method: ClusteringMethod) -> String {
        switch method {
        case .kMeans(let clusters):
            return "Perform k-means clustering with \(clusters) clusters, include elbow method validation"
        case .hierarchical:
            return "Perform hierarchical clustering with dendrogram"
        case .dbscan:
            return "Perform DBSCAN clustering for density-based grouping"
        }
    }
}

// Statistical analysis results
struct StatisticalResults {
    let summary: String
    let statistics: [String: Any]
    let plots: [String]  // Base64 encoded images
    let code: String
    let interpretation: String
}

// Enhanced assistant with statistical capabilities
extension DataAnalysisAssistant {
    func performStatisticalAnalysis(
        fileId: String,
        analysis: StatisticalAnalysis,
        columns: [String]? = nil,
        additionalInstructions: String? = nil
    ) -> ChatRequest {
        
        var prompt = """
        File ID: \(fileId)
        
        \(analysis.prompt)
        """
        
        if let columns = columns {
            prompt += "\n\nFocus on these columns: \(columns.joined(separator: ", "))"
        }
        
        if let additional = additionalInstructions {
            prompt += "\n\nAdditional requirements: \(additional)"
        }
        
        prompt += """
        
        Please ensure all code is well-commented and reproducible.
        Include both the analysis results and the Python code used.
        """
        
        return ChatRequest(
            model: config.model,
            messages: [
                .system(content: systemPrompt),
                .user(content: prompt)
            ],
            temperature: config.temperature,
            maxTokens: config.maxTokens,
            tools: [
                ChatRequest.Tool(type: .codeInterpreter)
            ]
        )
    }
}

// Example usage with different statistical analyses
Task {
    let assistant = DataAnalysisAssistant(openAI: openAI)
    
    // Example 1: Descriptive statistics
    let descriptiveRequest = assistant.performStatisticalAnalysis(
        fileId: "file-sales-data",
        analysis: .descriptive,
        columns: ["Sales", "Quantity"]
    )
    
    // Example 2: Correlation analysis
    let correlationRequest = assistant.performStatisticalAnalysis(
        fileId: "file-customer-data",
        analysis: .correlation,
        additionalInstructions: "Focus on relationships between customer age, purchase frequency, and total spending"
    )
    
    // Example 3: Time series analysis
    let timeSeriesRequest = assistant.performStatisticalAnalysis(
        fileId: "file-monthly-revenue",
        analysis: .timeSeries,
        columns: ["Date", "Revenue"],
        additionalInstructions: "Forecast the next 3 months using ARIMA if appropriate"
    )
    
    // Example 4: Clustering analysis
    let clusteringRequest = assistant.performStatisticalAnalysis(
        fileId: "file-customer-segments",
        analysis: .clustering(method: .kMeans(clusters: 4)),
        columns: ["Age", "Income", "SpendingScore"],
        additionalInstructions: "Provide customer segment profiles based on the clusters"
    )
    
    do {
        // Execute one of the analyses
        let response = try await openAI.chat.completions(request: descriptiveRequest)
        
        if let content = response.choices.first?.message.content {
            print("Statistical Analysis Results:")
            print("=" * 50)
            print(content)
            
            // Extract code blocks if present
            let codeBlocks = extractCodeBlocks(from: content)
            if !codeBlocks.isEmpty {
                print("\nExtracted Python Code:")
                print("=" * 50)
                for (index, code) in codeBlocks.enumerated() {
                    print("Code Block \(index + 1):")
                    print(code)
                    print()
                }
            }
        }
    } catch {
        print("Error performing analysis: \(error)")
    }
}

// Helper function to extract code blocks
func extractCodeBlocks(from content: String) -> [String] {
    let pattern = "```python\n(.*?)\n```"
    let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
    let matches = regex?.matches(in: content, range: NSRange(content.startIndex..., in: content)) ?? []
    
    return matches.compactMap { match in
        if let range = Range(match.range(at: 1), in: content) {
            return String(content[range])
        }
        return nil
    }
}