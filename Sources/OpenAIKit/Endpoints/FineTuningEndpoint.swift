import Foundation

public final class FineTuningEndpoint: Sendable {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
}