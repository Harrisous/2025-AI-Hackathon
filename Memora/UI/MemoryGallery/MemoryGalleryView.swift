//
//  MemoryGalleryView.swift
//  Memerai
//
//  Created by Rae Wang on 11/9/25.
//


//
//  MemoryGalleryView.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI

struct MemoryGalleryView: View {
    @ObservedObject private var memoryStorage = MemoryStorage.shared
    @State private var sidebarExpanded = false
    @State private var showAddMemory = false
    
    let columns = [
        GridItem(.adaptive(minimum: 220), spacing: 20)
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ZStack {
                    Palette.paper.ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        // Title
                        Text("Memory Gallery")
                            .font(.system(size: 72, design: .serif).weight(.semibold))
                            .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
                            .multilineTextAlignment(.center)
                            .padding(.top, 30)
                        
                        // Add Memory Button
                        Button(action: {
                            showAddMemory = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                Text("Upload Image")
                                    .font(.system(size: 24, design: .rounded).weight(.semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 30)
                            .background(Palette.recallButton)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Palette.shadow, radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 10)
                        
                        // Memory Grid
                        if memoryStorage.memories.isEmpty {
                            VStack(spacing: 20) {
                                Spacer()
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 60))
                                    .foregroundColor(Palette.ink.opacity(0.3))
                                Text("No memories yet")
                                    .font(.system(size: 24, design: .rounded))
                                    .foregroundColor(Palette.ink.opacity(0.6))
                                Text("Tap 'Add Memory' to get started")
                                    .font(.system(size: 18, design: .rounded))
                                    .foregroundColor(Palette.ink.opacity(0.5))
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 30) {
                                    ForEach(memoryStorage.memories) { memory in
                                        MemoryCardView(
                                            memory: memory,
                                            image: memoryStorage.getImage(for: memory)
                                        ) {
                                            memoryStorage.deleteMemory(memory)
                                        }
                                    }
                                }
                                .padding(.horizontal, 40)
                                .padding(.vertical, 20)
                            }
                        }
                    }
                }
                
                FoldableSidebar(isExpanded: $sidebarExpanded)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddMemory) {
            AddMemoryView(memoryStorage: memoryStorage)
        }
    }
}

#Preview {
    NavigationStack {
        MemoryGalleryView()
    }
    .previewInterfaceOrientation(.landscapeLeft)
    .previewLayout(.fixed(width: 1180, height: 820))
}
