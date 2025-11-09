//
//  RecallView.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI

struct RecallPlaceholderView: View {
    @StateObject private var trainingViewModel: MemoryTrainingViewModel
    @State private var sidebarExpanded = false
    
    init() {
        // Initialize memory training view model with backend URL and API key
        _trainingViewModel = StateObject(wrappedValue: MemoryTrainingViewModel(
            backendURL: APIConfig.memoryTrainingBackendURL,
            apiKey: APIConfig.openAIAPIKey
        ))
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Main content
                ZStack {
                    Palette.paper.ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        // Title at top middle
                        Text("Memory Training")
                            .font(.system(size: 72, design: .serif).weight(.semibold))
                            .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
                            .multilineTextAlignment(.center)
                            .padding(.top, 30)
                        
                        // Progress indicator
                        if trainingViewModel.phase == .training {
                            HStack {
                                Text("Question \(trainingViewModel.currentQuestionNumber)/\(trainingViewModel.totalQuestions)")
                                    .font(.system(size: 20, design: .rounded))
                                    .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145).opacity(0.7))
                                Spacer()
                            }
                            .padding(.horizontal, 30)
                        }
                        
                        // Chat box - narrower and longer
                        MemoryTrainingChatView(viewModel: trainingViewModel)
                            .frame(width: geo.size.width * 0.95, height: geo.size.height * 0.85)
                            .frame(maxWidth: 800)
                            .padding(.top, trainingViewModel.phase == .training ? 10 : 50)
                        
                        Spacer()
                    }
                }
                
                // Foldable sidebar
                FoldableSidebar(isExpanded: $sidebarExpanded)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Start session when view appears
            if trainingViewModel.phase == .notStarted {
                trainingViewModel.startSession()
            }
        }
    }
}

#Preview {
    NavigationStack {
        RecallPlaceholderView()
    }
    .previewInterfaceOrientation(.landscapeLeft)
    .previewLayout(.fixed(width: 1180, height: 820))
}

