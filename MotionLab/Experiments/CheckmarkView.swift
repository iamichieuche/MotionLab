//
//  CheckmarkView.swift
//  MotionLab
//
//  Experiment 01 — Checkbox: haptics + scratch sound
//

import SwiftUI
import AVFoundation  // Apple's audio framework — needed to play sounds

// MARK: - Haptic + Sound Engine
//
// Key design decisions:
//
// 1. Generators are PERSISTENT static instances, not recreated per tap.
//    Creating a new UIImpactFeedbackGenerator every tap means `prepare()`
//    has no time to warm up the Taptic Engine, causing inconsistent intensity.
//    Keeping one instance alive means it stays warm and fires consistently.
//
// 2. AVAudioSession is configured once at startup.
//    Without this, sounds are routed through the ringer channel and affected
//    by the silent switch and system volume inconsistently. `.playback` category
//    gives us a dedicated, consistent audio channel.
//
// 3. Audio players are pre-loaded, not created on every play.
//    Recreating AVAudioPlayer on each tap introduces latency and inconsistency.
class FeedbackEngine {

    static let shared = FeedbackEngine()

    // Persistent generators — created once, stay warm
    private let checkGenerator   = UIImpactFeedbackGenerator(style: .medium)
    private let uncheckGenerator = UIImpactFeedbackGenerator(style: .light)

    // Pre-loaded audio players
    private var checkPlayer:   AVAudioPlayer?
    private var uncheckPlayer: AVAudioPlayer?
    private var scratchPlayer: AVAudioPlayer?

    private init() {
        // Configure audio session once — consistent volume, ignores silent switch
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)

        // Pre-load all sounds so they're ready to fire instantly
        checkPlayer   = player(forResource: "check",   volume: 0.5)
        uncheckPlayer = player(forResource: "uncheck", volume: 0.4)
        scratchPlayer = player(forResource: "scratch", volume: 0.6)

        // Pre-warm generators so first tap feels identical to every other tap
        checkGenerator.prepare()
        uncheckGenerator.prepare()
    }

    private func player(forResource name: String, volume: Float) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav")
                     ?? Bundle.main.url(forResource: name, withExtension: "mp3") else { return nil }
        let p = try? AVAudioPlayer(contentsOf: url)
        p?.volume = volume
        p?.prepareToPlay() // Buffers the file so first play has zero latency
        return p
    }

    func checkHaptic() {
        checkGenerator.impactOccurred()
        checkGenerator.prepare() // Re-warm immediately for the next tap
    }

    func uncheckHaptic() {
        uncheckGenerator.impactOccurred()
        uncheckGenerator.prepare()
    }

    func checkSound() {
        checkPlayer?.currentTime = 0
        checkPlayer?.play()
    }

    func uncheckSound() {
        uncheckPlayer?.currentTime = 0
        uncheckPlayer?.play()
    }

    func scratchSound() {
        scratchPlayer?.currentTime = 0
        scratchPlayer?.play()
    }
}

// MARK: - Checkmark Shape
// @Animatable replaces manual animatableData getter/setter boilerplate.
@Animatable
struct CheckmarkShape: Shape {
    var trimTo: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let start = CGPoint(x: rect.width * 0.2, y: rect.height * 0.5)
        let mid   = CGPoint(x: rect.width * 0.42, y: rect.height * 0.7)
        let end   = CGPoint(x: rect.width * 0.8, y: rect.height * 0.25)
        path.move(to: start)
        path.addLine(to: mid)
        path.addLine(to: end)
        return path
    }
}

// MARK: - Checkbox Press Style
// Scales down while finger is held, springs back on release.
// This is a true press effect — the view responds to finger down/up,
// not just the completed tap. That physical responsiveness is what
// makes it feel like a real button rather than a tappable element.
struct CheckboxPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(duration: 0.2, bounce: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Reusable Checkbox
struct Checkbox: View {
    @Binding var isChecked: Bool
    var soundEnabled: Bool = true
    @State private var trimTo: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Using Button instead of onTapGesture gives us access to the real press state —
        // `configuration.isPressed` is true while your finger is DOWN, false when lifted.
        // onTapGesture only fires on release, so it can never feel like a physical press.
        Button {
            isChecked.toggle()

            if isChecked {
                FeedbackEngine.shared.checkHaptic()
                if soundEnabled { FeedbackEngine.shared.checkSound() }
            } else {
                FeedbackEngine.shared.uncheckHaptic()
                if soundEnabled { FeedbackEngine.shared.uncheckSound() }
            }

            let animation: Animation? = isChecked
                ? (reduceMotion ? nil : .spring(duration: 0.35, bounce: 0.2))
                : (reduceMotion ? nil : .easeOut(duration: 0.25))
            withAnimation(animation) {
                trimTo = isChecked ? 1 : 0
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isChecked ? Color(.systemGray4) : Color(.tertiarySystemGroupedBackground))
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                    )
                CheckmarkShape(trimTo: trimTo)
                    .trim(from: 0, to: trimTo)
                    .stroke(
                        Color.primary.opacity(0.6),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: 36, height: 36)
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(CheckboxPressStyle())
        .accessibilityLabel(isChecked ? "Checked" : "Unchecked")
        .accessibilityAddTraits(.isToggle)
    }
}

