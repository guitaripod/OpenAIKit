// ConversationAnalytics.swift
import Foundation
import SwiftUI

struct ConversationMetrics {
    let messageCount: Int
    let averageResponseTime: TimeInterval
    let topicFrequency: [String: Int]
    let userEngagement: Double
}

class ConversationAnalytics: ObservableObject {
    @Published var metrics = ConversationMetrics(
        messageCount: 0,
        averageResponseTime: 0,
        topicFrequency: [:],
        userEngagement: 0
    )
    
    private var messageTimes: [(Date, ChatRole)] = []
    private var topics: [String] = []
    
    func trackMessage(role: ChatRole, content: String, context: ConversationContext) {
        messageTimes.append((Date(), role))
        if let topic = context.topic {
            topics.append(topic)
        }
        updateMetrics()
    }
    
    private func updateMetrics() {
        let messageCount = messageTimes.count
        
        // Calculate average response time
        var responseTimes: [TimeInterval] = []
        for i in 1..<messageTimes.count {
            if messageTimes[i].1 == .assistant && messageTimes[i-1].1 == .user {
                responseTimes.append(messageTimes[i].0.timeIntervalSince(messageTimes[i-1].0))
            }
        }
        let avgResponseTime = responseTimes.isEmpty ? 0 : responseTimes.reduce(0, +) / Double(responseTimes.count)
        
        // Topic frequency
        var topicFreq: [String: Int] = [:]
        for topic in topics {
            topicFreq[topic, default: 0] += 1
        }
        
        metrics = ConversationMetrics(
            messageCount: messageCount,
            averageResponseTime: avgResponseTime,
            topicFrequency: topicFreq,
            userEngagement: Double(messageCount) / max(1, messageTimes.first?.0.timeIntervalSinceNow ?? 1)
        )
    }
}
