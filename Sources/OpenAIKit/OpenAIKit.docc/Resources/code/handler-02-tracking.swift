// Error tracking and analytics
import Foundation

class ErrorTracker {
    static let shared = ErrorTracker()
    
    private var errorCounts: [String: Int] = [:]
    private var errorTimestamps: [String: [Date]] = [:]
    private let windowSize: TimeInterval = 3600 // 1 hour
    
    func track(_ error: Error, operation: String) {
        let errorKey = key(for: error)
        
        // Update count
        errorCounts[errorKey, default: 0] += 1
        
        // Track timestamp
        var timestamps = errorTimestamps[errorKey, default: []]
        timestamps.append(Date())
        
        // Remove old timestamps
        let cutoff = Date().addingTimeInterval(-windowSize)
        timestamps.removeAll { $0 < cutoff }
        
        errorTimestamps[errorKey] = timestamps
        
        // Check for error patterns
        checkErrorPatterns(errorKey: errorKey, timestamps: timestamps)
    }
    
    private func key(for error: Error) -> String {
        let details = ErrorAnalyzer.analyze(error)
        return "\(details.type)_\(details.code)"
    }
    
    private func checkErrorPatterns(errorKey: String, timestamps: [Date]) {
        // Alert if too many errors in time window
        if timestamps.count > 10 {
            notifyHighErrorRate(errorKey: errorKey, count: timestamps.count)
        }
    }
    
    private func notifyHighErrorRate(errorKey: String, count: Int) {
        print("⚠️ High error rate detected: \(errorKey) occurred \(count) times in the last hour")
        
        // Could send to analytics service
        // Analytics.track("high_error_rate", properties: ["error": errorKey, "count": count])
    }
    
    func errorRate(for errorKey: String) -> Double {
        let timestamps = errorTimestamps[errorKey, default: []]
        let recentTimestamps = timestamps.filter { 
            $0 > Date().addingTimeInterval(-windowSize) 
        }
        
        return Double(recentTimestamps.count) / (windowSize / 60) // errors per minute
    }
    
    func mostCommonErrors(limit: Int = 5) -> [(error: String, count: Int)] {
        errorCounts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }
}

// Error Dashboard View
struct ErrorDashboard: View {
    @State private var commonErrors: [(error: String, count: Int)] = []
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Error Analytics")
                .font(.title)
            
            ForEach(commonErrors, id: \.error) { item in
                HStack {
                    Text(item.error)
                        .font(.caption)
                    Spacer()
                    Text("\(item.count)")
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 4)
            }
        }
        .onAppear {
            commonErrors = ErrorTracker.shared.mostCommonErrors()
        }
    }
}