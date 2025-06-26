// PersistentMemory.swift
import Foundation
import CoreData

class PersistentMemoryStore: MemoryStore {
    private let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "ConversationMemory")
        
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data failed to load: \(error)")
            }
        }
    }
    
    func store(key: String, value: Any) async {
        let context = container.viewContext
        
        await context.perform {
            let memory = MemoryEntity(context: context)
            memory.id = UUID()
            memory.key = key
            memory.value = String(describing: value)
            memory.timestamp = Date()
            memory.embedding = nil // Store embedding data if needed
            
            do {
                try context.save()
            } catch {
                print("Failed to save memory: \(error)")
            }
        }
    }
    
    func retrieve(key: String) async -> Any? {
        let context = container.viewContext
        let request = MemoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "key == %@", key)
        request.fetchLimit = 1
        
        return await context.perform {
            do {
                let memories = try context.fetch(request)
                return memories.first?.value
            } catch {
                print("Failed to retrieve memory: \(error)")
                return nil
            }
        }
    }
    
    func search(query: String) async -> [MemoryItem] {
        let context = container.viewContext
        let request = MemoryEntity.fetchRequest()
        
        // Search in both key and value
        request.predicate = NSPredicate(
            format: "key CONTAINS[cd] %@ OR value CONTAINS[cd] %@",
            query, query
        )
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = 20
        
        return await context.perform {
            do {
                let entities = try context.fetch(request)
                return entities.map { entity in
                    MemoryItem(
                        key: entity.key ?? "",
                        value: entity.value ?? "",
                        timestamp: entity.timestamp ?? Date(),
                        metadata: [:],
                        relevanceScore: nil
                    )
                }
            } catch {
                print("Failed to search memories: \(error)")
                return []
            }
        }
    }
    
    func clear() async {
        let context = container.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MemoryEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        await context.perform {
            do {
                try context.execute(deleteRequest)
                try context.save()
            } catch {
                print("Failed to clear memories: \(error)")
            }
        }
    }
}

// Core Data Model (create in .xcdatamodeld file)
/*
Entity: MemoryEntity
Attributes:
- id: UUID
- key: String
- value: String
- timestamp: Date
- embedding: Binary (optional)
- metadata: Binary (optional)
*/