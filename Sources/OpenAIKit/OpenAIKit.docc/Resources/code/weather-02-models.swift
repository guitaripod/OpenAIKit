// WeatherService.swift
import Foundation

struct WeatherData: Codable {
    let location: String
    let temperature: Double
    let unit: String
    let description: String
    let humidity: Int?
    let windSpeed: Double?
    
    var formattedTemperature: String {
        let symbol = unit == "celsius" ? "°C" : "°F"
        return "\(Int(temperature))\(symbol)"
    }
}

class WeatherService {
    static let shared = WeatherService()
    
    private init() {}
    
    func getCurrentWeather(location: String, unit: String = "celsius") async throws -> WeatherData {
        // Simulate API delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Mock weather data
        let temp = Double.random(in: 15...30)
        let fahrenheit = unit == "fahrenheit" ? (temp * 9/5) + 32 : temp
        
        return WeatherData(
            location: location,
            temperature: unit == "celsius" ? temp : fahrenheit,
            unit: unit,
            description: ["Sunny", "Partly Cloudy", "Cloudy", "Rainy"].randomElement()!,
            humidity: Int.random(in: 40...80),
            windSpeed: Double.random(in: 5...25)
        )
    }
}