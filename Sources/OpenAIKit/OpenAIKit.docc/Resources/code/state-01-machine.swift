// ConversationStateMachine.swift
import Foundation

enum ConversationState {
    case idle
    case greeting
    case questionAnswering
    case taskExecution
    case clarification
    case farewell
}

class ConversationStateMachine {
    @Published private(set) var currentState: ConversationState = .idle
    
    func transition(to newState: ConversationState) {
        currentState = newState
    }
    
    func determineState(from message: String) -> ConversationState {
        let lowercased = message.lowercased()
        
        if lowercased.contains("hello") || lowercased.contains("hi") {
            return .greeting
        } else if lowercased.contains("?") {
            return .questionAnswering
        } else if lowercased.contains("bye") || lowercased.contains("goodbye") {
            return .farewell
        } else {
            return .taskExecution
        }
    }
}
