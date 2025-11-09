//
//  NotificationManager.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification authorization granted")
                self.scheduleDailyReminder()
            } else if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }
    
    func scheduleDailyReminder() {
        // Remove existing notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyMemoryRecall"])
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Memory Recall Time"
        content.body = "It's time for your daily memory recall training! Open Memora to continue your journey."
        content.sound = .default
        content.badge = 1
        
        // Create date components for 3:10 PM
        var dateComponents = DateComponents()
        dateComponents.hour = 15 // 3 PM
        dateComponents.minute = 10 // 10 minutes
        
        // Create trigger for daily recurrence
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "dailyMemoryRecall",
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Daily reminder scheduled for 3:10 PM")
            }
        }
    }
    
    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyMemoryRecall"])
    }
}

