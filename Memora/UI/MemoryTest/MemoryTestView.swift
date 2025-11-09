//
//  MemoryTestView.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI

struct MemoryTestView: View {
    @State private var sidebarExpanded = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ZStack {
                    Palette.paper.ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Title
                        Text("MoCA Memory Test")
                            .font(.system(size: 68, design: .serif).weight(.semibold))
                            .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
                            .multilineTextAlignment(.center)
                            .padding(.top, 30)
                            .padding(.bottom, 20)
                        
                        // PDF Viewer
                        PDFKitView(fileName: "MoCA")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
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
        MemoryTestView()
    }
    .previewInterfaceOrientation(.landscapeLeft)
    .previewLayout(.fixed(width: 1180, height: 820))
}

