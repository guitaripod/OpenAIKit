import OpenAIKit
import Foundation

// Automatic categorization system
class AutomaticCategorizer {
    let openAI: OpenAI
    let categoryHierarchy: CategoryHierarchy
    let classificationEngine: ClassificationEngine
    
    init(apiKey: String) {
        self.openAI = OpenAI(apiKey: apiKey)
        self.categoryHierarchy = CategoryHierarchy()
        self.classificationEngine = ClassificationEngine(openAI: openAI)
    }
    
    // Categorize a document
    func categorize(_ document: Document) async throws -> CategorizedDocument {
        // Extract features from document
        let features = try await extractFeatures(from: document)
        
        // Classify using multiple strategies
        let classifications = try await performClassifications(
            document: document,
            features: features
        )
        
        // Determine final categories with confidence scores
        let finalCategories = mergeCategorizations(classifications)
        
        // Generate category explanation
        let explanation = try await generateCategoryExplanation(
            document: document,
            categories: finalCategories
        )
        
        // Suggest new categories if needed
        let suggestedCategories = try await suggestNewCategories(
            document: document,
            existingCategories: finalCategories
        )
        
        return CategorizedDocument(
            document: document,
            primaryCategory: finalCategories.first ?? Category.uncategorized,
            categories: finalCategories,
            explanation: explanation,
            suggestedCategories: suggestedCategories,
            metadata: CategorizationMetadata(
                confidence: calculateConfidence(finalCategories),
                method: .hybrid,
                timestamp: Date()
            )
        )
    }
    
    // Batch categorization with learning
    func categorizeBatch(_ documents: [Document]) async throws -> BatchCategorizationResult {
        var categorizedDocs: [CategorizedDocument] = []
        var categoryDistribution: [String: Int] = [:]
        
        // Categorize each document
        for document in documents {
            let categorized = try await categorize(document)
            categorizedDocs.append(categorized)
            
            // Update distribution
            for category in categorized.categories {
                categoryDistribution[category.name, default: 0] += 1
            }
        }
        
        // Learn from batch patterns
        let learningInsights = try await learnFromBatch(categorizedDocs)
        
        // Update category hierarchy if needed
        if shouldUpdateHierarchy(learningInsights) {
            try await updateCategoryHierarchy(with: learningInsights)
        }
        
        return BatchCategorizationResult(
            categorizedDocuments: categorizedDocs,
            categoryDistribution: categoryDistribution,
            learningInsights: learningInsights,
            hierarchyUpdated: shouldUpdateHierarchy(learningInsights)
        )
    }
    
    // Extract features from document
    private func extractFeatures(from document: Document) async throws -> DocumentFeatures {
        // Extract keywords
        let keywords = try await extractKeywords(from: document.content)
        
        // Extract entities
        let entities = try await extractEntities(from: document.content)
        
        // Analyze structure
        let structure = analyzeStructure(document.content)
        
        // Generate content embedding
        let embedding = try await generateEmbedding(for: document.content)
        
        return DocumentFeatures(
            keywords: keywords,
            entities: entities,
            structure: structure,
            embedding: embedding,
            metadata: document.metadata
        )
    }
    
    // Perform multiple classification strategies
    private func performClassifications(
        document: Document,
        features: DocumentFeatures
    ) async throws -> [Classification] {
        var classifications: [Classification] = []
        
        // Rule-based classification
        let ruleBasedResult = classifyByRules(features: features)
        classifications.append(Classification(
            method: .ruleBased,
            categories: ruleBasedResult,
            confidence: 0.7
        ))
        
        // Embedding-based classification
        let embeddingResult = try await classifyByEmbedding(
            embedding: features.embedding
        )
        classifications.append(Classification(
            method: .embedding,
            categories: embeddingResult,
            confidence: 0.85
        ))
        
        // LLM-based classification
        let llmResult = try await classificationEngine.classifyWithLLM(
            document: document,
            availableCategories: categoryHierarchy.getAllCategories()
        )
        classifications.append(Classification(
            method: .llm,
            categories: llmResult,
            confidence: 0.9
        ))
        
        return classifications
    }
    
