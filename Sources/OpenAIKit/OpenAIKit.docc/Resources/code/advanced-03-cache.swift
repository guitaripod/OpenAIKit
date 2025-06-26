// Function result caching
import Foundation

class CachedWeatherService {
    private let cache = NSCache<NSString, CacheEntry>()
    private let cacheLifetime: TimeInterval = 300 // 5 minutes
    
    func getCurrentWeather(location: String, unit: String) async throws -> WeatherData {
        let cacheKey = "weather_\(location)_\(unit)" as NSString
        
        // Check cache
        if let cached = cache.object(forKey: cacheKey),
           cached.isValid {
            return cached.data as! WeatherData
        }
        
        // Fetch fresh data
        let weatherData = try await fetchWeather(location: location, unit: unit)
        
        // Cache result
        let entry = CacheEntry(data: weatherData, timestamp: Date())
        cache.setObject(entry, forKey: cacheKey)
        
        return weatherData
    }
    
    private func fetchWeather(location: String, unit: String) async throws -> WeatherData {
        // Actual API call here
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate API
        
        return WeatherData(
            location: location,
            temperature: 22,
            unit: unit,
            description: "Partly cloudy",
            humidity: 65,
            windSpeed: 12
        )
    }
}

class CacheEntry: NSObject {
    let data: Any
    let timestamp: Date
    
    init(data: Any, timestamp: Date) {
        self.data = data
        self.timestamp = timestamp
    }
    
    var isValid: Bool {
        Date().timeIntervalSince(timestamp) < 300 // 5 minutes
    }
}