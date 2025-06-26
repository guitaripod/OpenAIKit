import OpenAIKit
import Foundation

// Query expansion techniques for comprehensive semantic search

struct QueryExpander {
    let openAI: OpenAI
    
    // Synonym expansion using embeddings
    func synonymExpansion(query: String) async throws -> ExpandedQuery {
        // Generate variations using GPT
        let request = ChatCompletionRequest(
            model: .gpt4turbo,
            messages: [
                .system("""
                Generate synonyms and related terms for the search query.
                Return a JSON object with:
                - synonyms: array of synonym phrases
                - related: array of related concepts
                - broader: array of broader terms
                - narrower: array of more specific terms
                """),
                .user(query)
            ],
            responseFormat: .jsonObject
        )
        
        let response = try await openAI.chat.completions.create(request)
        let expansions = try parseExpansions(response.choices.first?.message.content ?? "")
        
        // Generate embeddings for all variations
        var expandedTerms: [ExpandedTerm] = []
        
        // Original query
        expandedTerms.append(ExpandedTerm(
            text: query,
            type: .original,
            weight: 1.0
        ))
        
        // Synonyms
        for synonym in expansions.synonyms {
            expandedTerms.append(ExpandedTerm(
                text: synonym,
                type: .synonym,
                weight: 0.8
            ))
        }
        
        // Related terms
        for related in expansions.related {
            expandedTerms.append(ExpandedTerm(
                text: related,
                type: .related,
                weight: 0.6
            ))
        }
        
        // Broader/narrower terms
        for broader in expansions.broader {
            expandedTerms.append(ExpandedTerm(
                text: broader,
                type: .broader,
                weight: 0.5
            ))
        }
        
        for narrower in expansions.narrower {
            expandedTerms.append(ExpandedTerm(
                text: narrower,
                type: .narrower,
                weight: 0.7
            ))
        }
        
        return ExpandedQuery(
            original: query,
            expandedTerms: expandedTerms,
            strategy: .synonym
        )
    }
    
    // Conceptual expansion using knowledge graphs
    func conceptualExpansion(query: String, domain: String? = nil) async throws -> ExpandedQuery {
        let systemPrompt = """
        You are a knowledge graph expert. For the given query, identify:
        1. Core concepts and their relationships
        2. Domain-specific terminology (if domain is specified)
        3. Hierarchical relationships (parent/child concepts)
        4. Associated attributes and properties
        
        Return a structured JSON response.
        """
        
        let userPrompt = domain != nil 
            ? "Query: \(query)\nDomain: \(domain!)"
            : "Query: \(query)"
        
        let request = ChatCompletionRequest(
            model: .gpt4turbo,
            messages: [
                .system(systemPrompt),
                .user(userPrompt)
            ],
            responseFormat: .jsonObject
        )
        
        let response = try await openAI.chat.completions.create(request)
        let concepts = try parseConceptualExpansion(response.choices.first?.message.content ?? "")
        
        // Build expanded query with concept relationships
        var expandedTerms: [ExpandedTerm] = [
            ExpandedTerm(text: query, type: .original, weight: 1.0)
        ]
        
        // Add core concepts
        for concept in concepts.coreConcepts {
            expandedTerms.append(ExpandedTerm(
                text: concept.name,
                type: .concept,
                weight: concept.relevance
            ))
        }
        
        // Add related concepts with relationship weights
        for relation in concepts.relationships {
            let weight = calculateRelationshipWeight(relation.type)
            expandedTerms.append(ExpandedTerm(
                text: relation.targetConcept,
                type: .related,
                weight: weight,
                relationship: relation.type
            ))
        }
        
        return ExpandedQuery(
            original: query,
            expandedTerms: expandedTerms,
            strategy: .conceptual,
            conceptGraph: concepts
        )
    }
    
