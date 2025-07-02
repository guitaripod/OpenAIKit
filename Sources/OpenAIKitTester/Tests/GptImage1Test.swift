import Foundation
import OpenAIKit

/// Dedicated test for gpt-image-1 functionality
struct GptImage1Test {
    let output = ConsoleOutput()
    
    func runComprehensiveTest(openAI: OpenAIKit) async {
        output.startTest("🤖 Testing gpt-image-1 Comprehensive Features...")
        
        // Test 1: Basic generation with response field verification
        await testBasicGeneration(openAI: openAI)
        
        // Test 2: Transparent background
        await testTransparentBackground(openAI: openAI)
        
        // Test 3: Different quality levels
        await testQualityLevels(openAI: openAI)
        
        // Test 4: Output formats
        await testOutputFormats(openAI: openAI)
        
        // Test 5: Compression levels
        await testCompressionLevels(openAI: openAI)
    }
    
    private func testBasicGeneration(openAI: OpenAIKit) async {
        print("\n  1️⃣  Testing basic gpt-image-1 generation...")
        
        do {
            let request = ImageGenerationRequest(
                prompt: "A simple geometric pattern",
                model: Models.Images.gptImage1,
                n: 1,
                quality: "medium",
                size: "1024x1024"
            )
            
            let response = try await openAI.images.generations(request)
            
            print("  ✅ Basic generation successful!")
            print("     Created: \(response.created)")
            
            // Verify response fields
            print("     Response metadata:")
            print("       - Background: \(response.background ?? "not provided")")
            print("       - Output format: \(response.outputFormat ?? "not provided")")
            print("       - Quality: \(response.quality ?? "not provided")")
            print("       - Size: \(response.size ?? "not provided")")
            
            // Verify image data
            if let image = response.data.first {
                if let b64 = image.b64Json {
                    print("     Image data:")
                    print("       - Base64 length: \(b64.count) characters")
                    
                    if let data = Data(base64Encoded: b64) {
                        print("       - Decoded size: \(data.count) bytes (\(data.count / 1024)KB)")
                        print("       - Valid base64: ✅")
                    } else {
                        print("       - Valid base64: ❌")
                    }
                } else {
                    print("     ⚠️  No base64 data in response")
                }
            }
            
            // Check usage
            if let usage = response.usage {
                print("     Token usage:")
                print("       - Total: \(usage.totalTokens ?? 0)")
                print("       - Input: \(usage.inputTokens ?? 0)")
                print("       - Output: \(usage.outputTokens ?? 0)")
            }
        } catch {
            print("  ❌ Basic generation failed: \(error)")
        }
    }
    
    private func testTransparentBackground(openAI: OpenAIKit) async {
        print("\n  2️⃣  Testing transparent background...")
        
        do {
            let request = ImageGenerationRequest(
                prompt: "A red heart emoji style icon",
                background: "transparent",
                model: Models.Images.gptImage1,
                n: 1,
                outputFormat: "png",
                quality: "high",
                size: "1024x1024"
            )
            
            let response = try await openAI.images.generations(request)
            
            print("  ✅ Transparent background test successful!")
            print("     Background setting: \(response.background ?? "not specified")")
            print("     Output format: \(response.outputFormat ?? "not specified")")
            
            if let image = response.data.first, let b64 = image.b64Json {
                if let data = Data(base64Encoded: b64) {
                    // Check PNG signature
                    let pngSignature = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
                    let isPNG = data.prefix(8) == pngSignature
                    print("     Image format verification:")
                    print("       - Is PNG: \(isPNG ? "✅" : "❌")")
                    print("       - Size: \(data.count / 1024)KB")
                }
            }
        } catch {
            print("  ❌ Transparent background test failed: \(error)")
        }
    }
    
    private func testQualityLevels(openAI: OpenAIKit) async {
        print("\n  3️⃣  Testing quality levels...")
        
        let qualities = ["low", "medium", "high", "auto"]
        
        for quality in qualities {
            print("\n     Testing quality: \(quality)")
            
            do {
                let request = ImageGenerationRequest(
                    prompt: "A simple test pattern",
                    model: Models.Images.gptImage1,
                    n: 1,
                    quality: quality,
                    size: "1024x1024"
                )
                
                let response = try await openAI.images.generations(request)
                
                print("       ✅ Quality '\(quality)' successful")
                print("       Response quality: \(response.quality ?? "not specified")")
                
                if let image = response.data.first, let b64 = image.b64Json {
                    if let data = Data(base64Encoded: b64) {
                        print("       Image size: \(data.count / 1024)KB")
                    }
                }
            } catch {
                print("       ❌ Quality '\(quality)' failed: \(error)")
            }
        }
    }
    
    private func testOutputFormats(openAI: OpenAIKit) async {
        print("\n  4️⃣  Testing output formats...")
        
        let formats = ["png", "jpeg", "webp"]
        
        for format in formats {
            print("\n     Testing format: \(format)")
            
            do {
                let request = ImageGenerationRequest(
                    prompt: "A colorful gradient",
                    model: Models.Images.gptImage1,
                    n: 1,
                    outputFormat: format,
                    quality: "medium",
                    size: "1024x1024"
                )
                
                let response = try await openAI.images.generations(request)
                
                print("       ✅ Format '\(format)' successful")
                print("       Response format: \(response.outputFormat ?? "not specified")")
                
                if let image = response.data.first, let b64 = image.b64Json {
                    if let data = Data(base64Encoded: b64) {
                        print("       Image size: \(data.count / 1024)KB")
                        
                        // Verify format signatures
                        switch format {
                        case "png":
                            let isPNG = data.prefix(8) == Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
                            print("       Format verified: \(isPNG ? "✅ PNG" : "❌ Not PNG")")
                        case "jpeg":
                            let isJPEG = data.prefix(2) == Data([0xFF, 0xD8])
                            print("       Format verified: \(isJPEG ? "✅ JPEG" : "❌ Not JPEG")")
                        case "webp":
                            let isWEBP = data.count > 12 && data[8..<12] == "WEBP".data(using: .ascii)
                            print("       Format verified: \(isWEBP ? "✅ WebP" : "❌ Not WebP")")
                        default:
                            break
                        }
                    }
                }
            } catch {
                print("       ❌ Format '\(format)' failed: \(error)")
            }
        }
    }
    
    private func testCompressionLevels(openAI: OpenAIKit) async {
        print("\n  5️⃣  Testing compression levels...")
        
        let compressionLevels = [50, 75, 90, 100]
        
        for compression in compressionLevels {
            print("\n     Testing compression: \(compression)")
            
            do {
                let request = ImageGenerationRequest(
                    prompt: "A detailed landscape",
                    model: Models.Images.gptImage1,
                    n: 1,
                    outputCompression: compression,
                    outputFormat: "jpeg",
                    quality: "medium",
                    size: "1024x1024"
                )
                
                let response = try await openAI.images.generations(request)
                
                print("       ✅ Compression \(compression) successful")
                
                if let image = response.data.first, let b64 = image.b64Json {
                    if let data = Data(base64Encoded: b64) {
                        print("       Image size: \(data.count / 1024)KB")
                    }
                }
            } catch {
                print("       ❌ Compression \(compression) failed: \(error)")
            }
        }
    }
}

// Add this test to the main runner
extension ImageTests {
    func runGptImage1ComprehensiveTest(openAI: OpenAIKit) async {
        let gptImage1Test = GptImage1Test()
        await gptImage1Test.runComprehensiveTest(openAI: openAI)
    }
}