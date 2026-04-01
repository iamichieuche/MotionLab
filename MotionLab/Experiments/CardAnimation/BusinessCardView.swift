//
//  BusinessCardView.swift
//  MotionLab
//
//  Experiment 10 — Monzo Business Card
//
//  Built from Figma node 6:603 — exact assets, exact positions.
//  Holographic iridescent layer sits on top, driven by device tilt.
//  Pressing the card intensifies the holographic effect — like squeezing light through foil.

import SwiftUI

struct BusinessCardView: View {
    let pitch: Double
    let roll: Double
    let contentOpacity: Double
    let isPressing: Bool
    let shimmerTrigger: Int
    var cardWidth: CGFloat = 340

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shimmerX: CGFloat = -400

    // Scaled proportionally from Figma: 250×157 → 340×213 (1.592:1 ratio)
    private var cardHeight: CGFloat { (cardWidth / 340) * 213 }
    private var cornerRadius: CGFloat { (cardWidth / 340) * 11 }

    // Holographic gradient centre shifts with device tilt.
    // Returns static centre when reduceMotion is enabled.
    var holoCenter: UnitPoint {
        guard !reduceMotion else { return UnitPoint(x: 0.5, y: 0.5) }
        let x = 0.5 + CGFloat(min(max(roll,   -0.5), 0.5)) * 0.7
        let y = 0.5 + CGFloat(min(max(pitch,  -0.5), 0.5)) * 0.7
        return UnitPoint(x: x, y: y)
    }

    // Pressing intensifies the foil — like light catching the surface under pressure
    var holoOpacity1: Double { isPressing ? 0.18 : 0.10 }
    var holoOpacity2: Double { isPressing ? 0.10 : 0.05 }

    var body: some View {
        ZStack {

            // MARK: Layer 1 — Full card background
            Image("card_background")
                .resizable()
                .scaledToFill()
                .frame(width: cardWidth, height: cardHeight)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .accessibilityHidden(true)

            // MARK: Layer 2 — Card elements (chip, monzo, mastercard, name)
            cardElements
                .opacity(contentOpacity)
                .animation(.easeOut(duration: 0.25), value: contentOpacity)
                .accessibilityHidden(true)

            // MARK: Layer 3 — Iridescent holographic foil
            holoLayers.accessibilityHidden(true)

            // MARK: Layer 4 — Shimmer sweep
            // Diagonal white gradient that crosses the card once on reveal —
            // like a jeweller's light catching the surface as it's handed to you.
            // Skipped entirely when reduceMotion is enabled.
            if !reduceMotion {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.18),
                                .clear,
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 200, height: cardHeight * 3)
                    .rotationEffect(.degrees(10))
                    .offset(x: shimmerX)
                    .blendMode(.overlay)
                    .onChange(of: shimmerTrigger) { _, _ in
                        shimmerX = -(cardWidth + 200)
                        withAnimation(.easeInOut(duration: 0.9)) {
                            shimmerX = cardWidth + 200
                        }
                    }
                    .accessibilityHidden(true)
            }

            // MARK: Layer 5 — Business name (foil-stamped)
            // Sits above the holographic layers. Gradient highlight centre tracks holoCenter
            // so the bright spot sweeps across the letters as the card tilts — like light
            // catching raised print on a physical card.
            // Min opacity raised to 0.65 + text shadow to ensure contrast compliance.
            businessName
                .opacity(contentOpacity)
                .animation(.easeOut(duration: 0.25), value: contentOpacity)
                .accessibilityHidden(true)
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .drawingGroup()
        .shadow(color: Color.black.opacity(0.16), radius: 11, x: 0, y: 3)
        .rotation3DEffect(
            .degrees(reduceMotion ? 0 : min(max(pitch, -0.6), 0.6) * 18),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.4
        )
        .rotation3DEffect(
            .degrees(reduceMotion ? 0 : min(max(roll,  -0.6), 0.6) * -18),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.4
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Monzo Business Card for CAKE EXPECTATIONS")
    }

    // MARK: - Holographic Foil Layers
    // Extracted to keep body type-checkable. Two angular gradients at opposing
    // centres simulate real foil colour interference.
    @ViewBuilder var holoLayers: some View {
        let colors1: [Color] = [
            Color(hex: "#FF6B9D"), Color(hex: "#C44FFF"), Color(hex: "#4F8FFF"),
            Color(hex: "#4FFFB0"), Color(hex: "#FFE94F"), Color(hex: "#FF9A4F"),
            Color(hex: "#FF6B9D"),
        ]
        let colors2: [Color] = [
            Color(hex: "#4FFFB0"), Color(hex: "#FFE94F"), Color(hex: "#FF6B9D"),
            Color(hex: "#4F8FFF"), Color(hex: "#C44FFF"), Color(hex: "#4FFFB0"),
        ]
        let center2 = UnitPoint(x: 1 - holoCenter.x, y: 1 - holoCenter.y)

        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(AngularGradient(colors: colors1, center: holoCenter))
            .opacity(holoOpacity1)
            .blendMode(.overlay)
            .animation(.easeOut(duration: 0.2), value: isPressing)

        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(AngularGradient(colors: colors2, center: center2))
            .opacity(holoOpacity2)
            .blendMode(.overlay)
            .animation(.easeOut(duration: 0.2), value: isPressing)
    }

    // MARK: - Business Name (foil-stamped)
    // Positioned in absolute card space. The specular gradient moves with holoCenter
    // so tilting the card drags a bright streak across the letters.
    var businessName: some View {
        let scale = cardWidth / 340
        let x = (cardWidth  * 0.08).rounded()
        let y = (cardHeight * 0.8025).rounded()

        return ZStack(alignment: .topLeading) {
            Text("CAKE EXPECTATIONS")
                .font(.system(size: (12 * scale).rounded(), weight: .semibold, design: .monospaced))
                .tracking(2.5)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.65),
                            .white.opacity(0.92),
                            .white.opacity(0.65),
                        ],
                        startPoint: UnitPoint(x: holoCenter.x - 0.5, y: holoCenter.y - 0.3),
                        endPoint:   UnitPoint(x: holoCenter.x + 0.5, y: holoCenter.y + 0.3)
                    )
                )
                .shadow(color: .black.opacity(0.55), radius: 2, x: 0, y: 1)
                .offset(x: x, y: y)
        }
        .frame(width: cardWidth, height: cardHeight, alignment: .topLeading)
    }

    // MARK: - Card Elements
    var cardElements: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .topLeading) {

                // Monzo wordmark — trailing-aligned to match Mastercard right edge
                HStack {
                    Spacer()
                    Image("card_monzo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: h * 0.13)
                        .accessibilityHidden(true)
                }
                .frame(width: w - (w * 0.0328))
                .offset(y: h * 0.0534)

                // Chip — vertically centred on the card
                Image("card_chip")
                    .resizable()
                    .scaledToFit()
                    .frame(width: w * 0.16, height: h * 0.185)
                    .offset(x: w * 0.102, y: (h - h * 0.185) / 2)
                    .accessibilityHidden(true)

                // Mastercard — Figma: inset(67.77% top, 3.28% right, 6.73% bottom, 75.84% left)
                Image("card_mastercard")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: w - (w * 0.7584) - (w * 0.0328),
                        height: h - (h * 0.6777) - (h * 0.0673)
                    )
                    .offset(x: w * 0.7584, y: h * 0.6777)
                    .accessibilityHidden(true)

            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}
