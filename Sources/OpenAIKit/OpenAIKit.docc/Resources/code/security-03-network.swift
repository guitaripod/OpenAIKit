import Foundation
import OpenAIKit

// Configure network security and proxies for DeepResearch

class SecureNetworkConfiguration {
    private let certificatePinner: CertificatePinner
    private let proxyManager: ProxyManager
    private let networkMonitor: NetworkSecurityMonitor
    
    init() {
        self.certificatePinner = CertificatePinner()
        self.proxyManager = ProxyManager()
        self.networkMonitor = NetworkSecurityMonitor()
    }
    
    // Create secure URLSession configuration
    func createSecureConfiguration(
        options: NetworkSecurityOptions
    ) -> URLSessionConfiguration {
        
        let config = URLSessionConfiguration.default
        
        // Basic security settings
        config.tlsMinimumSupportedProtocolVersion = .TLSv12
        config.tlsMaximumSupportedProtocolVersion = .TLSv13
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        config.urlCache = nil
        
        // Timeout configuration
        config.timeoutIntervalForRequest = options.requestTimeout
        config.timeoutIntervalForResource = options.resourceTimeout
        
        // Proxy configuration
        if let proxyConfig = options.proxyConfiguration {
            applyProxyConfiguration(proxyConfig, to: config)
        }
        
        // Custom headers for security
        var headers = config.httpAdditionalHeaders ?? [:]
        headers["X-Request-ID"] = UUID().uuidString
        headers["X-Client-Version"] = "1.0.0"
        
        if let customHeaders = options.additionalHeaders {
            headers.merge(customHeaders) { _, new in new }
        }
        
        config.httpAdditionalHeaders = headers
        
        return config
    }
    
    // Create secure URLSession with certificate pinning
    func createSecureSession(
        configuration: URLSessionConfiguration,
        pinnedCertificates: [PinnedCertificate] = []
    ) -> URLSession {
        
        let delegate = SecureSessionDelegate(
            certificatePinner: certificatePinner,
            pinnedCertificates: pinnedCertificates,
            networkMonitor: networkMonitor
        )
        
        return URLSession(
            configuration: configuration,
            delegate: delegate,
            delegateQueue: nil
        )
    }
    
    // Create secure OpenAI client
    func createSecureOpenAIClient(
        apiKey: String,
        options: NetworkSecurityOptions
    ) -> OpenAI {
        
        let sessionConfig = createSecureConfiguration(options: options)
        let session = createSecureSession(
            configuration: sessionConfig,
            pinnedCertificates: options.pinnedCertificates
        )
        
        // Create custom configuration with secure session
        let config = Configuration(
            apiKey: apiKey,
            organizationId: options.organizationId,
            baseURL: options.customBaseURL ?? "https://api.openai.com",
            session: session
        )
        
        return OpenAI(config)
    }
    
    // Apply proxy configuration
    private func applyProxyConfiguration(
        _ proxyConfig: ProxyConfiguration,
        to sessionConfig: URLSessionConfiguration
    ) {
        
        var proxyDict: [String: Any] = [:]
        
        switch proxyConfig.type {
        case .http:
            proxyDict[kCFNetworkProxiesHTTPEnable as String] = true
            proxyDict[kCFNetworkProxiesHTTPProxy as String] = proxyConfig.host
            proxyDict[kCFNetworkProxiesHTTPPort as String] = proxyConfig.port
            
        case .https:
            proxyDict[kCFNetworkProxiesHTTPSEnable as String] = true
            proxyDict[kCFNetworkProxiesHTTPSProxy as String] = proxyConfig.host
            proxyDict[kCFNetworkProxiesHTTPSPort as String] = proxyConfig.port
            
        case .socks5:
            proxyDict[kCFNetworkProxiesSOCKSEnable as String] = true
            proxyDict[kCFNetworkProxiesSOCKSProxy as String] = proxyConfig.host
            proxyDict[kCFNetworkProxiesSOCKSPort as String] = proxyConfig.port
            
        case .pac:
            if let pacURL = proxyConfig.pacURL {
                proxyDict[kCFNetworkProxiesProxyAutoConfigEnable as String] = true
                proxyDict[kCFNetworkProxiesProxyAutoConfigURLString as String] = pacURL.absoluteString
            }
        }
        
        // Authentication
        if let auth = proxyConfig.authentication {
            switch auth {
            case .basic(let username, let password):
                proxyDict[kCFProxyUsernameKey as String] = username
                proxyDict[kCFProxyPasswordKey as String] = password
            case .ntlm:
                // NTLM requires additional configuration
                print("NTLM proxy authentication configured")
            }
        }
        
        // Bypass list
        if !proxyConfig.bypassHosts.isEmpty {
            proxyDict[kCFNetworkProxiesExceptionsList as String] = proxyConfig.bypassHosts
        }
        
        sessionConfig.connectionProxyDictionary = proxyDict
    }
}