    // Query reformulation using user context
    func contextualReformulation(
        query: String,
        userContext: UserContext,
        searchHistory: [SearchHistoryItem]
    ) async throws -> ExpandedQuery {
        // Analyze recent search patterns
        let recentQueries = searchHistory
            .prefix(10)
            .map { $0.query }
        
        let recentClicks = searchHistory
            .flatMap { $0.clickedResults }
            .prefix(20)
        
        // Generate contextual expansion
        let request = ChatCompletionRequest(
            model: .gpt4turbo,
            messages: [
                .system("""
                Based on the user's search history and context, reformulate and expand the query.
                Consider:
                - User's expertise level: \(userContext.expertiseLevel)
                - Previous searches: \(recentQueries.joined(separator: ", "))
                - Domain preferences: \(userContext.domainPreferences.joined(separator: ", "))
                
                Provide expansions that match the user's intent and knowledge level.
                """),
                .user("Current query: \(query)")
            ]
        )
        
        let response = try await openAI.chat.completions.create(request)
        let reformulations = try parseReformulations(response.choices.first?.message.content ?? "")
        
        // Weight expansions based on user behavior
        var expandedTerms: [ExpandedTerm] = []
        
        for reformulation in reformulations {
            let weight = calculateUserContextWeight(
                reformulation: reformulation,
                userContext: userContext,
                clickHistory: recentClicks
            )
            
            expandedTerms.append(ExpandedTerm(
                text: reformulation.text,
                type: reformulation.type,
                weight: weight,
                userContextMatch: reformulation.contextMatch
            ))
        }
        
        return ExpandedQuery(
            original: query,
            expandedTerms: expandedTerms,
            strategy: .contextual,
            userContext: userContext
        )
    }
    
    // Multi-lingual query expansion
    func multilingualExpansion(
        query: String,
        targetLanguages: [String],
        preserveIntent: Bool = true
    ) async throws -> MultilingualExpandedQuery {
        var translations: [LanguageTranslation] = []
        
        for language in targetLanguages {
            let request = ChatCompletionRequest(
                model: .gpt4turbo,
                messages: [
                    .system("""
                    Translate the search query to \(language) while preserving search intent.
                    Also provide:
                    - Cultural adaptations if needed
                    - Domain-specific terminology in target language
                    - Common variations in that language
                    """),
                    .user(query)
                ],
                responseFormat: .jsonObject
            )
            
            let response = try await openAI.chat.completions.create(request)
            let translation = try parseTranslation(response.choices.first?.message.content ?? "")
            
            translations.append(LanguageTranslation(
                language: language,
                query: translation.main,
                variations: translation.variations,
                culturalAdaptations: translation.culturalAdaptations
            ))
        }
        
        // Generate unified embeddings across languages
        let crossLingualEmbeddings = try await generateCrossLingualEmbeddings(
            original: query,
            translations: translations
        )
        
        return MultilingualExpandedQuery(
            original: query,
            originalLanguage: "en",
            translations: translations,
            crossLingualEmbeddings: crossLingualEmbeddings
        )
    }
    
    // Hybrid expansion combining multiple techniques
    func hybridExpansion(
        query: String,
        config: ExpansionConfig = .default
    ) async throws -> HybridExpandedQuery {
        // Run multiple expansion strategies in parallel
        async let synonyms = synonymExpansion(query: query)
        async let concepts = conceptualExpansion(query: query, domain: config.domain)
        
        // Combine results intelligently
        let (synonymResult, conceptResult) = try await (synonyms, concepts)
        
        // Deduplicate and merge expansions
        var mergedTerms: [String: ExpandedTerm] = [:]
        var termRelationships: [TermRelationship] = []
        
        // Process synonym expansions
        for term in synonymResult.expandedTerms {
            mergedTerms[term.text.lowercased()] = term
        }
        
        // Process conceptual expansions
        for term in conceptResult.expandedTerms {
            let key = term.text.lowercased()
            if let existing = mergedTerms[key] {
                // Merge weights using configured strategy
                mergedTerms[key] = mergeExpandedTerms(existing, term, strategy: config.mergeStrategy)
            } else {
                mergedTerms[key] = term
            }
        }
        
        // Identify term relationships
        if let conceptGraph = conceptResult.conceptGraph {
            termRelationships = extractTermRelationships(from: conceptGraph)
        }
        
        // Apply query intent analysis
        let intent = try await analyzeQueryIntent(query: query)
        
        // Adjust weights based on intent
        let adjustedTerms = adjustTermWeights(
            terms: Array(mergedTerms.values),
            intent: intent,
            config: config
        )
        
        return HybridExpandedQuery(
            original: query,
            expandedTerms: adjustedTerms,
            termRelationships: termRelationships,
            queryIntent: intent,
            expansionStrategies: [.synonym, .conceptual]
        )
    }
    
