import Foundation
import OpenAIKit

// Create reusable research templates

class ResearchTemplateManager {
    private var templates: [String: ResearchTemplate] = [:]
    private let openAI: OpenAI
    private let deepResearch: DeepResearch
    
    init(apiKey: String) {
        self.openAI = OpenAI(Configuration(apiKey: apiKey))
        self.deepResearch = DeepResearch(client: openAI)
        loadDefaultTemplates()
    }
    
    // Load default research templates
    private func loadDefaultTemplates() {
        // Market Analysis Template
        templates["market_analysis"] = ResearchTemplate(
            id: "market_analysis",
            name: "Market Analysis",
            description: "Comprehensive market research and competitive analysis",
            sections: [
                TemplateSection(
                    name: "Market Overview",
                    prompts: [
                        "What is the current market size and growth rate?",
                        "What are the key market segments?",
                        "What are the major trends and drivers?"
                    ],
                    required: true
                ),
                TemplateSection(
                    name: "Competitive Landscape",
                    prompts: [
                        "Who are the major players and their market share?",
                        "What are their key differentiators?",
                        "What are recent competitive moves?"
                    ],
                    required: true
                ),
                TemplateSection(
                    name: "Customer Analysis",
                    prompts: [
                        "Who are the target customers?",
                        "What are their pain points and needs?",
                        "How are buying behaviors changing?"
                    ],
                    required: true
                ),
                TemplateSection(
                    name: "Future Outlook",
                    prompts: [
                        "What are the growth projections?",
                        "What are potential disruptions?",
                        "What are the key opportunities and risks?"
                    ],
                    required: false
                )
            ],
            variables: ["industry", "geography", "timeframe"],
            outputFormat: .executive
        )
        
        // Technology Assessment Template
        templates["tech_assessment"] = ResearchTemplate(
            id: "tech_assessment",
            name: "Technology Assessment",
            description: "Evaluate technologies for adoption or investment",
            sections: [
                TemplateSection(
                    name: "Technology Overview",
                    prompts: [
                        "What is the technology and how does it work?",
                        "What problems does it solve?",
                        "What is the current maturity level?"
                    ],
                    required: true
                ),
                TemplateSection(
                    name: "Implementation Considerations",
                    prompts: [
                        "What are the technical requirements?",
                        "What is the typical implementation timeline?",
                        "What are common challenges and solutions?"
                    ],
                    required: true
                ),
                TemplateSection(
                    name: "Cost-Benefit Analysis",
                    prompts: [
                        "What are the implementation costs?",
                        "What are the expected benefits and ROI?",
                        "What are the ongoing maintenance needs?"
                    ],
                    required: true
                ),
                TemplateSection(
                    name: "Risk Assessment",
                    prompts: [
                        "What are the technical risks?",
                        "What are the security considerations?",
                        "What are the vendor/support risks?"
                    ],
                    required: true
                )
            ],
            variables: ["technology", "use_case", "organization_size"],
            outputFormat: .technical
        )
        
        // Regulatory Compliance Template
        templates["regulatory_compliance"] = ResearchTemplate(
            id: "regulatory_compliance",
            name: "Regulatory Compliance Research",
            description: "Research regulatory requirements and compliance strategies",
            sections: [
                TemplateSection(
                    name: "Regulatory Landscape",
                    prompts: [
                        "What are the applicable regulations?",
                        "Which regulatory bodies are involved?",
                        "What are recent regulatory changes?"
                    ],
                    required: true
                ),
                TemplateSection(
                    name: "Compliance Requirements",
                    prompts: [
                        "What are the specific requirements?",
                        "What are the documentation needs?",
                        "What are the reporting obligations?"
                    ],
                    required: true
                ),
                TemplateSection(
                    name: "Best Practices",
                    prompts: [
                        "What are industry best practices?",
                        "What compliance frameworks exist?",
                        "What tools and solutions are available?"
                    ],
                    required: true
                ),
                TemplateSection(
                    name: "Penalties and Enforcement",
                    prompts: [
                        "What are the penalties for non-compliance?",
                        "What is the enforcement history?",
                        "What are common violation areas?"
                    ],
                    required: false
                )
            ],
            variables: ["industry", "jurisdiction", "company_type"],
            outputFormat: .detailed
        )
        
        // Investment Due Diligence Template
        templates["investment_dd"] = ResearchTemplate(
            id: "investment_dd",
            name: "Investment Due Diligence",
            description: "Comprehensive due diligence for investment decisions",
            sections: [
                TemplateSection(
                    name: "Company Overview",
                    prompts: [
                        "What is the company's business model?",
                        "What is their competitive position?",
                        "What is their financial performance?"
                    ],
                    required: true
                ),
                TemplateSection(
                    name: "Market Opportunity",
                    prompts: [
                        "What is the addressable market size?",
                        "What is the growth potential?",
                        "What are the market dynamics?"
                    ],
                    required: true
                ),
                TemplateSection(
                    name: "Management Assessment",
                    prompts: [
                        "What is the management team's track record?",
                        "What is their vision and strategy?",
                        "What are potential leadership risks?"
                    ],
                    required: true
                ),
                TemplateSection(
                    name: "Risk Analysis",
                    prompts: [
                        "What are the business risks?",
                        "What are the market risks?",
                        "What are the execution risks?"
                    ],
                    required: true
                )
            ],
            variables: ["company", "industry", "investment_stage"],
            outputFormat: .executive
        )
    }
    
