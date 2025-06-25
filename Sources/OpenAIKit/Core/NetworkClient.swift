import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol NetworkClientProtocol: Sendable {
    func execute<T: Decodable>(_ request: any Request) async throws -> T
    func stream<T: Decodable>(_ request: any Request) -> AsyncThrowingStream<T, Error>
    func upload<T: Decodable>(_ request: any UploadRequest) async throws -> T
}

public final class NetworkClient: NetworkClientProtocol, @unchecked Sendable {
    
    private let session: URLSession
    private let configuration: Configuration
    private let decoder: JSONDecoder
    
    init(configuration: Configuration) {
        self.configuration = configuration
        
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = configuration.timeoutInterval
        sessionConfiguration.timeoutIntervalForResource = configuration.timeoutInterval * 2
        self.session = URLSession(configuration: sessionConfiguration)
        
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .secondsSince1970
    }
    
    public func execute<T: Decodable>(_ request: any Request) async throws -> T {
        let urlRequest = try await buildURLRequest(from: request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        try validateResponse(response, data: data)
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            if let apiError = try? decoder.decode(APIError.self, from: data) {
                throw OpenAIError.apiError(apiError)
            }
            throw OpenAIError.decodingFailed(error)
        }
    }
    
    public func stream<T: Decodable>(_ request: any Request) -> AsyncThrowingStream<T, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let urlRequest = try await buildStreamingURLRequest(from: request)
                    
                    #if canImport(FoundationNetworking)
                    // Linux implementation using URLSessionDataTask
                    let semaphore = DispatchSemaphore(value: 0)
                    var receivedData = Data()
                    
                    let task = self.session.dataTask(with: urlRequest) { data, response, error in
                        if let error = error {
                            continuation.finish(throwing: error)
                            semaphore.signal()
                            return
                        }
                        
                        if let response = response {
                            do {
                                try self.validateResponse(response, data: nil)
                            } catch {
                                continuation.finish(throwing: error)
                                semaphore.signal()
                                return
                            }
                        }
                        
                        if let data = data {
                            receivedData.append(data)
                            
                            // Process complete lines
                            if let string = String(data: receivedData, encoding: .utf8) {
                                let lines = string.components(separatedBy: "\n")
                                
                                for i in 0..<(lines.count - 1) {
                                    let line = lines[i]
                                    guard !line.isEmpty else { continue }
                                    guard line.hasPrefix("data: ") else { continue }
                                    
                                    let jsonString = String(line.dropFirst(6))
                                    guard jsonString != "[DONE]" else {
                                        continuation.finish()
                                        semaphore.signal()
                                        return
                                    }
                                    
                                    guard let lineData = jsonString.data(using: .utf8) else { continue }
                                    
                                    do {
                                        let decoded = try self.decoder.decode(T.self, from: lineData)
                                        continuation.yield(decoded)
                                    } catch {
                                        continuation.finish(throwing: OpenAIError.decodingFailed(error))
                                        semaphore.signal()
                                        return
                                    }
                                }
                                
                                // Keep the incomplete last line
                                if let lastLine = lines.last, !lastLine.isEmpty {
                                    receivedData = lastLine.data(using: .utf8) ?? Data()
                                } else {
                                    receivedData = Data()
                                }
                            }
                        }
                    }
                    
                    task.resume()
                    _ = semaphore.wait(timeout: .distantFuture)
                    #else
                    // macOS/iOS implementation using bytes API
                    let (bytes, response) = try await session.bytes(for: urlRequest)
                    
                    try validateResponse(response, data: nil)
                    
                    for try await line in bytes.lines {
                        guard !line.isEmpty else { continue }
                        guard line.hasPrefix("data: ") else { continue }
                        
                        let jsonString = String(line.dropFirst(6))
                        guard jsonString != "[DONE]" else {
                            continuation.finish()
                            return
                        }
                        
                        guard let data = jsonString.data(using: .utf8) else { continue }
                        
                        do {
                            let decoded = try self.decoder.decode(T.self, from: data)
                            continuation.yield(decoded)
                        } catch {
                            continuation.finish(throwing: OpenAIError.decodingFailed(error))
                            return
                        }
                    }
                    
                    continuation.finish()
                    #endif
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    public func upload<T: Decodable>(_ request: any UploadRequest) async throws -> T {
        let urlRequest = try await buildUploadURLRequest(from: request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        try validateResponse(response, data: data)
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            if let apiError = try? decoder.decode(APIError.self, from: data) {
                throw OpenAIError.apiError(apiError)
            }
            throw OpenAIError.decodingFailed(error)
        }
    }
    
    private func buildURLRequest(from request: any Request) async throws -> URLRequest {
        guard let url = URL(string: request.path, relativeTo: configuration.baseURL.appendingPathComponent("/v1")) else {
            throw OpenAIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        
        configureHeaders(&urlRequest)
        
        if request.method != .get, let body = request.body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            urlRequest.httpBody = try encoder.encode(body)
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        return urlRequest
    }
    
    private func buildStreamingURLRequest(from request: any Request) async throws -> URLRequest {
        var urlRequest = try await buildURLRequest(from: request)
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        return urlRequest
    }
    
    private func buildUploadURLRequest(from request: any UploadRequest) async throws -> URLRequest {
        guard let url = URL(string: request.path, relativeTo: configuration.baseURL.appendingPathComponent("/v1")) else {
            throw OpenAIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        
        configureHeaders(&urlRequest)
        
        let boundary = UUID().uuidString
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        urlRequest.httpBody = try await request.multipartData(boundary: boundary)
        
        return urlRequest
    }
    
    private func configureHeaders(_ request: inout URLRequest) {
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        
        if let organization = configuration.organization {
            request.setValue(organization, forHTTPHeaderField: "OpenAI-Organization")
        }
        
        if let project = configuration.project {
            request.setValue(project, forHTTPHeaderField: "OpenAI-Project")
        }
        
        request.setValue("OpenAIKit/1.0.0", forHTTPHeaderField: "User-Agent")
    }
    
    private func validateResponse(_ response: URLResponse, data: Data?) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw OpenAIError.authenticationFailed
        case 429:
            throw OpenAIError.rateLimitExceeded
        case 400...499:
            if let data = data, let apiError = try? decoder.decode(APIError.self, from: data) {
                throw OpenAIError.apiError(apiError)
            }
            throw OpenAIError.clientError(statusCode: httpResponse.statusCode)
        case 500...599:
            throw OpenAIError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw OpenAIError.unknownError(statusCode: httpResponse.statusCode)
        }
    }
}