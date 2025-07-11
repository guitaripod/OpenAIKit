import Foundation

/// A request to create a chat completion with OpenAI's chat models.
///
/// `ChatCompletionRequest` is the primary way to interact with OpenAI's language models. It encapsulates
/// all parameters needed to generate text, engage in conversations, call functions, and process multimodal content.
///
/// ## Overview
///
/// Chat completions power most AI interactions in OpenAIKit. The API is designed to be simple for basic use cases
/// while offering extensive customization for advanced scenarios.
///
/// ## Basic Usage
///
/// ```swift
/// // Simple request
/// let request = ChatCompletionRequest(
///     messages: [ChatMessage(role: .user, content: "Hello!")],
///     model: Models.Chat.gpt4o
/// )
///
/// // With system prompt
/// let request = ChatCompletionRequest(
///     messages: [
///         ChatMessage(role: .system, content: "You are a helpful assistant."),
///         ChatMessage(role: .user, content: "What is the capital of France?")
///     ],
///     model: Models.Chat.gpt4o
/// )
///
/// // With parameters
/// let request = ChatCompletionRequest(
///     messages: messages,
///     model: Models.Chat.gpt4o,
///     temperature: 0.7,
///     maxTokens: 500
/// )
/// ```
///
/// ## Topics
///
/// ### Essential Properties
/// - ``messages``
/// - ``model``
///
/// ### Response Control
/// - ``temperature``
/// - ``topP``
/// - ``maxTokens``
/// - ``maxCompletionTokens``
/// - ``stop``
/// - ``seed``
///
/// ### Output Formatting
/// - ``responseFormat``
/// - ``streamOptions``
///
/// ### Content Moderation
/// - ``frequencyPenalty``
/// - ``presencePenalty``
/// - ``logitBias``
///
/// ### Advanced Features
/// - ``tools``
/// - ``toolChoice``
/// - ``parallelToolCalls``
/// - ``functions`` (deprecated)
/// - ``functionCall`` (deprecated)
///
/// ### Streaming & Real-time
/// - ``stream``
/// - ``streamOptions``
///
/// ### Multimodal
/// - ``audio``
/// - ``modalities``
///
/// ### Metadata & Tracking
/// - ``metadata``
/// - ``user``
/// - ``store``
public struct ChatCompletionRequest: Codable, Sendable {
    /// The messages to generate a chat completion for.
    ///
    /// Messages form the conversation context that guides the model's response. The array must contain
    /// at least one message and represents the full conversation history.
    ///
    /// ## Message Roles
    ///
    /// - **System**: Instructions that define the assistant's behavior
    /// - **User**: Input from the human user
    /// - **Assistant**: Previous responses from the model
    /// - **Tool**: Results from function/tool calls
    ///
    /// ## Best Practices
    ///
    /// - Start with a system message to set behavior
    /// - Maintain conversation history for context
    /// - Trim old messages to stay within token limits
    /// - Include relevant tool responses in sequence
    ///
    /// ## Examples
    ///
    /// ```swift
    /// // Basic conversation
    /// let messages = [
    ///     ChatMessage(role: .system, content: "You are a helpful assistant."),
    ///     ChatMessage(role: .user, content: "Hello!")
    /// ]
    ///
    /// // Multi-turn conversation
    /// let messages = [
    ///     ChatMessage(role: .system, content: "You are a coding expert."),
    ///     ChatMessage(role: .user, content: "How do I sort an array?"),
    ///     ChatMessage(role: .assistant, content: "In Swift, use the sorted() method..."),
    ///     ChatMessage(role: .user, content: "What about descending order?")
    /// ]
    ///
    /// // With tool calls
    /// let messages = [
    ///     ChatMessage(role: .user, content: "What's the weather in Tokyo?"),
    ///     ChatMessage(role: .assistant, content: nil, toolCalls: [weatherToolCall]),
    ///     ChatMessage(role: .tool, content: "72°F and sunny", toolCallId: "call_123")
    /// ]
    /// ```
    public let messages: [ChatMessage]
    
    /// The ID of the model to use.
    ///
    /// Choose models based on your needs for capability, speed, and cost.
    ///
    /// ## Available Models
    ///
    /// **GPT-4 Family**
    /// - `gpt-4o` - Most capable, multimodal (128K context)
    /// - `gpt-4o-mini` - Affordable, fast, great for most tasks
    /// - `gpt-4-turbo` - High performance, vision capable
    /// - `gpt-4` - Original GPT-4 (8K context)
    ///
    /// **GPT-3.5 Family**
    /// - `gpt-3.5-turbo` - Fast, affordable, good for simple tasks
    /// - `gpt-3.5-turbo-16k` - Extended context window
    ///
    /// ## Model Selection
    ///
    /// ```swift
    /// // For complex reasoning, coding, or analysis
    /// model: Models.Chat.gpt4o
    ///
    /// // For most applications with good cost/performance
    /// model: Models.Chat.gpt4oMini
    ///
    /// // For simple, high-volume tasks
    /// model: Models.Chat.gpt35Turbo
    /// ```
    ///
    /// - Note: Model availability may vary based on your API access
    public let model: String
    
    /// Audio input or output configuration.
    ///
    /// Enables the model to process audio inputs or generate audio outputs.
    public let audio: ChatAudio?
    
    /// Penalty for token frequency to reduce repetition.
    ///
    /// Range: -2.0 to 2.0
    ///
    /// Positive values penalize tokens based on how often they've appeared, discouraging repetition.
    /// Negative values encourage repetition.
    ///
    /// ## Examples
    ///
    /// - `0.0`: No penalty (default)
    /// - `0.5`: Moderate reduction of repetition
    /// - `1.0`: Strong reduction of repetition
    /// - `2.0`: Maximum penalty, very diverse output
    ///
    /// ```swift
    /// // For creative writing (reduce repetition)
    /// frequencyPenalty: 0.8
    ///
    /// // For technical documentation (allow repetition)
    /// frequencyPenalty: 0.0
    /// ```
    public let frequencyPenalty: Double?
    
    /// Deprecated. Use ``tools`` or ``toolChoice`` instead.
    ///
    /// Controls which (if any) function is called by the model.
    public let functionCall: FunctionCall?
    
    /// Deprecated. Use ``tools`` instead.
    ///
    /// A list of functions the model may generate JSON inputs for.
    public let functions: [Function]?
    
    /// Modify the likelihood of specified tokens appearing in the completion.
    ///
    /// Maps token IDs (as strings) to bias values from -100 to 100.
    /// Mathematically, the bias is added to the logits generated by the model prior to sampling.
    public let logitBias: [String: Int]?
    
    /// Whether to return log probabilities of the output tokens.
    ///
    /// When enabled, provides confidence scores for each generated token, useful for:
    /// - Analyzing model uncertainty
    /// - Building custom scoring systems
    /// - Debugging token generation
    /// - Implementing alternative sampling strategies
    ///
    /// ## Example
    ///
    /// ```swift
    /// let request = ChatCompletionRequest(
    ///     messages: messages,
    ///     model: model,
    ///     logprobs: true,
    ///     topLogprobs: 5  // Get top 5 alternatives for each token
    /// )
    /// ```
    ///
    /// - Note: Increases response size and processing time
    public let logprobs: Bool?
    
    /// The maximum number of completion tokens.
    ///
    /// This is a hard limit on the total number of tokens that can be generated.
    /// Prefer this over ``maxTokens`` for newer models.
    public let maxCompletionTokens: Int?
    
    /// The maximum number of tokens to generate in the completion.
    ///
    /// Limits the length of the generated response. The total tokens (prompt + completion)
    /// cannot exceed the model's context window.
    ///
    /// ## Token Estimates
    ///
    /// - 1 token ≈ 4 characters in English
    /// - 1 token ≈ ¾ words
    /// - 100 tokens ≈ 75 words
    /// - 1,000 tokens ≈ 750 words
    /// - 2,048 tokens ≈ 1,500 words
    ///
    /// ## Model Limits
    ///
    /// - GPT-4o: 128,000 token context
    /// - GPT-4: 8,192 token context
    /// - GPT-3.5: 4,096 token context
    ///
    /// ```swift
    /// // Short response
    /// maxTokens: 100
    ///
    /// // Paragraph
    /// maxTokens: 500
    ///
    /// // Full article
    /// maxTokens: 2000
    /// ```
    ///
    /// - Important: Prefer ``maxCompletionTokens`` for newer models
    /// - Note: You're charged for all tokens generated, even if hitting the limit
    public let maxTokens: Int?
    
    /// Developer-defined tags and values for filtering completions.
    ///
    /// Useful for tracking and organizing API usage in production applications.
    public let metadata: [String: String]?
    
    /// The modalities to use for the completion.
    ///
    /// Controls what types of content the model can generate (e.g., "text", "audio").
    public let modalities: [String]?
    
    /// How many chat completion choices to generate for each input message.
    ///
    /// Note that you will be charged based on the number of generated tokens across all choices.
    /// Keep `n` as 1 to minimize costs.
    public let n: Int?
    
    /// Whether to enable parallel function calling during tool use.
    ///
    /// When enabled, the model may call multiple tools in a single response.
    public let parallelToolCalls: Bool?
    
    /// Configuration for predicted outputs to improve latency.
    ///
    /// Allows the model to skip processing of predicted content for faster responses.
    public let prediction: Prediction?
    
