// Error UI components
import SwiftUI

struct ErrorBanner: View {
    let error: Error
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                
                Text(ErrorMessageMapper.userFriendlyMessage(for: error))
                    .font(.subheadline)
                    .lineLimit(isExpanded ? nil : 1)
                
                Spacer()
                
                if !isExpanded {
                    Button(action: { isExpanded = true }) {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                }
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let retry = onRetry {
                        Button("Try Again", action: retry)
                            .font(.caption)
                            .padding(.top, 4)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemYellow).opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemYellow).opacity(0.3), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

// Error toast notification
struct ErrorToast: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.red)
        .cornerRadius(8)
        .shadow(radius: 4)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// Error handling view modifier
struct ErrorHandling: ViewModifier {
    @StateObject private var errorHandler = CentralizedErrorHandler.shared
    
    func body(content: Content) -> some View {
        content
            .sheet(item: $errorHandler.currentError) { error in
                ActionableErrorView(error: error)
            }
            .overlay(alignment: .top) {
                if let error = errorHandler.currentError,
                   !errorHandler.isShowingError {
                    ErrorToast(message: error.userMessage.message)
                        .padding(.top)
                        .onTapGesture {
                            errorHandler.isShowingError = true
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                if !errorHandler.isShowingError {
                                    errorHandler.currentError = nil
                                }
                            }
                        }
                }
            }
    }
}

extension View {
    func handlesErrors() -> some View {
        modifier(ErrorHandling())
    }
}