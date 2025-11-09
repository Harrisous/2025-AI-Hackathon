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
    static let recallButton = Color(hex: "E2B59A") // Easy to adjust
    static let settingColor    = Color(hex:"016B61")
    static let button = Color (hex:"9ECFD4")
}

enum TypeStyle {
    static let title = Font.system(.largeTitle, design: .serif).weight(.semibold)   // use .serif for "Journal" feel
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

// Color extension for hex strings
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

