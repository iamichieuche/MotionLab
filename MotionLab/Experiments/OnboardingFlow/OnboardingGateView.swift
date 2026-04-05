//
//  OnboardingGateView.swift
//  MotionLab
//
//  Experiment 03 — Onboarding Flow, Screen 1
//
//  Simulates the moment a user arrives after submitting their application.
//  In production this state is driven by the backend; here we let the user
//  advance manually so the card celebration lands with the right context.

import SwiftUI
import Lottie

struct OnboardingGateView: View {
    @State private var navigate = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.page.ignoresSafeArea()

            // Content — vertically centered in the space above the button
            VStack(spacing: 0) {
                Spacer(minLength: 0).frame(maxHeight: 60)

                // Drumroll Lottie animation.
                //
                // The source canvas is 720×480 (landscape), so we constrain the
                // width and let the height follow the aspect ratio (~0.667).
                // contentMode: .scaleAspectFit ensures the animation never crops.
                LottieView(animation: .named("Drumroll_720x480_8sec_02"))
                    .playing(loopMode: .loop)
                    .frame(maxWidth: .infinity)
                    .frame(height: 213)

                Spacer().frame(height: 40)

                VStack(spacing: 14) {
                    Text("We're processing\nyour application.")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.content)
                        .multilineTextAlignment(.center)

                    Text("Tap below to continue.")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color.contentSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer(minLength: 0)
            }
            // Padding clears the docked button height (52pt) + its 32pt inset + breathing room
            .padding(.bottom, 96)

            // Button — docked at 32pt from screen bottom, consistent across all screens
            Button { navigate = true } label: {
                Text("Complete application")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .background(Capsule().fill(Color(hex: "#218FB7")))
            .padding(.horizontal, 24)
            .buttonStyle(PressScaleButtonStyle())
            .padding(.bottom, 32)
        }
        .navigationDestination(isPresented: $navigate) {
            OnboardingCardView()
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingGateView()
    }
}
