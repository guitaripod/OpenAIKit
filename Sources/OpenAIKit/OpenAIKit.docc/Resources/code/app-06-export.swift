import SwiftUI
import OpenAIKit
import UniformTypeIdentifiers

// MARK: - Export Manager

class ExportManager: ObservableObject {
    @Published var isExporting = false
    @Published var exportProgress: Double = 0
    @Published var exportError: Error?
    
    enum ExportFormat {
        case txt
        case srt
        case vtt
        case json
        case csv
        case pdf
        
        var fileExtension: String {
            switch self {
            case .txt: return "txt"
            case .srt: return "srt"
            case .vtt: return "vtt"
            case .json: return "json"
            case .csv: return "csv"
            case .pdf: return "pdf"
            }
        }
        
        var contentType: UTType {
            switch self {
            case .txt: return .plainText
            case .srt: return .plainText
            case .vtt: return .plainText
            case .json: return .json
            case .csv: return .commaSeparatedText
            case .pdf: return .pdf
            }
        }
    }
    
    func exportRecording(
        _ recording: Recording,
        format: ExportFormat,
        includeMetadata: Bool = true
    ) async throws -> URL {
        isExporting = true
        exportProgress = 0
        
        defer {
            isExporting = false
        }
        
        let content: String
        
        switch format {
        case .txt:
            content = try createTextExport(recording, includeMetadata: includeMetadata)
        case .srt:
            content = try createSRTExport(recording)
        case .vtt:
            content = try createVTTExport(recording)
        case .json:
            content = try createJSONExport(recording)
        case .csv:
            content = try createCSVExport(recording)
        case .pdf:
            return try await createPDFExport(recording)
        }
        
        // Save to temporary file
        let fileName = "\(recording.name).\(format.fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try content.write(to: tempURL, atomically: true, encoding: .utf8)
        
        exportProgress = 1.0
        return tempURL
    }
    
    func exportMultipleRecordings(
        _ recordings: [Recording],
        format: ExportFormat
    ) async throws -> URL {
        isExporting = true
        exportProgress = 0
        
        defer {
            isExporting = false
        }
        
        var exportedFiles: [URL] = []
        
        for (index, recording) in recordings.enumerated() {
            let fileURL = try await exportRecording(recording, format: format)
            exportedFiles.append(fileURL)
            
            exportProgress = Double(index + 1) / Double(recordings.count)
        }
        
        // Create zip archive
        let zipURL = try createZipArchive(from: exportedFiles, name: "recordings_export")
        
        // Clean up temporary files
        for url in exportedFiles {
            try? FileManager.default.removeItem(at: url)
        }
        
        return zipURL
    }
    
    // MARK: - Export Formats
    
    private func createTextExport(_ recording: Recording, includeMetadata: Bool) throws -> String {
        var content = ""
        
        if includeMetadata {
            content += "Recording: \(recording.name)\n"
            content += "Date: \(recording.formattedDate)\n"
            content += "Duration: \(recording.formattedDuration)\n"
            content += "\n---\n\n"
        }
        
        content += recording.transcription ?? "No transcription available"
        
        return content
    }
    
    private func createSRTExport(_ recording: Recording) throws -> String {
        guard let segments = loadSegments(for: recording), !segments.isEmpty else {
            throw ExportError.noTimestamps
        }
        
        var srt = ""
        
        for (index, segment) in segments.enumerated() {
            srt += "\(index + 1)\n"
            srt += "\(formatSRTTime(segment.start ?? 0)) --> \(formatSRTTime(segment.end ?? 0))\n"
            srt += "\(segment.text)\n\n"
        }
        
        return srt
    }
    
    private func createVTTExport(_ recording: Recording) throws -> String {
        guard let segments = loadSegments(for: recording), !segments.isEmpty else {
            throw ExportError.noTimestamps
        }
        
        var vtt = "WEBVTT\n\n"
        
        for segment in segments {
            vtt += "\(formatVTTTime(segment.start ?? 0)) --> \(formatVTTTime(segment.end ?? 0))\n"
            vtt += "\(segment.text)\n\n"
        }
        
        return vtt
    }
    
