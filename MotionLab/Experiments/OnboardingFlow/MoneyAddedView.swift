//
//  MoneyAddedView.swift
//  MotionLab
//
//  Experiment 03 — Onboarding Flow, Screen 4
//
//  Success screen shown after mock Apple Pay confirmation.
//  Amount is passed in from AddMoneyView so "£250 added" is always accurate.
//
//  Sequence:
//  0.1s  Success haptic fires
//  0.1s  Checkmark circle springs in
//  0.4s  Amount + subtitle drift up and fade in
//  0.7s  Done button fades in

import SwiftUI

struct MoneyAddedView: View {
    @Environment(\.dismiss) private var dismiss
    let amount: String   // raw amount string, e.g. "250" or "1,000"

    @State private var ringScale:      CGFloat = 0.4
    @State private var ringOpacity:    Double  = 0
    @State private var checkOpacity:   Double  = 0
    @State private var textOpacity:    Double  = 0
    @State private var textOffsetY:    CGFloat = 16
    @State private var buttonOpacity:  Double  = 0
    @State private var hapticTrigger:  Int     = 0

    var displayAmount: String {
        amount.isEmpty ? "0" : amount
    }

    var body: some View {
        ZStack {
            Color.page.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // MARK: — Checkmark badge
                ZStack {
                    Circle()
                        .fill(Color.fillAccent.opacity(0.12))
                        .frame(width: 104, height: 104)

                    Circle()
                        .strokeBorder(Color.fillAccent.opacity(0.18), lineWidth: 1.5)
                        .frame(width: 104, height: 104)

                    Image(systemName: "checkmark")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(Color.fillAccent)
                        .opacity(checkOpacity)
                }
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

                Spacer().frame(height: 32)

                // MARK: — Text
                VStack(spacing: 10) {
                    Text("£\(displayAmount) added")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Color.content)

                    Text("Your account is topped up\nand ready to go.")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.contentSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .opacity(textOpacity)
                .offset(y: textOffsetY)
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button("Done") { dismiss() }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(Color.fillAccent))
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .buttonStyle(PressScaleButtonStyle())
                .opacity(buttonOpacity)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { runEntrance() }
        .sensoryFeedback(.success, trigger: hapticTrigger)
    }

    func runEntrance() {
        hapticTrigger += 1

        withAnimation(.spring(response: 0.5, dampingFraction: 0.62).delay(0.1)) {
            ringScale   = 1
            ringOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.25).delay(0.3)) {
            checkOpacity = 1
        }
        withAnimation(.spring(duration: 0.5, bounce: 0.1).delay(0.4)) {
            textOpacity  = 1
            textOffsetY  = 0
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.7)) {
            buttonOpacity = 1
        }
    }
}

#Preview {
    NavigationStack {
        MoneyAddedView(amount: "250")
    }
}
