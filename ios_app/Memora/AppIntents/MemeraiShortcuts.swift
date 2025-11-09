import AppIntents

struct MemeraiAppShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        
        AppShortcut(
            // Link to the Action we defined
            intent: StartMemoryRecallIntent(),
            
            // THE FIX: Every phrase MUST include \(.applicationName)
            phrases: [
                "Start memory training in \(.applicationName)",
                "Start \(.applicationName) memory recall",
                "Open \(.applicationName) and start training"
            ],
            
            // Short title for the Shortcuts app
            shortTitle: "Start Memory Recall",
            
            // System icon
            systemImageName: "brain.head.profile"
        )
    }
}