    // Execute research using a template
    func executeTemplateResearch(
        templateId: String,
        variables: [String: String],
        customizations: TemplateCustomization? = nil
    ) async throws -> TemplateResearchResult {
        
        guard let template = templates[templateId] else {
            throw TemplateError.templateNotFound(templateId)
        }
        
        // Validate required variables
        try validateVariables(variables, for: template)
        
        // Apply customizations if provided
        let customizedTemplate = customizations != nil ?
            applyCustomizations(template, customizations!) : template
        
        // Execute research for each section
        var sectionResults: [SectionResult] = []
        
        for section in customizedTemplate.sections {
            if !section.required && customizations?.skipOptionalSections == true {
                continue
            }
            
            let result = try await executeSection(
                section: section,
                template: customizedTemplate,
                variables: variables
            )
            
            sectionResults.append(result)
        }
        
        // Generate final report
        let report = try await generateTemplateReport(
            template: customizedTemplate,
            sectionResults: sectionResults,
            variables: variables
        )
        
        return TemplateResearchResult(
            templateId: templateId,
            templateName: template.name,
            variables: variables,
            sectionResults: sectionResults,
            finalReport: report,
            metadata: generateMetadata(template: template, results: sectionResults)
        )
    }
    
    // Execute a single template section
    private func executeSection(
        section: TemplateSection,
        template: ResearchTemplate,
        variables: [String: String]
    ) async throws -> SectionResult {
        
        print("Researching: \(section.name)")
        
        // Build section query
        let sectionQuery = buildSectionQuery(
            section: section,
            variables: variables
        )
        
        // Configure research based on section importance
        let config = DeepResearchConfiguration(
            maxSearchQueries: section.required ? 8 : 5,
            maxWebPages: section.required ? 15 : 10,
            searchDepth: section.required ? .comprehensive : .standard
        )
        
        // Execute research
        let result = try await deepResearch.research(
            query: sectionQuery,
            configuration: config
        )
        
        // Extract structured findings
        let findings = try await extractStructuredFindings(
            content: result.content,
            section: section,
            prompts: section.prompts
        )
        
        return SectionResult(
            sectionName: section.name,
            findings: findings,
            rawContent: result.content,
            searchQueries: result.searchQueries
        )
    }
    
