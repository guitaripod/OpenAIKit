// FunctionCalling.swift
import Foundation
import OpenAIKit

// Define function arguments structure
struct WeatherArgs: Codable {
    let location: String
    let unit: String?
}

// Create function definition
let getWeatherFunction = Function(
    name: "get_weather",
    description: "Get the current weather in a given location"
)