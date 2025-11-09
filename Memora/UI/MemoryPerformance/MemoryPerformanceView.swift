//
//  MemoryPerformanceView.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI

struct MemoryPerformanceView: View {
    @State private var sidebarExpanded = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ZStack {
                    Palette.paper.ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("Memory Performance")
                            .font(.system(size: 72, design: .serif).weight(.semibold))
                            .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
                            .multilineTextAlignment(.center)
                            .padding(.top, 30)
                        
                        Text("Memory performance tracking coming soon...")
                            .font(.system(size: 24, design: .rounded))
                            .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145).opacity(0.8))
                        
                        Spacer()
                    }
                }
                
                FoldableSidebar(isExpanded: $sidebarExpanded)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        MemoryPerformanceView()
    }
    .previewInterfaceOrientation(.landscapeLeft)
    .previewLayout(.fixed(width: 1180, height: 820))
}

