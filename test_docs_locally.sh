#!/bin/bash

# Script to build and test documentation locally
# Usage: ./test_docs_locally.sh

set -e

echo "🏗️  Building OpenAIKit documentation..."

# Clean previous build
rm -rf ./docs

# Build documentation
swift package --allow-writing-to-directory ./docs \
  generate-documentation \
  --target OpenAIKit \
  --output-path ./docs \
  --transform-for-static-hosting \
  --hosting-base-path OpenAIKit \
  --enable-inherited-docs

# Create index page
echo "📄 Creating index page..."
swift create_docs_index.swift

echo "✅ Documentation built successfully!"
echo ""
echo "🌐 Starting local server..."
echo "📍 Documentation will be available at: http://localhost:8000"
echo "📍 Direct link to docs: http://localhost:8000/documentation/openaikit"
echo "📍 Tutorials: http://localhost:8000/documentation/openaikit/tutorials/openaikit-tutorials"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start local server
cd docs && python3 -m http.server 8000