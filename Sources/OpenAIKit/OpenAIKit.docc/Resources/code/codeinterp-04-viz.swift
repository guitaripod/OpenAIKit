// Generate visualizations and charts with code interpreter
import Foundation
import OpenAIKit

let openAI = OpenAIKit(
    apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
)

// Visualization types and configurations
enum VisualizationType {
    case line(LineConfig)
    case bar(BarConfig)
    case scatter(ScatterConfig)
    case histogram(HistogramConfig)
    case heatmap(HeatmapConfig)
    case pie(PieConfig)
    case box(BoxConfig)
    case violin(ViolinConfig)
    case surface3D(Surface3DConfig)
    case custom(String)
    
    struct LineConfig {
        let xColumn: String
        let yColumns: [String]
        let title: String
        let smoothing: Bool = false
        let showGrid: Bool = true
        let annotations: [String] = []
    }
    
    struct BarConfig {
        let categories: String
        let values: String
        let orientation: Orientation = .vertical
        let grouped: Bool = false
        let stacked: Bool = false
        
        enum Orientation {
            case vertical, horizontal
        }
    }
    
    struct ScatterConfig {
        let xColumn: String
        let yColumn: String
        let sizeColumn: String? = nil
        let colorColumn: String? = nil
        let trendline: Bool = false
        let confidenceInterval: Bool = false
    }
    
    struct HistogramConfig {
        let column: String
        let bins: Int? = nil
        let density: Bool = false
        let cumulative: Bool = false
        let showNormalCurve: Bool = false
    }
    
    struct HeatmapConfig {
        let xColumn: String
        let yColumn: String
        let valueColumn: String
        let colormap: String = "viridis"
        let annotate: Bool = true
    }
    
    struct PieConfig {
        let labels: String
        let values: String
        let explode: [String] = []
        let showPercentages: Bool = true
    }
    
    struct BoxConfig {
        let column: String
        let groupBy: String? = nil
        let showOutliers: Bool = true
        let notched: Bool = false
    }
    
    struct ViolinConfig {
        let column: String
        let groupBy: String? = nil
        let showBox: Bool = true
        let split: Bool = false
    }
    
    struct Surface3DConfig {
        let xColumn: String
        let yColumn: String
        let zColumn: String
        let colormap: String = "plasma"
        let wireframe: Bool = false
    }
}

// Visualization style presets
enum VisualizationStyle {
    case minimal
    case publication
    case presentation
    case dark
    case colorblind
    
    var styleCode: String {
        switch self {
        case .minimal:
            return """
            plt.style.use('seaborn-v0_8-whitegrid')
            plt.rcParams['figure.facecolor'] = 'white'
            plt.rcParams['axes.facecolor'] = 'white'
            """
        case .publication:
            return """
            plt.style.use('seaborn-v0_8-paper')
            plt.rcParams['figure.dpi'] = 300
            plt.rcParams['savefig.dpi'] = 300
            plt.rcParams['font.size'] = 10
            """
        case .presentation:
            return """
            plt.style.use('seaborn-v0_8-talk')
            plt.rcParams['figure.figsize'] = (12, 8)
            plt.rcParams['font.size'] = 14
            """
        case .dark:
            return """
            plt.style.use('dark_background')
            plt.rcParams['figure.facecolor'] = '#1e1e1e'
            """
        case .colorblind:
            return """
            plt.style.use('seaborn-v0_8-colorblind')
            """
        }
    }
}

