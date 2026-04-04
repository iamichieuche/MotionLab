//
//  OnboardingCardView.swift
//  MotionLab
//
//  Experiment 03 — Onboarding Flow, Screen 2
//
//  The card celebration screen. Reuses BusinessCardView, MotionManager, and
//  CardSoundEngine from Experiment 02 — only the sequence is owned here.
//
//  Sequence (synced to CardAnimationView's updated timing):
//  0.15s  Card spring-drops from above
//  0.55s  Card face reveals
//  0.87s  Card settles — haptic + shimmer + land sound
//  0.97s  Headline drifts in (spring, 16pt → 0 drift) + shimmer sound
//  1.17s  Subtitle fades in
//  1.32s  Idle float begins
//  1.50s  CTA button fades in

import SwiftUI

struct OnboardingCardView: View {

    @State private var motion = MotionManager()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Card entry
    @State private var cardOffsetY:     CGFloat = -600
    @State private var cardScale:       CGFloat = 0.5
    @State private var contentOpacity:  Double  = 0
    @State private var shadowOpacity:   Double  = 0.0
    @State private var shadowY:         CGFloat = 12

    // Text layers
    @State private var headlineOpacity: Double  = 0
    @State private var headlineDriftY:  CGFloat = 16
    @State private var subtitleOpacity: Double  = 0
    @State private var ctaOpacity:      Double  = 0

    // Idle float
    @State private var floatOffsetY:    CGFloat = 0
    @State private var floatOffsetX:    CGFloat = 0

    // Card interaction
    @State private var isPressed:       Bool    = false
    @State private var isSettled:       Bool    = false
    @State private var shimmerTrigger:  Int     = 0

    @State private var landHapticTrigger: Int   = 0
    @State private var entranceGeneration: Int  = 0
    @State private var navigateToAddMoney: Bool = false

    var body: some View {
        GeometryReader { geo in
            let cardWidth = min(340, geo.size.width - 48)

            ZStack(alignment: .bottom) {
                Color.page.ignoresSafeArea()

                // MARK: — Content column
                //
                // VStack layout positions the card and text in a real vertical
                // relationship. Two Spacers distribute the remaining screen space
                // evenly above the card and between the text and the docked button —
                // no hardcoded offsets, no stranded void.
                //
                // The card still animates: cardOffsetY starts at -600 and springs
                // to 0, which means "600pt above its natural VStack position" → 0
                // (settled in layout). offset() is always relative to the view's
                // laid-out position, so the VStack handles placement and the offset
                // handles only the animation delta.
                VStack(spacing: 0) {
                    Spacer(minLength: 0).frame(maxHeight: 60)

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
                    .offset(x: floatOffsetX, y: cardOffsetY + floatOffsetY)
                    .shadow(
                        color: Color.black.opacity(shadowOpacity),
                        radius: 40, x: 0, y: shadowY
                    )
                    .sensoryFeedback(.impact(weight: .medium), trigger: landHapticTrigger)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in guard isSettled else { return }; isPressed = true }
                            .onEnded   { _             in isPressed = false }
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Monzo Business Card for CAKE EXPECTATIONS")

                    // Fixed gap between card bottom and headline — tight enough
                    // to read as a group, generous enough to breathe.
                    Spacer().frame(height: 40)

                    // MARK: — Text group
                    VStack(spacing: 12) {
                        Text("Your business account is ready!")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Color.content)
                            .opacity(headlineOpacity)
                            .offset(y: headlineDriftY)

                        Text("Your card's on its way 🎉\nAdd money now to get started.")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(Color.contentSecondary)
                            .lineSpacing(5)
                            .opacity(subtitleOpacity)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                    Spacer(minLength: 0)
                }
                // Bottom padding clears the docked button (52pt height + 32pt inset + some air)
                .padding(.bottom, 96)

                // MARK: — CTA (docked)
                Button("Add money") {
                    navigateToAddMoney = true
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(Color(hex: "#218FB7")))
                .padding(.horizontal, 24)
                .buttonStyle(PressScaleButtonStyle())
                .opacity(ctaOpacity)
                .padding(.bottom, 32)
            }
            .navigationDestination(isPresented: $navigateToAddMoney) {
                AddMoneyView()
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
    func runEntrance() {
        entranceGeneration += 1
        let gen = entranceGeneration

        cardOffsetY     = reduceMotion ? 0 : -600
        cardScale       = reduceMotion ? 1.0 : 0.5
        contentOpacity  = 0
        headlineOpacity = 0
        headlineDriftY  = 16
        subtitleOpacity = 0
        ctaOpacity      = 0
        floatOffsetY    = 0
        floatOffsetX    = 0
        shadowY         = 12
        shadowOpacity   = 0.0
        isSettled       = false

        if reduceMotion {
            headlineOpacity = 1
            headlineDriftY  = 0
            withAnimation(.easeOut(duration: 0.3)) {
                contentOpacity = 1
                shadowOpacity  = 0.45
            }
            subtitleOpacity = 1
            ctaOpacity      = 1
            isSettled       = true
            shimmerTrigger += 1
            CardSoundEngine.shared.playLand()
            return
        }

        // 150ms — card spring-drops from above its VStack position
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

        // 550ms — card face reveals
        Task {
            try? await Task.sleep(for: .milliseconds(550))
            guard gen == entranceGeneration else { return }
            withAnimation(.easeOut(duration: 0.35)) {
                contentOpacity = 1
            }
        }

        // 870ms — card settles
        Task {
            try? await Task.sleep(for: .milliseconds(870))
            guard gen == entranceGeneration else { return }
            landHapticTrigger += 1
            shimmerTrigger    += 1
            isSettled          = true
            CardSoundEngine.shared.playLand()
        }

        // 970ms — headline drifts in (the exhale)
        Task {
            try? await Task.sleep(for: .milliseconds(970))
            guard gen == entranceGeneration else { return }
            CardSoundEngine.shared.playShimmer()
            withAnimation(.spring(duration: 0.7, bounce: 0.1)) {
                headlineOpacity = 1
                headlineDriftY  = 0
            }
        }

        // 1170ms — subtitle fades in
        Task {
            try? await Task.sleep(for: .milliseconds(1170))
            guard gen == entranceGeneration else { return }
            withAnimation(.easeOut(duration: 0.4)) {
                subtitleOpacity = 1
            }
        }

        // 1320ms — idle float begins
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

        // 1500ms — CTA fades in
        Task {
            try? await Task.sleep(for: .milliseconds(1500))
            guard gen == entranceGeneration else { return }
            withAnimation(.easeOut(duration: 0.4)) {
                ctaOpacity = 1
            }
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingCardView()
    }
}
