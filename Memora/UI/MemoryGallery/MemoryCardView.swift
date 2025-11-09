//
//  MemoryCardView.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI

struct MemoryCardView: View {
    let memory: MemoryEntry
    let image: UIImage?
    let onDelete: () -> Void
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Image
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(Color.gray.opacity(0.5))
                    )
            }
            
            // Person name
            Text(memory.personName)
                .font(.system(size: 20, design: .rounded).weight(.bold))
                .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145)) // Dark brown color
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 200)
        }
        .padding(16)
        .background(Palette.paper)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Palette.shadow, radius: 8, x: 0, y: 4)
        .overlay(
            // Delete button
            Button(action: {
                showDeleteConfirmation = true
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red)
                    .background(Color.white.clipShape(Circle()))
            }
            .offset(x: 90, y: -90),
            alignment: .topTrailing
        )
        .confirmationDialog("Delete Memory", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this memory?")
        }
    }
}

