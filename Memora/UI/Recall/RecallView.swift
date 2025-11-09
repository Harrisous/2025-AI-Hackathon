//
//  RecallView.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI

struct RecallPlaceholderView: View {
    @State private var sidebarExpanded = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Main content
                ZStack {
                    Palette.paper.ignoresSafeArea()
                    
                    VStack(spacing: 40) {
                        Text("Memory Training")
                            .font(.system(size: 72, design: .serif).weight(.semibold))
                            .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
                            .multilineTextAlignment(.center)
                            .padding(.top, 30)
                        
                        // Two big buttons
                        VStack(spacing: 30) {
                            NavigationLink(destination: ImageTrainingView()) {
                                HStack(spacing: 16) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 40))
                                    Text("Image Training")
                                        .font(.system(size: 36, design: .rounded).weight(.semibold))
                                }
                                .foregroundColor(.white)
                                .frame(width: 400, height: 120)
                                .background(Palette.button)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .shadow(color: Palette.shadow, radius: 12, x: 0, y: 6)
                            }
                            
                            NavigationLink(destination: TextTrainingView()) {
                                HStack(spacing: 16) {
                                    Image(systemName: "text.bubble")
                                        .font(.system(size: 40))
                                    Text("Text Training")
                                        .font(.system(size: 36, design: .rounded).weight(.semibold))
                                }
                                .foregroundColor(.white)
                                .frame(width: 400, height: 120)
                                .background(Palette.button)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .shadow(color: Palette.shadow, radius: 12, x: 0, y: 6)
                            }
                        }
                        .padding(.top, 60)
                        
                        Spacer()
                    }
                }
                
                // Foldable sidebar
                FoldableSidebar(isExpanded: $sidebarExpanded)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        RecallPlaceholderView()
    }
    .previewInterfaceOrientation(.landscapeLeft)
    .previewLayout(.fixed(width: 1180, height: 820))
}

