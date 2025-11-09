//
//  MemoraApp.swift
//  Memora
//
//  Created by Rae Wang on 11/7/25.
//

import SwiftUI

@main
struct MemoraApp: App {
    @State private var showLaunchScreen = true
    
    init() {
        // Request notification permissions and schedule daily reminder
        NotificationManager.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(showLaunchScreen: $showLaunchScreen)
        }
    }
}

struct ContentView: View {
    @Binding var showLaunchScreen: Bool
    @Environment(\.scenePhase) var scenePhase
    @State private var homeOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Main app content - always present, fades in as launch screen fades out
            NavigationStack {
                HomeView()
            }
            .opacity(showLaunchScreen ? homeOpacity : 1.0)
            
            // Launch screen (fades out from right to left)
            if showLaunchScreen {
                LaunchScreenView(
                    isPresented: $showLaunchScreen,
                    onFadeOutStart: {
                        // Start fading in homepage when launch screen begins to fade out
                        withAnimation(.easeInOut(duration: 1.5)) {
                            homeOpacity = 1.0
                        }
                    }
                )
                .zIndex(1)
            }
        }
        .background(Color.clear) // Ensure no white background
        .ignoresSafeArea(.all) // Ignore safe areas to prevent white strips
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                // Reschedule notifications when app becomes active
                NotificationManager.shared.scheduleDailyReminder()
            }
        }
    }
}
