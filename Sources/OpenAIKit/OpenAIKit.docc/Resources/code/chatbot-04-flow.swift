// ConversationFlow.swift
import Foundation

protocol ConversationFlow {
    var name: String { get }
    var currentStep: Int { get }
    var isComplete: Bool { get }
    func process(message: String) -> FlowResponse
}

struct FlowResponse {
    let message: String
    let options: [String]
    let requiresInput: Bool
}

class OnboardingFlow: ConversationFlow {
    let name = "onboarding"
    private(set) var currentStep = 0
    
    var isComplete: Bool {
        currentStep >= 3
    }
    
    func process(message: String) -> FlowResponse {
        defer { currentStep += 1 }
        
        switch currentStep {
        case 0:
            return FlowResponse(
                message: "Welcome! What's your name?",
                options: [],
                requiresInput: true
            )
        case 1:
            return FlowResponse(
                message: "Nice to meet you, \(message)! What brings you here today?",
                options: ["Just exploring", "I have a question", "Need help with something"],
                requiresInput: true
            )
        case 2:
            return FlowResponse(
                message: "Great! I'm here to help. How can I assist you?",
                options: [],
                requiresInput: true
            )
        default:
            return FlowResponse(
                message: "How can I help you?",
                options: [],
                requiresInput: true
            )
        }
    }
}