    /// Penalty for token presence to encourage topic diversity.
    ///
    /// Range: -2.0 to 2.0
    ///
    /// Positive values penalize tokens that have appeared at all, encouraging new topics.
    /// Negative values encourage sticking to mentioned topics.
    ///
    /// ## Use Cases
    ///
    /// - `0.0`: No penalty (default)
    /// - `0.6`: Encourage exploring new topics
    /// - `1.2`: Strong push for topic variety
    /// - `-0.5`: Stay focused on current topics
    ///
    /// ```swift
    /// // For brainstorming (explore new ideas)
    /// presencePenalty: 0.8
    ///
    /// // For focused analysis (stay on topic)
    /// presencePenalty: -0.3
    /// ```
    ///
    /// - Tip: Use with ``frequencyPenalty`` for fine control
    public let presencePenalty: Double?
    
    /// The reasoning effort for the model.
    ///
    /// Controls how much computational effort the model should use for reasoning tasks.
    public let reasoningEffort: String?
    
    /// The format that the model must output.
    ///
    /// Controls the structure of the model's response, ensuring consistent output format.
    ///
    /// ## Modes
    ///
    /// - **Text** (default): Free-form text response
    /// - **JSON Object**: Guaranteed valid JSON output
    /// - **JSON Schema**: Structured JSON matching your schema
    ///
    /// ## JSON Mode Example
    ///
    /// ```swift
    /// let request = ChatCompletionRequest(
    ///     messages: [
    ///         ChatMessage(
    ///             role: .system,
    ///             content: "You are a helpful assistant. Always respond with valid JSON."
    ///         ),
    ///         ChatMessage(
    ///             role: .user,
    ///             content: "List 3 programming languages with their year of creation"
    ///         )
    ///     ],
    ///     model: model,
    ///     responseFormat: ResponseFormat(type: .jsonObject)
    /// )
    ///
    /// // Response will be valid JSON like:
    /// // {
    /// //   "languages": [
    /// //     {"name": "Python", "year": 1991},
    /// //     {"name": "Swift", "year": 2014},
    /// //     {"name": "Rust", "year": 2010}
    /// //   ]
    /// // }
    /// ```
    ///
    /// - Important: Must instruct the model to output JSON in the messages
    /// - Warning: JSON mode may use more tokens
    public let responseFormat: ResponseFormat?
    
    /// Random seed for deterministic output.
    ///
    /// If specified, the system will make a best effort to sample deterministically,
    /// such that repeated requests with the same seed and parameters should return the same result.
    public let seed: Int?
    
    /// The latency tier to use for processing the request.
    ///
    /// Currently supports "auto" (default) and "default".
    public let serviceTier: String?
    
    /// Up to 4 sequences where the API will stop generating further tokens.
    ///
    /// The returned text will not contain the stop sequence.
    public let stop: StopSequence?
    
    /// Whether to store the completion for model improvement.
    ///
    /// If false, the completion will not be stored or used for model training.
    public let store: Bool?
    
    /// Whether to stream the response.
    ///
    /// If true, partial message deltas will be sent as server-sent events as they become available.
    /// Use ``ChatStreamChunk`` to handle streamed responses.
    public let stream: Bool?
    
    /// Options for streaming responses.
    ///
    /// Only applies when ``stream`` is true.
    public let streamOptions: StreamOptions?
    
    /// The sampling temperature between 0 and 2.
    ///
    /// Controls randomness in the model's output. This is one of the most important parameters
    /// for controlling response quality and creativity.
    ///
    /// ## Temperature Scale
    ///
    /// - `0.0`: Deterministic, always picks most likely token
    /// - `0.2`: Very focused, minimal variation
    /// - `0.7`: Balanced creativity and coherence (default)
    /// - `1.0`: Creative, more variation
    /// - `1.5`: Very creative, occasional surprises
    /// - `2.0`: Maximum randomness, may be incoherent
    ///
    /// ## Use Cases
    ///
    /// ```swift
    /// // Code generation (precise)
    /// temperature: 0.2
    ///
    /// // General assistance (balanced)
    /// temperature: 0.7
    ///
    /// // Creative writing (imaginative)
    /// temperature: 0.9
    ///
    /// // Brainstorming (exploratory)
    /// temperature: 1.2
    /// ```
    ///
    /// ## Best Practices
    ///
    /// - Lower for: Facts, code, analysis, instructions
    /// - Higher for: Stories, ideas, jokes, creativity
    /// - Test different values for your use case
    /// - Use either temperature OR ``topP``, not both
    public let temperature: Double?
    
    /// Controls which (if any) tool is called by the model.
    ///
    /// Fine-tune how the model interacts with available tools/functions.
    ///
    /// ## Options
    ///
    /// - **none**: Disable all tool calls, text response only
    /// - **auto**: Model decides whether to call tools (default)
    /// - **required**: Force at least one tool call
    /// - **function**: Call a specific function by name
    ///
    /// ## Examples
    ///
    /// ```swift
    /// // Let model decide (default)
    /// toolChoice: .auto
    ///
    /// // Force text response only
    /// toolChoice: .none
    ///
    /// // Must use a tool
    /// toolChoice: .required
    ///
    /// // Call specific function
    /// toolChoice: .function(name: "get_weather")
    /// ```
    ///
    /// ## Use Cases
    ///
    /// - **auto**: General assistants that may or may not need tools
    /// - **required**: When you need structured data extraction
    /// - **none**: When you want analysis without tool execution
    /// - **function**: When you know exactly which tool to use
    public let toolChoice: ToolChoice?
    
    /// A list of tools the model may call.
    ///
    /// Tools extend the model's capabilities by allowing it to call functions you define.
    /// Currently supports function tools, with a maximum of 128 functions per request.
    ///
    /// ## Tool Definition
    ///
    /// ```swift
    /// let weatherTool = Tool(
    ///     type: .function,
    ///     function: Function(
    ///         name: "get_weather",
    ///         description: "Get current weather for a location",
    ///         parameters: [
    ///             "type": "object",
    ///             "properties": [
    ///                 "location": [
    ///                     "type": "string",
    ///                     "description": "City and state, e.g. San Francisco, CA"
    ///                 ],
    ///                 "unit": [
    ///                     "type": "string",
    ///                     "enum": ["celsius", "fahrenheit"]
    ///                 ]
    ///             ],
    ///             "required": ["location"]
    ///         ]
    ///     )
    /// )
    ///
    /// tools: [weatherTool]
    /// ```
    ///
    /// ## Common Use Cases
    ///
    /// - **Data Retrieval**: Database queries, API calls
    /// - **Calculations**: Math, date/time, conversions
    /// - **External Actions**: Send emails, create tasks
    /// - **Structured Output**: Extract data in specific format
    ///
    /// - SeeAlso: ``Tool``, ``Function``, ``toolChoice``
    public let tools: [Tool]?
    
    /// The number of most likely tokens to return at each token position.
    ///
    /// Each token includes a log probability. Must be between 0 and 20.
    public let topLogprobs: Int?
    
    /// Nucleus sampling parameter between 0 and 1.
    ///
    /// An alternative to temperature for controlling randomness. The model considers only
    /// tokens that comprise the top P probability mass.
    ///
    /// ## How it Works
    ///
    /// - `1.0`: Consider all tokens (default)
    /// - `0.9`: Consider tokens making up top 90% probability
    /// - `0.5`: Consider tokens making up top 50% probability
    /// - `0.1`: Only most likely tokens (top 10%)
    ///
    /// ## Comparison with Temperature
    ///
    /// ```swift
    /// // Temperature approach (scales all probabilities)
    /// temperature: 0.8
    ///
    /// // Top-p approach (cuts off unlikely tokens)
    /// topP: 0.9
    /// ```
    ///
    /// ## When to Use
    ///
    /// - **Top-p**: Better for maintaining quality while allowing creativity
    /// - **Temperature**: More predictable control over randomness
    ///
    /// - Important: Use either temperature OR topP, not both
    /// - Tip: topP often produces more coherent creative text
    public let topP: Double?
    
    /// A unique identifier representing your end-user.
    ///
    /// Can help OpenAI monitor and detect abuse.
    public let user: String?
    
    /// Configuration for web search integration.
    ///
    /// Allows the model to search the web for up-to-date information.
    public let webSearchOptions: WebSearchOptions?
    
