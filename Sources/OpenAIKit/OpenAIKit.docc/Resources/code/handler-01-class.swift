// CentralizedErrorHandler.swift
import Foundation
import Combine

@MainActor
class CentralizedErrorHandler: ObservableObject {
    static let shared = CentralizedErrorHandler()
    
    @Published var currentError: ActionableError?
    @Published var errorHistory: [ErrorRecord] = []
    @Published var isShowingError = false
    
    private init() {}
    
    func handle(
        _ error: Error,
        operation: String,
        context: [String: Any] = [:],
        recovery: ErrorRecovery? = nil
    ) {
        let errorContext = ErrorContext(
            error: error,
            operation: operation,
            context: context
        )
        
        let actionableError = ActionableError(
            error: error,
            context: errorContext,
            recovery: recovery
        )
        
        currentError = actionableError
        isShowingError = true
        
        // Record error
        recordError(error, operation: operation)
    }
    
    private func recordError(_ error: Error, operation: String) {
        let record = ErrorRecord(
            timestamp: Date(),
            error: error,
            operation: operation,
            resolved: false
        )
        
        errorHistory.append(record)
        
        // Keep only last 50 errors
        if errorHistory.count > 50 {
            errorHistory.removeFirst()
        }
    }
}

struct ErrorRecord: Identifiable {
    let id = UUID()
    let timestamp: Date
    let error: Error
    let operation: String
    var resolved: Bool
}