// Visualization builder
class VisualizationBuilder {
    static func buildPrompt(
        for visualization: VisualizationType,
        style: VisualizationStyle = .minimal,
        additionalRequirements: String? = nil
    ) -> String {
        
        var prompt = "Create a visualization using the following specifications:\n\n"
        
        // Add style configuration
        prompt += "Style Configuration:\n```python\n\(style.styleCode)\n```\n\n"
        
        // Add visualization-specific instructions
        prompt += "Visualization Type: "
        
        switch visualization {
        case .line(let config):
            prompt += """
            Line Chart
            - X-axis: \(config.xColumn)
            - Y-axis: \(config.yColumns.joined(separator: ", "))
            - Title: \(config.title)
            - Smoothing: \(config.smoothing ? "Apply smoothing" : "No smoothing")
            - Grid: \(config.showGrid ? "Show grid" : "Hide grid")
            \(config.annotations.isEmpty ? "" : "- Annotations: \(config.annotations.joined(separator: ", "))")
            """
            
        case .bar(let config):
            prompt += """
            Bar Chart
            - Categories: \(config.categories)
            - Values: \(config.values)
            - Orientation: \(config.orientation)
            - Grouped: \(config.grouped)
            - Stacked: \(config.stacked)
            """
            
        case .scatter(let config):
            prompt += """
            Scatter Plot
            - X-axis: \(config.xColumn)
            - Y-axis: \(config.yColumn)
            \(config.sizeColumn.map { "- Size by: \($0)" } ?? "")
            \(config.colorColumn.map { "- Color by: \($0)" } ?? "")
            - Trendline: \(config.trendline ? "Include linear trendline" : "No trendline")
            - Confidence Interval: \(config.confidenceInterval ? "Show 95% CI" : "No CI")
            """
            
        case .histogram(let config):
            prompt += """
            Histogram
            - Column: \(config.column)
            \(config.bins.map { "- Bins: \($0)" } ?? "- Bins: Auto-calculate optimal")
            - Density: \(config.density)
            - Cumulative: \(config.cumulative)
            - Normal Curve: \(config.showNormalCurve ? "Overlay normal distribution" : "No normal curve")
            """
            
        case .heatmap(let config):
            prompt += """
            Heatmap
            - X-axis: \(config.xColumn)
            - Y-axis: \(config.yColumn)
            - Values: \(config.valueColumn)
            - Colormap: \(config.colormap)
            - Annotations: \(config.annotate ? "Show values" : "No annotations")
            """
            
        case .pie(let config):
            prompt += """
            Pie Chart
            - Labels: \(config.labels)
            - Values: \(config.values)
            - Explode: \(config.explode.isEmpty ? "None" : config.explode.joined(separator: ", "))
            - Percentages: \(config.showPercentages ? "Show" : "Hide")
            """
            
        case .box(let config):
            prompt += """
            Box Plot
            - Column: \(config.column)
            \(config.groupBy.map { "- Group by: \($0)" } ?? "")
            - Outliers: \(config.showOutliers ? "Show" : "Hide")
            - Notched: \(config.notched)
            """
            
        case .violin(let config):
            prompt += """
            Violin Plot
            - Column: \(config.column)
            \(config.groupBy.map { "- Group by: \($0)" } ?? "")
            - Show Box: \(config.showBox)
            - Split: \(config.split)
            """
            
        case .surface3D(let config):
            prompt += """
            3D Surface Plot
            - X-axis: \(config.xColumn)
            - Y-axis: \(config.yColumn)
            - Z-axis: \(config.zColumn)
            - Colormap: \(config.colormap)
            - Wireframe: \(config.wireframe)
            """
            
        case .custom(let description):
            prompt += "Custom: \(description)"
        }
        
        if let additional = additionalRequirements {
            prompt += "\n\nAdditional Requirements:\n\(additional)"
        }
        
        prompt += """
        
        
        Please ensure:
        1. The visualization is clear and professionally formatted
        2. All axes are properly labeled with units if applicable
        3. Include a legend if multiple series are present
        4. Save the plot as a high-quality image
        5. Return the base64 encoded image data
        6. Include the complete Python code used
        """
        
        return prompt
    }
}

// Enhanced assistant with visualization capabilities
extension DataAnalysisAssistant {
    func createVisualization(
        fileId: String,
        visualization: VisualizationType,
        style: VisualizationStyle = .minimal,
        additionalRequirements: String? = nil
    ) -> ChatRequest {
        
        let vizPrompt = VisualizationBuilder.buildPrompt(
            for: visualization,
            style: style,
            additionalRequirements: additionalRequirements
        )
        
        let fullPrompt = """
        File ID: \(fileId)
        
        \(vizPrompt)
        """
        
        return ChatRequest(
            model: config.model,
            messages: [
                .system(content: systemPrompt),
                .user(content: fullPrompt)
            ],
            temperature: config.temperature,
            maxTokens: config.maxTokens,
            tools: [
                ChatRequest.Tool(type: .codeInterpreter)
            ]
        )
    }
}

// Example usage
Task {
    let assistant = DataAnalysisAssistant(openAI: openAI)
    
    // Example 1: Line chart with multiple series
    let lineChart = VisualizationType.line(
        VisualizationType.LineConfig(
            xColumn: "Date",
            yColumns: ["Revenue", "Costs", "Profit"],
            title: "Financial Performance Over Time",
            smoothing: true,
            annotations: ["Q1 End", "Product Launch", "Q2 End"]
        )
    )
    
    // Example 2: Interactive scatter plot
    let scatterPlot = VisualizationType.scatter(
        VisualizationType.ScatterConfig(
            xColumn: "Marketing_Spend",
            yColumn: "Sales",
            sizeColumn: "Market_Size",
            colorColumn: "Region",
            trendline: true,
            confidenceInterval: true
        )
    )
    
    // Example 3: Statistical visualization
    let violinPlot = VisualizationType.violin(
        VisualizationType.ViolinConfig(
            column: "Customer_Satisfaction",
            groupBy: "Product_Category",
            showBox: true,
            split: false
        )
    )
    
    // Example 4: 3D visualization
    let surface3D = VisualizationType.surface3D(
        VisualizationType.Surface3DConfig(
            xColumn: "Temperature",
            yColumn: "Pressure",
            zColumn: "Yield",
            colormap: "coolwarm"
        )
    )
    
    do {
        // Create a line chart visualization
        let request = assistant.createVisualization(
            fileId: "file-financial-data",
            visualization: lineChart,
            style: .publication,
            additionalRequirements: """
            - Add a subtle background grid
            - Use a color palette suitable for color-blind readers
            - Include data point markers at key events
            - Add a subtitle showing the date range
            """
        )
        
        let response = try await openAI.chat.completions(request: request)
        
        if let content = response.choices.first?.message.content {
            print("Visualization Created:")
            print("=" * 50)
            print(content)
            
            // In a real app, you would extract and display the base64 image
            if let imageData = extractBase64Image(from: content) {
                print("\nImage data received (first 100 chars):")
                print(String(imageData.prefix(100)) + "...")
            }
        }
    } catch {
        print("Error creating visualization: \(error)")
    }
}

// Helper to extract base64 image data
func extractBase64Image(from content: String) -> String? {
    let pattern = "data:image/[^;]+;base64,([A-Za-z0-9+/=]+)"
    let regex = try? NSRegularExpression(pattern: pattern)
    
    if let match = regex?.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
       let range = Range(match.range(at: 1), in: content) {
        return String(content[range])
    }
    
    return nil
}