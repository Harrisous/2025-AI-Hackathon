//
//  MemoryEntry.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import Foundation
import UIKit

struct MemoryEntry: Identifiable, Codable {
    let id: UUID
    let personName: String
    let imagePath: String
    let createdAt: Date
    
    init(id: UUID = UUID(), personName: String, imagePath: String, createdAt: Date = Date()) {
        self.id = id
        self.personName = personName
        self.imagePath = imagePath
        self.createdAt = createdAt
    }
}

