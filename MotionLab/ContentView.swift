//
//  ContentView.swift
//  MotionLab
//

import SwiftUI

struct Experiment: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let view: AnyView
}

let experiments: [Experiment] = [
    Experiment(
        title: "Checkmark Card",
        subtitle: "Simple card with icon",
        view: AnyView(CheckmarkView())
    ),
]

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List(experiments) { experiment in
                NavigationLink(destination: experiment.view) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(experiment.title)
                            .font(.headline)
                        Text(experiment.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Motion Lab")
        }
    }
}

#Preview {
    ContentView()
}