    /// Creates a new chat completion request.
    ///
    /// Most parameters are optional with sensible defaults, allowing you to start simple
    /// and add complexity as needed.
    ///
    /// ## Common Patterns
    ///
    /// ```swift
    /// // Simple request
    /// ChatCompletionRequest(
    ///     messages: [ChatMessage(role: .user, content: "Hello")],
    ///     model: Models.Chat.gpt4o
    /// )
    ///
    /// // Conversational with control
    /// ChatCompletionRequest(
    ///     messages: messages,
    ///     model: Models.Chat.gpt4o,
    ///     temperature: 0.7,
    ///     maxTokens: 1000,
    ///     user: "user123"
    /// )
    ///
    /// // With tools
    /// ChatCompletionRequest(
    ///     messages: messages,
    ///     model: Models.Chat.gpt4o,
    ///     tools: [weatherTool, calculatorTool],
    ///     toolChoice: .auto
    /// )
    ///
    /// // JSON mode
    /// ChatCompletionRequest(
    ///     messages: messages,
    ///     model: Models.Chat.gpt4o,
    ///     responseFormat: ResponseFormat(type: .jsonObject)
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - messages: The conversation history
    ///   - model: The model to use (e.g., "gpt-4o", "gpt-3.5-turbo")
    ///   - audio: Audio configuration for input/output
    ///   - frequencyPenalty: Penalty for token frequency (-2.0 to 2.0)
    ///   - functionCall: Deprecated. Use `tools` instead
    ///   - functions: Deprecated. Use `tools` instead
    ///   - logitBias: Token bias adjustments
    ///   - logprobs: Whether to include log probabilities
    ///   - maxCompletionTokens: Maximum completion tokens (preferred over maxTokens)
    ///   - maxTokens: Maximum tokens to generate
    ///   - metadata: Custom metadata for tracking
    ///   - modalities: Content types the model can generate
    ///   - n: Number of completions to generate
    ///   - parallelToolCalls: Enable parallel tool calling
    ///   - prediction: Predicted output configuration
    ///   - presencePenalty: Penalty for token presence (-2.0 to 2.0)
    ///   - reasoningEffort: Computational effort for reasoning
    ///   - responseFormat: Output format constraints
    ///   - seed: Random seed for deterministic output
    ///   - serviceTier: Processing tier selection
    ///   - stop: Stop sequences for generation
    ///   - store: Whether to store for model improvement
    ///   - stream: Enable streaming responses
    ///   - streamOptions: Configuration for streaming
    ///   - temperature: Sampling temperature (0 to 2)
    ///   - toolChoice: Tool selection strategy
    ///   - tools: Available tools for the model
    ///   - topLogprobs: Number of top log probabilities
    ///   - topP: Nucleus sampling parameter (0 to 1)
    ///   - user: End-user identifier
    ///   - webSearchOptions: Web search configuration
    public init(
        messages: [ChatMessage],
        model: String,
        audio: ChatAudio? = nil,
        frequencyPenalty: Double? = nil,
        functionCall: FunctionCall? = nil,
        functions: [Function]? = nil,
        logitBias: [String: Int]? = nil,
        logprobs: Bool? = nil,
        maxCompletionTokens: Int? = nil,
        maxTokens: Int? = nil,
        metadata: [String: String]? = nil,
        modalities: [String]? = nil,
        n: Int? = nil,
        parallelToolCalls: Bool? = nil,
        prediction: Prediction? = nil,
        presencePenalty: Double? = nil,
        reasoningEffort: String? = nil,
        responseFormat: ResponseFormat? = nil,
        seed: Int? = nil,
        serviceTier: String? = nil,
        stop: StopSequence? = nil,
        store: Bool? = nil,
        stream: Bool? = nil,
        streamOptions: StreamOptions? = nil,
        temperature: Double? = nil,
        toolChoice: ToolChoice? = nil,
        tools: [Tool]? = nil,
        topLogprobs: Int? = nil,
        topP: Double? = nil,
        user: String? = nil,
        webSearchOptions: WebSearchOptions? = nil
    ) {
        self.messages = messages
        self.model = model
        self.audio = audio
        self.frequencyPenalty = frequencyPenalty
        self.functionCall = functionCall
        self.functions = functions
        self.logitBias = logitBias
        self.logprobs = logprobs
        self.maxCompletionTokens = maxCompletionTokens
        self.maxTokens = maxTokens
        self.metadata = metadata
        self.modalities = modalities
        self.n = n
        self.parallelToolCalls = parallelToolCalls
        self.prediction = prediction
        self.presencePenalty = presencePenalty
        self.reasoningEffort = reasoningEffort
        self.responseFormat = responseFormat
        self.seed = seed
        self.serviceTier = serviceTier
        self.stop = stop
        self.store = store
        self.stream = stream
        self.streamOptions = streamOptions
        self.temperature = temperature
        self.toolChoice = toolChoice
        self.tools = tools
        self.topLogprobs = topLogprobs
        self.topP = topP
        self.user = user
        self.webSearchOptions = webSearchOptions
    }
}

/// A message in a chat conversation.
///
/// `ChatMessage` represents a single turn in a conversation. Messages form the context that
/// guides the model's behavior and responses. Each message has a role identifying the speaker
/// and content containing what was communicated.
///
/// ## Message Types
///
/// ### System Messages
/// Set the assistant's behavior and personality:
/// ```swift
/// ChatMessage(
///     role: .system,
///     content: "You are a helpful coding assistant who writes clear, efficient Swift code."
/// )
/// ```
///
/// ### User Messages
/// Input from the human user:
/// ```swift
/// ChatMessage(role: .user, content: "How do I sort an array in Swift?")
/// ```
///
/// ### Assistant Messages
/// The model's responses:
/// ```swift
/// ChatMessage(
///     role: .assistant,
///     content: "You can sort an array using the `sorted()` method..."
/// )
/// ```
///
/// ### Tool Messages
/// Results from function calls:
/// ```swift
/// ChatMessage(
///     role: .tool,
///     content: "Temperature: 72°F, Conditions: Sunny",
///     toolCallId: "call_abc123"
/// )
/// ```
///
/// ## Multimodal Messages
///
/// Messages can include images for vision-capable models:
/// ```swift
/// ChatMessage(
///     role: .user,
///     content: [
///         .text("What's in this image?"),
///         .imageURL(ChatImageURL(
///             url: "https://example.com/photo.jpg",
///             detail: .high
///         ))
///     ]
/// )
/// ```
///
/// ## Topics
///
/// ### Core Properties
/// - ``role``
/// - ``content``
/// - ``name``
///
/// ### Tool Integration  
/// - ``toolCalls``
/// - ``toolCallId``
///
/// ### Message Types
/// - ``ChatRole``
/// - ``MessageContent``
public struct ChatMessage: Codable, Sendable {
    /// The role of the message author.
    ///
    /// Determines who is speaking in the conversation. Each role has specific behaviors:
    /// - `.system`: Sets the assistant's behavior
    /// - `.user`: Represents the human user
    /// - `.assistant`: The AI model's responses
    /// - `.tool`: Results from tool/function calls
    public let role: ChatRole
    
    /// The content of the message.
    ///
    /// Can be either a simple string or an array of content parts for multimodal messages.
    /// Note: When the assistant makes function/tool calls, this may be nil.
    public let content: MessageContent?
    
    /// An optional name for the message author.
    ///
    /// Useful for distinguishing between multiple users or assistants in a conversation.
    public let name: String?
    
    /// Tool calls made by the assistant.
    ///
    /// When the model decides to use available tools, this array contains the specific
    /// function calls to make. Each tool call includes:
    /// - Unique ID for tracking the call
    /// - Function name to invoke
    /// - Arguments as a JSON string
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Assistant message with tool calls
    /// ChatMessage(
    ///     role: .assistant,
    ///     content: nil,  // Often nil when calling tools
    ///     toolCalls: [
    ///         ToolCall(
    ///             id: "call_abc123",
    ///             type: .function,
    ///             function: FunctionCall(
    ///                 name: "get_weather",
    ///                 arguments: "{\"location\": \"Tokyo\", \"unit\": \"celsius\"}"
    ///             )
    ///         )
    ///     ]
    /// )
    /// ```
    ///
    /// - Note: After receiving tool calls, you must execute them and send results back
    public let toolCalls: [ToolCall]?
    
    /// The ID of the tool call this message is responding to.
    ///
    /// Required when role is `.tool`. This ID must match the ID from the assistant's
    /// original tool call, maintaining the conversation flow.
    ///
    /// ## Example Flow
    ///
    /// ```swift
    /// // 1. User asks a question
    /// ChatMessage(role: .user, content: "What's the weather in Tokyo?")
    ///
    /// // 2. Assistant calls a tool
    /// ChatMessage(
    ///     role: .assistant,
    ///     toolCalls: [ToolCall(id: "call_123", ...)]
    /// )
    ///
    /// // 3. Tool response (this property)
    /// ChatMessage(
    ///     role: .tool,
    ///     content: "72°F and sunny",
    ///     toolCallId: "call_123"  // Must match the ID above
    /// )
    /// ```
    public let toolCallId: String?
    
    /// Creates a new chat message with full configuration options.
    ///
    /// - Parameters:
    ///   - role: The role of the message author
    ///   - content: The message content (text or multimodal)
    ///   - name: Optional name for the author
    ///   - toolCalls: Tool calls made by the assistant
    ///   - toolCallId: ID when responding to a tool call
    public init(
        role: ChatRole,
        content: MessageContent?,
        name: String? = nil,
        toolCalls: [ToolCall]? = nil,
        toolCallId: String? = nil
    ) {
        self.role = role
        self.content = content
        self.name = name
        self.toolCalls = toolCalls
        self.toolCallId = toolCallId
    }
    
    /// Creates a new chat message with simple text content.
    ///
    /// This convenience initializer is perfect for basic text-only messages.
    ///
    /// - Parameters:
    ///   - role: The role of the message author
    ///   - content: The text content of the message
    ///
    /// ## Example
    /// ```swift
    /// let message = ChatMessage(role: .user, content: "What is the capital of France?")
    /// ```
    public init(role: ChatRole, content: String) {
        self.init(role: role, content: .string(content))
    }
    
    /// Creates a new chat message without content.
    ///
    /// This is useful for function/tool call responses where content may be nil.
    ///
    /// - Parameters:
    ///   - role: The role of the message author
    ///   - name: Optional name for the author
    ///   - toolCalls: Tool calls made by the assistant
    ///   - toolCallId: ID when responding to a tool call
    public init(
        role: ChatRole,
        name: String? = nil,
        toolCalls: [ToolCall]? = nil,
        toolCallId: String? = nil
    ) {
        self.init(role: role, content: nil, name: name, toolCalls: toolCalls, toolCallId: toolCallId)
    }
}

