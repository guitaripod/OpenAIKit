// Localized error messages
import Foundation

class LocalizedErrorHandler {
    static func localizedMessage(for error: Error) -> String {
        let key = errorKey(for: error)
        return NSLocalizedString(key, comment: "")
    }
    
    private static func errorKey(for error: Error) -> String {
        let details = ErrorAnalyzer.analyze(error)
        
        switch details.type {
        case .api:
            return "error.api.\(details.code)"
        case .network:
            return "error.network.\(details.code)"
        case .unknown:
            return "error.unknown"
        }
    }
}

// Localizable.strings
/*
"error.api.rate_limit_exceeded" = "You're sending messages too quickly. Please wait a moment before trying again.";
"error.api.invalid_api_key" = "Unable to authenticate. Please check your API key in settings.";
"error.api.context_length_exceeded" = "Your message is too long. Please try sending a shorter message.";
"error.api.server_error" = "The service is temporarily unavailable. Please try again later.";
"error.network.-1009" = "No internet connection. Please check your network settings.";
"error.network.-1001" = "The request timed out. Please check your connection and try again.";
"error.unknown" = "An unexpected error occurred. Please try again.";
*/

// Usage in SwiftUI
struct ErrorAlert: ViewModifier {
    @Binding var error: Error?
    
    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: .constant(error != nil),
                presenting: error
            ) { _ in
                Button("OK") {
                    error = nil
                }
            } message: { error in
                Text(LocalizedErrorHandler.localizedMessage(for: error))
            }
    }
}

extension View {
    func errorAlert(error: Binding<Error?>) -> some View {
        modifier(ErrorAlert(error: error))
    }
}