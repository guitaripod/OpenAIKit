import Foundation
import CoreData

// MARK: - Vector Database Model

// Core Data model for vector storage
@objc(VectorDocument)
public class VectorDocument: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var content: String
    @NSManaged public var embeddingData: Data
    @NSManaged public var metadata: Data?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var dimension: Int32
    @NSManaged public var source: String?
    @NSManaged public var collectionName: String
    
    // Computed property for embedding vector
    var embedding: [Float] {
        get {
            guard let array = try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: NSArray.self,
                from: embeddingData
            ) as? [Float] else {
                return []
            }
            return array
        }
        set {
            embeddingData = try! NSKeyedArchiver.archivedData(
                withRootObject: newValue,
                requiringSecureCoding: false
            )
            dimension = Int32(newValue.count)
        }
    }
    
    // Computed property for metadata dictionary
    var metadataDict: [String: Any]? {
        get {
            guard let data = metadata else { return nil }
            return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        }
        set {
            metadata = newValue != nil ? try? JSONSerialization.data(withJSONObject: newValue!) : nil
        }
    }
}

// MARK: - Vector Database Protocol

protocol VectorDatabase {
    func insert(document: VectorDocumentInput) async throws -> String
    func insertBatch(documents: [VectorDocumentInput]) async throws -> [String]
    func search(query: VectorQuery) async throws -> [VectorSearchResult]
    func update(id: String, document: VectorDocumentInput) async throws
    func delete(id: String) async throws
    func deleteCollection(name: String) async throws
    func count(in collection: String?) async throws -> Int
}

// MARK: - Core Data Vector Database

class CoreDataVectorDatabase: VectorDatabase {
    private let container: NSPersistentContainer
    private let queue = DispatchQueue(label: "vectordb.coredata", attributes: .concurrent)
    
    init(modelName: String = "VectorDB") {
        container = NSPersistentContainer(name: modelName)
        setupCoreData()
    }
    