/// The role of a message author in a chat conversation.
///
/// Roles define who is speaking in the conversation and how the model should interpret
/// each message. The role system enables structured conversations with clear context.
///
/// ## Role Behaviors
///
/// Each role serves a specific purpose:
/// - **System**: Persistent instructions (usually first message)
/// - **User**: Human input driving the conversation
/// - **Assistant**: Model's responses and reasoning
/// - **Tool**: External data and function results
///
/// ## Conversation Flow
///
/// ```swift
/// let conversation = [
///     // 1. Set behavior
///     ChatMessage(role: .system, content: "You are a Swift expert."),
///     
///     // 2. User question
///     ChatMessage(role: .user, content: "How do I handle errors?"),
///     
///     // 3. Assistant response
///     ChatMessage(role: .assistant, content: "Use do-catch blocks..."),
///     
///     // 4. Follow-up
///     ChatMessage(role: .user, content: "Show me an example"),
///     
///     // 5. Assistant with code
///     ChatMessage(role: .assistant, content: "```swift\ndo {\n...") 
/// ]
/// ```
public enum ChatRole: String, Codable, Sendable {
    /// System message that sets the assistant's behavior.
    ///
    /// System messages provide persistent instructions that guide the assistant throughout
    /// the conversation. They're typically the first message but can appear anywhere.
    ///
    /// ## Best Practices
    ///
    /// - Be specific and clear about desired behavior
    /// - Include any constraints or guidelines
    /// - Define the assistant's expertise or persona
    /// - Specify output format preferences
    ///
    /// ## Examples
    ///
    /// ```swift
    /// // General assistant
    /// "You are a helpful, harmless, and honest assistant."
    ///
    /// // Expert system
    /// "You are a senior iOS developer with 10 years of Swift experience.
    ///  Provide code examples using the latest Swift features and best practices."
    ///
    /// // Specific format
    /// "You are a technical writer. Always structure responses with:
    ///  1. Brief summary
    ///  2. Detailed explanation
    ///  3. Code example if applicable"
    /// ```
    case system
    
    /// Message from the human user.
    ///
    /// User messages contain questions, requests, or responses from the person interacting
    /// with the assistant.
    case user
    
    /// Message from the AI assistant.
    ///
    /// Assistant messages contain the model's responses. They can include:
    /// - Text responses to user queries
    /// - Tool/function calls for extended capabilities
    /// - Multimodal content in supported models
    ///
    /// ## Message Patterns
    ///
    /// ```swift
    /// // Text response
    /// ChatMessage(
    ///     role: .assistant,
    ///     content: "Here's how to solve that problem..."
    /// )
    ///
    /// // Tool call (content often nil)
    /// ChatMessage(
    ///     role: .assistant,
    ///     content: nil,
    ///     toolCalls: [weatherToolCall]
    /// )
    ///
    /// // Combined response
    /// ChatMessage(
    ///     role: .assistant,
    ///     content: "I'll check the weather for you.",
    ///     toolCalls: [weatherToolCall]
    /// )
    /// ```
    case assistant
    
    /// Message containing results from a tool or function call.
    ///
    /// Tool messages provide results from external functions, enabling the assistant to:
    /// - Access real-time data (weather, news, prices)
    /// - Perform calculations or data processing
    /// - Interact with external systems
    /// - Retrieve specific information
    ///
    /// ## Requirements
    ///
    /// - Must include `toolCallId` matching the assistant's call
    /// - Should contain the result in the `content` field
    /// - Appears after the assistant's tool call message
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Complete tool interaction flow
    /// let messages = [
    ///     // User asks
    ///     ChatMessage(role: .user, content: "Calculate 15% tip on $84"),
    ///     
    ///     // Assistant calls tool
    ///     ChatMessage(
    ///         role: .assistant,
    ///         toolCalls: [calculatorCall]
    ///     ),
    ///     
    ///     // Tool responds
    ///     ChatMessage(
    ///         role: .tool,
    ///         content: "$12.60",
    ///         toolCallId: "call_calc_123"
    ///     ),
    ///     
    ///     // Assistant uses result
    ///     ChatMessage(
    ///         role: .assistant,
    ///         content: "The 15% tip on $84 is $12.60, making your total $96.60."
    ///     )
    /// ]
    /// ```
    case tool
}

/// The content of a chat message.
///
/// `MessageContent` provides flexibility in message formatting, supporting both simple text
/// and complex multimodal content. This enables rich interactions including vision capabilities,
/// structured data, and mixed media.
///
/// ## Content Types
///
/// ### Text Content
/// Simple string for text-only messages:
/// ```swift
/// let content: MessageContent = .string("Hello, how can I help you today?")
/// ```
///
/// ### Multimodal Content
/// Array of parts for complex messages:
/// ```swift
/// let content: MessageContent = .array([
///     .text("Analyze this chart:"),
///     .imageURL(ChatImageURL(
///         url: "https://example.com/chart.png",
///         detail: .high
///     )),
///     .text("What trends do you see?")
/// ])
/// ```
///
/// ## Usage Examples
///
/// ```swift
/// // Simple text message
/// ChatMessage(role: .user, content: "What is Swift?")
///
/// // Image analysis
/// ChatMessage(
///     role: .user,
///     content: [
///         .text("What's in this image?"),
///         .imageURL(ChatImageURL(url: imageURL))
///     ]
/// )
///
/// // Multiple images
/// ChatMessage(
///     role: .user,  
///     content: [
///         .text("Compare these designs:"),
///         .imageURL(ChatImageURL(url: design1URL)),
///         .imageURL(ChatImageURL(url: design2URL)),
///         .text("Which is more user-friendly?")
///     ]
/// )
/// ```
///     MessagePart(type: .imageUrl, imageUrl: ImageURL(url: "https://example.com/photo.jpg"))
/// ])
/// ```
public enum MessageContent: Codable, Sendable {
    /// Simple text content.
    ///
    /// Use this for standard text-only messages.
    case string(String)
    
    /// Multimodal content with multiple parts.
    ///
    /// Use this for messages that combine text with images or other content types.
    /// Each part is a ``MessagePart`` that specifies its type and content.
    case parts([MessagePart])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // First check if the value is null
        if container.decodeNil() {
            // If we have a null, we need to throw since MessageContent itself can't represent null
            // The parent ChatMessage should handle this as an optional
            throw DecodingError.typeMismatch(
                MessageContent.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "MessageContent cannot be null")
            )
        }
        
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let parts = try? container.decode([MessagePart].self) {
            self = .parts(parts)
        } else {
            throw DecodingError.typeMismatch(
                MessageContent.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or [MessagePart]")
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let string):
            try container.encode(string)
        case .parts(let parts):
            try container.encode(parts)
        }
    }
}

/// A single part of a multimodal message.
///
/// Message parts allow you to combine different types of content (text, images, etc.) within
/// a single message. This is particularly useful for vision-capable models.
///
/// ## Example
/// ```swift
/// let textPart = MessagePart(type: .text, text: "Describe this image:")
/// let imagePart = MessagePart(
///     type: .imageUrl,
///     imageUrl: ImageURL(url: "data:image/jpeg;base64,...")
/// )
/// ```
public struct MessagePart: Codable, Sendable {
    /// The type of content in this part.
    public let type: MessagePartType
    
    /// Text content when `type` is `.text`.
    public let text: String?
    
    /// Image URL information when `type` is `.imageUrl`.
    public let imageUrl: ImageURL?
    
    /// Creates a new message part.
    ///
    /// - Parameters:
    ///   - type: The type of content
    ///   - text: Text content (required when type is `.text`)
    ///   - imageUrl: Image URL information (required when type is `.imageUrl`)
    public init(type: MessagePartType, text: String? = nil, imageUrl: ImageURL? = nil) {
        self.type = type
        self.text = text
        self.imageUrl = imageUrl
    }
}

/// The type of content in a message part.
public enum MessagePartType: String, Codable, Sendable {
    /// Text content.
    case text
    
    /// Image content provided via URL.
    ///
    /// The URL can be a web URL or a base64-encoded data URL.
    case imageUrl = "image_url"
}

/// Image information for multimodal messages.
///
/// Supports both web URLs and base64-encoded data URLs. The detail level controls
/// how the model processes the image, affecting both quality and token usage.
///
/// ## Example
/// ```swift
/// // Web URL
/// let webImage = ImageURL(url: "https://example.com/image.jpg", detail: .high)
/// 
/// // Base64 data URL
/// let dataImage = ImageURL(
///     url: "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
///     detail: .low
/// )
/// ```
public struct ImageURL: Codable, Sendable {
    /// The URL of the image.
    ///
    /// Can be either:
    /// - A standard web URL (https://...)
    /// - A base64-encoded data URL (data:image/jpeg;base64,...)
    public let url: String
    
    /// The level of detail for image processing.
    ///
    /// Controls the resolution at which the model processes the image.
    /// Higher detail levels provide better quality but use more tokens.
    public let detail: ImageDetail?
    
    /// Creates a new image URL reference.
    ///
    /// - Parameters:
    ///   - url: The image URL (web or data URL)
    ///   - detail: Processing detail level (defaults to model's choice)
    public init(url: String, detail: ImageDetail? = nil) {
        self.url = url
        self.detail = detail
    }
}

/// The level of detail for image processing.
///
/// Controls how the model processes images, balancing between quality and token usage.
public enum ImageDetail: String, Codable, Sendable {
    /// Let the model choose the appropriate detail level.
    case auto
    
    /// Low detail mode.
    ///
    /// Faster and uses fewer tokens, but may miss fine details in the image.
    case low
    
    /// High detail mode.
    ///
    /// Provides the best quality but uses more tokens and processing time.
    case high
}

