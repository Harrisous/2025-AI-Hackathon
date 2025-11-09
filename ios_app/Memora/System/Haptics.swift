//
//  Haptics.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import UIKit

enum Haptics {
    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
}