    // Extract keywords using LLM
    private func extractKeywords(from content: String) async throws -> [String] {
        let request = CreateChatCompletionRequest(
            model: .gpt4,
            messages: [
                .system("Extract 5-10 key terms that best represent the document's content."),
                .user("Document: \(content.prefix(1000))...\n\nKey terms:")
            ],
            temperature: 0.1,
            maxTokens: 100
        )
        
        let response = try await openAI.chat.completions.create(request)
        let keywords = response.choices.first?.message.content ?? ""
        
        return keywords
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    // Extract entities
    private func extractEntities(from content: String) async throws -> [Entity] {
        let request = CreateChatCompletionRequest(
            model: .gpt4,
            messages: [
                .system("Extract named entities (people, organizations, locations, technologies) from the text."),
                .user("Text: \(content.prefix(1000))...\n\nFormat as JSON with entity type and name.")
            ],
            temperature: 0.1,
            responseFormat: .jsonObject
        )
        
        let response = try await openAI.chat.completions.create(request)
        
        // Parse entities (simplified)
        return [
            Entity(type: .technology, name: "Machine Learning"),
            Entity(type: .organization, name: "OpenAI")
        ]
    }
    
    // Analyze document structure
    private func analyzeStructure(_ content: String) -> DocumentStructure {
        let paragraphs = content.components(separatedBy: "\n\n").count
        let sentences = content.components(separatedBy: ". ").count
        let avgSentenceLength = sentences > 0 ? content.count / sentences : 0
        
        return DocumentStructure(
            paragraphCount: paragraphs,
            sentenceCount: sentences,
            avgSentenceLength: avgSentenceLength,
            hasHeaders: content.contains("\n#") || content.contains("\n##"),
            hasList: content.contains("\n- ") || content.contains("\n* "),
            hasCode: content.contains("```") || content.contains("    ")
        )
    }
    
    // Generate embedding
    private func generateEmbedding(for text: String) async throws -> [Double] {
        let request = CreateEmbeddingRequest(
            model: .textEmbeddingAda002,
            input: .text(text.prefix(8000).description) // Limit for embedding model
        )
        
        let response = try await openAI.embeddings.create(request)
        return response.data.first?.embedding ?? []
    }
    
    // Rule-based classification
    private func classifyByRules(features: DocumentFeatures) -> [Category] {
        var categories: [Category] = []
        
        // Technology rules
        let techKeywords = ["AI", "machine learning", "algorithm", "data", "software"]
        if features.keywords.contains(where: { keyword in
            techKeywords.contains { keyword.lowercased().contains($0.lowercased()) }
        }) {
            categories.append(categoryHierarchy.getCategory(named: "Technology") ?? Category.uncategorized)
        }
        
        // Science rules
        let scienceKeywords = ["research", "study", "experiment", "hypothesis"]
        if features.keywords.contains(where: { keyword in
            scienceKeywords.contains { keyword.lowercased().contains($0.lowercased()) }
        }) {
            categories.append(categoryHierarchy.getCategory(named: "Science") ?? Category.uncategorized)
        }
        
        return categories
    }
    
    // Embedding-based classification
    private func classifyByEmbedding(embedding: [Double]) async throws -> [Category] {
        // Compare with category prototype embeddings
        let categoryEmbeddings = try await categoryHierarchy.getCategoryEmbeddings()
        
        var similarities: [(Category, Double)] = []
        
        for (category, categoryEmbedding) in categoryEmbeddings {
            let similarity = cosineSimilarity(embedding, categoryEmbedding)
            similarities.append((category, similarity))
        }
        
        // Return top categories above threshold
        return similarities
            .filter { $0.1 > 0.7 }
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map { $0.0 }
    }
    
    // Merge categorizations from different methods
    private func mergeCategorizations(_ classifications: [Classification]) -> [Category] {
        var categoryScores: [String: Double] = [:]
        
        for classification in classifications {
            let weight = classification.confidence
            for category in classification.categories {
                categoryScores[category.name, default: 0] += weight
            }
        }
        
        // Normalize and sort
        let totalWeight = classifications.map { $0.confidence }.reduce(0, +)
        let normalizedScores = categoryScores.mapValues { $0 / totalWeight }
        
        return normalizedScores
            .sorted { $0.value > $1.value }
            .prefix(3)
            .compactMap { categoryHierarchy.getCategory(named: $0.key) }
    }
    
    // Generate category explanation
    private func generateCategoryExplanation(
        document: Document,
        categories: [Category]
    ) async throws -> String {
        let request = CreateChatCompletionRequest(
            model: .gpt4,
            messages: [
                .system("Explain why the document belongs to the given categories."),
                .user("""
                Document title: \(document.title)
                Categories: \(categories.map { $0.name }.joined(separator: ", "))
                
                Content preview: \(document.content.prefix(500))...
                
                Provide a brief explanation for the categorization.
                """)
            ],
            temperature: 0.3,
            maxTokens: 150
        )
        
        let response = try await openAI.chat.completions.create(request)
        return response.choices.first?.message.content ?? "Categorized based on content analysis."
    }
    
    // Suggest new categories
    private func suggestNewCategories(
        document: Document,
        existingCategories: [Category]
    ) async throws -> [SuggestedCategory] {
        let request = CreateChatCompletionRequest(
            model: .gpt4,
            messages: [
                .system("Suggest new categories if the document doesn't fit well into existing ones."),
                .user("""
                Document: \(document.title)
                Content: \(document.content.prefix(500))...
                
                Existing categories: \(existingCategories.map { $0.name }.joined(separator: ", "))
                
                Suggest new categories if needed. Format as JSON.
                """)
            ],
            temperature: 0.5,
            responseFormat: .jsonObject
        )
        
        let response = try await openAI.chat.completions.create(request)
        
        // Parse suggestions (simplified)
        return [
            SuggestedCategory(
                name: "Deep Learning",
                parent: "Machine Learning",
                rationale: "Document focuses specifically on deep neural networks"
            )
        ]
    }
    
    // Learn from batch patterns
    private func learnFromBatch(_ documents: [CategorizedDocument]) async throws -> LearningInsights {
        // Analyze category co-occurrences
        var coOccurrences: [String: [String: Int]] = [:]
        
        for doc in documents {
            let categoryNames = doc.categories.map { $0.name }
            for i in 0..<categoryNames.count {
                for j in (i+1)..<categoryNames.count {
                    coOccurrences[categoryNames[i], default: [:]][categoryNames[j], default: 0] += 1
                    coOccurrences[categoryNames[j], default: [:]][categoryNames[i], default: 0] += 1
                }
            }
        }
        
        // Find category patterns
        let patterns = findCategoryPatterns(coOccurrences: coOccurrences)
        
        // Identify potential new categories
        let newCategorySuggestions = findNewCategorySuggestions(documents: documents)
        
        return LearningInsights(
            categoryPatterns: patterns,
            suggestedNewCategories: newCategorySuggestions,
            accuracyMetrics: calculateAccuracyMetrics(documents),
            timestamp: Date()
        )
    }
    
    // Helper functions
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return 0 }
        
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        guard magnitudeA > 0 && magnitudeB > 0 else { return 0 }
        return dotProduct / (magnitudeA * magnitudeB)
    }
    
    private func calculateConfidence(_ categories: [Category]) -> Double {
        // Simple confidence based on category count
        return categories.isEmpty ? 0 : 1.0 / Double(categories.count)
    }
    
    private func shouldUpdateHierarchy(_ insights: LearningInsights) -> Bool {
        // Update if significant patterns found or new categories suggested
        return !insights.suggestedNewCategories.isEmpty ||
               insights.categoryPatterns.contains { $0.strength > 0.8 }
    }
    
    private func updateCategoryHierarchy(with insights: LearningInsights) async throws {
        // Update hierarchy based on insights
        for suggestion in insights.suggestedNewCategories {
            categoryHierarchy.addCategory(suggestion.name, parent: suggestion.parent)
        }
    }
    
    private func findCategoryPatterns(coOccurrences: [String: [String: Int]]) -> [CategoryPattern] {
        var patterns: [CategoryPattern] = []
        
        for (category1, related) in coOccurrences {
            for (category2, count) in related {
                if count > 5 {
                    patterns.append(CategoryPattern(
                        categories: [category1, category2],
                        frequency: count,
                        strength: Double(count) / 10.0 // Simplified
                    ))
                }
            }
        }
        
        return patterns
    }
    
    private func findNewCategorySuggestions(documents: [CategorizedDocument]) -> [SuggestedCategory] {
        // Analyze documents with low confidence or suggested categories
        var suggestions: [SuggestedCategory] = []
        
        for doc in documents {
            suggestions.append(contentsOf: doc.suggestedCategories)
        }
        
        // Deduplicate and return
        return Array(Set(suggestions))
    }
    
    private func calculateAccuracyMetrics(_ documents: [CategorizedDocument]) -> AccuracyMetrics {
        let avgConfidence = documents.map { $0.metadata.confidence }.reduce(0, +) / Double(documents.count)
        let multiCategoryRate = Double(documents.filter { $0.categories.count > 1 }.count) / Double(documents.count)
        
        return AccuracyMetrics(
            averageConfidence: avgConfidence,
            multiCategoryRate: multiCategoryRate,
            uncategorizedRate: 0 // Simplified
        )
    }
}

