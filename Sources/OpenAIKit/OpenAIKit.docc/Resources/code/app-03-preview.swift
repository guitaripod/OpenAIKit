import OpenAIKit
import Foundation

// Document preview functionality
class DocumentPreviewGenerator {
    let openAI: OpenAI
    let highlighter: TextHighlighter
    
    init(apiKey: String) {
        self.openAI = OpenAI(apiKey: apiKey)
        self.highlighter = TextHighlighter()
    }
    
    // Generate preview for search result
    func generatePreview(
        for result: RankedSearchResult,
        query: String,
        maxLength: Int = 300
    ) async throws -> DocumentPreview {
        let document = result.searchResult.document
        
        // Extract relevant snippet
        let snippet = try await extractRelevantSnippet(
            content: document.content,
            query: query,
            maxLength: maxLength
        )
        
        // Highlight query terms
        let highlightedSnippet = highlighter.highlight(
            text: snippet,
            terms: extractTerms(from: query)
        )
        
        // Generate summary if needed
        let summary = try await generateSummary(
            content: document.content,
            focusOn: query
        )
        
        return DocumentPreview(
            documentId: document.documentId,
            title: document.metadata.title,
            author: document.metadata.author,
            snippet: highlightedSnippet,
            summary: summary,
            relevanceScore: result.relevanceScore,
            matchedTerms: findMatchedTerms(content: document.content, query: query),
            previewMetadata: PreviewMetadata(
                wordCount: document.content.split(separator: " ").count,
                readingTime: estimateReadingTime(document.content),
                lastModified: Date(),
                documentType: detectDocumentType(document.metadata)
            )
        )
    }
    
    // Extract most relevant snippet
    private func extractRelevantSnippet(
        content: String,
        query: String,
        maxLength: Int
    ) async throws -> String {
        // Use LLM to find most relevant section
        let request = CreateChatCompletionRequest(
            model: .gpt4,
            messages: [
                .system("Extract the most relevant snippet from the content that best answers the query."),
                .user("""
                Query: \(query)
                
                Content: \(content)
                
                Extract a \(maxLength) character snippet that best addresses the query.
                """)
            ],
            temperature: 0.1,
            maxTokens: maxLength / 4
        )
        
        let response = try await openAI.chat.completions.create(request)
        let snippet = response.choices.first?.message.content ?? ""
        
        // Fallback to simple extraction if LLM fails
        if snippet.isEmpty {
            return simpleSnippetExtraction(content: content, query: query, maxLength: maxLength)
        }
        
        return snippet
    }
    
    // Simple snippet extraction fallback
    private func simpleSnippetExtraction(
        content: String,
        query: String,
        maxLength: Int
    ) -> String {
        let queryTerms = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let sentences = content.components(separatedBy: ". ")
        
        // Find sentences containing query terms
        let relevantSentences = sentences.filter { sentence in
            let lowerSentence = sentence.lowercased()
            return queryTerms.contains { lowerSentence.contains($0) }
        }
        
        // Build snippet from relevant sentences
        var snippet = ""
        for sentence in relevantSentences {
            if snippet.count + sentence.count > maxLength {
                break
            }
            snippet += sentence + ". "
        }
        
        // If no relevant sentences, use beginning of content
        if snippet.isEmpty {
            snippet = String(content.prefix(maxLength))
        }
        
        return snippet.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Generate focused summary
    private func generateSummary(content: String, focusOn query: String) async throws -> String {
        let request = CreateChatCompletionRequest(
            model: .gpt4,
            messages: [
                .system("Create a concise summary focusing on aspects related to the query."),
                .user("""
                Query: \(query)
                
                Content: \(content)
                
                Provide a 2-3 sentence summary focusing on information relevant to the query.
                """)
            ],
            temperature: 0.3,
            maxTokens: 150
        )
        
        let response = try await openAI.chat.completions.create(request)
        return response.choices.first?.message.content ?? "Summary unavailable"
    }
    
    // Extract search terms
    private func extractTerms(from query: String) -> [String] {
        return query.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 2 }
    }
    
    // Find matched terms in content
    private func findMatchedTerms(content: String, query: String) -> [MatchedTerm] {
        let queryTerms = extractTerms(from: query)
        let contentLower = content.lowercased()
        
        return queryTerms.compactMap { term in
            let count = contentLower.components(separatedBy: term).count - 1
            if count > 0 {
                return MatchedTerm(term: term, frequency: count)
            }
            return nil
        }
    }
    
    // Estimate reading time
    private func estimateReadingTime(_ content: String) -> TimeInterval {
        let wordsPerMinute = 200.0
        let wordCount = Double(content.split(separator: " ").count)
        return (wordCount / wordsPerMinute) * 60 // Return in seconds
    }
    
