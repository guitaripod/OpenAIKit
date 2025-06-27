import Foundation
import OpenAIKit

struct ModelTests {
    let output = ConsoleOutput()
    
    func runAll(openAI: OpenAIKit) async {
        await testListModels(openAI: openAI)
    }
    
    func testListModels(openAI: OpenAIKit) async {
        output.startTest("📋 Testing List Models...")
        
        do {
            let response = try await openAI.models.list()
            
            output.success("List models successful!")
            output.info("Found \(response.data.count) models")
            
            // Show first 5 models
            for model in response.data.prefix(5) {
                output.info("  - \(model.id) (owned by: \(model.ownedBy))")
            }
            
            if response.data.count > 5 {
                output.info("  ... and \(response.data.count - 5) more")
            }
        } catch {
            output.failure("List models failed", error: error)
        }
    }
}