//
//  TextTrainingView.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI

struct TextTrainingView: View {
    @StateObject private var viewModel: TextTrainingViewModel
    @State private var sidebarExpanded = false
    
    init() {
        _viewModel = StateObject(wrappedValue: TextTrainingViewModel(
            baseURL: APIConfig.textTrainingBackendURL,
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
                        Text("Text Training")
                            .font(.system(size: 72, design: .serif).weight(.semibold))
                            .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
                            .multilineTextAlignment(.center)
                            .padding(.top, 30)
                        
                        // Score display
                        if let score = viewModel.score {
                            HStack(spacing: 12) {
                                Text("Score: \(score.correct)/\(score.total)")
                                    .font(.system(size: 24, design: .rounded).weight(.semibold))
                                    .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        
                        // Chat box
                        TextTrainingChatView(viewModel: viewModel)
                            .frame(width: geo.size.width * 0.95, height: geo.size.height * 0.75)
                            .frame(maxWidth: 800)
                            .padding(.top, 50)
                        
                        Spacer()
                    }
                }
                
                // Foldable sidebar
                FoldableSidebar(isExpanded: $sidebarExpanded)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if viewModel.sessionId == nil {
                viewModel.startSession()
            }
        }
    }
}

#Preview {
    NavigationStack {
        TextTrainingView()
    }
    .previewInterfaceOrientation(.landscapeLeft)
    .previewLayout(.fixed(width: 1180, height: 820))
}

