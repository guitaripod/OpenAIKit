// JSONStreamParser.swift
import Foundation

class JSONStreamParser {
    private var buffer = ""
    private var depth = 0
    
    func parse(_ chunk: String) -> [Any]? {
        buffer += chunk
        var objects: [Any] = []
        
        var startIndex = buffer.startIndex
        for (index, char) in buffer.enumerated() {
            switch char {
            case "{", "[":
                depth += 1
            case "}", "]":
                depth -= 1
                
                if depth == 0 {
                    // Complete JSON object
                    let endIndex = buffer.index(buffer.startIndex, offsetBy: index + 1)
                    let jsonString = String(buffer[startIndex..<endIndex])
                    
                    if let data = jsonString.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) {
                        objects.append(json)
                    }
                    
                    startIndex = endIndex
                }
            default:
                break
            }
        }
        
        // Keep unparsed data in buffer
        if startIndex < buffer.endIndex {
            buffer = String(buffer[startIndex...])
        } else {
            buffer = ""
        }
        
        return objects.isEmpty ? nil : objects
    }
}