    // Build query for a section
    private func buildSectionQuery(
        section: TemplateSection,
        variables: [String: String]
    ) -> String {
        
        var query = "Research Topic: \(section.name)\n\n"
        
        // Add context from variables
        query += "Context:\n"
        for (key, value) in variables {
            query += "- \(key.capitalized): \(value)\n"
        }
        query += "\n"
        
        // Add section prompts
        query += "Please research and answer:\n"
        for prompt in section.prompts {
            // Replace variables in prompts
            var processedPrompt = prompt
            for (key, value) in variables {
                processedPrompt = processedPrompt.replacingOccurrences(
                    of: "{{\(key)}}",
                    with: value
                )
            }
            query += "• \(processedPrompt)\n"
        }
        
        return query
    }
    
    // Extract structured findings
    private func extractStructuredFindings(
        content: String,
        section: TemplateSection,
        prompts: [String]
    ) async throws -> [Finding] {
        
        let extractionPrompt = """
        Extract structured findings from this research content:
        
        Section: \(section.name)
        
        Content:
        \(content)
        
        For each of these questions, provide a clear finding:
        \(prompts.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
        
        Format each finding with:
        - Question number
        - Key finding (1-2 sentences)
        - Supporting evidence
        - Confidence level (high/medium/low)
        """
        
        let messages: [ChatMessage] = [
            ChatMessage(role: .system, content: "You are an expert at extracting structured research findings."),
            ChatMessage(role: .user, content: extractionPrompt)
        ]
        
        let request = ChatCompletionRequest(
            model: .gpt4,
            messages: messages,
            temperature: 0.3,
            maxTokens: 1500
        )
        
        let response = try await openAI.chats.create(request)
        let findingsText = response.choices.first?.message.content ?? ""
        
        return parseFindings(from: findingsText, prompts: prompts)
    }
    
    // Generate final report from template results
    private func generateTemplateReport(
        template: ResearchTemplate,
        sectionResults: [SectionResult],
        variables: [String: String]
    ) async throws -> String {
        
        let reportPrompt = """
        Generate a comprehensive research report based on this template:
        
        Template: \(template.name)
        Context: \(variables.map { "\($0.key): \($0.value)" }.joined(separator: ", "))
        
        Research Findings by Section:
        \(sectionResults.map { section in
            """
            
            === \(section.sectionName) ===
            \(section.findings.map { "• \($0.keyFinding)" }.joined(separator: "\n"))
            """
        }.joined(separator: "\n"))
        
        Create a professional report with:
        1. Executive Summary
        2. Detailed findings for each section
        3. Key insights and recommendations
        4. Conclusion
        
        Output format: \(template.outputFormat.rawValue)
        """
        
        let messages: [ChatMessage] = [
            ChatMessage(role: .system, content: "You are a professional research report writer."),
            ChatMessage(role: .user, content: reportPrompt)
        ]
        
        let request = ChatCompletionRequest(
            model: .gpt4,
            messages: messages,
            temperature: 0.3,
            maxTokens: 3000
        )
        
        let response = try await openAI.chats.create(request)
        return response.choices.first?.message.content ?? ""
    }
    
    // Create custom template
    func createCustomTemplate(
        id: String,
        name: String,
        description: String,
        sections: [TemplateSection],
        variables: [String],
        outputFormat: OutputFormat = .detailed
    ) -> ResearchTemplate {
        
        let template = ResearchTemplate(
            id: id,
            name: name,
            description: description,
            sections: sections,
            variables: variables,
            outputFormat: outputFormat
        )
        
        templates[id] = template
        return template
    }
    
