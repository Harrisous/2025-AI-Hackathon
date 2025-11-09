//
//  PageFlipTransition.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI

extension AnyTransition {
    static var pageFlip: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: PageFlipModifier(rotation: -90, scale: 0.8, opacity: 0),
                identity: PageFlipModifier(rotation: 0, scale: 1.0, opacity: 1)
            ),
            removal: .modifier(
                active: PageFlipModifier(rotation: 90, scale: 0.8, opacity: 0),
                identity: PageFlipModifier(rotation: 0, scale: 1.0, opacity: 1)
            )
        )
    }
}

struct PageFlipModifier: ViewModifier {
    let rotation: Double
    let scale: CGFloat
    let opacity: Double
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(rotation),
                axis: (x: 0, y: 1, z: 0),
                anchor: .trailing,
                perspective: 0.3
            )
            .scaleEffect(scale)
            .opacity(opacity)
    }
}

