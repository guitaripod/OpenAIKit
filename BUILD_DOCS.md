# Building OpenAIKit Documentation

This guide explains how to build and view the OpenAIKit documentation, including the interactive tutorials.

## Prerequisites

- Xcode 15.0 or later (for DocC support)
- Swift 5.9 or later

## Building Documentation

### Using Xcode

1. Open the package in Xcode:
   ```bash
   open Package.swift
   ```

2. Build documentation:
   - Select **Product → Build Documentation** (⌃⇧⌘D)
   - Xcode will build the documentation and open it in the Developer Documentation window

### Using Swift Package Manager

1. Build documentation archive:
   ```bash
   swift package generate-documentation
   ```

2. Build for specific platform:
   ```bash
   swift package generate-documentation \
     --target OpenAIKit \
     --output-path ./docs \
     --transform-for-static-hosting \
     --hosting-base-path OpenAIKit
   ```

## Viewing Documentation

### In Xcode
- After building, documentation appears in the Developer Documentation window
- Navigate through the tutorials in the sidebar
- Interactive tutorials include step-by-step code examples

### Static Hosting
- The generated documentation in `./docs` can be hosted on any static web server
- Open `./docs/index.html` in a web browser

## Documentation Structure

```
Sources/OpenAIKit/OpenAIKit.docc/
├── OpenAIKit.md                    # Main documentation page
├── GettingStarted.md              # Getting started article
├── Tutorials/
│   ├── OpenAIKit-Tutorials.tutorial     # Tutorial collection
│   ├── 01-Setting-Up-OpenAIKit.tutorial
│   ├── 02-Your-First-Chat-Completion.tutorial
│   ├── 03-Working-With-Functions.tutorial
│   ├── 04-Handling-Errors.tutorial
│   ├── 05-Building-Conversations.tutorial
│   ├── 06-Streaming-Responses.tutorial
│   ├── 07-Generating-Images.tutorial
│   ├── 08-Transcribing-Audio.tutorial
│   └── 09-Building-Semantic-Search.tutorial
└── Resources/
    ├── code/                      # Code snippets for tutorials
    └── *.png                      # Images for tutorials
```

## Adding Images

To complete the tutorials, add PNG images to the `Resources` directory:

1. Create tutorial hero images (1920x1080 recommended)
2. Create step-by-step screenshots (1280x720 recommended)
3. Use descriptive filenames matching tutorial references

## Tutorial Features

The interactive tutorials include:

- **Step-by-step instructions** with code progression
- **Assessments** with multiple-choice questions
- **Time estimates** for each tutorial
- **Prerequisites** and learning objectives
- **Code downloads** for each step

## Contributing

When adding new tutorials:

1. Create a `.tutorial` file in the `Tutorials` directory
2. Add references in `OpenAIKit-Tutorials.tutorial`
3. Include all code snippets in `Resources/code/`
4. Add placeholder images to `Resources/`
5. Test the tutorial flow in Xcode

## Troubleshooting

### Documentation doesn't build
- Ensure you have the latest Xcode with DocC support
- Check that all referenced images and code files exist
- Verify tutorial syntax matches DocC format

### Tutorials don't appear
- Rebuild documentation after changes
- Check that tutorials are referenced in the collection
- Ensure proper `@Tutorial` directive syntax

### Images don't load
- Place images in `Resources/` directory
- Use PNG format
- Match exact filenames in `@Image` directives