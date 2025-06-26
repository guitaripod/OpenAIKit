// BranchingConversation.swift
import Foundation

struct ConversationNode: Identifiable {
    let id = UUID()
    let content: String
    let speaker: ChatRole
    var children: [ConversationNode] = []
}

class BranchingConversationManager: ObservableObject {
    @Published var rootNode: ConversationNode
    @Published var currentPath: [ConversationNode] = []
    
    init(systemPrompt: String) {
        self.rootNode = ConversationNode(
            content: systemPrompt,
            speaker: .system
        )
        self.currentPath = [rootNode]
    }
    
    func addMessage(_ content: String, role: ChatRole) {
        let newNode = ConversationNode(content: content, speaker: role)
        if let parent = currentPath.last {
            // In real implementation, would update tree structure
            currentPath.append(newNode)
        }
    }
    
    func branch(from node: ConversationNode) {
        // Create new branch from node
        currentPath = [rootNode, node]
    }
}
