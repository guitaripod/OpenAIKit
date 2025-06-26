import OpenAIKit
import Foundation

// Advanced document chunking strategies for optimal semantic search

struct AdvancedChunker {
    let openAI: OpenAI
    let maxChunkSize: Int = 1500
    let chunkOverlap: Int = 200
    
    // Semantic chunking using sentence boundaries
    func semanticChunk(text: String) async throws -> [DocumentChunk] {
        let sentences = extractSentences(from: text)
        var chunks: [DocumentChunk] = []
        var currentChunk = ""
        var currentTokens = 0
        var chunkIndex = 0
        
        for sentence in sentences {
            let sentenceTokens = estimateTokens(sentence)
            
            if currentTokens + sentenceTokens > maxChunkSize && !currentChunk.isEmpty {
                // Create chunk with overlap
                let overlap = extractOverlap(from: currentChunk, tokens: chunkOverlap)
                chunks.append(DocumentChunk(
                    content: currentChunk,
                    index: chunkIndex,
                    metadata: ChunkMetadata(
                        startToken: chunkIndex * (maxChunkSize - chunkOverlap),
                        endToken: chunkIndex * (maxChunkSize - chunkOverlap) + currentTokens,
                        hasOverlap: chunkIndex > 0
                    )
                ))
                
                currentChunk = overlap + sentence
                currentTokens = estimateTokens(currentChunk)
                chunkIndex += 1
            } else {
                currentChunk += " " + sentence
                currentTokens += sentenceTokens
            }
        }
        
        // Add final chunk
        if !currentChunk.isEmpty {
            chunks.append(DocumentChunk(
                content: currentChunk,
                index: chunkIndex,
                metadata: ChunkMetadata(
                    startToken: chunkIndex * (maxChunkSize - chunkOverlap),
                    endToken: chunkIndex * (maxChunkSize - chunkOverlap) + currentTokens,
                    hasOverlap: chunkIndex > 0
                )
            ))
        }
        
        return chunks
    }
    
    // Hierarchical chunking for structured documents
    func hierarchicalChunk(document: StructuredDocument) async throws -> HierarchicalChunks {
        var chunks = HierarchicalChunks()
        
        // Process document hierarchy
        for section in document.sections {
            let sectionChunks = try await processSectionHierarchy(
                section: section,
                parentPath: [document.title]
            )
            chunks.sections.append(sectionChunks)
        }
        
        // Create summary embeddings for navigation
        chunks.summaryEmbeddings = try await createSummaryEmbeddings(chunks)
        
        return chunks
    }
    
    // Smart chunking with context preservation
    func contextAwareChunk(text: String, context: DocumentContext) async throws -> [ContextualChunk] {
        var chunks: [ContextualChunk] = []
        
        // Identify important entities and concepts
        let entities = try await extractEntities(from: text)
        let keyPhrases = try await extractKeyPhrases(from: text)
        
        // Chunk with entity boundaries
        let rawChunks = try await semanticChunk(text: text)
        
        for (index, chunk) in rawChunks.enumerated() {
            // Find entities in this chunk
            let chunkEntities = entities.filter { chunk.content.contains($0.text) }
            let chunkPhrases = keyPhrases.filter { chunk.content.contains($0) }
            
            // Add contextual information
            let contextualChunk = ContextualChunk(
                content: chunk.content,
                index: index,
                context: ChunkContext(
                    documentTitle: context.title,
                    documentType: context.type,
                    section: context.currentSection,
                    entities: chunkEntities,
                    keyPhrases: chunkPhrases,
                    precedingContext: index > 0 ? extractSummary(from: rawChunks[index - 1]) : nil,
                    followingContext: index < rawChunks.count - 1 ? extractSummary(from: rawChunks[index + 1]) : nil
                ),
                metadata: chunk.metadata
            )
            
            chunks.append(contextualChunk)
        }
        
        return chunks
    }
    
    // Sliding window chunking for dense information
    func slidingWindowChunk(text: String, windowSize: Int = 1000, stepSize: Int = 500) -> [WindowChunk] {
        var chunks: [WindowChunk] = []
        let tokens = tokenize(text)
        var position = 0
        
        while position < tokens.count {
            let endPosition = min(position + windowSize, tokens.count)
            let windowTokens = Array(tokens[position..<endPosition])
            
            let chunk = WindowChunk(
                content: windowTokens.joined(separator: " "),
                startPosition: position,
                endPosition: endPosition,
                overlapWithPrevious: position > 0 ? windowSize - stepSize : 0,
                overlapWithNext: endPosition < tokens.count ? windowSize - stepSize : 0
            )
            
            chunks.append(chunk)
            position += stepSize
        }
        
        return chunks
    }
    
    // Multi-modal chunking for documents with images/tables
    func multiModalChunk(document: MultiModalDocument) async throws -> [MultiModalChunk] {
        var chunks: [MultiModalChunk] = []
        
        for element in document.elements {
            switch element {
            case .text(let content):
                let textChunks = try await semanticChunk(text: content)
                chunks.append(contentsOf: textChunks.map { .text($0) })
                
            case .image(let imageData, let caption):
                // Generate image embedding
                let imageEmbedding = try await generateImageEmbedding(imageData)
                chunks.append(.image(ImageChunk(
                    embedding: imageEmbedding,
                    caption: caption,
                    surroundingText: extractSurroundingContext(document, element)
                )))
                
            case .table(let tableData):
                // Convert table to searchable format
                let tableChunks = try await processTable(tableData)
                chunks.append(contentsOf: tableChunks)
                
            case .code(let codeBlock):
                // Special handling for code blocks
                chunks.append(.code(CodeChunk(
                    content: codeBlock.content,
                    language: codeBlock.language,
                    documentation: try await generateCodeDocumentation(codeBlock)
                )))
            }
        }
        
        return chunks
    }
    
