//
//  FoldableSidebar.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI

struct FoldableSidebar: View {
    @Binding var isExpanded: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if isExpanded {
                // Expanded menu
                VStack(alignment: .leading, spacing: 0) {
                    // Menu items
                    VStack(alignment: .leading, spacing: 16) {
                        NavigationLink {
                            HomeView()
                        } label: {
                            MenuItemView(icon: "house.fill", title: "Home")
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink {
                            MemoryTestView()
                        } label: {
                            MenuItemView(icon: "brain.head.profile", title: "Memory Test")
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink {
                            MemoryGalleryView()
                        } label: {
                            MenuItemView(icon: "photo.on.rectangle", title: "Memory Gallery")
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink {
                            SettingsView()
                        } label: {
                            MenuItemView(icon: "gearshape.fill", title: "Settings")
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .padding(.top, 80)
                    
                    Spacer()
                }
                .frame(width: 280)
                .background(Palette.paper.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
                .shadow(color: Palette.shadow, radius: 20, x: 5, y: 0)
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
            
            // Circle button (always visible)
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 60, height: 60)
                        .shadow(color: Palette.shadow, radius: 8, x: 0, y: 4)
                    
                    Image(systemName: isExpanded ? "xmark" : "line.3.horizontal")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
                }
            }
            .padding(20)
            .zIndex(1)
        }
    }
}

struct MenuItemView: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
                .frame(width: 32)
            
            Text(title)
                .font(.system(size: 20, design: .rounded).weight(.semibold))
                .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

