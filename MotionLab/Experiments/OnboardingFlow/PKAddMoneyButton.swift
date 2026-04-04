//
//  PKAddMoneyButton.swift
//  MotionLab
//
//  Experiment 03 — Onboarding Flow
//
//  UIViewRepresentable wrapper around PKPaymentButton(.addMoney).
//  This gives you the exact Apple-certified button —
//  correct typography, correct Apple logo, correct sizing.
//
//  Note: PKPaymentButton renders correctly without the Apple Pay merchant
//  entitlement, so this works in Simulator and on-device for prototyping.
//  You only need the entitlement when processing real payments.
//
//  Usage:
//      PKAddMoneyButton { handlePayment() }
//          .frame(maxWidth: .infinity)
//          .frame(height: 48)

import SwiftUI
import PassKit

struct PKAddMoneyButton: UIViewRepresentable {
    let action: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(
            paymentButtonType:  .addMoney,
            paymentButtonStyle: .automatic   // black in light, white in dark
        )
        button.cornerRadius = 24
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.tapped),
            for: .touchUpInside
        )
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}

    class Coordinator: NSObject {
        let action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func tapped() { action() }
    }
}

#Preview {
    PKAddMoneyButton { }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .padding(.horizontal, 32)
}