// Classification engine
class ClassificationEngine {
    let openAI: OpenAI
    
    init(openAI: OpenAI) {
        self.openAI = openAI
    }
    
    func classifyWithLLM(
        document: Document,
        availableCategories: [Category]
    ) async throws -> [Category] {
        let categoryList = availableCategories.map { $0.name }.joined(separator: ", ")
        
        let request = CreateChatCompletionRequest(
            model: .gpt4,
            messages: [
                .system("Classify the document into appropriate categories from the given list."),
                .user("""
                Document: \(document.title)
                Content: \(document.content.prefix(1000))...
                
                Available categories: \(categoryList)
                
                Select 1-3 most appropriate categories. Return as JSON array.
                """)
            ],
            temperature: 0.2,
            responseFormat: .jsonObject
        )
        
        let response = try await openAI.chat.completions.create(request)
        
        // Parse and return categories (simplified)
        return availableCategories.prefix(2).map { $0 }
    }
}

// Category hierarchy
class CategoryHierarchy {
    private var categories: [Category] = []
    private var embeddings: [String: [Double]] = [:]
    
    init() {
        setupDefaultCategories()
    }
    
    private func setupDefaultCategories() {
        categories = [
            Category(id: "tech", name: "Technology", parent: nil),
            Category(id: "sci", name: "Science", parent: nil),
            Category(id: "ml", name: "Machine Learning", parent: "tech"),
            Category(id: "ai", name: "Artificial Intelligence", parent: "tech")
        ]
    }
    
