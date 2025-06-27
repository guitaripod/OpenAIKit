import Foundation
import OpenAIKit

struct FileTests {
    let output = ConsoleOutput()
    
    func runAll(openAI: OpenAIKit) async {
        await testFiles(openAI: openAI)
        await testFileOperationsWithMetadata(openAI: openAI)
    }
    
    func testFiles(openAI: OpenAIKit) async {
        output.startTest("📁 Testing Files...")
        
        do {
            // Create a test file
            let testContent = "This is a test file for OpenAIKit".data(using: .utf8)!
            let fileName = "test.txt"
            
            // Create temporary file
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try testContent.write(to: tempURL)
            
            // Upload file
            let uploadRequest = FileRequest(
                file: testContent,
                fileName: fileName,
                purpose: .assistants
            )
            
            let file = try await openAI.files.upload(uploadRequest)
            output.success("File uploaded: \(file.id)")
            output.info("File size: \(file.bytes) bytes")
            
            // List files
            let listResponse = try await openAI.files.list()
            output.info("Found \(listResponse.data.count) files")
            
            // Delete file
            let deleteResponse = try await openAI.files.delete(fileId: file.id)
            output.success("File deleted: \(deleteResponse.deleted)")
            
            // Clean up temp file
            try FileManager.default.removeItem(at: tempURL)
        } catch {
            output.failure("Files test failed", error: error)
        }
    }
    
    func testFileOperationsWithMetadata(openAI: OpenAIKit) async {
        output.startTest("Testing file operations with metadata...")
        
        do {
            let testData = "Line 1\\nLine 2\\nLine 3\\nLine 4\\nLine 5".data(using: .utf8)!
            let uploadRequest = FileRequest(
                file: testData,
                fileName: "test_metadata.txt",
                purpose: .assistants
            )
            
            let uploadedFile = try await openAI.files.upload(uploadRequest)
            output.success("File uploaded with ID: \(uploadedFile.id)")
            
            // Retrieve the file
            let retrievedFile = try await openAI.files.retrieve(fileId: uploadedFile.id)
            output.success("File retrieved successfully")
            output.info("File name: \(retrievedFile.filename)")
            output.info("File size: \(retrievedFile.bytes) bytes")
            
            // Clean up
            _ = try await openAI.files.delete(fileId: uploadedFile.id)
            output.success("File cleaned up")
        } catch {
            output.failure("File operations failed", error: error)
        }
    }
}