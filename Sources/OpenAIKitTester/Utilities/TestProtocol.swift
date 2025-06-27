import Foundation
import OpenAIKit

protocol OpenAIKitTest {
    var name: String { get }
    var description: String { get }
    func run(with openAI: OpenAIKit) async throws
}

protocol TestOutput {
    func startTest(_ name: String)
    func success(_ message: String)
    func failure(_ message: String, error: Error?)
    func info(_ message: String)
    func warning(_ message: String)
}

class ConsoleOutput: TestOutput {
    func startTest(_ name: String) {
        print("\n\(name)")
    }
    
    func success(_ message: String) {
        print("✅ \(message)")
    }
    
    func failure(_ message: String, error: Error? = nil) {
        print("❌ \(message)")
        if let error = error {
            print("   Error: \(error)")
            if let openAIError = error as? OpenAIError {
                print("   Details: \(openAIError)")
            }
        }
    }
    
    func info(_ message: String) {
        print("  \(message)")
    }
    
    func warning(_ message: String) {
        print("⚠️  \(message)")
    }
}