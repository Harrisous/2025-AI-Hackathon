//
//  AppIntents+Notification.swift
//  Memerai
//
//  Created by Rae Wang on 11/8/25.
//
import Foundation

// This creates a unique "channel name" that our
// App Intent and our HomeView can both use.
extension Notification.Name {
    
    // We'll name our notification "startMemoryRecall"
    // You can replace "com.your-app-name" with your app's bundle ID
    static let startMemoryRecall = Notification.Name("com.your-app-name.startMemoryRecall")
}
