// WeatherService.swift with real API integration
import Foundation

class WeatherService {
    static let shared = WeatherService()
    private let apiKey = ProcessInfo.processInfo.environment["WEATHER_API_KEY"] ?? ""
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    
    func getCurrentWeather(location: String, unit: String = "celsius") async throws -> WeatherData {
        guard !apiKey.isEmpty else {
            // Return mock data if no API key
            return mockWeather(for: location, unit: unit)
        }
        
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "q", value: location),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: unit == "celsius" ? "metric" : "imperial")
        ]
        
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let response = try JSONDecoder().decode(WeatherAPIResponse.self, from: data)
        
        return WeatherData(
            location: location,
            temperature: response.main.temp,
            unit: unit,
            description: response.weather.first?.description ?? "Unknown",
            humidity: response.main.humidity,
            windSpeed: response.wind.speed
        )
    }
    
    private func mockWeather(for location: String, unit: String) -> WeatherData {
        WeatherData(
            location: location,
            temperature: 22,
            unit: unit,
            description: "Partly cloudy",
            humidity: 65,
            windSpeed: 12
        )
    }
}

// API Response Models
struct WeatherAPIResponse: Codable {
    let main: MainWeather
    let weather: [Weather]
    let wind: Wind
}

struct MainWeather: Codable {
    let temp: Double
    let humidity: Int
}

struct Weather: Codable {
    let description: String
}

struct Wind: Codable {
    let speed: Double
}