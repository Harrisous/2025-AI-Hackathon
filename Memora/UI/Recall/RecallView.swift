//
//  RecallView.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI

struct RecallPlaceholderView: View {
    var body: some View {
        ZStack {
            Palette.paper.ignoresSafeArea()
            
            VStack(spacing: 28) {
                // Title at top middle
                Text("Memory Recall")
                    .font(.system(size: 72, design: .serif).weight(.semibold))
                    .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
                    .multilineTextAlignment(.center)
                    .padding(.top, 30)
                
                Spacer()
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

