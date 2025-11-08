//
//  Theme.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI

enum Palette {
    static let background = Color("Cream")
    static let paper      = Color("Paper")
    static let ink        = Color("Ink")
    static let blush      = Color("Blush")
    static let blueGray   = Color("BlueGray")
    static let shadow     = Color.black.opacity(0.08)
}

enum TypeStyle {
    static let title = Font.system(.largeTitle, design: .serif).weight(.semibold)   // use .serif for “Journal” feel
    static let sub   = Font.system(.title3, design: .serif)
    static let body  = Font.system(.title3, design: .rounded)                       // SF Rounded for body
}

struct JournalCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Palette.paper)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Palette.shadow, radius: 12, x: 0, y: 8)
    }
}
extension View { func journalCard() -> some View { modifier(JournalCard()) } }