/// The response from a chat completion request.
///
/// `ChatCompletionResponse` contains the model's generated response along with comprehensive
/// metadata about the generation process. This includes token usage for cost tracking,
/// finish reasons for understanding completion behavior, and system information for debugging.
///
/// ## Overview
///
/// Every chat completion returns this structured response, whether you're having a simple
/// conversation, calling functions, or generating multiple alternatives.
///
/// ## Basic Usage
///
/// ```swift
/// // Standard response handling
/// let response = try await openAI.chat.completions(request)
/// 
/// // Extract the message
/// if let message = response.choices.first?.message {
///     print("Role: \(message.role)")
///     print("Content: \(message.content ?? "")")
///     
///     // Handle tool calls
///     if let toolCalls = message.toolCalls {
///         for call in toolCalls {
///             print("Calling function: \(call.function.name)")
///         }
///     }
/// }
///
/// // Check completion status
/// if let finishReason = response.choices.first?.finishReason {
///     switch finishReason {
///     case .stop:
///         print("Completed normally")
///     case .length:
///         print("Hit token limit")
///     case .toolCalls:
///         print("Calling functions")
///     case .contentFilter:
///         print("Content filtered")
///     }
/// }
///
/// // Monitor costs
/// if let usage = response.usage {
///     let cost = calculateCost(usage, model: response.model)
///     print("Request cost: $\(cost)")
/// }
/// ```
///
/// ## Multiple Choices
///
/// When requesting multiple completions with `n > 1`:
///
/// ```swift
/// let request = ChatCompletionRequest(
///     messages: messages,
///     model: model,
///     n: 3  // Generate 3 alternatives
/// )
///
/// let response = try await openAI.chat.completions(request)
///
/// // Process all alternatives
/// for (index, choice) in response.choices.enumerated() {
///     print("Alternative \(index + 1): \(choice.message.content ?? "")")
/// }
/// ```
///
/// ## Topics
///
/// ### Response Content
/// - ``choices``
/// - ``ChatChoice``
/// - ``FinishReason``
///
/// ### Metadata
/// - ``id``
/// - ``model``
/// - ``created``
/// - ``systemFingerprint``
///
/// ### Usage Tracking
/// - ``usage``
/// - ``Usage``
public struct ChatCompletionResponse: Codable, Sendable {
    /// Unique identifier for this completion.
    ///
    /// Format: `chatcmpl-{unique-id}`
    ///
    /// Use this ID to:
    /// - Track specific completions in logs
    /// - Reference completions in support requests
    /// - Implement idempotency checks
    public let id: String
    
    /// Object type, always "chat.completion".
    public let object: String
    
    /// Unix timestamp (in seconds) when the completion was created.
    ///
    /// Convert to Date:
    /// ```swift
    /// let date = Date(timeIntervalSince1970: TimeInterval(response.created))
    /// print("Generated at: \(date)")
    /// ```
    public let created: Int
    
    /// The model used for this completion.
    ///
    /// This may differ from the requested model in cases where:
    /// - A model alias was used (e.g., "gpt-4" -> "gpt-4-0613")
    /// - A fallback occurred due to availability
    /// - The model was updated to a newer version
    ///
    /// Always check this field for accurate billing and capability information.
    public let model: String
    
    /// The list of completion choices.
    ///
    /// Contains one or more responses based on the `n` parameter in the request.
    /// Each choice represents a different completion for the same prompt.
    ///
    /// ## Single Response (Default)
    /// ```swift
    /// let message = response.choices.first?.message
    /// ```
    ///
    /// ## Multiple Alternatives
    /// ```swift
    /// // When n > 1 in request
    /// let bestChoice = response.choices.max { choice1, choice2 in
    ///     scoreResponse(choice1) < scoreResponse(choice2)
    /// }
    /// ```
    ///
    /// - Note: Choices are ordered by index, not quality
    public let choices: [ChatChoice]
    
    /// Token usage statistics for this completion.
    ///
    /// Essential for cost tracking and optimization. Includes:
    /// - Prompt tokens (input)
    /// - Completion tokens (output)
    /// - Total tokens (sum)
    /// - Detailed breakdowns for special features
    ///
    /// ## Cost Calculation Example
    /// ```swift
    /// func calculateCost(_ usage: Usage, model: String) -> Double {
    ///     let rates = [
    ///         "gpt-4o": (input: 0.005, output: 0.015),
    ///         "gpt-4o-mini": (input: 0.00015, output: 0.0006)
    ///     ]
    ///     
    ///     guard let rate = rates[model] else { return 0 }
    ///     
    ///     let inputCost = Double(usage.promptTokens) / 1_000_000 * rate.input
    ///     let outputCost = Double(usage.completionTokens) / 1_000_000 * rate.output
    ///     
    ///     return inputCost + outputCost
    /// }
    /// ```
    public let usage: Usage?
    
    /// System fingerprint for this completion.
    ///
    /// Represents the exact backend configuration used. This includes:
    /// - Model version
    /// - System prompts
    /// - Feature flags
    ///
    /// Use for:
    /// - Debugging inconsistent responses
    /// - Ensuring reproducibility
    /// - Tracking system changes
    ///
    /// Format: `fp_{hash}`
    public let systemFingerprint: String?
}

/// A single completion choice from the model.
///
/// Each `ChatChoice` represents one possible response to your prompt. When generating
/// multiple alternatives with `n > 1`, each choice provides a different completion
/// that you can evaluate and select from.
///
/// ## Basic Usage
///
/// ```swift
/// // Single choice (most common)
/// let choice = response.choices.first!
/// let content = choice.message.content ?? ""
/// 
/// // Check why it stopped
/// switch choice.finishReason {
/// case .stop:
///     // Normal completion
/// case .length:
///     // Hit token limit - response may be incomplete
/// case .toolCalls:
///     // Execute the requested functions
/// case .contentFilter:
///     // Content was filtered
/// default:
///     break
/// }
/// ```
///
/// ## Multiple Choices
///
/// ```swift
/// // Evaluate multiple alternatives
/// for choice in response.choices {
///     print("\n--- Alternative \(choice.index + 1) ---")
///     print(choice.message.content ?? "")
///     
///     // Score based on your criteria
///     let score = evaluateResponse(choice.message)
///     print("Quality score: \(score)")
/// }
/// ```
///
/// ## Tool Calls
///
/// ```swift
/// if choice.finishReason == .toolCalls,
///    let toolCalls = choice.message.toolCalls {
///     for call in toolCalls {
///         let result = try await executeFunction(
///             name: call.function.name,
///             arguments: call.function.arguments
///         )
///         // Send result back in conversation
///     }
/// }
/// ```
public struct ChatChoice: Codable, Sendable {
    /// The index of this choice in the list.
    ///
    /// Zero-based index corresponding to the position in the choices array.
    public let index: Int
    
    /// The message generated by the model.
    ///
    /// Contains the assistant's response, including any tool calls if applicable.
    public let message: ChatMessage
    
    /// The reason the model stopped generating.
    ///
    /// Critical for understanding completion behavior:
    /// - `.stop`: Natural ending (complete response)
    /// - `.length`: Token limit reached (may be cut off)
    /// - `.toolCalls`: Model wants to call functions
    /// - `.contentFilter`: Content policy triggered
    ///
    /// ## Handling Different Reasons
    ///
    /// ```swift
    /// switch finishReason {
    /// case .stop:
    ///     // Response is complete
    /// case .length:
    ///     // Consider increasing maxTokens or continuing
    /// case .toolCalls:
    ///     // Process function calls
    /// case .contentFilter:
    ///     // Handle filtered content
    /// case .none:
    ///     // Still generating (streaming)
    /// }
    /// ```
    public let finishReason: FinishReason?
    
    /// Log probability information.
    ///
    /// Only present when `logprobs` is true in the request.
    public let logprobs: Logprobs?
}

/// The reason why the model stopped generating tokens.
///
/// `FinishReason` indicates why the model stopped generating, which is crucial for
/// proper response handling and user experience.
///
/// ## Decision Flow
///
/// ```swift
/// func handleCompletion(_ choice: ChatChoice) {
///     switch choice.finishReason {
///     case .stop:
///         // Normal completion - display to user
///         showResponse(choice.message)
///         
///     case .length:
///         // Incomplete - warn user or continue
///         showResponse(choice.message)
///         showWarning("Response was truncated due to length")
///         
///     case .toolCalls:
///         // Execute functions
///         processFunctionCalls(choice.message.toolCalls)
///         
///     case .contentFilter:
///         // Content filtered
///         showError("Content was filtered for policy compliance")
///         
///     case .none:
///         // Should not happen in non-streaming
///         break
///     }
/// }
/// ```
public enum FinishReason: String, Codable, Sendable {
    /// Natural end of message.
    ///
    /// The model completed its response naturally. This is the ideal
    /// finish reason, indicating a complete, uninterrupted response.
    case stop
    
    /// Maximum token limit reached.
    ///
    /// The response was truncated due to token limits. This can happen when:
    /// - `maxTokens` parameter is too low
    /// - Combined prompt + response exceeds model's context window
    /// - `maxCompletionTokens` limit is reached
    ///
    /// Consider:
    /// - Increasing token limits
    /// - Shortening the prompt
    /// - Using a model with larger context window
    case length
    
    /// Model decided to call tools.
    ///
    /// The model is requesting to use one or more tools/functions.
    /// Check `message.toolCalls` for the specific calls to execute.
    ///
    /// Next steps:
    /// 1. Execute each requested function
    /// 2. Send results back as tool messages
    /// 3. Continue the conversation
    case toolCalls = "tool_calls"
    
    /// Content was filtered.
    ///
    /// The response violated content policy and was blocked. This can occur for:
    /// - Harmful or inappropriate content
    /// - Policy violations
    /// - Safety concerns
    ///
    /// Handle gracefully by:
    /// - Informing the user
    /// - Rephrasing the request
    /// - Adjusting system prompts
    case contentFilter = "content_filter"
}

