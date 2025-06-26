// ConversationExporter.swift
import Foundation

class ConversationExporter {
    enum ExportFormat {
        case markdown
        case json
        case csv
    }
    
    func export(messages: [ChatMessage], format: ExportFormat) -> Data? {
        switch format {
        case .markdown:
            return exportAsMarkdown(messages: messages)
        case .json:
            return exportAsJSON(messages: messages)
        case .csv:
            return exportAsCSV(messages: messages)
        }
    }
    
    private func exportAsMarkdown(messages: [ChatMessage]) -> Data? {
        var markdown = "# Conversation Export\n\n"
        
        for message in messages {
            switch message.role {
            case .user:
                markdown += "**You**: \(message.content)\n\n"
            case .assistant:
                markdown += "**Assistant**: \(message.content)\n\n"
            default:
                break
            }
        }
        
        return markdown.data(using: .utf8)
    }
    
    private func exportAsJSON(messages: [ChatMessage]) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(messages)
    }
    
    private func exportAsCSV(messages: [ChatMessage]) -> Data? {
        var csv = "Role,Content\n"
        
        for message in messages {
            let content = message.content.replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\"\(message.role.rawValue)\",\"\(content)\"\n"
        }
        
        return csv.data(using: .utf8)
    }
}
