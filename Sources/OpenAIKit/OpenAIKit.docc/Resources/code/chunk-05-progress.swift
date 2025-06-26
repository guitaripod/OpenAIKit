import SwiftUI
import OpenAIKit
import Combine

// MARK: - Chunk Progress Tracker

class ChunkProgressTracker: ObservableObject {
    @Published var overallProgress: Double = 0
    @Published var currentChunk: Int = 0
    @Published var totalChunks: Int = 0
    @Published var currentChunkProgress: Double = 0
    @Published var status: ProcessingStatus = .idle
    @Published var processingSpeed: Double = 0  // Chunks per minute
    @Published var estimatedTimeRemaining: TimeInterval?
    @Published var errors: [ChunkError] = []
    
    private var startTime: Date?
    private var processedChunks: Set<Int> = []
    private var chunkStartTimes: [Int: Date] = [:]
    
    enum ProcessingStatus {
        case idle
        case preparing
        case processing(chunkIndex: Int)
        case merging
        case completed
        case failed(Error)
        
        var description: String {
            switch self {
            case .idle:
                return "Ready"
            case .preparing:
                return "Preparing audio..."
            case .processing(let index):
                return "Processing chunk \(index + 1)..."
            case .merging:
                return "Merging results..."
            case .completed:
                return "Completed"
            case .failed(let error):
                return "Failed: \(error.localizedDescription)"
            }
        }
    }
    
    func startProcessing(totalChunks: Int) {
        self.totalChunks = totalChunks
        self.currentChunk = 0
        self.overallProgress = 0
        self.status = .preparing
        self.startTime = Date()
        self.processedChunks.removeAll()
        self.chunkStartTimes.removeAll()
        self.errors.removeAll()
    }
    
    func startChunk(_ index: Int) {
        currentChunk = index
        currentChunkProgress = 0
        status = .processing(chunkIndex: index)
        chunkStartTimes[index] = Date()
        updateEstimates()
    }
    
    func updateChunkProgress(_ progress: Double, for index: Int) {
        guard index == currentChunk else { return }
        currentChunkProgress = progress
        updateOverallProgress()
    }
    
    func completeChunk(_ index: Int) {
        processedChunks.insert(index)
        if index == currentChunk {
            currentChunkProgress = 1.0
        }
        updateOverallProgress()
        updateEstimates()
    }
    
    func failChunk(_ index: Int, error: Error) {
        let chunkError = ChunkError(
            chunkIndex: index,
            error: error,
            timestamp: Date()
        )
        errors.append(chunkError)
        
        // Continue with next chunk
        if index == currentChunk && index < totalChunks - 1 {
            startChunk(index + 1)
        }
    }
    
    func startMerging() {
        status = .merging
        currentChunkProgress = 0
    }
    
    func complete() {
        status = .completed
        overallProgress = 1.0
        estimatedTimeRemaining = nil
    }
    
    func fail(with error: Error) {
        status = .failed(error)
    }
    
    private func updateOverallProgress() {
        let completedProgress = Double(processedChunks.count) / Double(max(totalChunks, 1))
        let currentProgress = currentChunkProgress / Double(max(totalChunks, 1))
        overallProgress = completedProgress + currentProgress
    }
    
    private func updateEstimates() {
        guard let startTime = startTime,
              !processedChunks.isEmpty else {
            return
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        let chunksPerSecond = Double(processedChunks.count) / elapsedTime
        processingSpeed = chunksPerSecond * 60  // Convert to chunks per minute
        
        let remainingChunks = totalChunks - processedChunks.count
        if remainingChunks > 0 && chunksPerSecond > 0 {
            estimatedTimeRemaining = Double(remainingChunks) / chunksPerSecond
        } else {
            estimatedTimeRemaining = nil
        }
    }
    
    var formattedTimeRemaining: String {
        guard let time = estimatedTimeRemaining else {
            return "Calculating..."
        }
        
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s remaining"
        } else {
            return "\(seconds)s remaining"
        }
    }
    
    var successRate: Double {
        guard totalChunks > 0 else { return 0 }
        let failedCount = errors.count
        let successCount = processedChunks.count - failedCount
        return Double(successCount) / Double(processedChunks.count)
    }
}

// MARK: - Progress View

struct ChunkProgressView: View {
    @ObservedObject var tracker: ChunkProgressTracker
    @State private var showingErrors = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Status Header
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .font(.title2)
                
                Text(tracker.status.description)
                    .font(.headline)
                
                Spacer()
                