// Secure session delegate for certificate pinning
class SecureSessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    private let certificatePinner: CertificatePinner
    private let pinnedCertificates: [PinnedCertificate]
    private let networkMonitor: NetworkSecurityMonitor
    
    init(
        certificatePinner: CertificatePinner,
        pinnedCertificates: [PinnedCertificate],
        networkMonitor: NetworkSecurityMonitor
    ) {
        self.certificatePinner = certificatePinner
        self.pinnedCertificates = pinnedCertificates
        self.networkMonitor = networkMonitor
    }
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        let host = challenge.protectionSpace.host
        
        // Check if we have pinned certificates for this host
        let relevantPins = pinnedCertificates.filter { pin in
            pin.hosts.contains(host) || pin.hosts.contains("*")
        }
        
        if !relevantPins.isEmpty {
            // Perform certificate pinning
            do {
                try certificatePinner.evaluateServerTrust(
                    serverTrust,
                    forHost: host,
                    withPins: relevantPins
                )
                
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                
                networkMonitor.logSuccessfulConnection(
                    host: host,
                    pinned: true
                )
                
            } catch {
                networkMonitor.logSecurityViolation(
                    host: host,
                    error: error
                )
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        } else {
            // No pinning required, perform default validation
            completionHandler(.performDefaultHandling, nil)
            networkMonitor.logSuccessfulConnection(
                host: host,
                pinned: false
            )
        }
    }
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didFinishCollecting metrics: URLSessionTaskMetrics
    ) {
        networkMonitor.recordMetrics(metrics)
    }
}

// Certificate pinner
class CertificatePinner {
    enum PinningError: LocalizedError {
        case invalidServerTrust
        case noCertificatesFound
        case pinningFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidServerTrust:
                return "Invalid server trust"
            case .noCertificatesFound:
                return "No certificates found in trust chain"
            case .pinningFailed(let reason):
                return "Certificate pinning failed: \(reason)"
            }
        }
    }
    
    func evaluateServerTrust(
        _ serverTrust: SecTrust,
        forHost host: String,
        withPins pins: [PinnedCertificate]
    ) throws {
        
        // Evaluate the trust
        var error: CFError?
        let isValid = SecTrustEvaluateWithError(serverTrust, &error)
        
        guard isValid else {
            throw PinningError.invalidServerTrust
        }
        
        // Get certificate chain
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        guard certificateCount > 0 else {
            throw PinningError.noCertificatesFound
        }
        
        var certificateChain: [SecCertificate] = []
        for i in 0..<certificateCount {
            if let cert = SecTrustGetCertificateAtIndex(serverTrust, i) {
                certificateChain.append(cert)
            }
        }
        
        // Check pins
        var pinningPassed = false
        
        for pin in pins {
            switch pin.type {
            case .certificate:
                if verifyCertificatePin(
                    certificateChain: certificateChain,
                    pinnedData: pin.pinnedData
                ) {
                    pinningPassed = true
                    break
                }
                
            case .publicKey:
                if verifyPublicKeyPin(
                    certificateChain: certificateChain,
                    pinnedData: pin.pinnedData
                ) {
                    pinningPassed = true
                    break
                }
            }
        }
        
        if !pinningPassed {
            throw PinningError.pinningFailed("No matching pins found for \(host)")
        }
    }
    
    private func verifyCertificatePin(
        certificateChain: [SecCertificate],
        pinnedData: [Data]
    ) -> Bool {
        
        for cert in certificateChain {
            let certData = SecCertificateCopyData(cert) as Data
            let certHash = SHA256.hash(data: certData)
            let certHashData = Data(certHash)
            
            if pinnedData.contains(certHashData) {
                return true
            }
        }
        
        return false
    }
    
    private func verifyPublicKeyPin(
        certificateChain: [SecCertificate],
        pinnedData: [Data]
    ) -> Bool {
        
        for cert in certificateChain {
            guard let publicKey = SecCertificateCopyKey(cert),
                  let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
                continue
            }
            
            let keyHash = SHA256.hash(data: publicKeyData)
            let keyHashData = Data(keyHash)
            
            if pinnedData.contains(keyHashData) {
                return true
            }
        }
        
        return false
    }
}

