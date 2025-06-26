// Function argument validation
import Foundation

struct FunctionValidator {
    static func validateWeatherArgs(_ args: WeatherArgs) throws {
        // Validate location
        guard !args.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyLocation
        }
        
        // Validate unit if provided
        if let unit = args.unit {
            guard ["celsius", "fahrenheit"].contains(unit.lowercased()) else {
                throw ValidationError.invalidUnit(unit)
            }
        }
        
        // Check for common issues
        let location = args.location.lowercased()
        if location.count < 2 {
            throw ValidationError.locationTooShort
        }
        
        // Check for valid characters
        let allowedCharacters = CharacterSet.letters
            .union(.whitespaces)
            .union(.punctuationCharacters)
        
        guard location.rangeOfCharacter(from: allowedCharacters.inverted) == nil else {
            throw ValidationError.invalidCharacters
        }
    }
    
    static func validateForecastArgs(_ args: ForecastArgs) throws {
        // Validate location first
        try validateWeatherArgs(WeatherArgs(location: args.location, unit: args.unit))
        
        // Validate days
        guard (1...7).contains(args.days) else {
            throw ValidationError.invalidDayCount(args.days)
        }
    }
}

enum ValidationError: LocalizedError {
    case emptyLocation
    case locationTooShort
    case invalidCharacters
    case invalidUnit(String)
    case invalidDayCount(Int)
    
    var errorDescription: String? {
        switch self {
        case .emptyLocation:
            return "Location cannot be empty"
        case .locationTooShort:
            return "Location name is too short"
        case .invalidCharacters:
            return "Location contains invalid characters"
        case .invalidUnit(let unit):
            return "Invalid unit '\(unit)'. Use 'celsius' or 'fahrenheit'"
        case .invalidDayCount(let days):
            return "Invalid day count \(days). Must be between 1 and 7"
        }
    }
}

// Use in function execution
func executeWeatherFunction(_ args: WeatherArgs) async throws -> WeatherData {
    // Validate first
    try FunctionValidator.validateWeatherArgs(args)
    
    // Then execute
    return try await weatherService.getCurrentWeather(
        location: args.location,
        unit: args.unit ?? "celsius"
    )
}