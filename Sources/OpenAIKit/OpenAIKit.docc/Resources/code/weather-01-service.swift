// WeatherService.swift
import Foundation

class WeatherService {
    static let shared = WeatherService()
    
    private init() {}
    
    func getCurrentWeather(location: String, unit: String = "celsius") async throws -> WeatherData {
        // Mock implementation
        return WeatherData(
            location: location,
            temperature: 22,
            unit: unit,
            description: "Sunny"
        )
    }
}