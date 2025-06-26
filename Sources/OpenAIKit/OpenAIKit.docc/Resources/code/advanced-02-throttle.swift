// StreamThrottling.swift
import Foundation
import Combine

class ThrottledStreamProcessor {
    private let updateInterval: TimeInterval
    private var buffer = ""
    private var updateTimer: Timer?
    private let onUpdate: (String) -> Void
    
    init(updateInterval: TimeInterval = 0.1, onUpdate: @escaping (String) -> Void) {
        self.updateInterval = updateInterval
        self.onUpdate = onUpdate
    }
    
    func processChunk(_ chunk: String) {
        buffer += chunk
        
        if updateTimer == nil {
            updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
                self.flushBuffer()
            }
        }
    }
    
    func finish() {
        updateTimer?.invalidate()
        updateTimer = nil
        flushBuffer()
    }
    
    private func flushBuffer() {
        if !buffer.isEmpty {
            onUpdate(buffer)
            buffer = ""
        }
    }
}
