//
//  TextTrainingView.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI

struct TextTrainingView: View {
    @StateObject private var viewModel: TextTrainingViewModel
    @Environment(\.dismiss) private var dismiss
    
    init() {
        _viewModel = StateObject(wrappedValue: TextTrainingViewModel(
            baseURL: APIConfig.textTrainingBackendURL,
            apiKey: APIConfig.openAIAPIKey
        ))
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Palette.paper.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Back button and Title
                    HStack {
                        // Back button
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 20, design: .rounded).weight(.semibold))
                            }
                            .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: Palette.shadow, radius: 4, x: 0, y: 2)
                        }
                        .padding(.leading, 40)
                        
                        Spacer()
                        
                        // Title at top middle
                        Text("Text Training")
                            .font(.system(size: 72, design: .serif).weight(.semibold))
                            .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                        
                        // Spacer to balance the back button
                        Color.clear
                            .frame(width: 120)
                            .padding(.trailing, 40)
                    }
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