    func getAllCategories() -> [Category] {
        return categories
    }
    
    func getCategory(named name: String) -> Category? {
        return categories.first { $0.name == name }
    }
    
    func addCategory(_ name: String, parent: String?) {
        let parentCategory = parent.flatMap { getCategory(named: $0) }
        let newCategory = Category(
            id: UUID().uuidString,
            name: name,
            parent: parentCategory?.id
        )
        categories.append(newCategory)
    }
    
    func getCategoryEmbeddings() async throws -> [(Category, [Double])] {
        // Return pre-computed or generate embeddings for categories
        return categories.compactMap { category in
            if let embedding = embeddings[category.id] {
                return (category, embedding)
            }
            return nil
        }
    }
}

// Models
struct Category: Hashable {
    let id: String
    let name: String
    let parent: String?
    
    static let uncategorized = Category(id: "uncat", name: "Uncategorized", parent: nil)
}

struct CategorizedDocument {
    let document: Document
    let primaryCategory: Category
    let categories: [Category]
    let explanation: String
    let suggestedCategories: [SuggestedCategory]
    let metadata: CategorizationMetadata
}

struct DocumentFeatures {
    let keywords: [String]
    let entities: [Entity]
    let structure: DocumentStructure
    let embedding: [Double]
    let metadata: DocumentMetadata
}

