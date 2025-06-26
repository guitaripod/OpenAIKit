// Export results and generated code from code interpreter
import Foundation
import OpenAIKit

let openAI = OpenAIKit(
    apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
)

// Export formats for analysis results
enum ExportFormat {
    case jupyterNotebook
    case pythonScript
    case htmlReport
    case pdfReport
    case markdownReport
    case excelWorkbook
    case powerpoint
    
    var fileExtension: String {
        switch self {
        case .jupyterNotebook: return "ipynb"
        case .pythonScript: return "py"
        case .htmlReport: return "html"
        case .pdfReport: return "pdf"
        case .markdownReport: return "md"
        case .excelWorkbook: return "xlsx"
        case .powerpoint: return "pptx"
        }
    }
    
    var mimeType: String {
        switch self {
        case .jupyterNotebook: return "application/x-ipynb+json"
        case .pythonScript: return "text/x-python"
        case .htmlReport: return "text/html"
        case .pdfReport: return "application/pdf"
        case .markdownReport: return "text/markdown"
        case .excelWorkbook: return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case .powerpoint: return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        }
    }
}

// Analysis export manager
class AnalysisExporter {
    private let openAI: OpenAIKit
    private var analysisHistory: [AnalysisRecord] = []
    
    struct AnalysisRecord {
        let id: String
        let timestamp: Date
        let fileIds: [String]
        let analysisType: String
        let results: String
        let code: [CodeBlock]
        let visualizations: [VisualizationData]
    }
    
    struct CodeBlock {
        let language: String
        let code: String
        let description: String
        let imports: [String]
    }
    
    struct VisualizationData {
        let type: String
        let base64Data: String
        let caption: String
    }
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
    }
    
    // Export complete analysis to specified format
    func exportAnalysis(
        analysisId: String,
        format: ExportFormat,
        options: ExportOptions = ExportOptions()
    ) async throws -> ExportResult {
        
        guard let record = analysisHistory.first(where: { $0.id == analysisId }) else {
            throw ExportError.analysisNotFound
        }
        
        let exportPrompt = buildExportPrompt(
            record: record,
            format: format,
            options: options
        )
        
        let request = ChatRequest(
            model: .gpt4o,
            messages: [
                .system(content: """
                You are an expert at creating professional data analysis reports.
                Generate well-structured exports that include all analysis results,
                code, visualizations, and insights.
                """),
                .user(content: exportPrompt)
            ],
            temperature: 0.3,
            maxTokens: 8000,
            tools: [
                ChatRequest.Tool(type: .codeInterpreter)
            ]
        )
        
        let response = try await openAI.chat.completions(request: request)
        
        return processExportResponse(
            response: response,
            format: format,
            analysisId: analysisId
        )
    }
    
    // Build export prompt based on format
    private func buildExportPrompt(
        record: AnalysisRecord,
        format: ExportFormat,
        options: ExportOptions
    ) -> String {
        
        var prompt = "Create a \(format) export with the following content:\n\n"
        
        prompt += """
        Analysis ID: \(record.id)
        Date: \(record.timestamp)
        Type: \(record.analysisType)
        
        """
        
        switch format {
        case .jupyterNotebook:
            prompt += """
            Create a Jupyter notebook with:
            1. Title and metadata cell
            2. Import statements cell
            3. Data loading cell
            4. Analysis cells with markdown explanations
            5. Visualization cells
            6. Conclusion cell
            
            Structure:
            - Use markdown cells for explanations
            - Include all Python code in executable cells
            - Add inline visualizations
            - Include cell outputs
            """
            
        case .pythonScript:
            prompt += """
            Create a well-documented Python script with:
            1. Module docstring
            2. Import statements
            3. Configuration constants
            4. Main analysis functions
            5. Visualization functions
            6. Main execution block
            
            Include:
            - Type hints
            - Comprehensive docstrings
            - Error handling
            - Logging statements
            """
            
        case .htmlReport:
            prompt += """
            Create an HTML report with:
            1. Professional CSS styling
            2. Interactive table of contents
            3. Embedded visualizations
            4. Code snippets with syntax highlighting
            5. Responsive design
            
            Sections:
            - Executive Summary
            - Methodology
            - Results & Visualizations
            - Key Findings
            - Recommendations
            - Appendix with full code
            """
            
        case .pdfReport:
            prompt += """
            Create a PDF report structure using LaTeX/Markdown with:
            1. Title page
            2. Table of contents
            3. Executive summary
            4. Detailed analysis sections
            5. High-quality visualizations
            6. References and appendices
            
            Format for professional presentation.
            """
            
        case .markdownReport:
            prompt += """
            Create a comprehensive Markdown report with:
            1. Clear hierarchy with headers
            2. Code blocks with language tags
            3. Embedded images (base64)
            4. Tables for data summaries
            5. Links and cross-references
            
            GitHub-flavored Markdown format.
            """
            
        case .excelWorkbook:
            prompt += """
            Create Excel workbook structure with:
            1. Summary sheet
            2. Raw data sheet
            3. Analysis results sheets
            4. Charts sheet
            5. Python code sheet
            
            Include formulas and pivot tables where appropriate.
            """
            
        case .powerpoint:
            prompt += """
            Create PowerPoint presentation structure with:
            1. Title slide
            2. Agenda slide
            3. Key findings slides (3-5)
            4. Visualization slides
            5. Recommendations slide
            6. Appendix with technical details
            
            Focus on visual impact and clarity.
            """
        }
        
        if options.includeRawData {
            prompt += "\n\nInclude raw data tables or links."
        }
        
        if options.includeMethodology {
            prompt += "\n\nInclude detailed methodology section."
        }
        
        if let customSections = options.customSections {
            prompt += "\n\nAdditional sections: \(customSections.joined(separator: ", "))"
        }
        
        return prompt
    }
    
    // Process export response
    private func processExportResponse(
        response: ChatResponse,
        format: ExportFormat,
        analysisId: String
    ) -> ExportResult {
        
        let content = response.choices.first?.message.content ?? ""
        
        return ExportResult(
            analysisId: analysisId,
            format: format,
            content: content,
            fileSize: content.data(using: .utf8)?.count ?? 0,
            exportDate: Date()
        )
    }
}

