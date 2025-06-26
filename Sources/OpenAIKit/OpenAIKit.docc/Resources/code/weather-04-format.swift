// WeatherFormatter.swift
import Foundation

extension WeatherData {
    func formatForDisplay() -> String {
        var result = "Weather in \(location):\n"
        result += "🌡️ Temperature: \(formattedTemperature)\n"
        result += "☁️ Conditions: \(description)\n"
        
        if let humidity = humidity {
            result += "💧 Humidity: \(humidity)%\n"
        }
        
        if let windSpeed = windSpeed {
            let windUnit = unit == "celsius" ? "km/h" : "mph"
            result += "💨 Wind: \(Int(windSpeed)) \(windUnit)"
        }
        
        return result
    }
    
    func toJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        guard let data = try? encoder.encode(self),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        
        return json
    }
}