//
//  MoneyAddedView.swift
//  MotionLab
//
//  Experiment 03 — Onboarding Flow, Screen 4
//
//  Rebuilt to match Figma node 51:3272.
//  Lottie coins animation, mock iOS notification (amount-aware), dynamic copy.
//
//  Notification sequence:
//  0.20s  Slides in from top edge
//  2.20s  Slides back out — view is fully removed from hierarchy on exit
//
//  Content sequence:
//  0.40s  Lottie fades in and plays
//  0.65s  Title + body drift up and fade in
//  0.90s  Footer fades in

import SwiftUI
import Lottie

struct MoneyAddedView: View {
    @Environment(\.dismiss) private var dismiss
    let amount: String   // formatted number string, e.g. "250" or "1,000"

    private var displayAmount: String {
        amount.isEmpty ? "0" : amount
    }

    // MARK: - Dynamic copy

    private var bodyText: String {
        "Your money is safely in your account and ready to use."
    }

    // MARK: - State

    @State private var notifVisible:   Bool    = false
    @State private var lottieOpacity:  Double  = 0
    @State private var textOpacity:    Double  = 0
    @State private var textOffsetY:    CGFloat = 12
    @State private var footerOpacity:  Double  = 0
    @State private var hapticTrigger:  Int     = 0
    @State private var ctaScale:       CGFloat = 0.88

    var body: some View {
        ZStack {
            Color.page.ignoresSafeArea()

            // MARK: — Content
            // Same structure as OnboardingGateView: capped top spacer → illustration
            // → fixed gap → text → free spacer. Keeps text at a consistent Y.
            VStack(spacing: 0) {
                Spacer(minLength: 0).frame(maxHeight: 60)

                LottieView(animation: .named("Coinsarrow_04"))
                    .playing(loopMode: .playOnce)
                    .frame(maxWidth: .infinity)
                    .frame(height: 213)
                    .opacity(lottieOpacity)

                Spacer().frame(height: 40)

                VStack(spacing: 16) {
                    Text("You just added £\(displayAmount)!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.content)
                        .multilineTextAlignment(.center)

                    Text(bodyText)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.contentSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 32)
                .opacity(textOpacity)
                .offset(y: textOffsetY)

                Spacer(minLength: 0)
            }
            .padding(.bottom, 80)
        }
        // Notification sits above the safe area edge, completely removed when hidden
        .overlay(alignment: .top) {
            if notifVisible {
                MockNotificationBanner(amount: displayAmount)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .safeAreaInset(edge: .bottom) { footer }
        .navigationBarBackButtonHidden(true)
        .onAppear { runEntrance() }
        .sensoryFeedback(.success, trigger: hapticTrigger)
    }

    // MARK: - Footer

    var footer: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.contentSecondary)
                    .frame(width: 24, height: 24)

                Text("Your card details are stored securely and will never be shared.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.contentSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "#75817E").opacity(0.10))
            )

            Button { dismiss() } label: {
                Text("Next")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Capsule().fill(Color.fillAccent))
            }
            .buttonStyle(PressScaleButtonStyle())
            .scaleEffect(ctaScale)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
        .padding(.top, 32)
        .background(
            Rectangle()
                .fill(Color.page)
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [Color.page.opacity(0), Color.page],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 48)
                    .offset(y: -48)
                }
        )
        .opacity(footerOpacity)
    }

    // MARK: - Entrance

    func runEntrance() {
        hapticTrigger   += 1
        ctaScale         = 0.88

        // Visual animations — delay replaces Task.sleep chains
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.20)) {
            notifVisible = true
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.40)) {
            lottieOpacity = 1
        }
        withAnimation(.spring(duration: 0.5, bounce: 0.1).delay(0.65)) {
            textOpacity = 1
            textOffsetY = 0
        }
        withAnimation(.easeOut(duration: 0.35).delay(0.90)) {
            footerOpacity = 1
        }
        // Next button springs in with a bounce at the emotional peak
        withAnimation(.spring(duration: 0.5, bounce: 0.35).delay(0.90)) {
            ctaScale = 1.0
        }

        // Auto-dismiss notification — Task remains (timed behaviour, not entrance animation)
        Task {
            try? await Task.sleep(for: .milliseconds(2200))
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                notifVisible = false
            }
        }
    }
}

// MARK: - Mock Notification Banner
//
// Mimics a collapsed iOS notification (Figma node I51:3279;135:73230).
// Loads monzo logo.png from the app bundle via UIImage(named:).
// Falls back to a styled M if the asset is not yet bundled.

private struct MockNotificationBanner: View {
    let amount: String

    var body: some View {
        HStack(spacing: 10) {
            // Monzo app icon — loaded from bundle as loose PNG
            if let uiImage = UIImage(named: "monzo logo") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(Color(hex: "#1A2332"))
                    Text("M").font(.system(size: 17, weight: .black)).foregroundStyle(Color(hex: "#FF6849"))
                }
                .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Monzo")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.content)
                        .tracking(-0.23)
                    Spacer()
                    Text("now")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.contentSecondary)
                }
                Text("You've been paid £\(amount) 🤑")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.contentSecondary)
                    .tracking(-0.23)
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 17)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
                )
        )
    }
}

#Preview {
    NavigationStack {
        MoneyAddedView(amount: "250")
    }
}
