import Foundation

/// A request to create a response using OpenAI's Responses API.
///
/// This struct represents the complete set of parameters you can send to the OpenAI Responses API.
/// The API provides enhanced capabilities including deep research, web search, MCP tool integration,
/// and code interpretation.
///
/// ## Example
/// ```swift
/// let request = ResponseRequest(
///     input: "Research the latest developments in quantum computing and their applications in cryptography",
///     model: "o3-deep-research",
///     tools: [
///         .webSearchPreview(WebSearchPreviewTool()),
///         .mcp(MCPTool(
///             serverLabel: "github",
///             serverUrl: "https://api.github.com",
///             requireApproval: false
///         ))
///     ]
/// )
/// ```
///
/// ## Topics
/// ### Essential Properties
/// - ``input``
/// - ``model``
///
/// ### Tool Configuration
/// - ``tools``
/// - ``ResponseTool``
/// - ``WebSearchPreviewTool``
/// - ``MCPTool``
/// - ``CodeInterpreterTool``
///
/// ### Response Control
/// - ``temperature``
/// - ``maxTokens``
/// - ``responseFormat``
/// - ``metadata``
public struct ResponseRequest: Codable, Sendable {
    /// The input text to generate a response for.
    ///
    /// For DeepResearch models, this should be a well-formed research query or prompt.
    /// The input can be a question, topic, or detailed instructions for the research task.
    public let input: String
    
    /// The ID of the model to use.
    ///
    /// Common model IDs include:
    /// - `"o3-deep-research"` - Most capable research model
    /// - `"o4-mini-deep-research"` - Faster research model
    /// - `"gpt-4o"` - Optimized for research and complex tasks
    /// - `"gpt-4o-mini"` - Faster and more cost-effective
    public let model: String
    
    /// The tools available to the model.
    ///
    /// An array of tools that the model can use during response generation,
    /// including web search, MCP tools, and code interpretation.
    public let tools: [ResponseTool]?
    
    /// The sampling temperature between 0 and 2.
    ///
    /// Higher values like 0.8 will make the output more random, while lower values like 0.2
    /// will make it more focused and deterministic.
    public let temperature: Double?
    
    /// The maximum number of tokens to generate in the response.
    ///
    /// The token count of your prompt plus `maxOutputTokens` cannot exceed the model's context length.
    public let maxOutputTokens: Int?
    
    /// The format that the model must output.
    ///
    /// Setting to `{ "type": "json_object" }` enables JSON mode, which ensures the model
    /// generates valid JSON.
    public let responseFormat: ResponseFormat?
    
    /// Developer-defined tags and values for filtering completions.
    ///
    /// Useful for tracking and organizing API usage in production applications.
    public let metadata: [String: String]?
    
    /// Whether to stream the response.
    ///
    /// When true, partial message deltas will be sent. Tokens will be sent as they become available.
    public let stream: Bool?
    
    /// Whether to run this request in background mode.
    ///
    /// Background mode is recommended for DeepResearch tasks that may take tens of minutes.
    /// When true, the response will include a task ID that can be polled for completion.
    public let background: Bool?
    
    /// Creates a new response request.
    ///
    /// - Parameters:
    ///   - input: The input text or research query
    ///   - model: The model ID to use (e.g., "o3-deep-research", "o4-mini-deep-research", "gpt-4o")
    ///   - tools: Available tools for the model
    ///   - temperature: Sampling temperature (0 to 2)
    ///   - maxOutputTokens: Maximum tokens to generate
    ///   - responseFormat: Output format constraints
    ///   - metadata: Custom metadata for tracking
    public init(
        input: String,
        model: String,
        tools: [ResponseTool]? = nil,
        temperature: Double? = nil,
        maxOutputTokens: Int? = nil,
        responseFormat: ResponseFormat? = nil,
        metadata: [String: String]? = nil,
        stream: Bool? = nil,
        background: Bool? = nil
    ) {
        self.input = input
        self.model = model
        self.tools = tools
        self.temperature = temperature
        self.maxOutputTokens = maxOutputTokens
        self.responseFormat = responseFormat
        self.metadata = metadata
        self.stream = stream
        self.background = background
    }
    