    // Detect document type
    private func detectDocumentType(_ metadata: ChunkMetadata) -> DocumentType {
        switch metadata.category.lowercased() {
        case "technology", "science":
            return .technical
        case "tutorial", "guide":
            return .educational
        case "news", "article":
            return .article
        default:
            return .general
        }
    }
}

// Text highlighter
class TextHighlighter {
    func highlight(text: String, terms: [String]) -> HighlightedText {
        var highlights: [TextHighlight] = []
        let lowerText = text.lowercased()
        
        for term in terms {
            var searchRange = lowerText.startIndex..<lowerText.endIndex
            
            while let range = lowerText.range(of: term, options: .caseInsensitive, range: searchRange) {
                let startOffset = lowerText.distance(from: lowerText.startIndex, to: range.lowerBound)
                let endOffset = lowerText.distance(from: lowerText.startIndex, to: range.upperBound)
                
                highlights.append(TextHighlight(
                    range: startOffset..<endOffset,
                    term: term,
                    style: .primary
                ))
                
                searchRange = range.upperBound..<lowerText.endIndex
            }
        }
        
        // Sort highlights by position
        highlights.sort { $0.range.lowerBound < $1.range.lowerBound }
        
        return HighlightedText(
            text: text,
            highlights: highlights
        )
    }
}

// Preview models
struct DocumentPreview {
    let documentId: String
    let title: String
    let author: String
    let snippet: HighlightedText
    let summary: String
    let relevanceScore: Double
    let matchedTerms: [MatchedTerm]
    let previewMetadata: PreviewMetadata
}

struct HighlightedText {
    let text: String
    let highlights: [TextHighlight]
}

struct TextHighlight {
    let range: Range<Int>
    let term: String
    let style: HighlightStyle
}

enum HighlightStyle {
    case primary
    case secondary
}

struct MatchedTerm {
    let term: String
    let frequency: Int
}

struct PreviewMetadata {
    let wordCount: Int
    let readingTime: TimeInterval
    let lastModified: Date
    let documentType: DocumentType
}

enum DocumentType {
    case technical
    case educational
    case article
    case general
}

// Preview renderer
class PreviewRenderer {
    func render(_ preview: DocumentPreview) -> String {
        var output = ""
        
        // Title and metadata
        output += "\(preview.title)\n"
        output += "By \(preview.author) • \(formatReadingTime(preview.previewMetadata.readingTime))\n"
        output += "Relevance: \(String(format: "%.1f%%", preview.relevanceScore * 100))\n\n"
        
        // Highlighted snippet
        output += "Preview:\n"
        output += renderHighlightedText(preview.snippet) + "\n\n"
        
        // Summary
        output += "Summary: \(preview.summary)\n\n"
        
        // Matched terms
        if !preview.matchedTerms.isEmpty {
            output += "Matched terms: "
            output += preview.matchedTerms.map { "\($0.term) (\($0.frequency))" }.joined(separator: ", ")
        }
        
        return output
    }
    
    private func renderHighlightedText(_ highlightedText: HighlightedText) -> String {
        var result = highlightedText.text
        
        // Apply highlights (in reverse order to maintain positions)
        for highlight in highlightedText.highlights.reversed() {
            let startIndex = result.index(result.startIndex, offsetBy: highlight.range.lowerBound)
            let endIndex = result.index(result.startIndex, offsetBy: highlight.range.upperBound)
            let highlightedTerm = "**\(result[startIndex..<endIndex])**"
            result.replaceSubrange(startIndex..<endIndex, with: highlightedTerm)
        }
        
        return result
    }
    
    private func formatReadingTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 1 {
            return "< 1 min read"
        } else {
            return "\(minutes) min read"
        }
    }
}

// Usage example
func demonstratePreview() async throws {
    let previewGenerator = DocumentPreviewGenerator(apiKey: "your-api-key")
    let renderer = PreviewRenderer()
    
    // Create mock search result
    let mockResult = RankedSearchResult(
        searchResult: SearchResult(
            document: ChunkDocument(
                id: "chunk001",
                documentId: "doc001",
                content: """
                Machine learning algorithms are computational methods that enable 
                computers to learn from data without being explicitly programmed. 
                These algorithms build mathematical models based on training data 
                to make predictions or decisions. Common types include supervised 
                learning, unsupervised learning, and reinforcement learning.
                """,
                embedding: [],
                metadata: ChunkMetadata(
                    title: "Introduction to Machine Learning",
                    author: "Dr. Sarah Johnson",
                    category: "Technology",
                    tags: ["AI", "Machine Learning"],
                    chunkIndex: 0,
                    totalChunks: 5
                )
            ),
            score: 0.85
        ),
        rank: 1,
        relevanceScore: 0.85,
        explanation: "Highly relevant content"
    )
    
    // Generate preview
    let preview = try await previewGenerator.generatePreview(
        for: mockResult,
        query: "machine learning algorithms",
        maxLength: 200
    )
    
    // Render preview
    let renderedPreview = renderer.render(preview)
    print(renderedPreview)
}