struct Entity {
    let type: EntityType
    let name: String
}

enum EntityType {
    case person
    case organization
    case location
    case technology
}

struct DocumentStructure {
    let paragraphCount: Int
    let sentenceCount: Int
    let avgSentenceLength: Int
    let hasHeaders: Bool
    let hasList: Bool
    let hasCode: Bool
}

struct DocumentMetadata {
    let author: String
    let createdAt: Date
    let source: String?
}

struct Classification {
    let method: ClassificationMethod
    let categories: [Category]
    let confidence: Double
}

enum ClassificationMethod {
    case ruleBased
    case embedding
    case llm
}

struct CategorizationMetadata {
    let confidence: Double
    let method: CategorizationMethod
    let timestamp: Date
}

enum CategorizationMethod {
    case manual
    case automatic
    case hybrid
}

struct SuggestedCategory: Hashable {
    let name: String
    let parent: String?
    let rationale: String
}

struct BatchCategorizationResult {
    let categorizedDocuments: [CategorizedDocument]
    let categoryDistribution: [String: Int]
    let learningInsights: LearningInsights
    let hierarchyUpdated: Bool
}

struct LearningInsights {
    let categoryPatterns: [CategoryPattern]
    let suggestedNewCategories: [SuggestedCategory]
    let accuracyMetrics: AccuracyMetrics
    let timestamp: Date
}

struct CategoryPattern {
    let categories: [String]
    let frequency: Int
    let strength: Double
}

struct AccuracyMetrics {
    let averageConfidence: Double
    let multiCategoryRate: Double
    let uncategorizedRate: Double
}

// Document extension with metadata
extension Document {
    var metadata: DocumentMetadata {
        return DocumentMetadata(
            author: author,
            createdAt: createdAt,
            source: nil
        )
    }
}

// Usage example
func demonstrateCategorization() async throws {
    let categorizer = AutomaticCategorizer(apiKey: "your-api-key")
    
    // Single document categorization
    let document = Document(
        id: "doc001",
        title: "Deep Learning for Natural Language Processing",
        content: """
        This comprehensive guide explores the application of deep learning 
        techniques to natural language processing tasks. We cover transformer 
        architectures, attention mechanisms, and pre-trained language models 
        like BERT and GPT. The tutorial includes practical examples using 
        PyTorch and demonstrates how to fine-tune models for specific NLP tasks.
        """,
        author: "Dr. Sarah Johnson",
        category: "Technology",
        tags: ["AI", "NLP", "Deep Learning"],
        createdAt: Date()
    )
    
    let categorized = try await categorizer.categorize(document)
    
    print("Document Categorization:")
    print("Title: \(categorized.document.title)")
    print("Primary Category: \(categorized.primaryCategory.name)")
    print("All Categories: \(categorized.categories.map { $0.name }.joined(separator: ", "))")
    print("Confidence: \(String(format: "%.2f", categorized.metadata.confidence))")
    print("Explanation: \(categorized.explanation)")
    
    if !categorized.suggestedCategories.isEmpty {
        print("\nSuggested New Categories:")
        for suggestion in categorized.suggestedCategories {
            print("- \(suggestion.name): \(suggestion.rationale)")
        }
    }
    
    // Batch categorization
    let documents = [document] // Add more documents in real usage
    let batchResult = try await categorizer.categorizeBatch(documents)
    
    print("\n\nBatch Categorization Results:")
    print("Total Documents: \(batchResult.categorizedDocuments.count)")
    print("\nCategory Distribution:")
    for (category, count) in batchResult.categoryDistribution.sorted(by: { $0.value > $1.value }) {
        print("- \(category): \(count) documents")
    }
    
    print("\nLearning Insights:")
    print("Average Confidence: \(String(format: "%.2f", batchResult.learningInsights.accuracyMetrics.averageConfidence))")
    print("Multi-category Rate: \(String(format: "%.1f%%", batchResult.learningInsights.accuracyMetrics.multiCategoryRate * 100))")
    
    if batchResult.hierarchyUpdated {
        print("\nCategory hierarchy has been updated based on learning insights!")
    }
}