/// Token usage statistics for a completion.
///
/// `Usage` provides comprehensive token consumption data essential for cost management,
/// optimization, and understanding model behavior. All counts include special tokens
/// (formatting, function calls, etc.).
///
/// ## Token Economics
///
/// ```swift
/// extension Usage {
///     func estimatedCost(for model: String) -> Double {
///         let pricing: [String: (input: Double, output: Double)] = [
///             "gpt-4o": (0.005, 0.015),           // per 1K tokens
///             "gpt-4o-mini": (0.00015, 0.0006),
///             "gpt-3.5-turbo": (0.0005, 0.0015)
///         ]
///         
///         guard let rate = pricing[model] else { return 0 }
///         
///         let inputCost = Double(promptTokens) / 1000 * rate.input
///         let outputCost = Double(completionTokens) / 1000 * rate.output
///         
///         return inputCost + outputCost
///     }
///     
///     var efficiency: Double {
///         // Ratio of output to input tokens
///         return Double(completionTokens) / Double(promptTokens)
///     }
/// }
/// ```
///
/// ## Optimization Strategies
///
/// ```swift
/// // Monitor token usage trends
/// var totalTokensUsed = 0
/// var totalCost = 0.0
///
/// if let usage = response.usage {
///     totalTokensUsed += usage.totalTokens
///     totalCost += usage.estimatedCost(for: response.model)
///     
///     // Alert if exceeding budget
///     if totalCost > dailyBudget {
///         print("Daily budget exceeded!")
///     }
///     
///     // Optimize if inefficient
///     if usage.efficiency < 0.5 {
///         print("Consider shorter prompts")
///     }
/// }
/// ```
public struct Usage: Codable, Sendable {
    /// Number of tokens in the prompt.
    ///
    /// Includes:
    /// - All messages in the conversation
    /// - System prompts
    /// - Function definitions
    /// - Formatting tokens
    /// - Special tokens
    ///
    /// This is what you're charged for input.
    public let promptTokens: Int
    
    /// Number of tokens in the completion.
    ///
    /// The tokens generated by the model, including:
    /// - Response text
    /// - Function call syntax
    /// - Formatting tokens
    /// - Stop sequences
    ///
    /// This is what you're charged for output (typically 2-3x input rate).
    public let completionTokens: Int
    
    /// Total tokens used (prompt + completion).
    ///
    /// The sum of `promptTokens` and `completionTokens`.
    public let totalTokens: Int
    
    /// Detailed breakdown of completion tokens.
    ///
    /// Provides granular information about different types of completion tokens.
    public let completionTokensDetails: CompletionTokensDetails?
    
    /// Detailed breakdown of prompt tokens.
    ///
    /// Provides information about cached tokens and other optimizations.
    public let promptTokensDetails: PromptTokensDetails?
}

/// Detailed breakdown of completion token usage.
///
/// Provides granular information about different types of tokens used in the completion,
/// particularly useful for models with special capabilities like reasoning or audio.
public struct CompletionTokensDetails: Codable, Sendable {
    /// Tokens used for reasoning steps.
    ///
    /// Present in models that show their reasoning process.
    public let reasoningTokens: Int?
    
    /// Tokens used for audio generation.
    ///
    /// Present when generating audio outputs.
    public let audioTokens: Int?
    
    /// Accepted tokens from prediction.
    ///
    /// Tokens that matched the predicted output.
    public let acceptedPredictionTokens: Int?
    
    /// Rejected tokens from prediction.
    ///
    /// Tokens that didn't match the predicted output.
    public let rejectedPredictionTokens: Int?
}

/// Detailed breakdown of prompt token usage.
///
/// Provides information about optimizations applied to the prompt tokens.
public struct PromptTokensDetails: Codable, Sendable {
    /// Tokens used for audio input.
    ///
    /// Present when processing audio inputs.
    public let audioTokens: Int?
    
    /// Tokens retrieved from cache.
    ///
    /// Cached tokens reduce processing time and cost.
    public let cachedTokens: Int?
}

/// A chunk of data from a streaming chat completion.
///
/// `ChatStreamChunk` represents a single piece of a streaming response. When streaming
/// is enabled, responses arrive as a series of Server-Sent Events (SSE), each containing
/// incremental updates that build the complete response.
///
/// ## Stream Processing
///
/// ```swift
/// // Basic streaming
/// var completeResponse = ""
/// 
/// for try await chunk in openAI.chat.completionsStream(request) {
///     // Process text content
///     if let content = chunk.choices.first?.delta.content {
///         completeResponse += content
///         print(content, terminator: "")  // Real-time output
///     }
///     
///     // Check if finished
///     if let finishReason = chunk.choices.first?.finishReason {
///         print("\n\nFinished: \(finishReason)")
///     }
///     
///     // Final chunk includes usage
///     if let usage = chunk.usage {
///         print("Total tokens: \(usage.totalTokens)")
///     }
/// }
/// ```
///
/// ## Advanced Stream Handling
///
/// ```swift
/// class StreamProcessor {
///     var messages: [String] = []
///     var toolCalls: [String: ToolCall] = [:]
///     
///     func process(_ chunk: ChatStreamChunk) {
///         for choice in chunk.choices {
///             // Accumulate content
///             if let content = choice.delta.content {
///                 if messages.count <= choice.index {
///                     messages.append("")
///                 }
///                 messages[choice.index] += content
///             }
///             
///             // Merge tool calls
///             if let calls = choice.delta.toolCalls {
///                 for call in calls {
///                     if var existing = toolCalls[call.id] {
///                         // Merge partial call
///                         existing.function.arguments += call.function.arguments
///                         toolCalls[call.id] = existing
///                     } else {
///                         toolCalls[call.id] = call
///                     }
///                 }
///             }
///         }
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Stream Data
/// - ``choices``
/// - ``ChatStreamChoice``
/// - ``ChatDelta``
///
/// ### Metadata
/// - ``id``
/// - ``model``
/// - ``created``
/// - ``usage``
/// - ``systemFingerprint``
public struct ChatStreamChunk: Codable, Sendable {
    /// Unique identifier for this completion stream.
    public let id: String
    
    /// Object type, always "chat.completion.chunk".
    public let object: String
    
    /// Unix timestamp when the chunk was created.
    public let created: Int
    
    /// The model used for this completion.
    public let model: String
    
    /// Incremental choice updates.
    ///
    /// Each choice contains a delta with partial content updates.
    public let choices: [ChatStreamChoice]
    
    /// Token usage statistics.
    ///
    /// Only included in the final chunk when `streamOptions.includeUsage` is true.
    public let usage: Usage?
    
    /// System fingerprint for this completion.
    public let systemFingerprint: String?
}

/// A streaming choice containing incremental updates.
///
/// Represents partial updates to a completion choice. The delta contains
/// only the new content since the last chunk.
public struct ChatStreamChoice: Codable, Sendable {
    /// The index of this choice.
    public let index: Int
    
    /// Incremental content update.
    ///
    /// Contains only the new content added since the last chunk.
    public let delta: ChatDelta
    
    /// The reason the model stopped generating.
    ///
    /// Only present in the final chunk for this choice.
    public let finishReason: FinishReason?
    
    /// Log probability information for this chunk.
    public let logprobs: Logprobs?
}

/// Incremental updates in a streaming response.
///
/// `ChatDelta` contains partial content that arrives incrementally during streaming.
/// These deltas must be accumulated to reconstruct the complete message.
///
/// ## Delta Types
///
/// ### Text Content
/// Arrives character by character or in small chunks:
/// ```swift
/// // Accumulate text
/// var fullText = ""
/// if let content = delta.content {
///     fullText += content
/// }
/// ```
///
/// ### Tool Calls
/// May arrive across multiple chunks:
/// ```swift
/// // First chunk: function name and start of arguments
/// {
///   "toolCalls": [{
///     "id": "call_abc",
///     "type": "function",
///     "function": {
///       "name": "get_weather",
///       "arguments": "{\"loc"
///     }
///   }]
/// }
///
/// // Second chunk: rest of arguments
/// {
///   "toolCalls": [{
///     "id": "call_abc",
///     "function": {
///       "arguments": "ation\": \"Tokyo\"}"
///     }
///   }]
/// }
/// ```
///
/// ## Complete Example
///
/// ```swift
/// class MessageBuilder {
///     var role: ChatRole?
///     var content = ""
///     var toolCalls: [String: ToolCall] = [:]
///     
///     func addDelta(_ delta: ChatDelta) {
///         // Set role once
///         if let deltaRole = delta.role {
///             role = deltaRole
///         }
///         
///         // Append content
///         if let deltaContent = delta.content {
///             content += deltaContent
///         }
///         
///         // Merge tool calls
///         if let deltaCalls = delta.toolCalls {
///             for call in deltaCalls {
///                 if var existing = toolCalls[call.id] {
///                     // Merge arguments
///                     existing.function.arguments += call.function.arguments
///                     toolCalls[call.id] = existing
///                 } else {
///                     // New tool call
///                     toolCalls[call.id] = call
///                 }
///             }
///         }
///     }
///     
///     func buildMessage() -> ChatMessage {
///         ChatMessage(
///             role: role ?? .assistant,
///             content: content.isEmpty ? nil : content,
///             toolCalls: toolCalls.isEmpty ? nil : Array(toolCalls.values)
///         )
///     }
/// }
/// ```
public struct ChatDelta: Codable, Sendable {
    /// Role of the message author.
    ///
    /// Usually only present in the first chunk.
    public let role: ChatRole?
    
    /// Incremental text content.
    ///
    /// Append this to previously received content.
    public let content: String?
    
    /// Tool calls being constructed.
    ///
    /// May be sent across multiple chunks that need to be merged.
    public let toolCalls: [ToolCall]?
}

/// Stop sequences for controlling generation.
///
/// The model will stop generating further tokens when it encounters any of these sequences.
/// The stop sequence itself is not included in the response.
///
/// ## Example
/// ```swift
/// // Single stop sequence
/// let request1 = ChatCompletionRequest(
///     messages: messages,
///     model: "gpt-4",
///     stop: .string("\n")
/// )
/// 
/// // Multiple stop sequences
/// let request2 = ChatCompletionRequest(
///     messages: messages,
///     model: "gpt-4",
///     stop: .array(["\n", "END", "STOP"])
/// )
/// ```
public enum StopSequence: Codable, Sendable {
    /// A single stop sequence.
    case string(String)
    
