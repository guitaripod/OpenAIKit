// Multiple function support
import OpenAIKit

// Define multiple functions
let functions = [
    Function(
        name: "get_weather",
        description: "Get the current weather in a given location",
        parameters: JSONSchema(
            type: .object,
            properties: [
                "location": .init(type: .string, description: "The city and state"),
                "unit": .init(type: .string, enum: ["celsius", "fahrenheit"])
            ],
            required: ["location"]
        )
    ),
    
    Function(
        name: "get_forecast",
        description: "Get weather forecast for the next few days",
        parameters: JSONSchema(
            type: .object,
            properties: [
                "location": .init(type: .string, description: "The city and state"),
                "days": .init(type: .integer, description: "Number of days (1-7)"),
                "unit": .init(type: .string, enum: ["celsius", "fahrenheit"])
            ],
            required: ["location", "days"]
        )
    ),
    
    Function(
        name: "get_air_quality",
        description: "Get air quality index for a location",
        parameters: JSONSchema(
            type: .object,
            properties: [
                "location": .init(type: .string, description: "The city and state")
            ],
            required: ["location"]
        )
    )
]

// Use in request
let request = ChatCompletionRequest(
    messages: messages,
    model: "gpt-4o-mini",
    tools: functions.map { Tool(type: .function, function: $0) },
    toolChoice: "auto"
)