    private enum CodingKeys: String, CodingKey {
        case input
        case model
        case tools
        case temperature
        case maxOutputTokens = "max_output_tokens"
        case responseFormat = "response_format"
        case metadata
        case stream
        case background
    }
}

/// A tool that can be used by the model in the Responses API.
///
/// Tools extend the model's capabilities by allowing it to search the web,
/// call MCP tools, or execute code. Each tool type has specific configuration options.
///
/// ## Example
/// ```swift
/// let webSearch = ResponseTool.webSearchPreview(WebSearchPreviewTool())
/// let mcpTool = ResponseTool.mcp(MCPTool(
///     serverLabel: "database",
///     serverUrl: "postgres://localhost:5432",
///     requireApproval: true
/// ))
/// let codeInterpreter = ResponseTool.codeInterpreter(CodeInterpreterTool(
///     container: CodeContainer(imageUrl: "python:3.10")
/// ))
/// ```
public enum ResponseTool: Codable, Sendable {
    /// Web search preview tool for searching the internet.
    case webSearchPreview(WebSearchPreviewTool)
    
    /// MCP (Model Context Protocol) tool for external integrations.
    case mcp(MCPTool)
    
    /// Code interpreter tool for executing code.
    case codeInterpreter(CodeInterpreterTool)
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    private enum ToolType: String, Codable {
        case webSearchPreview = "web_search_preview"
        case mcp = "mcp"
        case codeInterpreter = "code_interpreter"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ToolType.self, forKey: .type)
        
        switch type {
        case .webSearchPreview:
            let tool = try WebSearchPreviewTool(from: decoder)
            self = .webSearchPreview(tool)
        case .mcp:
            let tool = try MCPTool(from: decoder)
            self = .mcp(tool)
        case .codeInterpreter:
            let tool = try CodeInterpreterTool(from: decoder)
            self = .codeInterpreter(tool)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .webSearchPreview(let tool):
            try container.encode(ToolType.webSearchPreview, forKey: .type)
            try tool.encode(to: encoder)
        case .mcp(let tool):
            try container.encode(ToolType.mcp, forKey: .type)
            try tool.encode(to: encoder)
        case .codeInterpreter(let tool):
            try container.encode(ToolType.codeInterpreter, forKey: .type)
            try tool.encode(to: encoder)
        }
    }
}

/// Web search preview tool configuration.
///
/// Enables the model to search the web for current information and research.
/// This tool provides capabilities for web searching, opening pages, and finding
/// information within pages.
///
/// ## Example
/// ```swift
/// let webSearchTool = WebSearchPreviewTool()
/// ```
public struct WebSearchPreviewTool: Codable, Sendable {
    /// The type of tool, always "web_search_preview".
    public let type: String
    
    /// Creates a new web search preview tool.
    public init() {
        self.type = "web_search_preview"
    }
}

/// MCP (Model Context Protocol) tool configuration.
///
/// Allows integration with external services and tools through the Model Context Protocol.
/// MCP tools can connect to databases, APIs, and other services to extend the model's capabilities.
///
/// ## Example
/// ```swift
/// let mcpTool = MCPTool(
///     serverLabel: "github",
///     serverUrl: "https://api.github.com",
///     requireApproval: false
/// )
/// ```
public struct MCPTool: Codable, Sendable {
    /// The type of tool, always "mcp".
    public let type: String
    
    /// A label identifying the MCP server.
    ///
    /// Used to distinguish between different MCP servers when multiple are configured.
    public let serverLabel: String
    
    /// The URL of the MCP server.
    ///
    /// This should be a valid URL pointing to the MCP service endpoint.
    public let serverUrl: String
    
    /// Whether user approval is required before calling this tool.
    ///
    /// When true, the model will request user confirmation before executing
    /// operations on this MCP server.
    public let requireApproval: Bool
    
