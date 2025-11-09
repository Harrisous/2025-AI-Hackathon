import AppIntents
import Foundation

struct StartMemoryRecallIntent: AppIntent {
    
    // This is just a friendly name for the
    // Shortcuts app, so a user could find it manually.
    static var title: LocalizedStringResource = "Start Memory Recall"
    
    // THIS IS KEY: This line tells Siri
    // "Launch the app into the foreground."
    static var openAppWhenRun: Bool = true

    // This is the function that runs when Siri hears the phrase.
    @MainActor
    func perform() async throws -> some IntentResult {
        
        // THIS IS THE "DEEP LINK":
        // This line sends a "secret message" (a Notification)
        // inside your app on the "startMemoryRecall" channel.
        NotificationCenter.default.post(
            name: .startMemoryRecall,
            object: nil
        )
        
        // This just tells Siri "Everything worked!"
        return .result()
    }
}
