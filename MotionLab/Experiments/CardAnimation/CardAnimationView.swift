//
//  CardAnimationView.swift
//  MotionLab
//
//  Experiment 10 — Business Card Animation Study

import SwiftUI

// MARK: - Root View

struct CardAnimationView: View {

    @State private var motion = MotionManager()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Entry animation
    @State private var cardOffsetY: CGFloat = -500
    @State private var cardScale:   CGFloat = 0.5

    // Card content
    @State private var contentOpacity: Double = 0
    @State private var textOpacity:    Double = 0
    @State private var shimmerTrigger: Int    = 0

    // Press interaction (gated until card settles)
    @State private var isPressed:  Bool = false
    @State private var isSettled:  Bool = false

    // Post-settle float + synced shadow
    @State private var floatOffsetY:  CGFloat = 0
    @State private var floatOffsetX:  CGFloat = 0
    @State private var shadowY:       CGFloat = 12
    @State private var shadowOpacity: Double  = 0.0

    // Sound
    @State private var soundEnabled: Bool = true

    // Replay icon bounce trigger
    @State private var replayCount: Int = 0

    // Haptic triggers — drives .sensoryFeedback() modifiers
    @State private var landHapticTrigger:  Int = 0
    @State private var lightHapticTrigger: Int = 0

    // Generation counter — stale Tasks self-invalidate on rapid replay
    @State private var entranceGeneration: Int = 0

