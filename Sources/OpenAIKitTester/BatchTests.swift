import Foundation
import OpenAIKit

extension OpenAIKitTester {
    static func testBatchAPI(openAI: OpenAIKit) async {
        print("\n📦 Testing Batch API...")
        
        do {
            // 1. Create batch requests
            print("Creating batch requests...")
            let requests = [
                BatchRequest(
                    customId: "test-request-1",
                    url: "/v1/chat/completions",
                    body: [
                        "model": .string(Models.Chat.gpt4oMini),
                        "messages": .array([
                            .object([
                                "role": .string("system"),
                                "content": .string("You are a helpful assistant.")
                            ]),
                            .object([
                                "role": .string("user"),
                                "content": .string("Say 'Hello from batch request 1!'")
                            ])
                        ]),
                        "max_completion_tokens": .int(50),
                        "temperature": .double(0.7)
                    ]
                ),
                BatchRequest(
                    customId: "test-request-2",
                    url: "/v1/chat/completions",
                    body: [
                        "model": .string(Models.Chat.gpt4oMini),
                        "messages": .array([
                            .object([
                                "role": .string("system"),
                                "content": .string("You are a creative assistant.")
                            ]),
                            .object([
                                "role": .string("user"),
                                "content": .string("Say 'Hello from batch request 2!'")
                            ])
                        ]),
                        "max_completion_tokens": .int(50),
                        "temperature": .double(0.9)
                    ]
                )
            ]
            
            // 2. Create batch file
            print("Creating batch file...")
            let batchData = try BatchFileBuilder.createBatchFile(from: requests)
            print("Batch file size: \(batchData.count) bytes")
            
            // 3. Upload batch file
            print("Uploading batch file...")
            let file = try await openAI.files.upload(
                FileRequest(
                    file: batchData,
                    fileName: "test-batch.jsonl",
                    purpose: .batch
                )
            )
            print("✅ File uploaded: \(file.id)")
            
            // 4. Create batch
            print("Creating batch...")
            let batch = try await openAI.batches.create(
                inputFileId: file.id,
                endpoint: "/v1/chat/completions",
                metadata: ["test": "true", "purpose": "SDK testing"]
            )
            print("✅ Batch created: \(batch.id)")
            print("Status: \(batch.status)")
            print("Request counts: \(batch.requestCounts.total) total")
            
            // 5. Check batch status
            print("\nChecking batch status...")
            let status = try await openAI.batches.retrieve(batch.id)
            print("Current status: \(status.status)")
            print("Progress: \(status.requestCounts.completed)/\(status.requestCounts.total) completed")
            
            // 6. List batches
            print("\nListing batches...")
            let batches = try await openAI.batches.list(limit: 5)
            print("Found \(batches.data.count) batches")
            for batchItem in batches.data.prefix(3) {
                print("  - \(batchItem.id): \(batchItem.status) (\(batchItem.completionPercentage)% complete)")
            }
            
            // 7. Cancel batch (optional test)
            if batch.status == BatchStatus.validating || batch.status == BatchStatus.inProgress {
                print("\nTesting batch cancellation...")
                let cancelledBatch = try await openAI.batches.cancel(batch.id)
                print("✅ Batch cancelled: \(cancelledBatch.status)")
            }
            
            // 8. If a completed batch exists, try to parse results
            if let completedBatch = batches.data.first(where: { $0.status == .completed }),
               let outputFileId = completedBatch.outputFileId {
                print("\nFound completed batch, retrieving results...")
                let resultsData = try await openAI.files.content(fileId: outputFileId)
                let responses = try BatchFileBuilder.parseBatchResults(from: resultsData)
                print("✅ Retrieved \(responses.count) responses")
                
                for response in responses.prefix(2) {
                    print("\nResponse for \(response.customId):")
                    if let responseData = response.response {
                        print("  Status: \(responseData.statusCode)")
                        if let body = responseData.body,
                           let choices = body["choices"]?.arrayValue,
                           let firstChoice = choices.first?.objectValue,
                           let message = firstChoice["message"]?.objectValue,
                           let content = message["content"]?.stringValue {
                            print("  Content: \(content)")
                        }
                    } else if let error = response.error {
                        print("  Error: \(error.message ?? "Unknown error")")
                    }
                }
            }
            
            print("\n✅ Batch API test completed successfully!")
            
        } catch {
            print("❌ Batch API test failed: \(error)")
            if let openAIError = error as? OpenAIError {
                print("Error details: \(openAIError.userFriendlyMessage)")
            }
        }
    }
    
    static func testBatchEdgeCases(openAI: OpenAIKit) async {
        print("\n🔧 Testing Batch API Edge Cases...")
        
        do {
            // Test 1: Invalid file purpose
            print("Testing invalid file upload...")
            do {
                let invalidData = "invalid batch data".data(using: .utf8)!
                _ = try await openAI.files.upload(
                    FileRequest(
                        file: invalidData,
                        fileName: "invalid.txt",
                        purpose: .batch
                    )
                )
                print("❌ Should have failed with invalid file")
            } catch {
                print("✅ Correctly rejected invalid file: \(error)")
            }
            
            // Test 2: Empty batch file
            print("\nTesting empty batch file...")
            do {
                let emptyData = try BatchFileBuilder.createBatchFile(from: [])
                _ = try await openAI.files.upload(
                    FileRequest(
                        file: emptyData,
                        fileName: "empty.jsonl",
                        purpose: .batch
                    )
                )
                print("✅ Empty file uploaded (API may accept or reject during batch creation)")
            } catch {
                print("✅ Empty file rejected: \(error)")
            }
            
            // Test 3: Large batch request
            print("\nTesting large batch request...")
            var largeBatchRequests: [BatchRequest] = []
            for i in 1...10 {
                largeBatchRequests.append(
                    BatchRequest(
                        customId: "large-request-\(i)",
                        url: "/v1/embeddings",
                        body: [
                            "model": .string(Models.Embeddings.textEmbedding3Small),
                            "input": .string("Test embedding \(i)"),
                            "dimensions": .int(256)
                        ]
                    )
                )
            }
            
            let largeBatchData = try BatchFileBuilder.createBatchFile(from: largeBatchRequests)
            print("Created batch with \(largeBatchRequests.count) requests (\(largeBatchData.count) bytes)")
            
            // Test 4: Parse batch results
            print("\nTesting batch result parsing...")
            let sampleResults = """
            {"id": "batch_req_1", "custom_id": "test-1", "response": {"status_code": 200, "request_id": "req_123", "body": {"choices": [{"message": {"content": "Hello!"}}]}}, "error": null}
            {"id": "batch_req_2", "custom_id": "test-2", "response": null, "error": {"code": "rate_limit_exceeded", "message": "Rate limit exceeded"}}
            """.data(using: .utf8)!
            
            let parsedResults = try BatchFileBuilder.parseBatchResults(from: sampleResults)
            print("✅ Parsed \(parsedResults.count) results")
            for result in parsedResults {
                if let response = result.response {
                    print("  - \(result.customId): Success (status \(response.statusCode))")
                } else if let error = result.error {
                    print("  - \(result.customId): Error (\(error.code ?? "unknown"))")
                }
            }
            
            print("\n✅ Batch edge case tests completed!")
            
        } catch {
            print("❌ Batch edge case test failed: \(error)")
        }
    }
}