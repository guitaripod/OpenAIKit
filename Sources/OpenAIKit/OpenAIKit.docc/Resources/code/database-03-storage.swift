import Foundation
import Compression

// MARK: - Efficient Vector Storage

/// Optimized storage for vector embeddings with compression
class VectorStorage {
    private let dimension: Int
    private let compressionAlgorithm: NSData.CompressionAlgorithm
    private let quantizationBits: Int?
    
    init(
        dimension: Int,
        compressionAlgorithm: NSData.CompressionAlgorithm = .lzfse,
        quantizationBits: Int? = nil
    ) {
        self.dimension = dimension
        self.compressionAlgorithm = compressionAlgorithm
        self.quantizationBits = quantizationBits
    }
    
    // MARK: - Vector Compression
    
    func compress(embedding: [Float]) throws -> Data {
        var processedEmbedding = embedding
        
        // Apply quantization if specified
        if let bits = quantizationBits {
            processedEmbedding = quantize(embedding: embedding, bits: bits)
        }
        
        // Convert to data
        let data = processedEmbedding.withUnsafeBytes { bytes in
            Data(bytes)
        }
        
        // Apply compression
        guard let compressed = (data as NSData).compressed(using: compressionAlgorithm) else {
            throw StorageError.compressionFailed
        }
        
        return compressed as Data
    }
    
    func decompress(data: Data) throws -> [Float] {
        // Decompress data
        guard let decompressed = (data as NSData).decompressed(using: compressionAlgorithm) else {
            throw StorageError.decompressionFailed
        }
        
        // Convert back to float array
        let floatArray = decompressed.withUnsafeBytes { bytes in
            Array(bytes.bindMemory(to: Float.self))
        }
        
        // Apply dequantization if needed
        if let bits = quantizationBits {
            return dequantize(embedding: floatArray, bits: bits)
        }
        
        return floatArray
    }
    
    // MARK: - Quantization
    
    private func quantize(embedding: [Float], bits: Int) -> [Float] {
        let levels = Float(1 << bits)
        
        // Find min and max values
        let minVal = embedding.min() ?? 0
        let maxVal = embedding.max() ?? 1
        let range = maxVal - minVal
        
        // Quantize each value
        return embedding.map { value in
            let normalized = (value - minVal) / range
            let quantized = round(normalized * (levels - 1))
            return quantized / (levels - 1) * range + minVal
        }
    }
    
    private func dequantize(embedding: [Float], bits: Int) -> [Float] {
        // In this simplified version, dequantization is already done during decompression
        return embedding
    }
}

// MARK: - Storage Manager

/// Manages efficient storage of vector documents
class VectorStorageManager {
    private let storage: VectorStorage
    private let fileManager = FileManager.default
    private let baseURL: URL
    private let queue = DispatchQueue(label: "vectordb.storage", attributes: .concurrent)
    
    // Metadata cache for fast lookups
    private var metadataCache: [String: DocumentMetadata] = [:]
    
    struct DocumentMetadata: Codable {
        let id: String
        let dimension: Int
        let compressed: Bool
        let compressionRatio: Float?
        let createdAt: Date
        let fileOffset: Int64
        let fileSize: Int64
        let checksum: String
    }
    
    init(
        baseURL: URL,
        dimension: Int,
        enableCompression: Bool = true
    ) throws {
        self.baseURL = baseURL
        self.storage = VectorStorage(
            dimension: dimension,
            compressionAlgorithm: enableCompression ? .lzfse : .none,
            quantizationBits: enableCompression ? 8 : nil
        )
        
        // Create storage directory if needed
        try fileManager.createDirectory(
            at: baseURL,
            withIntermediateDirectories: true
        )
        
        // Load metadata cache
        loadMetadataCache()
    }
    
    // MARK: - Storage Operations
    