    // Headline variant toggle — A: sharp cut, B: blur-to-sharp reveal
    @State private var headlineVariantB: Bool  = false
    @State private var headlineBlur:     CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            let cardWidth = min(340, geo.size.width - 48)

            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                // Context header — fades in with card content
                Text("Your business account is ready!")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(textOpacity)
                    .blur(radius: headlineVariantB ? headlineBlur : 0)
                    .offset(y: -14)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                // MARK: — Card
                BusinessCardView(
                    pitch: motion.pitch,
                    roll: motion.roll,
                    contentOpacity: contentOpacity,
                    isPressing: isPressed,
                    shimmerTrigger: shimmerTrigger,
                    cardWidth: cardWidth
                )
                .scaleEffect(cardScale)
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .animation(.spring(duration: 0.25, bounce: 0.2), value: isPressed)
                .offset(x: floatOffsetX, y: cardOffsetY + floatOffsetY - 200)
                .shadow(
                    color: Color.black.opacity(shadowOpacity),
                    radius: 40,
                    x: 0,
                    y: shadowY
                )
                .sensoryFeedback(.impact(weight: .medium), trigger: landHapticTrigger)
                .sensoryFeedback(.impact(weight: .light),  trigger: lightHapticTrigger)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Monzo Business Card for CAKE EXPECTATIONS")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction {
                    guard isSettled else { return }
                    isPressed = true
                    Task {
                        try? await Task.sleep(for: .seconds(0.15))
                        isPressed = false
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            guard isSettled else { return }
                            isPressed = true
                        }
                        .onEnded { _ in isPressed = false }
                )

                // MARK: — Bottom controls
                VStack(spacing: 32) {
                    HStack(spacing: 12) {
                        SoundTogglePill(soundEnabled: $soundEnabled)

                        Button { replay() } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 14, weight: .medium))
                                    .symbolEffect(.bounce, value: replayCount)
                                    .frame(width: 18, height: 18)
                                Text("Replay")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color(.systemGray5)))
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }

                    Button {
                        headlineVariantB.toggle()
                        isSettled     = false
                        floatOffsetY  = 0
                        floatOffsetX  = 0
                        shadowY       = 12
                        shadowOpacity = 0.0
                        Task {
                            try? await Task.sleep(for: .milliseconds(50))
                            runEntrance()
                        }
                    } label: {
                        Text(headlineVariantB ? "Variant B" : "Variant A")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color(.systemGray6)))
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 40)
            }
            .onAppear {
                motion.start()
                runEntrance()
            }
            .onDisappear {
                motion.stop()
            }
        }
    }

    // MARK: - Entrance Sequence
    //
    //  Card drops from above, growing 0.5 → 1.0 as it descends —
    //  like a card being handed to you across a desk.
    //
    //  0.00s  headline appears (A: sharp cut / B: blur-to-sharp)
    //  0.15s  spring drop begins (duration 1.0, bounce 0.1)
    //  0.15s  shadow fades in alongside
    //  0.55s  card face reveals (logos, chip, name)
    //  0.87s  spring settles — medium haptic + shimmer + land sound
    //  0.97s  shimmer sound rides the visual sweep
    //  1.32s  idle float begins (±4pt Y / 3.5s, ±2pt X / 4.7s)
    //
    //  reduceMotion: headline and card fade in immediately, no drop, no float
    func runEntrance() {
        entranceGeneration += 1
        let gen = entranceGeneration

        cardOffsetY    = reduceMotion ? 0 : -500
        cardScale      = reduceMotion ? 1.0 : 0.5
        contentOpacity = 0
        textOpacity    = 0
        headlineBlur   = 12
        floatOffsetY   = 0
        floatOffsetX   = 0
        shadowY        = 12
        shadowOpacity  = 0.0
        isSettled      = false

        if reduceMotion {
            textOpacity  = 1
            headlineBlur = 0
            withAnimation(.easeOut(duration: 0.3)) {
                contentOpacity = 1
                shadowOpacity  = 0.45
            }
            isSettled = true
            shimmerTrigger += 1
            if soundEnabled { CardSoundEngine.shared.playLand() }
            return
        }

        // Headline appears first — one frame after reset so the opacity-0 renders
        Task {
            try? await Task.sleep(for: .milliseconds(16))
            guard gen == entranceGeneration else { return }
            if headlineVariantB {
                withAnimation(.easeOut(duration: 0.6)) { textOpacity = 1 }
                withAnimation(.easeOut(duration: 0.9)) { headlineBlur = 0 }
            } else {
                textOpacity = 1
            }
        }

        Task {
            try? await Task.sleep(for: .milliseconds(150))
            guard gen == entranceGeneration else { return }

            withAnimation(.spring(duration: 1.0, bounce: 0.1)) {
                cardOffsetY = 0
                cardScale   = 1.0
            }
            withAnimation(.easeOut(duration: 0.75)) {
                shadowOpacity = 0.45
            }
        }

        // Card face reveals at ~55% of the spring
        Task {
            try? await Task.sleep(for: .milliseconds(550))
            guard gen == entranceGeneration else { return }
            withAnimation(.easeOut(duration: 0.35)) {
                contentOpacity = 1
            }
        }

        // Haptic + shimmer as spring settles
        Task {
            try? await Task.sleep(for: .milliseconds(870))
            guard gen == entranceGeneration else { return }
            landHapticTrigger += 1
            shimmerTrigger    += 1
            isSettled          = true
            if soundEnabled { CardSoundEngine.shared.playLand() }
        }

        // Shimmer sound rides the visual sweep
        Task {
            try? await Task.sleep(for: .milliseconds(970))
            guard gen == entranceGeneration else { return }
            if soundEnabled { CardSoundEngine.shared.playShimmer() }
        }

        // Idle float — two independent oscillations so motion never feels mechanical
        Task {
            try? await Task.sleep(for: .milliseconds(1320))
            guard gen == entranceGeneration else { return }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                floatOffsetY  = -4
                shadowY       = 18
                shadowOpacity = 0.32
            }
            withAnimation(.easeInOut(duration: 4.7).repeatForever(autoreverses: true)) {
                floatOffsetX = 2
            }
        }
    }

    func replay() {
        lightHapticTrigger += 1
        replayCount        += 1
        isSettled           = false
        floatOffsetY        = 0
        floatOffsetX        = 0
        shadowY             = 12
        shadowOpacity       = 0.0

        Task {
            try? await Task.sleep(for: .milliseconds(50))
            runEntrance()
        }
    }
}

#Preview {
    CardAnimationView()
}