    // Clone and modify existing template
    func cloneTemplate(
        fromId: String,
        newId: String,
        modifications: TemplateModification
    ) throws -> ResearchTemplate {
        
        guard let original = templates[fromId] else {
            throw TemplateError.templateNotFound(fromId)
        }
        
        var newSections = original.sections
        
        // Apply section modifications
        if let sectionMods = modifications.sectionModifications {
            for (sectionName, prompts) in sectionMods {
                if let index = newSections.firstIndex(where: { $0.name == sectionName }) {
                    newSections[index].prompts.append(contentsOf: prompts)
                }
            }
        }
        
        // Add new sections
        if let additionalSections = modifications.additionalSections {
            newSections.append(contentsOf: additionalSections)
        }
        
        let newTemplate = ResearchTemplate(
            id: newId,
            name: modifications.newName ?? original.name,
            description: modifications.newDescription ?? original.description,
            sections: newSections,
            variables: modifications.additionalVariables != nil ?
                original.variables + modifications.additionalVariables! : original.variables,
            outputFormat: modifications.outputFormat ?? original.outputFormat
        )
        
        templates[newId] = newTemplate
        return newTemplate
    }
    
    // Validate variables
    private func validateVariables(_ variables: [String: String], for template: ResearchTemplate) throws {
        for requiredVar in template.variables {
            guard variables[requiredVar] != nil else {
                throw TemplateError.missingVariable(requiredVar)
            }
        }
    }
    
    // Apply customizations
    private func applyCustomizations(
        _ template: ResearchTemplate,
        _ customization: TemplateCustomization
    ) -> ResearchTemplate {
        
        var customizedTemplate = template
        
        if let additionalPrompts = customization.additionalPrompts {
            for (sectionName, prompts) in additionalPrompts {
                if let index = customizedTemplate.sections.firstIndex(where: { $0.name == sectionName }) {
                    customizedTemplate.sections[index].prompts.append(contentsOf: prompts)
                }
            }
        }
        
        return customizedTemplate
    }
    
    // Parse findings from text
    private func parseFindings(from text: String, prompts: [String]) -> [Finding] {
        // Simplified parsing - in production use more sophisticated methods
        var findings: [Finding] = []
        
        let sections = text.components(separatedBy: "\n\n")
        for (index, prompt) in prompts.enumerated() {
            if index < sections.count {
                let section = sections[index]
                let lines = section.components(separatedBy: .newlines)
                
                findings.append(Finding(
                    question: prompt,
                    keyFinding: lines.first ?? "No finding",
                    evidence: lines.dropFirst().joined(separator: " "),
                    confidence: .medium
                ))
            }
        }
        
        return findings
    }
    
    // Generate metadata
    private func generateMetadata(
        template: ResearchTemplate,
        results: [SectionResult]
    ) -> ResearchMetadata {
        
        return ResearchMetadata(
            totalSections: template.sections.count,
            completedSections: results.count,
            totalFindings: results.reduce(0) { $0 + $1.findings.count },
            totalSearchQueries: results.reduce(0) { $0 + $1.searchQueries.count },
            timestamp: Date()
        )
    }
}

// Template models
struct ResearchTemplate {
    let id: String
    let name: String
    let description: String
    var sections: [TemplateSection]
    let variables: [String]
    let outputFormat: OutputFormat
}

struct TemplateSection {
    let name: String
    var prompts: [String]
    let required: Bool
}

struct TemplateCustomization {
    let additionalPrompts: [String: [String]]?
    let skipOptionalSections: Bool
    let focusAreas: [String]?
}

struct TemplateModification {
    let newName: String?
    let newDescription: String?
    let sectionModifications: [String: [String]]?
    let additionalSections: [TemplateSection]?
    let additionalVariables: [String]?
    let outputFormat: OutputFormat?
}

enum OutputFormat: String {
    case brief = "Brief Summary"
    case detailed = "Detailed Report"
    case executive = "Executive Summary"
    case technical = "Technical Analysis"
    case academic = "Academic Paper"
}

// Result models
struct TemplateResearchResult {
    let templateId: String
    let templateName: String
    let variables: [String: String]
    let sectionResults: [SectionResult]
    let finalReport: String
    let metadata: ResearchMetadata
}

struct SectionResult {
    let sectionName: String
    let findings: [Finding]
    let rawContent: String
    let searchQueries: [String]
}

