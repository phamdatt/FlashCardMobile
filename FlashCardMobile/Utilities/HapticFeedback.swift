//
//  HapticFeedback.swift
//  FlashCardMobile
//

import SwiftUI
import UIKit

enum HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

/// ButtonStyle that adds haptic on press. Use instead of .plain for tappable buttons.
struct HapticButtonStyle: ButtonStyle {
    var style: UIImpactFeedbackGenerator.FeedbackStyle = .light

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, new in
                if new {
                    HapticFeedback.impact(style)
                }
            }
    }
}
