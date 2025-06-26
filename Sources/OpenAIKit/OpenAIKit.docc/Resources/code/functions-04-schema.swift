// FunctionCalling.swift
import Foundation
import OpenAIKit

// Define function arguments structure
struct WeatherArgs: Codable {
    let location: String
    let unit: String?
}

// Create function definition with parameter schema
let getWeatherFunction = Function(
    name: "get_weather",
    description: "Get the current weather in a given location",
    parameters: JSONSchema(
        type: .object,
        properties: [
            "location": .init(type: .string, description: "The city and state, e.g. San Francisco, CA"),
            "unit": .init(type: .string, enum: ["celsius", "fahrenheit"], description: "Temperature unit")
        ],
        required: ["location"]
    )
)