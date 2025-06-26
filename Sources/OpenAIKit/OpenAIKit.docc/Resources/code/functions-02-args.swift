// FunctionCalling.swift
import Foundation
import OpenAIKit

// Define function arguments structure
struct WeatherArgs: Codable {
    let location: String
    let unit: String?
}