// Proxy manager
class ProxyManager {
    func detectSystemProxy() -> ProxyConfiguration? {
        guard let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any] else {
            return nil
        }
        
        // Check for HTTP proxy
        if let httpEnabled = proxySettings[kCFNetworkProxiesHTTPEnable as String] as? Bool,
           httpEnabled,
           let host = proxySettings[kCFNetworkProxiesHTTPProxy as String] as? String,
           let port = proxySettings[kCFNetworkProxiesHTTPPort as String] as? Int {
            
            return ProxyConfiguration(
                type: .http,
                host: host,
                port: port,
                authentication: nil,
                bypassHosts: []
            )
        }
        
        // Check for PAC
        if let pacEnabled = proxySettings[kCFNetworkProxiesProxyAutoConfigEnable as String] as? Bool,
           pacEnabled,
           let pacURLString = proxySettings[kCFNetworkProxiesProxyAutoConfigURLString as String] as? String,
           let pacURL = URL(string: pacURLString) {
            
            return ProxyConfiguration(
                type: .pac,
                host: "",
                port: 0,
                authentication: nil,
                bypassHosts: [],
                pacURL: pacURL
            )
        }
        
        return nil
    }
}

// Network security monitor
class NetworkSecurityMonitor {
    private var connectionLogs: [ConnectionLog] = []
    private var violationLogs: [SecurityViolationLog] = []
    private let logQueue = DispatchQueue(label: "network.monitor", attributes: .concurrent)
    
    func logSuccessfulConnection(host: String, pinned: Bool) {
        let log = ConnectionLog(
            host: host,
            timestamp: Date(),
            pinned: pinned,
            success: true
        )
        
        logQueue.async(flags: .barrier) {
            self.connectionLogs.append(log)
        }
    }
    
    func logSecurityViolation(host: String, error: Error) {
        let violation = SecurityViolationLog(
            host: host,
            timestamp: Date(),
            error: error.localizedDescription,
            severity: .high
        )
        
        logQueue.async(flags: .barrier) {
            self.violationLogs.append(violation)
        }
        
        // In production, alert security team
        print("SECURITY VIOLATION: \(host) - \(error)")
    }
    
    func recordMetrics(_ metrics: URLSessionTaskMetrics) {
        // Record performance and security metrics
        for transaction in metrics.transactionMetrics {
            if let connectionTime = transaction.connectEndDate?.timeIntervalSince(
                transaction.connectStartDate ?? Date()
            ) {
                print("Connection time: \(connectionTime)s")
            }
            
            print("Protocol: \(transaction.networkProtocolName ?? "Unknown")")
            print("TLS Version: \(transaction.negotiatedTLSProtocolVersion?.rawValue ?? 0)")
        }
    }
    
    func generateSecurityReport() -> NetworkSecurityReport {
        logQueue.sync {
            return NetworkSecurityReport(
                totalConnections: connectionLogs.count,
                pinnedConnections: connectionLogs.filter { $0.pinned }.count,
                violations: violationLogs.count,
                recentViolations: violationLogs.suffix(10),
                generatedAt: Date()
            )
        }
    }
}

// Models
struct NetworkSecurityOptions {
    let requestTimeout: TimeInterval
    let resourceTimeout: TimeInterval
    let proxyConfiguration: ProxyConfiguration?
    let pinnedCertificates: [PinnedCertificate]
    let organizationId: String?
    let customBaseURL: String?
    let additionalHeaders: [String: String]?
    
    static let `default` = NetworkSecurityOptions(
        requestTimeout: 30,
        resourceTimeout: 300,
        proxyConfiguration: nil,
        pinnedCertificates: [],
        organizationId: nil,
        customBaseURL: nil,
        additionalHeaders: nil
    )
}

struct ProxyConfiguration {
    enum ProxyType {
        case http
        case https
        case socks5
        case pac
    }
    
    enum Authentication {
        case basic(username: String, password: String)
        case ntlm
    }
    
    let type: ProxyType
    let host: String
    let port: Int
    let authentication: Authentication?
    let bypassHosts: [String]
    let pacURL: URL?
    
    init(
        type: ProxyType,
        host: String,
        port: Int,
        authentication: Authentication? = nil,
        bypassHosts: [String] = [],
        pacURL: URL? = nil
    ) {
        self.type = type
        self.host = host
        self.port = port
        self.authentication = authentication
        self.bypassHosts = bypassHosts
        self.pacURL = pacURL
    }
}

