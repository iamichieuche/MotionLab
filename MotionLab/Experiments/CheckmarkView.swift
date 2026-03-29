//
//  CheckmarkView.swift
//  MotionLab
//
//  Experiment 01 — Hand-crafted checkbox with haptics + scratch sound
//

import SwiftUI
import AVFoundation  // Apple's audio framework — needed to play sounds

// MARK: - Haptic + Sound Engine
// A small helper that lives outside of any view.
// We keep it separate so any experiment can reuse it later.
//
// `UIImpactFeedbackGenerator` talks directly to the Taptic Engine — the
// physical vibration motor inside your iPhone. You choose an intensity
// style (.light, .medium, .heavy, .rigid, .soft) and call `.impactOccurred()`.
//
// `AVAudioPlayer` plays an audio file from your bundle. We use system sounds
// here via `AudioServicesPlaySystemSound` so there's nothing to import —
// Apple ships hundreds of short UI sounds baked into iOS.
struct FeedbackEngine {

    // Haptic for checking — medium weight, feels decisive
    static func checkHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare() // `prepare` warms up the engine so there's no delay
        generator.impactOccurred()
    }

    // Haptic for unchecking — lighter, feels like a release
    static func uncheckHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    // A second, softer haptic fired slightly after the strikethrough animates —
    // punctuates the "task done" moment on the list row.
    // `UINotificationFeedbackGenerator` has three styles: .success, .warning, .error.
    // `.success` is a double-tap pattern — satisfying for completion.
    static func completionHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    // System sound IDs are Apple's built-in library of short UI sounds.
    // 1104 = a soft, clean tick (used in Clock app)
    // 1105 = a slightly softer tick — good for unchecking
    // These don't require any audio files in your project — they're baked into iOS.
    static func checkSound() {
        AudioServicesPlaySystemSound(1104)
    }

    static func uncheckSound() {
        AudioServicesPlaySystemSound(1105)
    }

    // Scratch sound — plays a custom audio file from your app bundle.
    //
    // `Bundle.main` is your app's package — everything you add to Xcode
    // lives here at runtime. `url(forResource:withExtension:)` finds your
    // file by name. If it returns nil, the file isn't in the bundle yet.
    //
    // `AVAudioPlayer` loads the file into memory and plays it.
    // We store it as a static var so it isn't deallocated mid-playback —
    // if the player gets destroyed while the sound is playing, it cuts off instantly.
    //
    // TO ADD YOUR SOUND: drag a file named "scratch.wav" or "scratch.mp3"
    // into the MotionLab folder in Xcode's project navigator.
    // Tick "Add to target: MotionLab" in the import dialog.
    private static var scratchPlayer: AVAudioPlayer?

    static func scratchSound() {
        guard let url = Bundle.main.url(forResource: "scratch", withExtension: "wav")
                     ?? Bundle.main.url(forResource: "scratch", withExtension: "mp3") else {
            // File not added yet — silently does nothing until you drop it in
            return
        }
        do {
            scratchPlayer = try AVAudioPlayer(contentsOf: url)
            scratchPlayer?.volume = 0.6  // Subtle, like a real pen
            scratchPlayer?.play()
        } catch {
            // If something goes wrong loading the file, skip the sound
        }
    }
}

// MARK: - Checkmark Shape
struct CheckmarkShape: Shape {
    var trimTo: CGFloat

    var animatableData: CGFloat {
        get { trimTo }
        set { trimTo = newValue }
    }

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

// MARK: - Reusable Checkbox
struct Checkbox: View {
    @Binding var isChecked: Bool
    @State private var trimTo: CGFloat = 0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .frame(width: 36, height: 36)
                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 0)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                )

            CheckmarkShape(trimTo: trimTo)
                .trim(from: 0, to: trimTo)
                .stroke(
                    Color(hex: "#555555"),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
                .frame(width: 36, height: 36)
        }
        .scaleEffect(scale)
        .onTapGesture {
            isChecked.toggle()

            // Fire haptic and sound immediately on tap — before the animation.
            // This is intentional: haptics feel most natural when they land
            // at the exact moment of the gesture, not after a delay.
            if isChecked {
                FeedbackEngine.checkHaptic()
                FeedbackEngine.checkSound()
            } else {
                FeedbackEngine.uncheckHaptic()
                FeedbackEngine.uncheckSound()
            }

            withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.6)) {
                scale = 0.85
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.1)) {
                scale = 1.0
            }
            withAnimation(.easeInOut(duration: 0.3)) {
                trimTo = isChecked ? 1 : 0
            }
        }
    }
}

// MARK: - List Row
struct TaskRow: View {
    let title: String
    let subtitle: String
    @Binding var isChecked: Bool

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.05))
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: "doc.text")
                        .foregroundColor(Color.black.opacity(0.3))
                        .font(.system(size: 16))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .strikethrough(isChecked, color: Color.black.opacity(0.3))
                    .animation(.easeInOut(duration: 0.2), value: isChecked)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // When the checkbox inside the row is tapped, the Checkbox view
            // handles its own haptic + sound. But we also want a second haptic
            // to fire slightly later, timed with the strikethrough appearing —
            // so the list row itself reacts to the completion moment.
            // We watch `isChecked` change using `onChange` and fire a delayed haptic.
            Checkbox(isChecked: $isChecked)
                .onChange(of: isChecked) { _, newValue in
                    if newValue {
                        // Fire the scratch sound at the same moment the
                        // strikethrough starts drawing — so it sounds like
                        // the line is being physically drawn across the text.
                        FeedbackEngine.scratchSound()

                        // Completion haptic lands slightly after, as the
                        // strikethrough finishes — a second punctuation beat.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            FeedbackEngine.completionHaptic()
                        }
                    }
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Main View
struct CheckmarkView: View {
    @State private var checked1 = false
    @State private var checked2 = false
    @State private var checked3 = false

    var body: some View {
        ZStack {
            Color(hex: "#F7F7F7")
                .ignoresSafeArea()

            VStack(spacing: 24) {

                VStack(spacing: 8) {
                    Text("Component")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)

                    Checkbox(isChecked: $checked1)
                }
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
                        isChecked: $checked2
                    )

                    TaskRow(
                        title: "Push Motion Lab to device",
                        subtitle: "In progress · Xcode",
                        isChecked: $checked3
                    )
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }
}

#Preview {
    CheckmarkView()
}
