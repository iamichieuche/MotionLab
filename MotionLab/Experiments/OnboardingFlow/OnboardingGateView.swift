//
//  OnboardingGateView.swift
//  MotionLab
//
//  Experiment 03 — Onboarding Flow
//
//  Entry point. Simulates a user arriving after completing their application,
//  so the card celebration that follows lands in the right emotional context.

import SwiftUI

struct OnboardingGateView: View {
    @State private var navigate = false

    var body: some View {
        ZStack {
            Color(hex: "#F2F8F3").ignoresSafeArea()

            VStack(spacing: 12) {
                Text("You're nearly there.")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.content)

                Text("Tap below to complete your application.")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.contentSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button("Complete application") {
                navigate = true
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(Color.contentOnFill)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Capsule().fill(Color.content))
            .padding(.horizontal, 24)
            .buttonStyle(PressScaleButtonStyle())
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 48)
        }
        .navigationBarHidden(true)
        // navigationDestination is the modern SwiftUI way to push a view.
        // Unlike the old NavigationLink(destination:isActive:), it keeps the
        // trigger (@State bool) and the destination (the view) separate —
        // making it easier to trigger navigation from anywhere in your code,
        // not just from inside a NavigationLink wrapper.
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