// MARK: - List Row
struct TaskRow: View {
    let title: String
    let subtitle: String
    @Binding var isChecked: Bool
    var soundEnabled: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Controls how much of the strikethrough line is drawn.
    // 0 = invisible, 1 = fully across the text.
    // This mirrors exactly the same trim technique used on the checkmark —
    // the same concept, applied to a different shape.
    @State private var strikeProgress: CGFloat = 0

    // The scratch sound clip is 2 seconds long, so we match the
    // animation duration to 2 seconds — the line draws at the same
    // rate the sound plays, making them feel physically connected.
    private let scratchDuration: Double = 0.4

    var body: some View {
        HStack(spacing: 14) {
            Checkbox(isChecked: $isChecked, soundEnabled: soundEnabled)
                .onChange(of: isChecked) { _, newValue in
                    if newValue {
                        if soundEnabled { FeedbackEngine.shared.scratchSound() }
                    }
                    let animation: Animation? = newValue
                        ? (reduceMotion ? nil : .spring(duration: 0.35, bounce: 0.2))
                        : (reduceMotion ? nil : .easeOut(duration: 0.25))
                    withAnimation(animation) {
                        strikeProgress = newValue ? 1 : 0
                    }
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .opacity(isChecked ? 0.5 : 1)
                    .strikethrough(strikeProgress > 0.5, color: Color.primary.opacity(0.35))
                    .animation(.spring(duration: 0.35, bounce: 0.2), value: isChecked)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .opacity(isChecked ? 0.35 : 1)
                    .animation(.spring(duration: 0.35, bounce: 0.2), value: isChecked)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.tertiarySystemGroupedBackground))
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: "doc.text")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                        .accessibilityHidden(true)
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}


// MARK: - Sound Toggle Pill
struct SoundTogglePill: View {
    @Binding var soundEnabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.3)) {
                soundEnabled.toggle()
            }
            let g = UIImpactFeedbackGenerator(style: .light)
            g.prepare()
            g.impactOccurred()
        } label: {
            HStack(spacing: 8) {

                // contentTransition animates the icon swap as a symbol replace effect —
                // cleaner than a manual ZStack crossfade and uses the system's own
                // SF Symbol animation path.
                Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .contentTransition(.symbolEffect(.replace.downUp))
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 18, height: 18)
                    .animation(.smooth(duration: 0.3), value: soundEnabled)

                // Fixed width prevents the pill from resizing between "Sound on" and "Sound off".
                // Without this, the different text lengths cause the capsule to jump size on toggle.
                Text(soundEnabled ? "Sound on" : "Sound off")
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 72, alignment: .leading)
            }
            .foregroundColor(soundEnabled ? .primary : .secondary)
            .animation(.smooth(duration: 0.3), value: soundEnabled)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color(.systemGray5))
            )
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel("Sound")
        .accessibilityValue(soundEnabled ? "On" : "Off")
        .accessibilityAddTraits(.isToggle)
    }
}

// MARK: - Main View
struct CheckmarkView: View {
    @State private var checked1 = false
    @State private var checked2 = false
    @State private var checked3 = false

    // Single source of truth for sound — owned here, passed down to rows.
    // This is the same @Binding pattern: one parent owns it, children read it.
    @State private var soundEnabled = true

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {

                Checkbox(isChecked: $checked1, soundEnabled: soundEnabled)
                    .padding(.top, 80)

                Spacer()
                    .frame(height: 48)

                VStack(spacing: 10) {
                    Text("In context")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)

                    TaskRow(
                        title: "Review design handoff",
                        subtitle: "Due today · Figma",
                        isChecked: $checked2,
                        soundEnabled: soundEnabled
                    )

                    TaskRow(
                        title: "Push Motion Lab to device",
                        subtitle: "In progress · Xcode",
                        isChecked: $checked3,
                        soundEnabled: soundEnabled
                    )
                }
                .padding(.horizontal, 24)

                Spacer()
            }

            // Floating pill pinned to the bottom, layered above everything.
            SoundTogglePill(soundEnabled: $soundEnabled)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 48)
        }
    }
}

#Preview {
    CheckmarkView()
}