    // Advanced reranking with expanded queries
    func expandAndRerank(
        query: String,
        candidates: [SearchResult],
        expansionStrategy: ExpansionStrategy
    ) async throws -> [RankedResult] {
        // Expand query
        let expandedQuery = try await hybridExpansion(query: query)
        
        // Generate embeddings for all expanded terms
        var termEmbeddings: [String: [Float]] = [:]
        
        for term in expandedQuery.expandedTerms {
            let embedding = try await generateEmbedding(for: term.text)
            termEmbeddings[term.text] = embedding
        }
        
        // Score each candidate against expanded query
        var rankedResults: [RankedResult] = []
        
        for candidate in candidates {
            var totalScore: Float = 0.0
            var termScores: [String: Float] = [:]
            
            // Score against each expanded term
            for term in expandedQuery.expandedTerms {
                if let termEmbedding = termEmbeddings[term.text] {
                    let similarity = cosineSimilarity(
                        termEmbedding,
                        candidate.embedding
                    )
                    
                    let weightedScore = similarity * term.weight
                    termScores[term.text] = weightedScore
                    totalScore += weightedScore
                }
            }
            
            // Apply relationship bonus
            let relationshipBonus = calculateRelationshipBonus(
                candidate: candidate,
                relationships: expandedQuery.termRelationships
            )
            
            totalScore += relationshipBonus
            
            rankedResults.append(RankedResult(
                result: candidate,
                score: totalScore,
                termScores: termScores,
                expansionContribution: totalScore - candidate.baseScore
            ))
        }
        
        // Sort by score
        return rankedResults.sorted { $0.score > $1.score }
    }
    
    // Helper functions
    private func parseExpansions(_ json: String) throws -> QueryExpansions {
        // Parse JSON response
        QueryExpansions(
            synonyms: [],
            related: [],
            broader: [],
            narrower: []
        )
    }
    
    private func calculateRelationshipWeight(_ type: RelationType) -> Float {
        switch type {
        case .synonym: return 0.9
        case .hyponym: return 0.7
        case .hypernym: return 0.6
        case .meronym: return 0.5
        case .holonym: return 0.5
        case .related: return 0.4
        }
    }
    
    private func generateEmbedding(for text: String) async throws -> [Float] {
        let request = EmbeddingRequest(
            model: .textEmbedding3Large,
            input: .string(text)
        )
        
        let response = try await openAI.embeddings.create(request)
        return response.data.first?.embedding ?? []
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }
        
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
}

// Data structures
struct ExpandedQuery {
    let original: String
    let expandedTerms: [ExpandedTerm]
    let strategy: ExpansionStrategy
    var conceptGraph: ConceptGraph?
    var userContext: UserContext?
}

struct ExpandedTerm {
    let text: String
    let type: TermType
    let weight: Float
    var relationship: RelationType?
    var userContextMatch: Float?
}

enum TermType {
    case original
    case synonym
    case related
    case broader
    case narrower
    case concept
    case contextual
}

enum ExpansionStrategy {
    case synonym
    case conceptual
    case contextual
    case multilingual
    case hybrid
}

