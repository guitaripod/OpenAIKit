// Upload data files for analysis with code interpreter
import Foundation
import OpenAIKit

let openAI = OpenAIKit(
    apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
)

// File upload manager for data analysis
class DataFileManager {
    private let openAI: OpenAIKit
    private var uploadedFiles: [String: FileInfo] = [:]
    
    struct FileInfo {
        let id: String
        let name: String
        let size: Int
        let type: FileType
        let uploadedAt: Date
    }
    
    enum FileType {
        case csv
        case excel
        case json
        case parquet
        case text
        
        var mimeType: String {
            switch self {
            case .csv: return "text/csv"
            case .excel: return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            case .json: return "application/json"
            case .parquet: return "application/octet-stream"
            case .text: return "text/plain"
            }
        }
    }
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
    }
    
    // Upload a data file for analysis
    func uploadDataFile(
        data: Data,
        fileName: String,
        fileType: FileType
    ) async throws -> String {
        // In a real implementation, this would upload to OpenAI's file storage
        // For now, we'll simulate the upload process
        
        let fileId = "file-\(UUID().uuidString)"
        let fileInfo = FileInfo(
            id: fileId,
            name: fileName,
            size: data.count,
            type: fileType,
            uploadedAt: Date()
        )
        
        uploadedFiles[fileId] = fileInfo
        
        print("Uploaded file: \(fileName)")
        print("File ID: \(fileId)")
        print("Size: \(formatBytes(data.count))")
        print("Type: \(fileType)")
        
        return fileId
    }
    
    // Load file from URL
    func uploadFileFromURL(url: URL) async throws -> String {
        let data = try Data(contentsOf: url)
        let fileName = url.lastPathComponent
        let fileType = detectFileType(from: url.pathExtension)
        
        return try await uploadDataFile(
            data: data,
            fileName: fileName,
            fileType: fileType
        )
    }
    
    // Helper to detect file type
    private func detectFileType(from extension: String) -> FileType {
        switch extension.lowercased() {
        case "csv": return .csv
        case "xlsx", "xls": return .excel
        case "json": return .json
        case "parquet": return .parquet
        default: return .text
        }
    }
    
    // Format bytes for display
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// Extended DataAnalysisAssistant with file support
extension DataAnalysisAssistant {
    func analyzeFile(
        fileId: String,
        analysisPrompt: String
    ) -> ChatRequest {
        let prompt = """
        File ID: \(fileId)
        
        \(analysisPrompt)
        
        Please load the file and perform the requested analysis.
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
    let fileManager = DataFileManager(openAI: openAI)
    let assistant = DataAnalysisAssistant(openAI: openAI)
    
    // Create sample CSV data
    let csvData = """
    Date,Product,Sales,Quantity
    2024-01-01,Widget A,1500,30
    2024-01-02,Widget B,2300,45
    2024-01-03,Widget A,1800,35
    2024-01-04,Widget C,3200,50
    2024-01-05,Widget B,2100,40
    """.data(using: .utf8)!
    
    do {
        // Upload the file
        let fileId = try await fileManager.uploadDataFile(
            data: csvData,
            fileName: "sales_data.csv",
            fileType: .csv
        )
        
        // Request analysis
        let request = assistant.analyzeFile(
            fileId: fileId,
            analysisPrompt: """
            Please analyze this sales data:
            1. Calculate total sales by product
            2. Find the average daily sales
            3. Create a bar chart showing sales by product
            4. Identify any trends or patterns
            """
        )
        
        let response = try await openAI.chat.completions(request: request)
        print("\nAnalysis Results:")
        print(response.choices.first?.message.content ?? "")
        
    } catch {
        print("Error: \(error)")
    }
}