    private func setupCoreData() {
        // Create model programmatically if needed
        let model = NSManagedObjectModel()
        
        // VectorDocument entity
        let vectorEntity = NSEntityDescription()
        vectorEntity.name = "VectorDocument"
        vectorEntity.managedObjectClassName = "VectorDocument"
        
        // Add attributes
        let attributes: [(String, NSAttributeType, Bool)] = [
            ("id", .stringAttributeType, false),
            ("content", .stringAttributeType, false),
            ("embeddingData", .binaryDataAttributeType, false),
            ("metadata", .binaryDataAttributeType, true),
            ("createdAt", .dateAttributeType, false),
            ("updatedAt", .dateAttributeType, false),
            ("dimension", .integer32AttributeType, false),
            ("source", .stringAttributeType, true),
            ("collectionName", .stringAttributeType, false)
        ]
        
        var properties: [NSPropertyDescription] = []
        
        for (name, type, optional) in attributes {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            properties.append(attribute)
        }
        
        vectorEntity.properties = properties
        model.entities = [vectorEntity]
        
        container.persistentStoreDescriptions.first?.setOption(
            true as NSNumber,
            forKey: NSPersistentHistoryTrackingKey
        )
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
        }
    }
    
    func insert(document: VectorDocumentInput) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    let vectorDoc = VectorDocument(context: context)
                    vectorDoc.id = document.id ?? UUID().uuidString
                    vectorDoc.content = document.content
                    vectorDoc.embedding = document.embedding
                    vectorDoc.metadataDict = document.metadata
                    vectorDoc.createdAt = Date()
                    vectorDoc.updatedAt = Date()
                    vectorDoc.source = document.source
                    vectorDoc.collectionName = document.collection ?? "default"
                    
                    try context.save()
                    continuation.resume(returning: vectorDoc.id)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func insertBatch(documents: [VectorDocumentInput]) async throws -> [String] {
        return try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                context.undoManager = nil  // Disable undo for performance
                
                var ids: [String] = []
                
                do {
                    for document in documents {
                        let vectorDoc = VectorDocument(context: context)
                        vectorDoc.id = document.id ?? UUID().uuidString
                        vectorDoc.content = document.content
                        vectorDoc.embedding = document.embedding
                        vectorDoc.metadataDict = document.metadata
                        vectorDoc.createdAt = Date()
                        vectorDoc.updatedAt = Date()
                        vectorDoc.source = document.source
                        vectorDoc.collectionName = document.collection ?? "default"
                        
                        ids.append(vectorDoc.id)
                    }
                    
                    try context.save()
                    continuation.resume(returning: ids)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func search(query: VectorQuery) async throws -> [VectorSearchResult] {
        return try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    // Fetch all documents from collection
                    let request = VectorDocument.fetchRequest()
                    
                    if let collection = query.collection {
                        request.predicate = NSPredicate(format: "collectionName == %@", collection)
                    }
                    
                    let documents = try context.fetch(request)
                    
                    // Calculate similarities
                    var results: [VectorSearchResult] = []
                    
                    for doc in documents {
                        let similarity = SimilarityCalculator.cosineSimilarity(
                            query.vector,
                            doc.embedding
                        )
                        
                        if similarity >= query.threshold {
                            results.append(VectorSearchResult(
                                id: doc.id,
                                content: doc.content,
                                similarity: similarity,
                                metadata: doc.metadataDict,
                                embedding: doc.embedding
                            ))
                        }
                    }
                    
                    // Sort by similarity and limit
                    results.sort { $0.similarity > $1.similarity }
                    if let limit = query.limit {
                        results = Array(results.prefix(limit))
                    }
                    
                    continuation.resume(returning: results)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func update(id: String, document: VectorDocumentInput) async throws {
        try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    let request = VectorDocument.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", id)
                    
                    guard let vectorDoc = try context.fetch(request).first else {
                        throw VectorDatabaseError.documentNotFound(id: id)
                    }
                    
                    vectorDoc.content = document.content
                    vectorDoc.embedding = document.embedding
                    vectorDoc.metadataDict = document.metadata
                    vectorDoc.updatedAt = Date()
                    
                    if let source = document.source {
                        vectorDoc.source = source
                    }
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func delete(id: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    let request = VectorDocument.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", id)
                    
                    guard let vectorDoc = try context.fetch(request).first else {
                        throw VectorDatabaseError.documentNotFound(id: id)
                    }
                    
                    context.delete(vectorDoc)
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func deleteCollection(name: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    let request = VectorDocument.fetchRequest()
                    request.predicate = NSPredicate(format: "collectionName == %@", name)
                    
                    let documents = try context.fetch(request)
                    for doc in documents {
                        context.delete(doc)
                    }
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func count(in collection: String? = nil) async throws -> Int {
        return try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    let request = VectorDocument.fetchRequest()
                    
                    if let collection = collection {
                        request.predicate = NSPredicate(format: "collectionName == %@", collection)
                    }
                    
                    let count = try context.count(for: request)
                    continuation.resume(returning: count)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Models

struct VectorDocumentInput {
    let id: String?
    let content: String
    let embedding: [Float]
    let metadata: [String: Any]?
    let source: String?
    let collection: String?
}

struct VectorQuery {
    let vector: [Float]
    let limit: Int?
    let threshold: Float
    let collection: String?
    let filter: NSPredicate?
}

struct VectorSearchResult {
    let id: String
    let content: String
    let similarity: Float
    let metadata: [String: Any]?
    let embedding: [Float]
}

enum VectorDatabaseError: LocalizedError {
    case documentNotFound(id: String)
    case invalidEmbedding
    case collectionNotFound(name: String)
    
    var errorDescription: String? {
        switch self {
        case .documentNotFound(let id):
            return "Document with ID '\(id)' not found"
        case .invalidEmbedding:
            return "Invalid embedding vector"
        case .collectionNotFound(let name):
            return "Collection '\(name)' not found"
        }
    }
}