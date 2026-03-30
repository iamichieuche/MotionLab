//
//  ShimmerModifier.swift
//  MotionLab
//
//  Experiment 10 — Business Card Animation
//
//  A reusable ViewModifier that overlays a diagonal shimmer sweep.
//
//  How it works:
//  A LinearGradient (transparent → white → transparent) sits above the view.
//  Its X offset animates from left of the card to right of the card.
//  A mask clips it to the card shape so it doesn't bleed outside the edges.
//  This is called a "travelling highlight" — the gradient moves, not the opacity
//  of the card itself. That's what makes it look like light catching a surface.

import SwiftUI

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    let cardWidth: CGFloat

    // The shimmer gradient offset — starts fully left of the card, ends fully right.
    // We track this as a state so it can be animated.
    @State private var offsetX: CGFloat = -400

    func body(content: Content) -> some View {
        content.overlay(
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.0), location: 0.3),
                    .init(color: .white.opacity(0.35), location: 0.5),
                    .init(color: .white.opacity(0.0), location: 0.7),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // Rotate the gradient ~30° for a diagonal sweep
            .rotationEffect(.degrees(30))
            .offset(x: offsetX)
            // Clip the shimmer to the card's rounded shape
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .allowsHitTesting(false) // Shimmer is visual only — taps pass through
        )
        .onChange(of: isActive) { _, newValue in
            if newValue {
                // Reset to start position, then animate across
                offsetX = -cardWidth
                withAnimation(.easeInOut(duration: 0.9)) {
                    offsetX = cardWidth
                }
            }
        }
    }
}

extension View {
    func shimmer(isActive: Bool, cardWidth: CGFloat) -> some View {
        modifier(ShimmerModifier(isActive: isActive, cardWidth: cardWidth))
    }
}
