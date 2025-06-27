import Foundation
import OpenAIKit

struct ImageTests {
    let output = ConsoleOutput()
    
    func runAll(openAI: OpenAIKit) async {
        await testImageGeneration(openAI: openAI)
    }
    
    func testImageGeneration(openAI: OpenAIKit) async {
        output.startTest("🎨 Testing Image Generation...")
        
        // Test DALL-E 2
        print("\n  Testing DALL-E 2...")
        do {
            let request = ImageGenerationRequest(
                prompt: "A simple red circle on white background",
                model: Models.Images.dallE2,
                n: 2,  // Test multiple images
                responseFormat: .url,
                size: "256x256"
            )
            
            let response = try await openAI.images.generations(request)
            
            print("  ✅ DALL-E 2 generation successful!")
            print("  Created: \(response.created)")
            print("  Generated \(response.data.count) images")
            
            for (index, image) in response.data.enumerated() {
                if let url = image.url {
                    print("  Image \(index + 1) URL: \(url.prefix(80))...")
                }
            }
        } catch {
            print("  ❌ DALL-E 2 generation failed: \(error)")
        }
        
        // Test DALL-E 3
        print("\n  Testing DALL-E 3...")
        do {
            let request = ImageGenerationRequest(
                prompt: "A photorealistic golden retriever puppy playing in a field of flowers",
                model: Models.Images.dallE3,
                n: 1,  // DALL-E 3 only supports n=1
                quality: "standard",
                responseFormat: .url,
                size: "1024x1024",
                style: "vivid"
            )
            
            let response = try await openAI.images.generations(request)
            
            print("  ✅ DALL-E 3 generation successful!")
            print("  Created: \(response.created)")
            
            for image in response.data {
                if let url = image.url {
                    print("  Image URL: \(url.prefix(80))...")
                }
                if let revisedPrompt = image.revisedPrompt {
                    print("  Revised prompt: \(revisedPrompt)")
                }
            }
        } catch {
            print("  ❌ DALL-E 3 generation failed: \(error)")
        }
        
        // Test DALL-E 3 HD quality
        print("\n  Testing DALL-E 3 HD quality...")
        do {
            let request = ImageGenerationRequest(
                prompt: "A serene Japanese garden with cherry blossoms, highly detailed",
                model: Models.Images.dallE3,
                n: 1,
                quality: "hd",
                responseFormat: .url,
                size: "1792x1024",  // Wide format
                style: "natural"
            )
            
            let response = try await openAI.images.generations(request)
            
            print("  ✅ DALL-E 3 HD generation successful!")
            print("  Created: \(response.created)")
            
            for image in response.data {
                if let url = image.url {
                    print("  Image URL: \(url.prefix(80))...")
                }
            }
        } catch {
            print("  ❌ DALL-E 3 HD generation failed: \(error)")
        }
        
        // Test base64 response format with DALL-E 2
        print("\n  Testing base64 response format (DALL-E 2)...")
        do {
            let request = ImageGenerationRequest(
                prompt: "A small blue square",
                model: Models.Images.dallE2,
                n: 1,
                responseFormat: .b64Json,
                size: "256x256"
            )
            
            let response = try await openAI.images.generations(request)
            
            print("  ✅ Base64 generation successful!")
            
            for image in response.data {
                if let b64 = image.b64Json {
                    print("  Base64 data length: \(b64.count) characters")
                    print("  Base64 prefix: \(b64.prefix(50))...")
                }
            }
        } catch {
            print("  ❌ Base64 generation failed: \(error)")
        }
        
        // Test gpt-image-1 model
        print("\n  Testing gpt-image-1 model...")
        do {
            let request = ImageGenerationRequest(
                prompt: "A simple geometric pattern with triangles",
                model: Models.Images.gptImage1,
                n: 1,
                outputCompression: 90,
                outputFormat: "jpeg",
                quality: "medium",
                size: "1024x1024"
            )
            
            let response = try await openAI.images.generations(request)
            
            print("  ✅ gpt-image-1 generation successful!")
            print("  Created: \(response.created)")
            
            // gpt-image-1 always returns base64
            for image in response.data {
                if let b64 = image.b64Json {
                    print("  Base64 data length: \(b64.count) characters")
                }
            }
            
            // Check if usage is returned
            if let usage = response.usage {
                print("  Usage - Total tokens: \(usage.totalTokens ?? 0)")
                if let inputTokens = usage.inputTokens {
                    print("  Input tokens: \(inputTokens)")
                }
            }
        } catch {
            print("  ❌ gpt-image-1 generation failed: \(error)")
        }
        
        // Test gpt-image-1 with transparent background
        print("\n  Testing gpt-image-1 with transparent background...")
        do {
            let request = ImageGenerationRequest(
                prompt: "A red heart shape",
                background: "transparent",
                model: Models.Images.gptImage1,
                n: 1,
                outputFormat: "png",
                quality: "high",
                size: "auto"
            )
            
            let response = try await openAI.images.generations(request)
            
            print("  ✅ gpt-image-1 transparent generation successful!")
            
            for image in response.data {
                if let b64 = image.b64Json {
                    print("  Base64 data length: \(b64.count) characters")
                }
            }
        } catch {
            print("  ❌ gpt-image-1 transparent generation failed: \(error)")
        }
    }
}