                if !tracker.errors.isEmpty {
                    Button(action: { showingErrors = true }) {
                        Label("\(tracker.errors.count)", systemImage: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Overall Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Overall Progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(tracker.overallProgress * 100))%")
                        .font(.subheadline)
                        .monospacedDigit()
                }
                
                ProgressView(value: tracker.overallProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
            
            // Chunk Progress
            if case .processing = tracker.status {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Chunk \(tracker.currentChunk + 1) of \(tracker.totalChunks)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(tracker.currentChunkProgress * 100))%")
                            .font(.subheadline)
                            .monospacedDigit()
                    }
                    
                    ProgressView(value: tracker.currentChunkProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                }
            }
            
            // Statistics
            HStack(spacing: 30) {
                // Processing Speed
                VStack(alignment: .leading) {
                    Text("Speed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(tracker.processingSpeed, specifier: "%.1f") chunks/min")
                        .font(.caption)
                        .monospacedDigit()
                }
                
                // Time Remaining
                VStack(alignment: .leading) {
                    Text("Time Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(tracker.formattedTimeRemaining)
                        .font(.caption)
                        .monospacedDigit()
                }
                
                // Success Rate
                if tracker.processedChunks.count > 0 {
                    VStack(alignment: .leading) {
                        Text("Success Rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(tracker.successRate * 100))%")
                            .font(.caption)
                            .monospacedDigit()
                    }
                }
                
                Spacer()
            }
            
            // Visual Progress Indicator
            ChunkVisualizer(
                totalChunks: tracker.totalChunks,
                processedChunks: tracker.processedChunks,
                currentChunk: tracker.currentChunk,
                errors: Set(tracker.errors.map { $0.chunkIndex })
            )
            .frame(height: 40)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingErrors) {
            ErrorListView(errors: tracker.errors)
        }
    }
    
    private var statusIcon: String {
        switch tracker.status {
        case .idle:
            return "circle"
        case .preparing:
            return "gear"
        case .processing:
            return "waveform"
        case .merging:
            return "arrow.triangle.merge"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch tracker.status {
        case .idle:
            return .gray
        case .preparing, .processing, .merging:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
}

// MARK: - Chunk Visualizer

struct ChunkVisualizer: View {
    let totalChunks: Int
    let processedChunks: Set<Int>
    let currentChunk: Int
    let errors: Set<Int>
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<totalChunks, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(chunkColor(for: index))
                        .frame(width: max(2, (geometry.size.width - CGFloat(totalChunks - 1) * 2) / CGFloat(totalChunks)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(index == currentChunk ? Color.white : Color.clear, lineWidth: 2)
                        )
                }
            }
        }
    }
    
    private func chunkColor(for index: Int) -> Color {
        if errors.contains(index) {
            return .red
        } else if processedChunks.contains(index) {
            return .green
        } else if index == currentChunk {
            return .blue
        } else {
            return .gray.opacity(0.3)
        }
    }
}

// MARK: - Error List View

struct ErrorListView: View {
    let errors: [ChunkError]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(errors) { error in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Chunk \(error.chunkIndex + 1)")
                            .font(.headline)
                        Spacer()
                        Text(error.timestamp, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(error.error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Processing Errors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Models

struct ChunkError: Identifiable {
    let id = UUID()
    let chunkIndex: Int
    let error: Error
    let timestamp: Date
}

// MARK: - Progress Manager

class ChunkProgressManager {
    private let tracker = ChunkProgressTracker()
    private var cancellables = Set<AnyCancellable>()
    
    func processAudioWithProgress(
        url: URL,
        options: ProcessingOptions,
        completion: @escaping (Result<MergedTranscriptionResult, Error>) -> Void
    ) {
        Task {
            do {
                // Prepare chunks
                tracker.startProcessing(totalChunks: 0)
                
                let chunkManager = AudioChunkManager()
                let chunkingResult = try await chunkManager.prepareAudioFile(url)
                
                tracker.startProcessing(totalChunks: chunkingResult.chunks.count)
                
                // Process chunks
                let processor = ChunkProcessor(apiKey: AppSettings.shared.getAPIKey() ?? "")
                var results: [ChunkTranscriptionResult] = []
                
                for (index, chunk) in chunkingResult.chunks.enumerated() {
                    tracker.startChunk(index)
                    
                    do {
                        let result = try await processor.processChunkWithRetry(
                            chunk,
                            options: options
                        )
                        results.append(result)
                        tracker.completeChunk(index)
                    } catch {
                        tracker.failChunk(index, error: error)
                        // Continue with next chunk
                    }
                }
                
                // Merge results
                tracker.startMerging()
                let merged = processor.mergeChunkResults(results)
                
                tracker.complete()
                completion(.success(merged))
                
            } catch {
                tracker.fail(with: error)
                completion(.failure(error))
            }
        }
    }
}