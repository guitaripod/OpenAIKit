// Error state management
import SwiftUI
import Combine

@MainActor
class ErrorStateManager: ObservableObject {
    @Published var errors: [UUID: Error] = [:]
    @Published var isRetrying: [UUID: Bool] = [:]
    @Published var errorStates: [UUID: ErrorState] = [:]
    
    enum ErrorState {
        case active
        case recovering
        case resolved
        case dismissed
    }
    
    func setError(_ error: Error, for id: UUID) {
        errors[id] = error
        errorStates[id] = .active
    }
    
    func clearError(for id: UUID) {
        errors.removeValue(forKey: id)
        errorStates.removeValue(forKey: id)
        isRetrying.removeValue(forKey: id)
    }
    
    func startRetry(for id: UUID) {
        isRetrying[id] = true
        errorStates[id] = .recovering
    }
    
    func endRetry(for id: UUID, success: Bool) {
        isRetrying[id] = false
        if success {
            errorStates[id] = .resolved
            // Clear after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.clearError(for: id)
            }
        } else {
            errorStates[id] = .active
        }
    }
}

// Usage in a view
struct ContentViewWithErrors: View {
    @StateObject private var errorManager = ErrorStateManager()
    @State private var taskId = UUID()
    
    var body: some View {
        VStack {
            // Main content
            Button("Perform Task") {
                Task {
                    await performTask()
                }
            }
            
            // Error display
            if let error = errorManager.errors[taskId] {
                ErrorRow(
                    error: error,
                    state: errorManager.errorStates[taskId] ?? .active,
                    isRetrying: errorManager.isRetrying[taskId] ?? false,
                    onRetry: {
                        Task {
                            await retryTask()
                        }
                    },
                    onDismiss: {
                        errorManager.clearError(for: taskId)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(), value: errorManager.errors.count)
    }
    
    private func performTask() async {
        do {
            // Perform operation
            _ = try await sendChatMessage("Hello")
        } catch {
            errorManager.setError(error, for: taskId)
        }
    }
    
    private func retryTask() async {
        errorManager.startRetry(for: taskId)
        
        do {
            // Retry operation
            _ = try await sendChatMessage("Hello")
            errorManager.endRetry(for: taskId, success: true)
        } catch {
            errorManager.setError(error, for: taskId)
            errorManager.endRetry(for: taskId, success: false)
        }
    }
}

struct ErrorRow: View {
    let error: Error
    let state: ErrorStateManager.ErrorState
    let isRetrying: Bool
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .animation(.easeInOut, value: state)
            
            VStack(alignment: .leading) {
                Text(ErrorMessageMapper.userFriendlyMessage(for: error))
                    .font(.subheadline)
                
                if state == .resolved {
                    Text("Resolved")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            if isRetrying {
                ProgressView()
                    .scaleEffect(0.8)
            } else if state == .active {
                Button("Retry", action: onRetry)
                    .font(.caption)
            }
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(8)
    }
    
    private var iconName: String {
        switch state {
        case .active:
            return "exclamationmark.triangle.fill"
        case .recovering:
            return "arrow.clockwise"
        case .resolved:
            return "checkmark.circle.fill"
        case .dismissed:
            return "xmark.circle"
        }
    }
    
    private var iconColor: Color {
        switch state {
        case .active:
            return .red
        case .recovering:
            return .orange
        case .resolved:
            return .green
        case .dismissed:
            return .gray
        }
    }
    
    private var backgroundColor: Color {
        switch state {
        case .active:
            return Color(.systemRed).opacity(0.1)
        case .recovering:
            return Color(.systemOrange).opacity(0.1)
        case .resolved:
            return Color(.systemGreen).opacity(0.1)
        case .dismissed:
            return Color(.systemGray).opacity(0.1)
        }
    }
}