    /// Multiple stop sequences (up to 4).
    case array([String])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([String].self) {
            self = .array(array)
        } else {
            throw DecodingError.typeMismatch(
                StopSequence.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or [String]")
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let string):
            try container.encode(string)
        case .array(let array):
            try container.encode(array)
        }
    }
}

/// A tool that the model can use.
///
/// Tools extend the model's capabilities by allowing it to call functions,
/// run code, or search files. Currently, function calling is the most common tool type.
///
/// ## Example
/// ```swift
/// let weatherTool = Tool(
///     type: .function,
///     function: Function(
///         name: "get_weather",
///         description: "Get the current weather in a location",
///         parameters: [
///             "type": "object",
///             "properties": [
///                 "location": ["type": "string", "description": "The city and state"],
///                 "unit": ["type": "string", "enum": ["celsius", "fahrenheit"]]
///             ],
///             "required": ["location"]
///         ]
///     )
/// )
/// ```
///
/// ## Topics
/// ### Tool Configuration
/// - ``type``
/// - ``function``
/// - ``ToolType``
public struct Tool: Codable, Sendable {
    /// The type of tool.
    public let type: ToolType
    
    /// Function definition when `type` is `.function`.
    ///
    /// Contains the function's name, description, and parameter schema.
    public let function: Function?
    
    /// Creates a new tool definition.
    ///
    /// - Parameters:
    ///   - type: The type of tool
    ///   - function: Function definition (required when type is `.function`)
    public init(type: ToolType, function: Function? = nil) {
        self.type = type
        self.function = function
    }
}

/// The type of tool available to the model.
public enum ToolType: String, Codable, Sendable {
    /// Function calling tool.
    ///
    /// Allows the model to call custom functions with structured inputs.
    case function
    
    /// Code interpreter tool.
    ///
    /// Enables the model to write and execute Python code.
    case codeInterpreter = "code_interpreter"
    
    /// File search tool.
    ///
    /// Allows the model to search through uploaded files.
    case fileSearch = "file_search"
    
    /// Web search preview tool.
    ///
    /// Enables the model to search the web for information.
    case webSearchPreview = "web_search_preview"
    
    /// MCP (Model Context Protocol) tool.
    ///
    /// Allows the model to interact with MCP-compliant tools.
    case mcp
}

/// A function that the model can call.
///
/// Functions allow the model to interact with external systems or perform computations
/// beyond its built-in capabilities. The model will generate structured JSON arguments
/// that match the provided parameter schema.
///
/// ## Example
/// ```swift
/// let function = Function(
///     name: "calculate_discount",
///     description: "Calculate the discount price for a product",
///     parameters: [
///         "type": "object",
///         "properties": [
///             "original_price": [
///                 "type": "number",
///                 "description": "The original price of the product"
///             ],
///             "discount_percentage": [
///                 "type": "number",
///                 "description": "The discount percentage (0-100)"
///             ]
///         ],
///         "required": ["original_price", "discount_percentage"]
///     ]
/// )
/// ```
///
/// ## Topics
/// ### Function Definition
/// - ``name``
/// - ``description``
/// - ``parameters``
public struct Function: Codable, Sendable {
    /// The name of the function.
    ///
    /// Must be a valid identifier (letters, numbers, underscores).
    /// This is how the model will reference the function in its calls.
    public let name: String
    
    /// A description of what the function does.
    ///
    /// Used by the model to understand when and how to use this function.
    /// Be clear and specific about the function's purpose and behavior.
    public let description: String?
    
    /// The parameters the function accepts, described as a JSON Schema.
    ///
    /// Defines the structure and types of arguments the model should provide.
    /// Follow JSON Schema specification for parameter definitions.
    public let parameters: JSONValue?
    
    /// Creates a function with pre-encoded JSON Schema parameters.
    ///
    /// - Parameters:
    ///   - name: The function name
    ///   - description: What the function does
    ///   - parameters: JSON Schema as ``JSONValue``
    public init(name: String, description: String? = nil, parameters: JSONValue? = nil) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
    
    /// Creates a function with dictionary-based parameters.
    ///
    /// This convenience initializer automatically converts Swift dictionaries
    /// to the required ``JSONValue`` format.
    ///
    /// - Parameters:
    ///   - name: The function name
    ///   - description: What the function does
    ///   - parameters: JSON Schema as a dictionary
    public init(name: String, description: String? = nil, parameters: [String: Any]? = nil) {
        self.name = name
        self.description = description
        if let params = parameters {
            self.parameters = Self.convertToJSONValue(params)
        } else {
            self.parameters = nil
        }
    }
    
    private static func convertToJSONValue(_ dict: [String: Any]) -> JSONValue {
        var result = [String: JSONValue]()
        for (key, value) in dict {
            if let string = value as? String {
                result[key] = .string(string)
            } else if let int = value as? Int {
                result[key] = .int(int)
            } else if let double = value as? Double {
                result[key] = .double(double)
            } else if let bool = value as? Bool {
                result[key] = .bool(bool)
            } else if let dict = value as? [String: Any] {
                result[key] = convertToJSONValue(dict)
            } else if let array = value as? [Any] {
                result[key] = convertToJSONValue(array)
            }
        }
        return .object(result)
    }
    
    private static func convertToJSONValue(_ array: [Any]) -> JSONValue {
        var result = [JSONValue]()
        for value in array {
            if let string = value as? String {
                result.append(.string(string))
            } else if let int = value as? Int {
                result.append(.int(int))
            } else if let double = value as? Double {
                result.append(.double(double))
            } else if let bool = value as? Bool {
                result.append(.bool(bool))
            } else if let dict = value as? [String: Any] {
                result.append(convertToJSONValue(dict))
            } else if let array = value as? [Any] {
                result.append(convertToJSONValue(array))
            }
        }
        return .array(result)
    }
}

/// A tool call made by the model.
///
/// When the model decides to use a tool, it generates a tool call with a unique ID
/// and the necessary arguments. Your application should execute the tool and return
/// the results using a tool message.
///
/// ## Example
/// ```swift
/// if let toolCalls = message.toolCalls {
///     for toolCall in toolCalls {
///         if toolCall.type == .function,
///            let functionCall = toolCall.function {
///             // Parse arguments and execute function
///             let result = executeFunction(
///                 name: functionCall.name,
///                 arguments: functionCall.arguments
///             )
///             
///             // Return result as tool message
///             let toolMessage = ChatMessage(
///                 role: .tool,
///                 content: result,
///                 toolCallId: toolCall.id
///             )
///         }
///     }
/// }
/// ```
public struct ToolCall: Codable, Sendable {
    /// Unique identifier for this tool call.
    ///
    /// Use this ID when sending the tool's response back to the model.
    public let id: String
    
    /// The type of tool being called.
    public let type: ToolType
    
    /// Function call details when `type` is `.function`.
    public let function: FunctionCall?
    
    /// Creates a new tool call.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the call
    ///   - type: Type of tool being called
    ///   - function: Function details (required when type is `.function`)
    public init(id: String, type: ToolType, function: FunctionCall? = nil) {
        self.id = id
        self.type = type
        self.function = function
    }
}

/// Details of a function call.
///
/// Contains the function name and JSON-encoded arguments that the model
/// has generated based on the function's parameter schema.
///
/// ## Example
/// ```swift
/// // Parse and use function call arguments
/// if let data = functionCall.arguments.data(using: .utf8),
///    let args = try? JSONDecoder().decode(WeatherArgs.self, from: data) {
///     let weather = getWeather(location: args.location, unit: args.unit)
///     // Return weather data as tool response
/// }
/// ```
public struct FunctionCall: Codable, Sendable {
    /// The name of the function to call.
    ///
    /// Matches one of the function names provided in the tools array.
    public let name: String
    
    /// JSON-encoded arguments for the function.
    ///
    /// The arguments match the schema defined in the function's parameters.
    /// Parse this JSON string to extract the actual argument values.
    public let arguments: String
    
    /// Creates a new function call.
    ///
    /// - Parameters:
    ///   - name: The function name
    ///   - arguments: JSON-encoded arguments string
    public init(name: String, arguments: String) {
        self.name = name
        self.arguments = arguments
    }
}

/// Controls which tools the model can use.
///
/// Provides fine-grained control over tool usage, from disabling all tools
/// to requiring specific function calls.
///
/// ## Example
/// ```swift
/// // Let the model decide
/// let request1 = ChatCompletionRequest(
///     messages: messages,
///     model: "gpt-4",
///     tools: tools,
///     toolChoice: .auto
/// )
/// 
/// // Force specific function
/// let request2 = ChatCompletionRequest(
///     messages: messages,
///     model: "gpt-4",
///     tools: tools,
///     toolChoice: .function(name: "get_weather")
/// )
/// ```
public enum ToolChoice: Codable, Sendable {
    /// The model will not call any tools.
    case none
    
    /// The model can choose to call tools or respond with text.
    ///
    /// This is the default behavior when tools are provided.
    case auto
    
    /// The model must call at least one tool.
    ///
    /// Useful when you need the model to use tools rather than just respond.
    case required
    