// Export options
struct ExportOptions {
    var includeRawData: Bool = false
    var includeMethodology: Bool = true
    var includeCodeComments: Bool = true
    var customSections: [String]? = nil
    var theme: ExportTheme = .professional
    
    enum ExportTheme {
        case minimal
        case professional
        case academic
        case corporate
    }
}

// Export result
struct ExportResult {
    let analysisId: String
    let format: ExportFormat
    let content: String
    let fileSize: Int
    let exportDate: Date
    
    // Save to file
    func save(to url: URL) throws {
        guard let data = content.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        try data.write(to: url)
    }
}

// Export errors
enum ExportError: Error {
    case analysisNotFound
    case exportFailed
    case encodingFailed
    case invalidFormat
}

// Enhanced assistant with export capabilities
extension DataAnalysisAssistant {
    func exportAnalysisSession(
        sessionId: String,
        format: ExportFormat,
        includeAllResults: Bool = true
    ) -> ChatRequest {
        
        let prompt = """
        Export the complete analysis session (ID: \(sessionId)) to \(format) format.
        
        Include:
        - All analysis results
        - All generated visualizations
        - Complete Python code with comments
        - Summary of key findings
        - Recommendations based on the analysis
        
        \(includeAllResults ? "Include all intermediate results and iterations." : "Include only final results.")
        
        Ensure the export is self-contained and can be shared or presented independently.
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

// Example usage
Task {
    let assistant = DataAnalysisAssistant(openAI: openAI)
    let exporter = AnalysisExporter(openAI: openAI)
    
    // Simulate an analysis session
    let sessionId = "analysis-\(UUID().uuidString)"
    
    // Request export to Jupyter notebook
    let exportRequest = assistant.exportAnalysisSession(
        sessionId: sessionId,
        format: .jupyterNotebook,
        includeAllResults: true
    )
    
    do {
        let response = try await openAI.chat.completions(request: exportRequest)
        
        if let content = response.choices.first?.message.content {
            print("Export Generated:")
            print("=" * 50)
            
            // Show first part of the export
            let preview = String(content.prefix(1000))
            print(preview)
            print("\n... (truncated)")
            
            // Save to file
            let documentsPath = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first!
            
            let exportURL = documentsPath.appendingPathComponent(
                "analysis_\(sessionId).ipynb"
            )
            
            let exportResult = ExportResult(
                analysisId: sessionId,
                format: .jupyterNotebook,
                content: content,
                fileSize: content.count,
                exportDate: Date()
            )
            
            try exportResult.save(to: exportURL)
            print("\nExport saved to: \(exportURL.path)")
            print("File size: \(exportResult.fileSize) bytes")
        }
        
    } catch {
        print("Error exporting analysis: \(error)")
    }
}