#!/usr/bin/env swift

import Foundation

// Script to create a nice landing page for the documentation
// This can be added to the GitHub Actions workflow

let indexHTML = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>OpenAIKit - Swift SDK for OpenAI API</title>
    <meta name="description" content="A comprehensive Swift SDK for the OpenAI API with support for all Apple platforms and Linux">
    <link rel="canonical" href="./documentation/openaikit">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Helvetica Neue", Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 2rem;
        }
        
        .container {
            background: rgba(255, 255, 255, 0.95);
            border-radius: 20px;
            padding: 3rem;
            max-width: 800px;
            width: 100%;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            text-align: center;
        }
        
        h1 {
            font-size: 3rem;
            font-weight: 700;
            margin-bottom: 1rem;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        
        .subtitle {
            font-size: 1.25rem;
            color: #666;
            margin-bottom: 2rem;
        }
        
        .features {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1.5rem;
            margin: 2rem 0;
            text-align: left;
        }
        
        .feature {
            padding: 1rem;
            background: #f8f9fa;
            border-radius: 10px;
        }
        
        .feature h3 {
            font-size: 1.1rem;
            margin-bottom: 0.5rem;
            color: #667eea;
        }
        
        .feature p {
            font-size: 0.9rem;
            color: #666;
        }
        
        .buttons {
            margin-top: 2rem;
            display: flex;
            gap: 1rem;
            justify-content: center;
            flex-wrap: wrap;
        }
        
        .button {
            display: inline-block;
            padding: 0.75rem 2rem;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-decoration: none;
            border-radius: 30px;
            font-weight: 600;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        
        .button:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(0, 0, 0, 0.2);
        }
        
        .button.secondary {
            background: #f8f9fa;
            color: #667eea;
        }
        
        .emoji {
            font-size: 2rem;
            margin: 0 0.5rem;
        }
        
        @media (max-width: 600px) {
            h1 {
                font-size: 2rem;
            }
            
            .container {
                padding: 2rem;
            }
            
            .features {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>OpenAIKit</h1>
        <p class="subtitle">A powerful Swift SDK for the OpenAI API</p>
        
        <div class="features">
            <div class="feature">
                <h3>🚀 Type-Safe</h3>
                <p>Fully type-safe API with Swift's powerful type system</p>
            </div>
            <div class="feature">
                <h3>🌍 Cross-Platform</h3>
                <p>Supports iOS, macOS, watchOS, tvOS, visionOS, and Linux</p>
            </div>
            <div class="feature">
                <h3>📚 Complete Coverage</h3>
                <p>Chat, Images, Audio, Embeddings, and more</p>
            </div>
            <div class="feature">
                <h3>🎓 Interactive Tutorials</h3>
                <p>Step-by-step guides with code examples</p>
            </div>
            <div class="feature">
                <h3>⚡ Async/Await</h3>
                <p>Modern Swift concurrency with streaming support</p>
            </div>
            <div class="feature">
                <h3>🛡️ Robust</h3>
                <p>Comprehensive error handling and retry logic</p>
            </div>
        </div>
        
        <div class="buttons">
            <a href="./documentation/openaikit" class="button">
                View Documentation
            </a>
            <a href="./documentation/openaikit/tutorials/openaikit-tutorials" class="button secondary">
                Start Tutorial
            </a>
        </div>
        
    </div>
</body>
</html>
"""

// Write the index file
do {
    try indexHTML.write(to: URL(fileURLWithPath: "docs/index.html"), atomically: true, encoding: .utf8)
    print("✅ Created index.html")
} catch {
    print("❌ Failed to create index.html: \\(error)")
}