    /// The model must call the specified function.
    ///
    /// Forces the model to use a specific function by name.
    case function(name: String)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            switch string {
            case "none": self = .none
            case "auto": self = .auto
            case "required": self = .required
            default:
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown tool choice: \(string)")
            }
        } else if let dict = try? container.decode(JSONValue.self),
                  let type = dict.type?.stringValue,
                  type == "function",
                  let name = dict.function?.name?.stringValue {
            self = .function(name: name)
        } else {
            throw DecodingError.typeMismatch(ToolChoice.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or specific object structure"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .none:
            try container.encode("none")
        case .auto:
            try container.encode("auto")
        case .required:
            try container.encode("required")
        case .function(let name):
            let functionDict: JSONValue = [
                "type": "function",
                "function": ["name": .string(name)]
            ]
            try container.encode(functionDict)
        }
    }
}

/// Response format configuration.
///
/// Controls the format of the model's output, ensuring it returns text,
/// JSON objects, or conforms to a specific JSON schema.
///
/// When using `.jsonSchema` type, see ``JSONSchema`` for important schema limits.
///
/// ## Example
/// ```swift
/// // JSON mode
/// let jsonFormat = ResponseFormat(type: .jsonObject)
/// 
/// // Structured output with schema
/// let structuredFormat = ResponseFormat(
///     type: .jsonSchema,
///     jsonSchema: JSONSchema(
///         name: "recipe",
///         schema: [
///             "type": "object",
///             "properties": [
///                 "name": ["type": "string"],
///                 "ingredients": [
///                     "type": "array",
///                     "items": ["type": "string"]
///                 ],
///                 "instructions": ["type": "string"]
///             ],
///             "required": ["name", "ingredients", "instructions"]
///         ]
///     )
/// )
/// ```
public struct ResponseFormat: Codable, Sendable {
    /// The type of response format.
    public let type: ResponseFormatType
    
    /// JSON schema when `type` is `.jsonSchema`.
    ///
    /// Defines the exact structure the response must follow.
    public let jsonSchema: JSONSchema?
    
    /// Creates a new response format configuration.
    ///
    /// - Parameters:
    ///   - type: The format type
    ///   - jsonSchema: Schema definition (required when type is `.jsonSchema`)
    public init(type: ResponseFormatType, jsonSchema: JSONSchema? = nil) {
        self.type = type
        self.jsonSchema = jsonSchema
    }
}

/// The type of response format.
public enum ResponseFormatType: String, Codable, Sendable {
    /// Standard text response.
    ///
    /// The default format for model responses.
    case text
    
    /// JSON object response.
    ///
    /// Ensures the model returns valid JSON. Remember to instruct the model
    /// to produce JSON in your prompt.
    case jsonObject = "json_object"
    
    /// Structured JSON following a schema.
    ///
    /// The model's response will conform to the provided JSON schema.
    case jsonSchema = "json_schema"
}

/// JSON schema definition for structured outputs.
///
/// Defines the exact structure that the model's JSON response must follow.
/// This ensures type-safe, predictable outputs that can be reliably parsed.
///
/// ## Schema Limits
///
/// OpenAI has the following limits for structured output schemas:
/// - **Object properties**: Up to 5,000 properties per object
/// - **String length**: Up to 120,000 characters per string
/// - **Enum values**: Up to 1,000 values per enum
/// - **Enum string length**: For enums with >250 values, total character count across all values up to 15,000
///
/// ## Example
/// ```swift
/// let schema = JSONSchema(
///     name: "math_response",
///     schema: [
///         "type": "object",
///         "properties": [
///             "steps": [
///                 "type": "array",
///                 "items": [
///                     "type": "object",
///                     "properties": [
///                         "explanation": ["type": "string"],
///                         "result": ["type": "number"]
///                     ],
///                     "required": ["explanation", "result"]
///                 ]
///             ],
///             "final_answer": ["type": "number"]
///         ],
///         "required": ["steps", "final_answer"]
///     ],
///     strict: true
/// )
/// ```
public struct JSONSchema: Codable, Sendable {
    /// The name of the schema.
    ///
    /// Used for identification and error messages.
    public let name: String
    
    /// The JSON Schema definition.
    ///
    /// Must be a valid JSON Schema that defines the structure of the response.
    public let schema: JSONValue
    
    /// Whether to enforce strict schema validation.
    ///
    /// When true, the model must exactly match the schema.
    public let strict: Bool?
    
    /// Creates a schema with pre-encoded JSON Schema.
    ///
    /// - Parameters:
    ///   - name: Schema identifier
    ///   - schema: JSON Schema as ``JSONValue``
    ///   - strict: Enable strict validation
    public init(name: String, schema: JSONValue, strict: Bool? = nil) {
        self.name = name
        self.schema = schema
        self.strict = strict
    }
    
    /// Creates a schema from a dictionary.
    ///
    /// - Parameters:
    ///   - name: Schema identifier
    ///   - schema: JSON Schema as a dictionary
    ///   - strict: Enable strict validation
    public init(name: String, schema: [String: Any], strict: Bool? = nil) {
        self.name = name
        self.schema = Self.convertToJSONValue(schema)
        self.strict = strict
    }
    
    private static func convertToJSONValue(_ dict: [String: Any]) -> JSONValue {
        var result = [String: JSONValue]()
        for (key, value) in dict {
            if let string = value as? String {
                result[key] = .string(string)
            } else if let int = value as? Int {
                result[key] = .int(int)
            } else if let double = value as? Double {
                result[key] = .double(double)
            } else if let bool = value as? Bool {
                result[key] = .bool(bool)
            } else if let dict = value as? [String: Any] {
                result[key] = convertToJSONValue(dict)
            } else if let array = value as? [Any] {
                result[key] = convertToJSONValue(array)
            }
        }
        return .object(result)
    }
    
    private static func convertToJSONValue(_ array: [Any]) -> JSONValue {
        var result = [JSONValue]()
        for value in array {
            if let string = value as? String {
                result.append(.string(string))
            } else if let int = value as? Int {
                result.append(.int(int))
            } else if let double = value as? Double {
                result.append(.double(double))
            } else if let bool = value as? Bool {
                result.append(.bool(bool))
            } else if let dict = value as? [String: Any] {
                result.append(convertToJSONValue(dict))
            } else if let array = value as? [Any] {
                result.append(convertToJSONValue(array))
            }
        }
        return .array(result)
    }
}

/// Audio configuration for chat completions.
///
/// Enables audio input processing or audio output generation depending on
/// the model's capabilities.
///
/// ## Example
/// ```swift
/// let audioConfig = ChatAudio(
///     format: "mp3",
///     voice: "alloy"
/// )
/// ```
public struct ChatAudio: Codable, Sendable {
    /// The audio format.
    ///
    /// Common formats include "mp3", "opus", "aac", "flac", "wav", and "pcm".
    public let format: String?
    
    /// The voice to use for audio generation.
    ///
    /// Available voices depend on the model. Common options include
    /// "alloy", "echo", "fable", "onyx", "nova", and "shimmer".
    public let voice: String?
    
    /// Creates audio configuration.
    ///
    /// - Parameters:
    ///   - format: Audio format
    ///   - voice: Voice selection for generation
    public init(format: String? = nil, voice: String? = nil) {
        self.format = format
        self.voice = voice
    }
}

/// Prediction configuration for improved latency.
///
/// Allows the model to skip processing of predicted content, reducing
/// response time when the expected output is known.
public struct Prediction: Codable, Sendable {
    /// The type of prediction.
    public let type: String
    
    /// The predicted content.
    ///
    /// The model will attempt to match this content and skip processing if possible.
    public let content: String
    
    /// Creates prediction configuration.
    ///
    /// - Parameters:
    ///   - type: Prediction type
    ///   - content: Expected content
    public init(type: String, content: String) {
        self.type = type
        self.content = content
    }
}

/// Options for streaming responses.
///
/// Controls additional features available when streaming is enabled.
///
/// ## Example
/// ```swift
/// let streamOptions = StreamOptions(includeUsage: true)
/// ```
public struct StreamOptions: Codable, Sendable {
    /// Whether to include usage statistics in stream chunks.
    ///
    /// When true, the final chunk will include token usage information.
    public let includeUsage: Bool?
    
    /// Creates streaming options.
    ///
    /// - Parameter includeUsage: Include usage stats in final chunk
    public init(includeUsage: Bool? = nil) {
        self.includeUsage = includeUsage
    }
}

/// Web search integration options.
///
/// Allows the model to search the web for current information when enabled.
public struct WebSearchOptions: Codable, Sendable {
    /// Whether web search is enabled.
    ///
    /// When true, the model can search for up-to-date information online.
    public let enabled: Bool
    
    /// Creates web search options.
    ///
    /// - Parameter enabled: Enable web search capability
    public init(enabled: Bool) {
        self.enabled = enabled
    }
}

/// Log probability information for tokens.
///
/// Provides insight into the model's token selection process, showing
/// the probability distribution over possible tokens at each position.
public struct Logprobs: Codable, Sendable {
    /// Log probability data for each content token.
    ///
    /// Each entry corresponds to a token in the generated content.
    public let content: [LogprobContent]?
}

/// Log probability data for a single token.
///
/// Shows the selected token and alternative possibilities with their
/// respective probabilities.
public struct LogprobContent: Codable, Sendable {
    /// The selected token.
    public let token: String
    
    /// The log probability of the selected token.
    ///
    /// More negative values indicate lower probability.
    public let logprob: Double
    
    /// UTF-8 byte representation of the token.
    public let bytes: [Int]?
    
    /// Alternative tokens and their probabilities.
    ///
    /// Shows what other tokens the model considered at this position.
    public let topLogprobs: [TopLogprob]?
}

/// Alternative token with its probability.
///
/// Represents a token that was considered but not selected by the model.
public struct TopLogprob: Codable, Sendable {
    /// The alternative token.
    public let token: String
    
    /// The log probability of this token.
    ///
    /// More negative values indicate lower probability.
    public let logprob: Double
    
    /// UTF-8 byte representation of the token.
    public let bytes: [Int]?
}