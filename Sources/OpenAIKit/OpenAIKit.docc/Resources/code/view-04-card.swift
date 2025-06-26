// WeatherCardView.swift
import SwiftUI

struct WeatherCardView: View {
    let weatherData: WeatherData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Location
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                Text(weatherData.location)
                    .font(.headline)
            }
            
            // Temperature
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading) {
                    Text(weatherData.formattedTemperature)
                        .font(.system(size: 48, weight: .light))
                    Text(weatherData.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: weatherIcon)
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
            }
            
            // Additional info
            HStack(spacing: 30) {
                if let humidity = weatherData.humidity {
                    Label("\(humidity)%", systemImage: "humidity.fill")
                }
                
                if let windSpeed = weatherData.windSpeed {
                    let windUnit = weatherData.unit == "celsius" ? "km/h" : "mph"
                    Label("\(Int(windSpeed)) \(windUnit)", systemImage: "wind")
                }
            }
            .font(.footnote)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var weatherIcon: String {
        switch weatherData.description.lowercased() {
        case let desc where desc.contains("sun") || desc.contains("clear"):
            return "sun.max.fill"
        case let desc where desc.contains("cloud"):
            return "cloud.fill"
        case let desc where desc.contains("rain"):
            return "cloud.rain.fill"
        case let desc where desc.contains("snow"):
            return "cloud.snow.fill"
        default:
            return "cloud.sun.fill"
        }
    }
}