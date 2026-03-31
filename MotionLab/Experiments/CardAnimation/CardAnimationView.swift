//
//  CardAnimationView.swift
//  MotionLab
//
//  Experiment 10 — Business Card Animation Study

import SwiftUI

struct CardAnimationView: View {

    @State private var motion = MotionManager()

    // Entry animation state
    @State private var cardOffsetY: CGFloat = -500
    @State private var cardScale: CGFloat = 0.5
    @State private var contentOpacity: Double = 0
    @State private var textOpacity: Double = 0

    // Press interaction
    @State private var isPressed: Bool = false
    @State private var isSettled: Bool = false  // gates press until card has landed

    // Shimmer — increments each entrance so onChange always fires
    @State private var shimmerTrigger: Int = 0

    // Sound
    @State private var soundEnabled: Bool = true

    // Post-entry effects
    @State private var floatOffsetY: CGFloat = 0
    @State private var floatOffsetX: CGFloat = 0  // secondary drift — different period
    @State private var shadowY: CGFloat = 12
    @State private var shadowOpacity: Double = 0.0

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            // MARK: — Context header
            Text("Your business account is ready!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(textOpacity)
                // 48pt below the card — card centre sits at -150, card half-height ~106pt
                // so card bottom is at -44pt from screen centre; text sits 48pt below that
                .offset(y: 48)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            // MARK: — Card
            BusinessCardView(
                pitch: motion.pitch,
                roll: motion.roll,
                contentOpacity: contentOpacity,
                isPressing: isPressed,
                shimmerTrigger: shimmerTrigger
            )
            .scaleEffect(cardScale)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
            .offset(x: floatOffsetX, y: cardOffsetY + floatOffsetY)
            .shadow(
                color: Color.black.opacity(shadowOpacity),
                radius: 40,
                x: 0,
                y: shadowY
            )
            .offset(y: -150)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard isSettled else { return }
                        isPressed = true
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )

            // MARK: — Bottom controls
            HStack(spacing: 12) {
                SoundTogglePill(soundEnabled: $soundEnabled)

                Button {
                    replay()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .medium))
                        Text("Replay")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color(.systemGray5)))
                }
                .buttonStyle(PressScaleButtonStyle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 72)
        }
        .onAppear {
            motion.start()
            runEntrance()
        }
        .onDisappear {
            motion.stop()
        }
    }

    // MARK: - Entrance Sequence
    //
    // Card slides in from above, growing from 0.5 → 1.0 as it descends —
    // like a card being handed to you across a desk, approaching and landing.
    //
    //  0.15s  card begins moving
    //  0.15s  shadow fades in
    //  0.60s  card face reveals (logos, chip, name)
    //  0.60s  context text fades in
    //  1.00s  haptic fires as spring settles
    //  1.45s  idle float begins (vertical + horizontal drift at different periods)
    func runEntrance() {
        cardOffsetY    = -500
        cardScale      = 0.5
        contentOpacity = 0
        textOpacity    = 0
        floatOffsetY   = 0
        floatOffsetX   = 0
        shadowY        = 12
        shadowOpacity  = 0.0
        isSettled      = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {

            withAnimation(.spring(response: 1.0, dampingFraction: 0.82)) {
                cardOffsetY = 0
                cardScale   = 1.0
            }

            withAnimation(.easeOut(duration: 0.75)) {
                shadowOpacity = 0.45
            }

            // Content and text reveal earlier — no more blank card window
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                withAnimation(.easeOut(duration: 0.45)) {
                    contentOpacity = 1
                    textOpacity    = 1
                }
            }

            // Haptic + land sound as spring settles
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
                let g = UIImpactFeedbackGenerator(style: .medium)
                g.prepare()
                g.impactOccurred()
                if soundEnabled { CardSoundEngine.shared.playLand() }

                shimmerTrigger += 1
                isSettled = true

                // Shimmer sound fires with the visual sweep
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    if soundEnabled { CardSoundEngine.shared.playShimmer() }
                }

                // Float begins — two independent oscillations so motion never feels mechanical
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    startFloat()
                }
            }
        }
    }

    func startFloat() {
        // Primary vertical float — 3.5s period
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
            floatOffsetY  = -4
            shadowY       = 18
            shadowOpacity = 0.32
        }
        // Secondary horizontal drift — 4.7s period, never in perfect sync with vertical
        withAnimation(.easeInOut(duration: 4.7).repeatForever(autoreverses: true)) {
            floatOffsetX = 2
        }
    }

    func replay() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare()
        g.impactOccurred()

        isSettled    = false
        floatOffsetY = 0
        floatOffsetX  = 0
        shadowY       = 12
        shadowOpacity = 0.0

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            runEntrance()
        }
    }
}

#Preview {
    CardAnimationView()
}