struct Finding {
    let question: String
    let keyFinding: String
    let evidence: String
    let confidence: Confidence
    
    enum Confidence {
        case high
        case medium
        case low
    }
}

struct ResearchMetadata {
    let totalSections: Int
    let completedSections: Int
    let totalFindings: Int
    let totalSearchQueries: Int
    let timestamp: Date
}

// Errors
enum TemplateError: LocalizedError {
    case templateNotFound(String)
    case missingVariable(String)
    case invalidSection(String)
    
    var errorDescription: String? {
        switch self {
        case .templateNotFound(let id):
            return "Template not found: \(id)"
        case .missingVariable(let variable):
            return "Missing required variable: \(variable)"
        case .invalidSection(let section):
            return "Invalid section: \(section)"
        }
    }
}

// Example usage
func demonstrateResearchTemplates() async {
    let templateManager = ResearchTemplateManager(apiKey: "your-api-key")
    
    // Example 1: Use built-in market analysis template
    do {
        let marketResult = try await templateManager.executeTemplateResearch(
            templateId: "market_analysis",
            variables: [
                "industry": "Electric Vehicles",
                "geography": "North America",
                "timeframe": "2024-2029"
            ],
            customizations: TemplateCustomization(
                additionalPrompts: [
                    "Market Overview": [
                        "What role does government policy play?",
                        "How is charging infrastructure developing?"
                    ]
                ],
                skipOptionalSections: false,
                focusAreas: ["Technology", "Infrastructure", "Policy"]
            )
        )
        
        print("Market Analysis Complete")
        print("Sections completed: \(marketResult.metadata.completedSections)")
        print("Total findings: \(marketResult.metadata.totalFindings)")
        print("\nReport Preview:")
        print(marketResult.finalReport.prefix(500))
        
    } catch {
        print("Template research error: \(error)")
    }
    
    // Example 2: Create custom template
    let customTemplate = templateManager.createCustomTemplate(
        id: "startup_analysis",
        name: "Startup Analysis",
        description: "Analyze early-stage startups for investment",
        sections: [
            TemplateSection(
                name: "Problem Validation",
                prompts: [
                    "What problem does the startup solve?",
                    "How big is the problem?",
                    "Who experiences this problem?"
                ],
                required: true
            ),
            TemplateSection(
                name: "Solution Analysis",
                prompts: [
                    "What is the proposed solution?",
                    "How does it differ from existing solutions?",
                    "What is the technical feasibility?"
                ],
                required: true
            ),
            TemplateSection(
                name: "Market Validation",
                prompts: [
                    "What evidence of product-market fit exists?",
                    "What is the customer feedback?",
                    "What are the early traction metrics?"
                ],
                required: true
            )
        ],
        variables: ["startup_name", "industry", "stage"],
        outputFormat: .executive
    )
    
    // Example 3: Clone and modify existing template
    do {
        let modifiedTemplate = try templateManager.cloneTemplate(
            fromId: "tech_assessment",
            newId: "ai_assessment",
            modifications: TemplateModification(
                newName: "AI Technology Assessment",
                newDescription: "Specialized assessment for AI/ML technologies",
                sectionModifications: [
                    "Technology Overview": [
                        "What type of AI/ML approach is used?",
                        "What training data is required?",
                        "What are the model performance metrics?"
                    ]
                ],
                additionalSections: [
                    TemplateSection(
                        name: "Ethical Considerations",
                        prompts: [
                            "What are the bias risks?",
                            "What are the privacy implications?",
                            "How is explainability addressed?"
                        ],
                        required: true
                    )
                ],
                additionalVariables: ["model_type", "data_requirements"],
                outputFormat: .technical
            )
        )
        
        print("\nCreated modified template: \(modifiedTemplate.name)")
        print("Sections: \(modifiedTemplate.sections.count)")
        
    } catch {
        print("Template modification error: \(error)")
    }
}