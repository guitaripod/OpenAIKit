// Actionable error messages with recovery
import SwiftUI

struct ActionableError: Identifiable {
    let id = UUID()
    let error: Error
    let context: ErrorContext
    let recovery: ErrorRecovery?
    
    var userMessage: UserErrorMessage {
        context.userMessage()
    }
}

protocol ErrorRecovery {
    func attemptRecovery() async -> Bool
}

struct RetryRecovery: ErrorRecovery {
    let action: () async throws -> Void
    
    func attemptRecovery() async -> Bool {
        do {
            try await action()
            return true
        } catch {
            return false
        }
    }
}

struct ConfigurationRecovery: ErrorRecovery {
    let openSettings: () -> Void
    
    func attemptRecovery() async -> Bool {
        openSettings()
        return true
    }
}

// SwiftUI Error Presentation
struct ActionableErrorView: View {
    let error: ActionableError
    @Environment(\.dismiss) var dismiss
    @State private var isRecovering = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: error.userMessage.icon)
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text(error.userMessage.title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error.userMessage.message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                ForEach(error.userMessage.actions, id: \.title) { action in
                    Button(action: {
                        handleAction(action)
                    }) {
                        Text(action.title)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(backgroundForAction(action))
                            .foregroundColor(foregroundForAction(action))
                            .cornerRadius(10)
                    }
                    .disabled(isRecovering)
                }
            }
            .padding(.top)
            
            if isRecovering {
                ProgressView("Recovering...")
                    .padding()
            }
        }
        .padding()
        .frame(maxWidth: 400)
    }
    
    private func handleAction(_ action: ErrorAction) {
        switch action {
        case .retry:
            if let recovery = error.recovery {
                Task {
                    isRecovering = true
                    let success = await recovery.attemptRecovery()
                    isRecovering = false
                    if success {
                        dismiss()
                    }
                }
            }
        case .dismiss:
            dismiss()
        case .configure:
            if let recovery = error.recovery as? ConfigurationRecovery {
                Task {
                    _ = await recovery.attemptRecovery()
                    dismiss()
                }
            }
        case .wait:
            dismiss()
        default:
            dismiss()
        }
    }
    
    private func backgroundForAction(_ action: ErrorAction) -> Color {
        switch action {
        case .retry:
            return .blue
        case .dismiss:
            return Color(.systemGray5)
        default:
            return Color(.systemGray6)
        }
    }
    
    private func foregroundForAction(_ action: ErrorAction) -> Color {
        switch action {
        case .retry:
            return .white
        default:
            return .primary
        }
    }
}