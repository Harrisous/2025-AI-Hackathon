//
//  ImageTrainingView.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI

struct ImageTrainingView: View {
    @StateObject private var viewModel: ImageTrainingViewModel
    @Environment(\.dismiss) private var dismiss
    
    init() {
        _viewModel = StateObject(wrappedValue: ImageTrainingViewModel(
            baseURL: APIConfig.imageTrainingBackendURL,
            apiKey: APIConfig.openAIAPIKey
        ))
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Palette.paper.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Back button and Title
                    HStack {
                        // Back button
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 18, design: .rounded).weight(.semibold))
                            }
                            .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .shadow(color: Palette.shadow, radius: 4, x: 0, y: 2)
                        }
                        .padding(.leading, 40)
                        
                        Spacer()
                        
                        // Title at top middle
                        VStack(spacing: 12) {
                            Text("Image Training")
                                .font(.system(size: 58, design: .serif).weight(.semibold))
                                .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
                                .multilineTextAlignment(.center)
                            
                            // Score display (below title)
                            if let score = viewModel.score {
                                HStack(spacing: 12) {
                                    Text("Score: \(score.correct)/\(score.total)")
                                        .font(.system(size: 20, design: .rounded).weight(.semibold))
                                        .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                        
                        Spacer()
                        
                        // Spacer to balance the back button
                        Color.clear
                            .frame(width: 120)
                            .padding(.trailing, 40)
                    }
                    .padding(.top, 30)
                    .frame(height: 120)
                    
                    // Split screen 50/50: Image (top) and Chat (bottom)
                    VStack(spacing: 20) {
                        // Top half: Image display
                        VStack {
                            if let imageUrlString = viewModel.currentImageUrl,
                               let imageUrl = URL(string: imageUrlString) {
                                AsyncImage(url: imageUrl) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                            .shadow(color: Palette.shadow, radius: 8, x: 0, y: 4)
                                    case .failure:
                                        Image(systemName: "photo")
                                            .font(.system(size: 60))
                                            .foregroundColor(.gray)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else {
                                // Placeholder when no image
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.5))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .overlay(
                                        ProgressView()
                                            .scaleEffect(1.5)
                                    )
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        // Bottom half: Chat view
                        ImageTrainingChatView(viewModel: viewModel)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    .frame(height: max(0, geo.size.height - 140))
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
        ImageTrainingView()
    }
    .previewInterfaceOrientation(.landscapeLeft)
    .previewLayout(.fixed(width: 1180, height: 820))
}

