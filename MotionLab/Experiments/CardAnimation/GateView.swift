//
//  GateView.swift
//  MotionLab
//
//  Gate screen before the Business Card animation.
//  Simulates the moment a user arrives after completing their application,
//  so the celebration animation lands in the right emotional context.
//

import SwiftUI

struct GateView: View {
    @State private var navigate = false

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            NavigationLink(destination: CardAnimationView(), isActive: $navigate) {
                EmptyView()
            }

            Button("Complete application") {
                navigate = true
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(Color.contentOnFill)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.content)
            )
            .padding(.horizontal, 24)
            .buttonStyle(PressScaleButtonStyle())
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        GateView()
    }
}