struct PinnedCertificate {
    enum PinType {
        case certificate
        case publicKey
    }
    
    let hosts: [String]
    let type: PinType
    let pinnedData: [Data]
    let expiryDate: Date?
}

struct ConnectionLog {
    let host: String
    let timestamp: Date
    let pinned: Bool
    let success: Bool
}

struct SecurityViolationLog {
    let host: String
    let timestamp: Date
    let error: String
    let severity: Severity
    
    enum Severity {
        case low, medium, high, critical
    }
}

struct NetworkSecurityReport {
    let totalConnections: Int
    let pinnedConnections: Int
    let violations: Int
    let recentViolations: [SecurityViolationLog]
    let generatedAt: Date
}

// SHA256 extension
import CryptoKit

extension SHA256 {
    static func hash(data: Data) -> SHA256.Digest {
        return SHA256.hash(data: data)
    }
}

// Configuration extension for custom session
extension Configuration {
    init(apiKey: String, organizationId: String? = nil, baseURL: String = "https://api.openai.com", session: URLSession) {
        // This would require OpenAIKit to support custom URLSession
        // For now, this is a conceptual implementation
        self.init(apiKey: apiKey, organizationId: organizationId)
    }
}

// Example usage
func demonstrateNetworkSecurity() async {
    let networkConfig = SecureNetworkConfiguration()
    
    // Example 1: Basic secure configuration
    let basicOptions = NetworkSecurityOptions(
        requestTimeout: 30,
        resourceTimeout: 300,
        proxyConfiguration: nil,
        pinnedCertificates: [],
        organizationId: "org-123",
        customBaseURL: nil,
        additionalHeaders: ["X-Custom-Header": "value"]
    )
    
    let secureClient = networkConfig.createSecureOpenAIClient(
        apiKey: "your-api-key",
        options: basicOptions
    )
    
    // Example 2: With proxy configuration
    let proxyConfig = ProxyConfiguration(
        type: .http,
        host: "proxy.company.com",
        port: 8080,
        authentication: .basic(username: "user", password: "pass"),
        bypassHosts: ["localhost", "*.internal.com"]
    )
    
    let proxyOptions = NetworkSecurityOptions(
        requestTimeout: 30,
        resourceTimeout: 300,
        proxyConfiguration: proxyConfig,
        pinnedCertificates: [],
        organizationId: nil,
        customBaseURL: nil,
        additionalHeaders: nil
    )
    
    // Example 3: With certificate pinning
    let openAIPins = PinnedCertificate(
        hosts: ["api.openai.com"],
        type: .publicKey,
        pinnedData: [
            // Add actual public key hashes here
            Data(base64Encoded: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")!
        ],
        expiryDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())
    )
    
    let pinnedOptions = NetworkSecurityOptions(
        requestTimeout: 30,
        resourceTimeout: 300,
        proxyConfiguration: nil,
        pinnedCertificates: [openAIPins],
        organizationId: nil,
        customBaseURL: nil,
        additionalHeaders: nil
    )
    
    // Create DeepResearch with secure client
    let deepResearch = DeepResearch(client: secureClient)
    
    // Monitor network security
    let monitor = NetworkSecurityMonitor()
    
    do {
        let result = try await deepResearch.research(
            query: "Latest cybersecurity trends",
            configuration: DeepResearchConfiguration(
                maxSearchQueries: 5,
                maxWebPages: 10
            )
        )
        
        print("Secure research completed")
        
        // Generate security report
        let report = monitor.generateSecurityReport()
        print("Security Report:")
        print("Total connections: \(report.totalConnections)")
        print("Pinned connections: \(report.pinnedConnections)")
        print("Security violations: \(report.violations)")
        
    } catch {
        print("Secure network error: \(error)")
    }
}

// Network security best practices
extension SecureNetworkConfiguration {
    static var bestPractices: [String] {
        return [
            "Always use TLS 1.2 or higher",
            "Implement certificate pinning for critical APIs",
            "Use proxy configurations for corporate networks",
            "Set appropriate timeout values",
            "Monitor and log security violations",
            "Rotate pinned certificates before expiry",
            "Use separate configurations for different environments",
            "Implement retry logic with exponential backoff",
            "Validate all server certificates",
            "Use secure DNS resolution when possible"
        ]
    }
}