    func store(document: VectorDocument) async throws -> DocumentMetadata {
        try await withCheckedThrowingContinuation { continuation in
            queue.async(flags: .barrier) {
                do {
                    // Compress embedding
                    let originalSize = document.embedding.count * MemoryLayout<Float>.size
                    let compressedData = try self.storage.compress(embedding: document.embedding)
                    let compressionRatio = Float(originalSize) / Float(compressedData.count)
                    
                    // Create document package
                    let package = DocumentPackage(
                        id: document.id,
                        content: document.content,
                        embedding: compressedData,
                        metadata: document.metadataDict,
                        source: document.source,
                        collection: document.collectionName
                    )
                    
                    // Write to file
                    let fileURL = self.documentURL(for: document.id)
                    let packageData = try JSONEncoder().encode(package)
                    try packageData.write(to: fileURL)
                    
                    // Create metadata
                    let metadata = DocumentMetadata(
                        id: document.id,
                        dimension: Int(document.dimension),
                        compressed: true,
                        compressionRatio: compressionRatio,
                        createdAt: document.createdAt,
                        fileOffset: 0,
                        fileSize: Int64(packageData.count),
                        checksum: self.calculateChecksum(for: packageData)
                    )
                    
                    // Update cache
                    self.metadataCache[document.id] = metadata
                    self.saveMetadataCache()
                    
                    continuation.resume(returning: metadata)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func retrieve(id: String) async throws -> StoredDocument? {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    guard let metadata = self.metadataCache[id] else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    // Read document package
                    let fileURL = self.documentURL(for: id)
                    let packageData = try Data(contentsOf: fileURL)
                    
                    // Verify checksum
                    let checksum = self.calculateChecksum(for: packageData)
                    guard checksum == metadata.checksum else {
                        throw StorageError.checksumMismatch
                    }
                    
                    // Decode package
                    let package = try JSONDecoder().decode(
                        DocumentPackage.self,
                        from: packageData
                    )
                    
                    // Decompress embedding
                    let embedding = try self.storage.decompress(data: package.embedding)
                    
                    let document = StoredDocument(
                        id: package.id,
                        content: package.content,
                        embedding: embedding,
                        metadata: package.metadata,
                        source: package.source,
                        collection: package.collection,
                        storageMetadata: metadata
                    )
                    
                    continuation.resume(returning: document)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func delete(id: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async(flags: .barrier) {
                do {
                    let fileURL = self.documentURL(for: id)
                    try self.fileManager.removeItem(at: fileURL)
                    
                    self.metadataCache.removeValue(forKey: id)
                    self.saveMetadataCache()
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Batch Operations
    
    func storeBatch(documents: [VectorDocument]) async throws -> [DocumentMetadata] {
        // Process in parallel batches for efficiency
        let batchSize = 10
        var allMetadata: [DocumentMetadata] = []
        
        for batchStart in stride(from: 0, to: documents.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, documents.count)
            let batch = Array(documents[batchStart..<batchEnd])
            
            let batchMetadata = try await withThrowingTaskGroup(of: DocumentMetadata.self) { group in
                for document in batch {
                    group.addTask {
                        try await self.store(document: document)
                    }
                }
                
                var metadata: [DocumentMetadata] = []
                for try await result in group {
                    metadata.append(result)
                }
                return metadata
            }
            
            allMetadata.append(contentsOf: batchMetadata)
        }
        
        return allMetadata
    }
    
    // MARK: - Storage Statistics
    
    func getStorageStatistics() async -> StorageStatistics {
        await withCheckedContinuation { continuation in
            queue.async {
                var totalSize: Int64 = 0
                var totalDocuments = 0
                var averageCompressionRatio: Float = 0
                
                for metadata in self.metadataCache.values {
                    totalSize += metadata.fileSize
                    totalDocuments += 1
                    if let ratio = metadata.compressionRatio {
                        averageCompressionRatio += ratio
                    }
                }
                
                if totalDocuments > 0 {
                    averageCompressionRatio /= Float(totalDocuments)
                }
                
                let stats = StorageStatistics(
                    totalDocuments: totalDocuments,
                    totalSizeBytes: totalSize,
                    averageCompressionRatio: averageCompressionRatio,
                    storageEfficiency: self.calculateStorageEfficiency()
                )
                
                continuation.resume(returning: stats)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func documentURL(for id: String) -> URL {
        // Use subdirectories to avoid too many files in one directory
        let prefix = String(id.prefix(2))
        let directory = baseURL.appendingPathComponent(prefix)
        
        try? fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        
        return directory.appendingPathComponent("\(id).vdoc")
    }
    
    private func calculateChecksum(for data: Data) -> String {
        // Simple checksum using CRC32
        var crc: UInt32 = 0
        data.withUnsafeBytes { bytes in
            for byte in bytes {
                crc = (crc >> 8) ^ crcTable[Int((crc ^ UInt32(byte)) & 0xFF)]
            }
        }
        return String(format: "%08X", crc)
    }
    
    private func loadMetadataCache() {
        let cacheURL = baseURL.appendingPathComponent("metadata.cache")
        
        guard let data = try? Data(contentsOf: cacheURL),
              let cache = try? JSONDecoder().decode(
                [String: DocumentMetadata].self,
                from: data
              ) else {
            return
        }
        
        metadataCache = cache
    }
    
    private func saveMetadataCache() {
        let cacheURL = baseURL.appendingPathComponent("metadata.cache")
        
        guard let data = try? JSONEncoder().encode(metadataCache) else {
            return
        }
        
        try? data.write(to: cacheURL)
    }
    
    private func calculateStorageEfficiency() -> Float {
        // Calculate how efficiently we're using disk space
        let optimalSize = Float(metadataCache.count * dimension * MemoryLayout<Float>.size)
        let actualSize = metadataCache.values.reduce(0) { $0 + Float($1.fileSize) }
        
        return actualSize > 0 ? optimalSize / actualSize : 0
    }
}

// MARK: - Models

struct DocumentPackage: Codable {
    let id: String
    let content: String
    let embedding: Data  // Compressed
    let metadata: [String: Any]?
    let source: String?
    let collection: String
    
    enum CodingKeys: String, CodingKey {
        case id, content, embedding, source, collection
        case metadata
    }
    
    init(
        id: String,
        content: String,
        embedding: Data,
        metadata: [String: Any]?,
        source: String?,
        collection: String
    ) {
        self.id = id
        self.content = content
        self.embedding = embedding
        self.metadata = metadata
        self.source = source
        self.collection = collection
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        embedding = try container.decode(Data.self, forKey: .embedding)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        collection = try container.decode(String.self, forKey: .collection)
        
        if let metadataData = try container.decodeIfPresent(Data.self, forKey: .metadata) {
            metadata = try JSONSerialization.jsonObject(with: metadataData) as? [String: Any]
        } else {
            metadata = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(embedding, forKey: .embedding)
        try container.encodeIfPresent(source, forKey: .source)
        try container.encode(collection, forKey: .collection)
        
        if let metadata = metadata {
            let metadataData = try JSONSerialization.data(withJSONObject: metadata)
            try container.encode(metadataData, forKey: .metadata)
        }
    }
}

struct StoredDocument {
    let id: String
    let content: String
    let embedding: [Float]
    let metadata: [String: Any]?
    let source: String?
    let collection: String
    let storageMetadata: VectorStorageManager.DocumentMetadata
}

struct StorageStatistics {
    let totalDocuments: Int
    let totalSizeBytes: Int64
    let averageCompressionRatio: Float
    let storageEfficiency: Float
    
    var totalSizeMB: Double {
        Double(totalSizeBytes) / (1024 * 1024)
    }
}

enum StorageError: LocalizedError {
    case compressionFailed
    case decompressionFailed
    case checksumMismatch
    case storageFull
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress vector data"
        case .decompressionFailed:
            return "Failed to decompress vector data"
        case .checksumMismatch:
            return "Data integrity check failed"
        case .storageFull:
            return "Storage capacity exceeded"
        }
    }
}

// CRC32 table for checksum calculation
private let crcTable: [UInt32] = {
    var table = [UInt32](repeating: 0, count: 256)
    for i in 0..<256 {
        var c = UInt32(i)
        for _ in 0..<8 {
            if c & 1 != 0 {
                c = 0xEDB88320 ^ (c >> 1)
            } else {
                c = c >> 1
            }
        }
        table[i] = c
    }
    return table
}()