    /// Creates a new MCP tool configuration.
    ///
    /// - Parameters:
    ///   - serverLabel: Label identifying the server
    ///   - serverUrl: URL of the MCP server
    ///   - requireApproval: Whether to require user approval for operations
    public init(serverLabel: String, serverUrl: String, requireApproval: Bool = true) {
        self.type = "mcp"
        self.serverLabel = serverLabel
        self.serverUrl = serverUrl
        self.requireApproval = requireApproval
    }
}

/// Code interpreter tool configuration.
///
/// Enables the model to write and execute code in a sandboxed environment.
/// Supports various programming languages and can be configured with custom containers.
///
/// ## Example
/// ```swift
/// let codeInterpreter = CodeInterpreterTool(
///     container: CodeContainer(
///         imageUrl: "python:3.10",
///         environment: ["API_KEY": "secret"]
///     )
/// )
/// ```
public struct CodeInterpreterTool: Codable, Sendable {
    /// The type of tool, always "code_interpreter".
    public let type: String
    
    /// Container configuration for code execution.
    ///
    /// Specifies the runtime environment for code execution.
    public let container: CodeContainer?
    
    /// Creates a new code interpreter tool.
    ///
    /// - Parameter container: Container configuration for code execution
    public init(container: CodeContainer? = nil) {
        self.type = "code_interpreter"
        self.container = container
    }
}

/// Container configuration for code interpreter.
///
/// Defines the runtime environment for code execution. For DeepResearch,
/// typically uses "auto" to let the system choose the appropriate container.
///
/// ## Example
/// ```swift
/// let container = CodeContainer(type: "auto")
/// ```
public struct CodeContainer: Codable, Sendable {
    /// The type of container configuration.
    ///
    /// Usually "auto" to let the system automatically select the appropriate
    /// runtime environment based on the code being executed.
    public let type: String
    
    /// Creates a new container configuration.
    ///
    /// - Parameter type: Container type, typically "auto"
    public init(type: String = "auto") {
        self.type = type
    }
}

/// The response from the Responses API.
///
/// Contains the model's response along with metadata about the generation process,
/// including any tool calls made during deep research or code execution.
///
/// ## Example
/// ```swift
/// let response: Response = try await openAI.createResponse(request)
/// 
/// // Extract the final text from output items
/// if let output = response.output {
///     for item in output {
///         if item.type == "message" {
///             // Handle the final message content
///         }
///     }
/// }
/// ```
public struct Response: Codable, Sendable {
    /// Unique identifier for this response.
    public let id: String
    
    /// Object type, always "response".
    public let object: String
    
    /// Timestamp when the response was created.
    public let createdAt: Date?
    
    /// Status of the response (e.g., "complete", "incomplete").
    public let status: String?
    
    /// Whether this is a background task.
    public let background: Bool?
    
    /// Error information if the response failed.
    public let error: APIErrorDetail?
    
    /// Details about why the response is incomplete.
    public let incompleteDetails: IncompleteDetails?
    
    /// The model used for this response.
    public let model: String
    
    /// Array of output items generated during the response.
    ///
    /// Contains reasoning traces, tool calls, and final messages.
    public let output: [ResponseOutputItem]?
    
    /// Token usage statistics for this response.
    ///
    /// Provides detailed information about token consumption for billing
    /// and optimization purposes.
    public let usage: ResponseUsage?
    
    /// Additional metadata about the response.
    public let metadata: [String: String]?
    
    /// Maximum output tokens configured.
    public let maxOutputTokens: Int?
    
    /// Maximum tool calls allowed.
    public let maxToolCalls: Int?
    
    /// Temperature used for generation.
    public let temperature: Double?
    
    /// Service tier used.
    public let serviceTier: String?
    
    /// Whether the response was stored.
    public let store: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case object
        case createdAt = "created_at"
        case status
        case background
        case error
        case incompleteDetails = "incomplete_details"
        case model
        case output
        case usage
        case metadata
        case maxOutputTokens = "max_output_tokens"
        case maxToolCalls = "max_tool_calls"
        case temperature
        case serviceTier = "service_tier"
        case store
    }
}

/// Details about why a response is incomplete.
public struct IncompleteDetails: Codable, Sendable {
    /// The reason for incompletion (e.g., "max_output_tokens").
    public let reason: String
}