    private func createJSONExport(_ recording: Recording) throws -> String {
        let exportData = RecordingExportData(
            name: recording.name,
            date: recording.date,
            duration: recording.duration,
            transcription: recording.transcription,
            segments: loadSegments(for: recording)
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(exportData)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
    
    private func createCSVExport(_ recording: Recording) throws -> String {
        var csv = "Time,Text\n"
        
        if let segments = loadSegments(for: recording) {
            for segment in segments {
                let time = formatTime(segment.start ?? 0)
                let text = segment.text.replacingOccurrences(of: "\"", with: "\"\"")
                csv += "\"\(time)\",\"\(text)\"\n"
            }
        } else {
            csv += "\"00:00\",\"\(recording.transcription ?? "")\"\n"
        }
        
        return csv
    }
    
    private func createPDFExport(_ recording: Recording) async throws -> URL {
        // Create PDF using Core Graphics
        let pdfURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(recording.name).pdf")
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold)
            ]
            
            let titleRect = CGRect(x: 50, y: 50, width: 512, height: 40)
            recording.name.draw(in: titleRect, withAttributes: attributes)
            
            // Add metadata
            let metadataAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.gray
            ]
            
            let metadata = "Date: \(recording.formattedDate) | Duration: \(recording.formattedDuration)"
            let metadataRect = CGRect(x: 50, y: 100, width: 512, height: 20)
            metadata.draw(in: metadataRect, withAttributes: metadataAttributes)
            
            // Add transcription
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12)
            ]
            
            let text = recording.transcription ?? "No transcription available"
            let textRect = CGRect(x: 50, y: 140, width: 512, height: 600)
            text.draw(in: textRect, withAttributes: textAttributes)
        }
        
        try data.write(to: pdfURL)
        return pdfURL
    }
    
    // MARK: - Helper Functions
    
    private func loadSegments(for recording: Recording) -> [TranscriptionSegment]? {
        // In a real app, you'd load segments from storage
        // For now, return nil to indicate no segments available
        return nil
    }
    
    private func formatSRTTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, milliseconds)
    }
    
    private func formatVTTTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        
        return String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func createZipArchive(from files: [URL], name: String) throws -> URL {
        // Simple implementation - in production use a proper zip library
        let zipURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name).zip")
        
        // For now, just return the first file
        // In a real app, you'd create a proper zip archive
        if let firstFile = files.first {
            try FileManager.default.copyItem(at: firstFile, to: zipURL)
        }
        
        return zipURL
    }
}

// MARK: - Export View

struct ExportView: View {
    let recording: Recording
    @StateObject private var exportManager = ExportManager()
    @State private var selectedFormat: ExportManager.ExportFormat = .txt
    @State private var includeMetadata = true
    @State private var showingShareSheet = false
    @State private var exportedURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Export Format") {
                    ForEach(exportFormats, id: \.0) { format, description in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(description)
                                    .font(.headline)
                                Text(format.fileExtension.uppercased())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedFormat == format {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedFormat = format
                        }
                    }
                }
                
                Section("Options") {
                    Toggle("Include Metadata", isOn: $includeMetadata)
                        .disabled(selectedFormat == .srt || selectedFormat == .vtt)
                }
                
                Section {
                    Button(action: performExport) {
                        if exportManager.isExporting {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Exporting...")
                            }
                        } else {
                            Label("Export Recording", systemImage: "square.and.arrow.up")
                        }
                    }
                    .disabled(exportManager.isExporting)
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Export Error", isPresented: .constant(exportManager.exportError != nil)) {
                Button("OK") {
                    exportManager.exportError = nil
                }
            } message: {
                Text(exportManager.exportError?.localizedDescription ?? "Unknown error")
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    private var exportFormats: [(ExportManager.ExportFormat, String)] {
        [
            (.txt, "Plain Text"),
            (.srt, "SubRip Subtitle"),
            (.vtt, "WebVTT Subtitle"),
            (.json, "JSON Data"),
            (.csv, "Spreadsheet"),
            (.pdf, "PDF Document")
        ]
    }
    
    private func performExport() {
        Task {
            do {
                let url = try await exportManager.exportRecording(
                    recording,
                    format: selectedFormat,
                    includeMetadata: includeMetadata
                )
                
                await MainActor.run {
                    exportedURL = url
                    showingShareSheet = true
                }
            } catch {
                await MainActor.run {
                    exportManager.exportError = error
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Models

struct RecordingExportData: Codable {
    let name: String
    let date: Date
    let duration: TimeInterval
    let transcription: String?
    let segments: [TranscriptionSegment]?
}

enum ExportError: LocalizedError {
    case noTimestamps
    case exportFailed
    
    var errorDescription: String? {
        switch self {
        case .noTimestamps:
            return "This format requires timestamp information, which is not available for this recording."
        case .exportFailed:
            return "Failed to export the recording. Please try again."
        }
    }
}