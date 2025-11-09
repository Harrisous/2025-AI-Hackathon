//
//  LaunchScreenView.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI

struct LaunchScreenView: View {
    @Binding var isPresented: Bool
    var onFadeOutStart: (() -> Void)? = nil // Callback when fade out starts
    @State private var backgroundOpacity: Double = 0
    @State private var textRevealProgress: Double = 0
    @State private var textScale: Double = 0.9
    @State private var fadeOutProgress: Double = 0 // For right-to-left fade out
    
    private let quote = "   Every memory we keep is a story worth retelling"
    private let darkBrown = Color(red: 0.35, green: 0.25, blue: 0.20) // Dark brown color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background image with fade-in - fully covers screen with no gaps
                Image("LaunchPage")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .scaleEffect(1.2) // Scale up to ensure full coverage even with safe areas
                    .clipped()
                    .ignoresSafeArea(.all, edges: .all)
                    .opacity(backgroundOpacity)
                
                // Text overlay
                VStack {
                    Spacer()
                    
                    Text(quote)
                        .font(.system(size: 42, design: .serif).italic())
                        .foregroundColor(darkBrown)
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .padding(.horizontal, 50)
                        .offset(x: 40) // Move text slightly to the right
                        .scaleEffect(textScale)
                        .frame(maxWidth: .infinity)
                        .mask(
                            // Left-to-right reveal mask (like being written)
                            GeometryReader { textGeometry in
                                HStack(spacing: 0) {
                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(width: textGeometry.size.width * textRevealProgress)
                                    Spacer()
                                }
                            }
                        )
                        .opacity(textRevealProgress > 0 ? 1 : 0)
                        .padding(.top,800)
      
                    Spacer()
                }
                
                // Right-to-left fade out mask
                HStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: geometry.size.width * fadeOutProgress)
                }
                .opacity(fadeOutProgress > 0 ? 1 : 0)
                .allowsHitTesting(false)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .mask(
                // Right-to-left fade out mask
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * (1 - fadeOutProgress))
                    Spacer()
                }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all, edges: .all)
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Background fade-in: 2 seconds
        withAnimation(.easeIn(duration: 2.0)) {
            backgroundOpacity = 1.0
        }
        
        // Text reveal: 4 seconds (left to right with scale-up)
        // Small delay to let background start fading in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Scale-up animation (gentle enlargement)
            withAnimation(.easeOut(duration: 4.0)) {
                textScale = 1.0
            }
            
            // Left-to-right reveal animation (like being written)
            withAnimation(.linear(duration: 4.0)) {
                textRevealProgress = 1.0
            }
        }
        
        // Right-to-left fade out transition after animations complete
        // Wait for text animation to complete (2s background + 4s text + 0.5s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.5) {
            // Notify that fade out is starting (so homepage can fade in)
            onFadeOutStart?()
            
            // Start right-to-left fade out animation (smooth wipe from right to left)
            withAnimation(.easeInOut(duration: 1.5)) {
                fadeOutProgress = 1.0
            }
            
            // Hide launch screen after fade out animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // Small delay to ensure smooth transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPresented = false
                }
            }
        }
    }
}

#Preview {
    LaunchScreenView(isPresented: .constant(true))
        .previewInterfaceOrientation(.landscapeLeft)
        .previewLayout(.fixed(width: 1180, height: 820))
}

