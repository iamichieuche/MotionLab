//
//  Colors.swift
//  MotionLab
//
//  Design system colour tokens — sourced from Figma (jmaSq07PeuWliZKQLJo7sx)
//
//  Usage:   Text("Hello").foregroundColor(Color.content)
//           Color.background.ignoresSafeArea()
//
//  Tokens adapt automatically to light/dark mode.
//  Named to match Figma exactly so there's no translation layer.

import SwiftUI

extension Color {

    // MARK: - Backgrounds
    // Light: green-tinted off-white (#F2F8F3)   Dark: deep navy (#091723)
    static let background = Color(
        light: Color(hex: "#F2F8F3"),
        dark:  Color(hex: "#091723")
    )
    // Non-conflicting alias for use in view bodies.
    // `Color.background` clashes with SwiftUI's ShapeStyle.background protocol member
    // (which requires Self == BackgroundStyle), causing a compiler error when used
    // directly in views. `Color.page` is identical but unambiguous.
    static let page = Color(
        light: Color(hex: "#F2F8F3"),
        dark:  Color(hex: "#091723")
    )
    // Light: white   Dark: section/card surface — one step lighter than page (#162535)
    static let backgroundSecondary = Color(
        light: .white,
        dark:  Color(hex: "#162535")
    )
    // Light: same as background   Dark: nested card surface — one step lighter than section (#1E2D3C)
    static let backgroundTertiary = Color(
        light: Color(hex: "#F2F8F3"),
        dark:  Color(hex: "#1E2D3C")
    )
    // 10% navy600 in both modes — used for selected/pressed states
    static let backgroundSelected = Color(hex: "#3B4C54").opacity(0.1)

    // MARK: - Content (text & icons)
    // Light: navy900   Dark: white
    static let content = Color(
        light: Color(hex: "#091723"),
        dark:  .white
    )
    // Light: 60% navy900   Dark: 60% white
    static let contentSecondary = Color(
        light: Color(hex: "#091723").opacity(0.6),
        dark:  Color.white.opacity(0.6)
    )
    // Light: 30% navy900   Dark: 30% white
    static let contentDisabled = Color(
        light: Color(hex: "#091723").opacity(0.3),
        dark:  Color.white.opacity(0.3)
    )
    // Always white — used on coloured fills/buttons
    static let contentOnFill = Color.white

    // MARK: - Semantic content colours (same in both modes)
    static let contentAccent    = Color(hex: "#218FB7")  // blue / paleTeal
    static let contentPositive  = Color(hex: "#34C759")  // green
    static let contentNegative  = Color(hex: "#FF3B30")  // red
    static let contentWarning   = Color(hex: "#FF9500")  // yellow

    // MARK: - Separators & Fills
    // Light: 20% navy900   Dark: 20% white
    static let separator = Color(
        light: Color(hex: "#091723").opacity(0.2),
        dark:  Color.white.opacity(0.2)
    )
    // Light: 10% grey500   Dark: 20% grey500
    static let fill = Color(
        light: Color(hex: "#75817E").opacity(0.1),
        dark:  Color(hex: "#75817E").opacity(0.2)
    )
    static let fillAccent   = Color(hex: "#218FB7")
    static let fillPositive = Color(hex: "#34C759")
    static let fillNegative = Color(hex: "#FF3B30")
    static let fillWarning  = Color(hex: "#FF9500")
    static let fillNeutral  = Color(hex: "#75817E")   // grey500
    // 50% navy900 — overlay on images/cards
    static let fillOnImage  = Color(hex: "#091723").opacity(0.5)
}

// MARK: - Adaptive colour helper
// Creates a colour that switches between light and dark automatically.
// This is more explicit than relying on system semantic colours,
// and matches your Figma tokens exactly.
private extension Color {
    init(light: Color, dark: Color) {
#if os(iOS)
        self.init(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
#else
        self.init(NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(dark)
                : NSColor(light)
        })
#endif
    }
}