    // Helper functions
    private func extractSentences(from text: String) -> [String] {
        // Use NLP for proper sentence segmentation
        let tagger = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)
        tagger.string = text
        var sentences: [String] = []
        var currentSentence = ""
        
        tagger.enumerateTags(in: NSRange(location: 0, length: text.count), 
                            unit: .sentence, 
                            scheme: .tokenType, 
                            options: [.omitWhitespace]) { _, tokenRange, _ in
            let sentence = (text as NSString).substring(with: tokenRange)
            sentences.append(sentence)
            return true
        }
        
        return sentences
    }
    
    private func estimateTokens(_ text: String) -> Int {
        // Rough estimation: ~4 characters per token
        return text.count / 4
    }
    
    private func extractOverlap(from chunk: String, tokens: Int) -> String {
        let words = chunk.split(separator: " ")
        let overlapWords = Int(Double(words.count) * Double(tokens) / Double(estimateTokens(chunk)))
        return words.suffix(overlapWords).joined(separator: " ")
    }
    
    private func extractEntities(from text: String) async throws -> [Entity] {
        let request = ChatCompletionRequest(
            model: .gpt4turbo,
            messages: [
                .system("Extract named entities (people, places, organizations, etc.) from the text."),
                .user(text)
            ],
            responseFormat: .jsonObject
        )
        
        let response = try await openAI.chat.completions.create(request)
        // Parse entities from response
        return []
    }
    
    private func extractKeyPhrases(from text: String) async throws -> [String] {
        let request = ChatCompletionRequest(
            model: .gpt4turbo,
            messages: [
                .system("Extract key phrases and important concepts from the text."),
                .user(text)
            ]
        )
        
        let response = try await openAI.chat.completions.create(request)
        // Parse key phrases from response
        return []
    }
}

// Data structures
struct DocumentChunk {
    let content: String
    let index: Int
    let metadata: ChunkMetadata
}

struct ChunkMetadata {
    let startToken: Int
    let endToken: Int
    let hasOverlap: Bool
}

struct StructuredDocument {
    let title: String
    let sections: [Section]
}

struct Section {
    let title: String
    let content: String
    let subsections: [Section]
}

struct HierarchicalChunks {
    var sections: [SectionChunks] = []
    var summaryEmbeddings: [String: [Float]] = [:]
}

struct SectionChunks {
    let path: [String]
    let chunks: [DocumentChunk]
    let summary: String
}

struct DocumentContext {
    let title: String
    let type: DocumentType
    let currentSection: String?
}

enum DocumentType {
    case technical
    case narrative
    case reference
    case mixed
}

struct ContextualChunk {
    let content: String
    let index: Int
    let context: ChunkContext
    let metadata: ChunkMetadata
}

struct ChunkContext {
    let documentTitle: String
    let documentType: DocumentType
    let section: String?
    let entities: [Entity]
    let keyPhrases: [String]
    let precedingContext: String?
    let followingContext: String?
}

struct Entity {
    let text: String
    let type: EntityType
}

enum EntityType {
    case person
    case place
    case organization
    case concept
}

struct WindowChunk {
    let content: String
    let startPosition: Int
    let endPosition: Int
    let overlapWithPrevious: Int
    let overlapWithNext: Int
}

enum MultiModalElement {
    case text(String)
    case image(Data, caption: String)
    case table(TableData)
    case code(CodeBlock)
}

struct MultiModalDocument {
    let elements: [MultiModalElement]
}

enum MultiModalChunk {
    case text(DocumentChunk)
    case image(ImageChunk)
    case table(TableChunk)
    case code(CodeChunk)
}

struct ImageChunk {
    let embedding: [Float]
    let caption: String
    let surroundingText: String
}

struct TableChunk {
    let content: String
    let headers: [String]
    let summary: String
}

struct CodeChunk {
    let content: String
    let language: String
    let documentation: String
}

struct TableData {
    let headers: [String]
    let rows: [[String]]
}

struct CodeBlock {
    let content: String
    let language: String
}

// Usage example
func demonstrateAdvancedChunking() async throws {
    let openAI = OpenAI(apiKey: "your-api-key")
    let chunker = AdvancedChunker(openAI: openAI)
    
    // Example 1: Semantic chunking with overlap
    let document = """
    Introduction to Machine Learning. Machine learning is a subset of artificial intelligence.
    It focuses on the development of algorithms that can learn from data. These algorithms
    improve their performance over time without being explicitly programmed.
    
    Types of Machine Learning. There are three main types: supervised learning, unsupervised
    learning, and reinforcement learning. Each type has its own characteristics and use cases.
    """
    
    let semanticChunks = try await chunker.semanticChunk(text: document)
    print("Semantic chunks with overlap: \(semanticChunks.count)")
    
    // Example 2: Context-aware chunking
    let context = DocumentContext(
        title: "ML Fundamentals",
        type: .technical,
        currentSection: "Introduction"
    )
    
    let contextualChunks = try await chunker.contextAwareChunk(
        text: document,
        context: context
    )
    
    print("Contextual chunks with entities: \(contextualChunks.count)")
    
    // Example 3: Sliding window for dense information
    let denseText = "Deep learning neural networks transformer models attention mechanisms..."
    let windowChunks = chunker.slidingWindowChunk(
        text: denseText,
        windowSize: 100,
        stepSize: 50
    )
    
    print("Sliding window chunks: \(windowChunks.count)")
}