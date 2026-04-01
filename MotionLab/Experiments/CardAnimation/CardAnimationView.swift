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

    // Geometry — captured once from GeometryReader on appear
    @State private var finalCardWidth:  CGFloat = 340
    @State private var finalCardHeight: CGFloat = 213
    @State private var diOffsetY:       CGFloat = -400  // Dynamic Island Y from screen centre
    @State private var targetOffsetY:   CGFloat = -150  // resting card Y from screen centre

    // Expansion state machine
    @State private var expansionState: CardExpansionState = .pill

    // Pill → card morph
    @State private var pillWidth:           CGFloat = 126
    @State private var pillHeight:          CGFloat = 37
    @State private var currentCornerRadius: CGFloat = 18
    @State private var cardOffsetY:         CGFloat = -400

    // Entrance tilt — X axis, 8° → 0°, concurrent with expansion
    @State private var entranceTilt: Double = 8

    // Card content
    @State private var contentOpacity: Double = 0
    @State private var textOpacity:    Double = 0
    @State private var shimmerTrigger: Int    = 0

    // Post-settle float + synced shadow
    @State private var floatOffsetY:  CGFloat = 0
    @State private var floatOffsetX:  CGFloat = 0
    @State private var shadowY:       CGFloat = 16
    @State private var shadowOpacity: Double  = 0.0

    // Press interaction (gated until card settles)
    @State private var isPressed: Bool = false

    // Sound
    @State private var soundEnabled: Bool = true

    // Replay icon rotation trigger
    @State private var replayCount: Int = 0

    // Haptic triggers — drives .sensoryFeedback() modifiers on the ZStack
    @State private var landHapticTrigger:  Int = 0
    @State private var lightHapticTrigger: Int = 0

    // Generation counter — incremented on each entrance so stale Tasks self-invalidate
    // if replay() is called before the previous entrance has finished.
    @State private var entranceGeneration: Int = 0

    private var isSettled: Bool {
        expansionState == .settled || expansionState == .floating
    }

    var body: some View {
        GeometryReader { geo in
            let cardWidth  = min(340, geo.size.width - 48)
            let cardHeight = (cardWidth / 340) * 213
            // Dynamic Island centre sits ~20pt below the top of the geometry frame
            let diY        = -(geo.size.height / 2 - 20)
            let centerY: CGFloat = -150

            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                // Context header — fades in with card content
                Text("Your business account is ready!")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(textOpacity)
                    .offset(y: 48)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                // MARK: — Pill → card

                ZStack {
                    // Navy base: the pill that exhales into the card frame
                    RoundedRectangle(cornerRadius: currentCornerRadius)
                        .fill(Color(hex: "#1A1F36"))

                    // Card face: clipped to the pill during expansion, revealed at 80%
                    BusinessCardView(
                        pitch: motion.pitch,
                        roll: motion.roll,
                        contentOpacity: contentOpacity,
                        isPressing: isPressed,
                        shimmerTrigger: shimmerTrigger,
                        cardWidth: finalCardWidth
                    )
                }
                .frame(width: pillWidth, height: pillHeight)
                .clipShape(RoundedRectangle(cornerRadius: currentCornerRadius))
                // Entrance tilt — resolves 8° → 0° as the expansion spring settles
                .rotation3DEffect(.degrees(entranceTilt), axis: (x: 1, y: 0, z: 0), perspective: 0.4)
                // Press feedback — gated until settled
                .scaleEffect(isPressed ? 0.96 : 1.0)
                .animation(.spring(duration: 0.25, bounce: 0.2), value: isPressed)
                .offset(x: floatOffsetX, y: cardOffsetY + floatOffsetY)
                .shadow(
                    color: Color.black.opacity(shadowOpacity),
                    radius: 24,
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
                HStack(spacing: 12) {
                    SoundTogglePill(soundEnabled: $soundEnabled)

                    Button { replay() } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.subheadline.weight(.medium))
                                .symbolEffect(.rotate, value: replayCount)
                            Text("Replay")
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundStyle(.primary)
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
                finalCardWidth  = cardWidth
                finalCardHeight = cardHeight
                diOffsetY       = diY
                targetOffsetY   = centerY
                cardOffsetY     = diY
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
    //  0.00s  Dark navy pill at Dynamic Island position (126 × 37pt, cornerRadius 18)
    //  0.15s  Pill expands to card dimensions — spring(duration: 0.6, bounce: 0.15)
    //         Concurrent: cornerRadius 18 → 16, cardOffsetY → -150, entranceTilt 8° → 0°
    //         Shadow fades in alongside the expansion
    //  0.63s  Card face reveals at 80% of spring (easeOut, 0.2s)
    //  0.75s  Spring settles — .medium haptic, shimmer triggered
    //  0.85s  Shimmer sound fires with the visual sweep
    //  1.75s  Idle float begins — ±3pt Y over 3.5s, ±2pt X over 4.7s
    //         Shadow Y (16 → 19) and opacity (0.3 → 0.22) sync with the float
    //
    //  reduceMotion: card appears immediately at full size, no motion at all
    func runEntrance() {
        entranceGeneration += 1
        let gen = entranceGeneration

        // Snap to pill at Dynamic Island — breaks any running repeat-forever loops
        pillWidth           = 126
        pillHeight          = 37
        currentCornerRadius = 18
        cardOffsetY         = diOffsetY
        entranceTilt        = 8
        contentOpacity      = 0
        textOpacity         = 0
        floatOffsetY        = 0
        floatOffsetX        = 0
        shadowY             = 16
        shadowOpacity       = 0.0
        expansionState      = .pill

        if reduceMotion {
            pillWidth           = finalCardWidth
            pillHeight          = finalCardHeight
            currentCornerRadius = 16
            cardOffsetY         = targetOffsetY
            entranceTilt        = 0
            withAnimation(.easeOut(duration: 0.3)) {
                contentOpacity = 1
                textOpacity    = 1
                shadowOpacity  = 0.3
            }
            expansionState = .settled
            shimmerTrigger += 1
            if soundEnabled { CardSoundEngine.shared.playLand() }
            return
        }

        // Pill → card: all geometry + tilt driven by the same spring so everything
        // settles at exactly the same moment. 0.15s pause lets the pill register.
        withAnimation(.spring(duration: 0.6, bounce: 0.15).delay(0.15)) {
            expansionState      = .expanding
            pillWidth           = finalCardWidth
            pillHeight          = finalCardHeight
            currentCornerRadius = 16
            cardOffsetY         = targetOffsetY
            entranceTilt        = 0
        }

        // Shadow arrives with the card — same delay, slightly longer ease
        withAnimation(.easeOut(duration: 0.45).delay(0.15)) {
            shadowOpacity = 0.3
        }

        // Card face reveals at 80% of the spring (0.15 + 0.6 × 0.8 = 0.63s)
        // Header text staggers 100ms after the card face — lets each element land before the next.
        withAnimation(.easeOut(duration: 0.2).delay(0.63)) {
            contentOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.25).delay(0.73)) {
            textOpacity = 1
        }

        // Haptic + shimmer trigger as the spring settles (0.15 + 0.6 = 0.75s)
        Task {
            try? await Task.sleep(for: .seconds(0.75))
            guard gen == entranceGeneration else { return }
            landHapticTrigger += 1
            expansionState = .settled
            shimmerTrigger += 1
            if soundEnabled { CardSoundEngine.shared.playLand() }
        }

        // Shimmer sound rides the visual sweep (0.1s after haptic)
        Task {
            try? await Task.sleep(for: .seconds(0.85))
            guard gen == entranceGeneration else { return }
            if soundEnabled { CardSoundEngine.shared.playShimmer() }
        }

        // Idle float starts after shimmer completes (1.75s).
        // Task.sleep avoids a transaction conflict with the earlier shadowOpacity reveal —
        // both target the same property and a delayed repeat-forever in the same render
        // pass would override the reveal.
        Task {
            try? await Task.sleep(for: .seconds(1.75))
            guard gen == entranceGeneration else { return }
            // Primary: vertical float with synced shadow grounding (3.5s period)
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                floatOffsetY  = -3
                shadowY       = 19
                shadowOpacity = 0.22
            }
            // Secondary: horizontal drift at a different period — prevents mechanical feel
            withAnimation(.easeInOut(duration: 4.7).repeatForever(autoreverses: true)) {
                floatOffsetX = 2
            }
            expansionState = .floating
        }
    }

    func replay() {
        lightHapticTrigger += 1
        replayCount += 1

        // Setting state without animation interrupts all pending repeat-forever loops,
        // snapping values back to their reset positions immediately.
        expansionState      = .pill
        pillWidth           = 126
        pillHeight          = 37
        currentCornerRadius = 18
        cardOffsetY         = diOffsetY
        entranceTilt        = 8
        contentOpacity      = 0
        textOpacity         = 0
        floatOffsetY        = 0
        floatOffsetX        = 0
        shadowY             = 16
        shadowOpacity       = 0.0

        // Brief pause lets the reset render before the entrance sequence begins,
        // so animations start from the correct presentation values
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            runEntrance()
        }
    }
}

#Preview {
    CardAnimationView()
}