/// An output item in the response array.
///
/// Represents different types of outputs generated during response processing,
/// including reasoning traces, tool calls, and final messages.
public struct ResponseOutputItem: Codable, Sendable {
    /// Unique identifier for this output item.
    public let id: String
    
    /// The type of output (e.g., "reasoning", "message", "tool_call", "web_search_call").
    public let type: String
    
    /// Summary information for reasoning outputs.
    public let summary: [String]?
    
    /// Content for message outputs - can be either a string or array of content objects.
    public let content: ResponseMessageContent?
    
    /// Status of the output item (e.g., "completed").
    public let status: String?
    
    /// Role for message outputs (e.g., "assistant").
    public let role: String?
    
    /// Action information for web search calls.
    public let action: WebSearchAction?
    
    /// Tool call information.
    public let toolCall: ToolCallInfo?
    
    /// Tool response information.
    public let toolResponse: ToolResponseInfo?
    
    private enum CodingKeys: String, CodingKey {
        case id, type, summary, content, status, role, action
        case toolCall = "tool_call"
        case toolResponse = "tool_response"
    }
}

/// Message content that can be either a string or array of content objects.
public enum ResponseMessageContent: Codable, Sendable {
    case string(String)
    case array([MessageContentItem])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let arrayValue = try? container.decode([MessageContentItem].self) {
            self = .array(arrayValue)
        } else {
            throw DecodingError.typeMismatch(ResponseMessageContent.self, DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Expected String or [MessageContentItem]"
            ))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        }
    }
    
    /// Extract text content from the message content.
    public var text: String? {
        switch self {
        case .string(let value):
            return value
        case .array(let items):
            return items.compactMap { $0.text }.joined(separator: "\n")
        }
    }
}

/// A content item within a message.
public struct MessageContentItem: Codable, Sendable {
    /// The type of content (e.g., "output_text").
    public let type: String
    
    /// The text content.
    public let text: String?
    
    /// Annotations for the content.
    public let annotations: [JSONValue]?
    
    /// Log probabilities.
    public let logprobs: [JSONValue]?
}

/// Web search action information.
public struct WebSearchAction: Codable, Sendable {
    /// The type of action (e.g., "search").
    public let type: String
    
    /// The search query.
    public let query: String?
}

/// Information about a tool call.
public struct ToolCallInfo: Codable, Sendable {
    /// The type of tool called.
    public let type: String?
    
    /// The name of the tool function.
    public let name: String?
    
    /// Arguments passed to the tool.
    public let arguments: JSONValue?
}

/// Information about a tool response.
public struct ToolResponseInfo: Codable, Sendable {
    /// The result from the tool.
    public let result: JSONValue?
    
    /// Any error from the tool.
    public let error: String?
}

/// Token usage statistics for Responses API.
public struct ResponseUsage: Codable, Sendable {
    /// Number of tokens in the input.
    public let inputTokens: Int?
    
    /// Detailed information about input tokens.
    public let inputTokensDetails: TokenDetails?
    
    /// Number of tokens in the output.
    public let outputTokens: Int?
    
    /// Detailed information about output tokens.
    public let outputTokensDetails: OutputTokenDetails?
    
    /// Total number of tokens used.
    public let totalTokens: Int?
    
    private enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case inputTokensDetails = "input_tokens_details"
        case outputTokens = "output_tokens"
        case outputTokensDetails = "output_tokens_details"
        case totalTokens = "total_tokens"
    }
}

/// Detailed information about input tokens.
public struct TokenDetails: Codable, Sendable {
    /// Number of cached tokens.
    public let cachedTokens: Int?
    
    private enum CodingKeys: String, CodingKey {
        case cachedTokens = "cached_tokens"
    }
}

/// Detailed information about output tokens.
public struct OutputTokenDetails: Codable, Sendable {
    /// Number of reasoning tokens.
    public let reasoningTokens: Int?
    
    private enum CodingKeys: String, CodingKey {
        case reasoningTokens = "reasoning_tokens"
    }
}