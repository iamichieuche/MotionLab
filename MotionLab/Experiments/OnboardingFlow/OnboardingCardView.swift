//
//  OnboardingCardView.swift
//  MotionLab
//
//  Experiment 03 — Onboarding Flow, Screen 2
//
//  The card celebration screen. Reuses BusinessCardView, MotionManager, and
//  CardSoundEngine from Experiment 02 — only the sequence is owned here.
//
//  Sequence:
//  0.00s  Headline cuts in — sharp, no animation
//  0.15s  Card spring-drops from above (duration 1.0, bounce 0.1)
//  0.55s  Card face reveals
//  0.87s  Card settles — haptic + shimmer + sound
//  1.07s  Subtitle fades in
//  1.40s  CTA button fades in

import SwiftUI

struct OnboardingCardView: View {

    @State private var motion = MotionManager()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Card entry
    @State private var cardOffsetY:     CGFloat = -500
    @State private var cardScale:       CGFloat = 0.5
    @State private var contentOpacity:  Double  = 0
    @State private var shadowOpacity:   Double  = 0.0
    @State private var shadowY:         CGFloat = 12

    // Text layers
    @State private var headlineOpacity: Double  = 0
    @State private var subtitleOpacity: Double  = 0
    @State private var ctaOpacity:      Double  = 0

    // Idle float — two independent axes so motion never feels mechanical
    @State private var floatOffsetY:    CGFloat = 0
    @State private var floatOffsetX:    CGFloat = 0

    // Card interaction
    @State private var isPressed:       Bool    = false
    @State private var isSettled:       Bool    = false
    @State private var shimmerTrigger:  Int     = 0

    // Haptic triggers — drives .sensoryFeedback() modifiers
    // SwiftUI's .sensoryFeedback fires whenever the trigger value changes,
    // so we increment an Int rather than toggle a Bool — that way rapid
    // taps each get their own haptic even if two happen in the same frame.
    @State private var landHapticTrigger: Int   = 0

    // Generation counter — lets Task closures self-invalidate when a
    // new entrance starts before the previous one finished.
    @State private var entranceGeneration: Int  = 0

    // Navigation to AddMoneyView
    @State private var navigateToAddMoney: Bool = false

    var body: some View {
        GeometryReader { geo in
            let cardWidth = min(340, geo.size.width - 48)

            ZStack {
                Color(hex: "#F2F8F3").ignoresSafeArea()

                // MARK: — Headline
                // Sharp cut — no animation on the headline itself.
                // It's already present when your eyes arrive on the screen.
                Text("Your business account is ready!")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.content)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(headlineOpacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .offset(y: 48)

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
                .offset(x: floatOffsetX, y: cardOffsetY + floatOffsetY - 150)
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

                // MARK: — Subtitle
                Text("Your card's on its way 🎉 Add money now to get started.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.contentSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(subtitleOpacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 186)

                // MARK: — CTA
                // .navigationDestination sits on the ZStack — that's fine.
                // In SwiftUI, navigation modifiers can be attached to any view
                // in the hierarchy; they don't need to be on the button itself.
                Button("Add money") {
                    navigateToAddMoney = true
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color.contentOnFill)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(Color.content))
                .padding(.horizontal, 24)
                .buttonStyle(PressScaleButtonStyle())
                .opacity(ctaOpacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 120)
            }
            .navigationBarHidden(true)
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

        // Reset everything to starting state
        cardOffsetY    = reduceMotion ? 0 : -500
        cardScale      = reduceMotion ? 1.0 : 0.5
        contentOpacity = 0
        headlineOpacity = 0
        subtitleOpacity = 0
        ctaOpacity      = 0
        floatOffsetY   = 0
        floatOffsetX   = 0
        shadowY        = 12
        shadowOpacity  = 0.0
        isSettled      = false

        // reduceMotion: skip all animation, everything appears at once
        if reduceMotion {
            headlineOpacity = 1
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

        // 0ms — headline cuts in one frame after reset so opacity-0 renders first
        Task {
            try? await Task.sleep(for: .milliseconds(16))
            guard gen == entranceGeneration else { return }
            headlineOpacity = 1
        }

        // 150ms — card spring-drops, shadow fades alongside
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

        // 550ms — card face reveals at ~55% of the spring
        Task {
            try? await Task.sleep(for: .milliseconds(550))
            guard gen == entranceGeneration else { return }
            withAnimation(.easeOut(duration: 0.35)) {
                contentOpacity = 1
            }
        }

        // 870ms — spring settles: haptic + shimmer + sound
        Task {
            try? await Task.sleep(for: .milliseconds(870))
            guard gen == entranceGeneration else { return }
            landHapticTrigger += 1
            shimmerTrigger    += 1
            isSettled          = true
            CardSoundEngine.shared.playLand()
        }

        // 970ms — shimmer sound rides the visual sweep
        Task {
            try? await Task.sleep(for: .milliseconds(970))
            guard gen == entranceGeneration else { return }
            CardSoundEngine.shared.playShimmer()
        }

        // 1070ms — subtitle fades in
        Task {
            try? await Task.sleep(for: .milliseconds(1070))
            guard gen == entranceGeneration else { return }
            withAnimation(.easeOut(duration: 0.4)) {
                subtitleOpacity = 1
            }
        }

        // 1400ms — CTA fades in
        Task {
            try? await Task.sleep(for: .milliseconds(1400))
            guard gen == entranceGeneration else { return }
            withAnimation(.easeOut(duration: 0.4)) {
                ctaOpacity = 1
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
    }
}

#Preview {
    NavigationStack {
        OnboardingCardView()
    }
}