struct QueryExpansions {
    let synonyms: [String]
    let related: [String]
    let broader: [String]
    let narrower: [String]
}

struct ConceptGraph {
    let coreConcepts: [Concept]
    let relationships: [ConceptRelationship]
}

struct Concept {
    let name: String
    let relevance: Float
    let attributes: [String]
}

struct ConceptRelationship {
    let sourceConcept: String
    let targetConcept: String
    let type: RelationType
}

enum RelationType {
    case synonym
    case hyponym
    case hypernym
    case meronym
    case holonym
    case related
}

struct UserContext {
    let expertiseLevel: ExpertiseLevel
    let domainPreferences: [String]
    let searchHistory: [String]
}

enum ExpertiseLevel {
    case beginner
    case intermediate
    case expert
}

struct SearchHistoryItem {
    let query: String
    let timestamp: Date
    let clickedResults: [String]
}

struct MultilingualExpandedQuery {
    let original: String
    let originalLanguage: String
    let translations: [LanguageTranslation]
    let crossLingualEmbeddings: [String: [Float]]
}

struct LanguageTranslation {
    let language: String
    let query: String
    let variations: [String]
    let culturalAdaptations: [String]
}

struct HybridExpandedQuery {
    let original: String
    let expandedTerms: [ExpandedTerm]
    let termRelationships: [TermRelationship]
    let queryIntent: QueryIntent
    let expansionStrategies: [ExpansionStrategy]
}

struct TermRelationship {
    let term1: String
    let term2: String
    let relationship: RelationType
    let strength: Float
}

struct QueryIntent {
    let type: IntentType
    let confidence: Float
    let entities: [String]
}

enum IntentType {
    case informational
    case navigational
    case transactional
    case research
}

struct ExpansionConfig {
    let domain: String?
    let mergeStrategy: MergeStrategy
    let maxTerms: Int
    let minWeight: Float
    
    static let `default` = ExpansionConfig(
        domain: nil,
        mergeStrategy: .weighted,
        maxTerms: 20,
        minWeight: 0.3
    )
}

enum MergeStrategy {
    case weighted
    case maximum
    case average
}

struct SearchResult {
    let id: String
    let content: String
    let embedding: [Float]
    let baseScore: Float
}

struct RankedResult {
    let result: SearchResult
    let score: Float
    let termScores: [String: Float]
    let expansionContribution: Float
}

// Usage example
func demonstrateQueryExpansion() async throws {
    let openAI = OpenAI(apiKey: "your-api-key")
    let expander = QueryExpander(openAI: openAI)
    
    // Example 1: Synonym expansion
    let synonymExpanded = try await expander.synonymExpansion(
        query: "machine learning algorithms"
    )
    print("Synonym expansion: \(synonymExpanded.expandedTerms.count) terms")
    
    // Example 2: Conceptual expansion with domain
    let conceptExpanded = try await expander.conceptualExpansion(
        query: "neural networks",
        domain: "deep learning"
    )
    print("Conceptual expansion: \(conceptExpanded.expandedTerms.count) terms")
    
    // Example 3: Contextual reformulation
    let userContext = UserContext(
        expertiseLevel: .intermediate,
        domainPreferences: ["AI", "data science"],
        searchHistory: ["pytorch tutorials", "transformer models"]
    )
    
    let contextualExpanded = try await expander.contextualReformulation(
        query: "attention mechanism",
        userContext: userContext,
        searchHistory: []
    )
    print("Contextual expansion: \(contextualExpanded.expandedTerms.count) terms")
    
    // Example 4: Hybrid expansion
    let hybridExpanded = try await expander.hybridExpansion(
        query: "natural language processing",
        config: ExpansionConfig(
            domain: "AI",
            mergeStrategy: .weighted,
            maxTerms: 30,
            minWeight: 0.4
        )
    )
    print("Hybrid expansion: \(hybridExpanded.expandedTerms.count) terms")
}