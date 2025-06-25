#!/bin/bash

# Script to generate placeholder images for DocC tutorials using ImageMagick
# Requires: ImageMagick (install with: sudo pacman -S imagemagick)

RESOURCES_PATH="Sources/OpenAIKit/OpenAIKit.docc/Resources"

# Create resources directory if needed
mkdir -p "$RESOURCES_PATH"

# Function to create placeholder image
create_placeholder() {
    local filename=$1
    local width=$2
    local height=$3
    local text=$4
    
    # Create image with dark background and white text using ImageMagick 7
    magick -size ${width}x${height} \
        -background '#1a1a2e' \
        -fill white \
        -pointsize 36 \
        -gravity center \
        label:"$text" \
        "$RESOURCES_PATH/$filename"
    
    echo "✅ Created: $filename"
}

# General images
create_placeholder "openaikit-hero.png" 1920 1080 "OpenAIKit Hero"
create_placeholder "chapter1-hero.png" 1920 1080 "Chapter 1 Hero"
create_placeholder "chapter2-hero.png" 1920 1080 "Chapter 2 Hero"
create_placeholder "chapter3-hero.png" 1920 1080 "Chapter 3 Hero"

# Tutorial 1: Setting Up
create_placeholder "setup-intro.png" 1280 720 "Setup Intro"
create_placeholder "spm-install.png" 1280 720 "SPM Install"
create_placeholder "setup-step2.png" 1280 720 "Setup Step 2"
create_placeholder "api-key-section.png" 1280 720 "API Key Section"
create_placeholder "openai-platform.png" 1280 720 "OpenAI Platform"
create_placeholder "api-keys-nav.png" 1280 720 "API Keys Nav"
create_placeholder "create-key.png" 1280 720 "Create Key"
create_placeholder "copy-key.png" 1280 720 "Copy Key"
create_placeholder "configure-intro.png" 1280 720 "Configure Intro"
create_placeholder "env-vars.png" 1280 720 "Env Vars"
create_placeholder "edit-scheme.png" 1280 720 "Edit Scheme"
create_placeholder "scheme-arguments.png" 1280 720 "Scheme Arguments"
create_placeholder "add-env-var.png" 1280 720 "Add Env Var"

# Tutorial 2: First Chat
create_placeholder "first-chat-intro.png" 1280 720 "First Chat Intro"
create_placeholder "chat-request.png" 1280 720 "Chat Request"
create_placeholder "message-roles.png" 1280 720 "Message Roles"
create_placeholder "parameters.png" 1280 720 "Parameters"
create_placeholder "chat-interface.png" 1280 720 "Chat Interface"

# Tutorial 3: Functions
create_placeholder "functions-intro.png" 1280 720 "Functions Intro"
create_placeholder "function-flow.png" 1280 720 "Function Flow"
create_placeholder "weather-api.png" 1280 720 "Weather API"
create_placeholder "function-execution.png" 1280 720 "Function Execution"
create_placeholder "weather-assistant-ui.png" 1280 720 "Weather Assistant UI"
create_placeholder "advanced-functions.png" 1280 720 "Advanced Functions"

# Tutorial 4: Error Handling
create_placeholder "error-handling-intro.png" 1280 720 "Error Handling Intro"
create_placeholder "error-types.png" 1280 720 "Error Types"
create_placeholder "retry-logic.png" 1280 720 "Retry Logic"
create_placeholder "user-errors.png" 1280 720 "User Errors"
create_placeholder "error-handler.png" 1280 720 "Error Handler"

# Tutorial 5: Conversations
create_placeholder "conversations-intro.png" 1280 720 "Conversations Intro"
create_placeholder "context-management.png" 1280 720 "Context Management"
create_placeholder "conversation-memory.png" 1280 720 "Conversation Memory"
create_placeholder "personas.png" 1280 720 "Personas"
create_placeholder "advanced-patterns.png" 1280 720 "Advanced Patterns"
create_placeholder "complete-chatbot.png" 1280 720 "Complete Chatbot"

# Tutorial 6: Streaming
create_placeholder "streaming-intro.png" 1280 720 "Streaming Intro"
create_placeholder "streaming-flow.png" 1280 720 "Streaming Flow"
create_placeholder "streaming-ui.png" 1280 720 "Streaming UI"
create_placeholder "stream-errors.png" 1280 720 "Stream Errors"
create_placeholder "advanced-streaming.png" 1280 720 "Advanced Streaming"
create_placeholder "cross-platform.png" 1280 720 "Cross Platform"

# Tutorial 7: Images
create_placeholder "image-generation-intro.png" 1280 720 "Image Generation Intro"
create_placeholder "dalle-basic.png" 1280 720 "DALLE Basic"
create_placeholder "image-options.png" 1280 720 "Image Options"
create_placeholder "image-ui.png" 1280 720 "Image UI"
create_placeholder "image-variations.png" 1280 720 "Image Variations"
create_placeholder "prompt-engineering.png" 1280 720 "Prompt Engineering"

# Tutorial 8: Audio
create_placeholder "audio-transcription-intro.png" 1280 720 "Audio Transcription Intro"
create_placeholder "whisper-basics.png" 1280 720 "Whisper Basics"
create_placeholder "transcription-options.png" 1280 720 "Transcription Options"
create_placeholder "audio-translation.png" 1280 720 "Audio Translation"
create_placeholder "voice-notes-app.png" 1280 720 "Voice Notes App"
create_placeholder "large-audio.png" 1280 720 "Large Audio"

# Tutorial 9: Semantic Search
create_placeholder "semantic-search-intro.png" 1280 720 "Semantic Search Intro"
create_placeholder "embeddings-explained.png" 1280 720 "Embeddings Explained"
create_placeholder "vector-similarity.png" 1280 720 "Vector Similarity"
create_placeholder "vector-database.png" 1280 720 "Vector Database"
create_placeholder "search-engine.png" 1280 720 "Search Engine"
create_placeholder "knowledge-base-app.png" 1280 720 "Knowledge Base App"
create_placeholder "advanced-embeddings.png" 1280 720 "Advanced Embeddings"

echo ""
echo "✅ All placeholder images generated successfully!"
echo "These are temporary placeholders - replace with actual screenshots and diagrams."
echo ""
echo "Note: If text appears too small, you can adjust the -pointsize parameter in the script."