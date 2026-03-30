//
//  ContentView.swift
//  MotionLab
//

import SwiftUI

struct Experiment: Identifiable {
    let id = UUID()
    let number: String
    let title: String
    let subtitle: String
    let view: AnyView
}

let experiments: [Experiment] = [
    Experiment(
        number: "01",
        title: "Checkmark",
        subtitle: "A checkbox that feels satisfying to tap — haptics, sound, and a hand-crafted animation.",
        view: AnyView(CheckmarkView())
    ),
    Experiment(
        number: "02",
        title: "Business Card",
        subtitle: "Your card revealed with weight and presence. Holographic foil driven by real device tilt.",
        view: AnyView(CardAnimationView())
    ),
]

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: — Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Motion Lab")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Interaction experiments, one a day.")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 32)

                    // MARK: — Experiment list
                    VStack(spacing: 12) {
                        ForEach(experiments) { experiment in
                            NavigationLink(destination: experiment.view) {
                                ExperimentRow(experiment: experiment)
                            }
                            .buttonStyle(PressScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Experiment Row
struct ExperimentRow: View {
    let experiment: Experiment

    var body: some View {
        HStack(spacing: 16) {

            // Text
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(experiment.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(experiment.number)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Text(experiment.subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    ContentView()
}
