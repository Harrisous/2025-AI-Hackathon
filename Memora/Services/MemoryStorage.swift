//
//  MemoryStorage.swift
//  Memerai
//
//  Created by Rae Wang on 11/9/25.
//


//
//  MemoryStorage.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import Foundation
import UIKit

class MemoryStorage: ObservableObject {
    static let shared = MemoryStorage()
    
    @Published var memories: [MemoryEntry] = []
    
    private let memoriesKey = "saved_memories"
    private let documentsDirectory: URL
    
    private init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        loadMemories()
    }
    
    // MARK: - Memory Management
    
    func addMemory(personName: String, image: UIImage) -> Bool {
        // Generate unique filename
        let imageName = "\(UUID().uuidString).jpg"
        let imagePath = documentsDirectory.appendingPathComponent(imageName)
        
        // Save image to disk
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return false
        }
        
        do {
            try imageData.write(to: imagePath)
            
            // Create memory entry
            let memory = MemoryEntry(personName: personName, imagePath: imageName)
            
            // Add to array and save
            memories.append(memory)
            saveMemories()
            
            return true
        } catch {
            print("Failed to save image: \(error)")
            return false
        }
    }
    
    func deleteMemory(_ memory: MemoryEntry) {
        // Remove image file
        let imagePath = documentsDirectory.appendingPathComponent(memory.imagePath)
        try? FileManager.default.removeItem(at: imagePath)
        
        // Remove from array
        memories.removeAll { $0.id == memory.id }
        saveMemories()
    }
    
    func getImage(for memory: MemoryEntry) -> UIImage? {
        let imagePath = documentsDirectory.appendingPathComponent(memory.imagePath)
        guard let imageData = try? Data(contentsOf: imagePath) else {
            return nil
        }
        return UIImage(data: imageData)
    }
    
    // MARK: - Persistence
    
    private func saveMemories() {
        if let encoded = try? JSONEncoder().encode(memories) {
            UserDefaults.standard.set(encoded, forKey: memoriesKey)
        }
    }
    
    private func loadMemories() {
        if let data = UserDefaults.standard.data(forKey: memoriesKey),
           let decoded = try? JSONDecoder().decode([MemoryEntry].self, from: data) {
            memories = decoded
        }
    }
}
