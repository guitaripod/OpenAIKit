// Create a data analysis assistant with code interpreter
import Foundation
import OpenAIKit

// Initialize OpenAI client
let openAI = OpenAIKit(
    apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
)

// Configuration for data analysis assistant
struct DataAnalysisConfig {
    let model: Model = .gpt4o
    let temperature: Double = 0.2
    let maxTokens: Int = 4000
    let enableCodeInterpreter: Bool = true
}

// Create the data analysis assistant
class DataAnalysisAssistant {
    private let openAI: OpenAIKit
    private let config: DataAnalysisConfig
    
    init(openAI: OpenAIKit, config: DataAnalysisConfig = DataAnalysisConfig()) {
        self.openAI = openAI
        self.config = config
    }
    
    // System prompt for the assistant
    private var systemPrompt: String {
        """
        You are a data scientist with access to Python code interpreter.
        You can analyze data, perform statistical calculations, and create visualizations.
        
        Your capabilities include:
        - Loading and preprocessing data files (CSV, Excel, JSON)
        - Performing statistical analysis (descriptive stats, correlations, hypothesis testing)
        - Creating visualizations (matplotlib, seaborn, plotly)
        - Building predictive models
        - Generating insights and recommendations
        
        Always:
        1. Start by examining the data structure and quality
        2. Provide clear explanations of your analysis
        3. Include relevant visualizations
        4. Summarize key findings
        """
    }
    
    // Create a chat request with code interpreter enabled
    func createAnalysisRequest(prompt: String) -> ChatRequest {
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

// Example usage
Task {
    let assistant = DataAnalysisAssistant(openAI: openAI)
    
    let request = assistant.createAnalysisRequest(
        prompt: "I need help analyzing sales data to identify trends and patterns."
    )
    
    do {
        let response = try await openAI.chat.completions(request: request)
        print("Assistant: \(response.choices.first?.message.content ?? "")")
    } catch {
        print("Error: \(error)")
    }
}