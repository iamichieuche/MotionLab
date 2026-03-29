//
//  CheckmarkView.swift
//  MotionLab
//
//  Experiment 01 — Hand-crafted checkbox, real-world context
//

import SwiftUI

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
// Extracted into its own view so it can be used both standalone and inside a list row.
// `isChecked` is passed in as a `Binding` — meaning the parent owns the state,
// and the checkbox just reads and writes it. This is how SwiftUI shares state
// between a parent view and a child view.
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
// A realistic task row: icon, title, subtitle, checkbox on the right.
// `HStack` lays views out horizontally. `Spacer()` pushes the checkbox
// all the way to the trailing edge — it fills all available space between
// the text and the checkbox.
struct TaskRow: View {
    let title: String
    let subtitle: String
    @Binding var isChecked: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Left icon
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.05))
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: "doc.text")
                        .foregroundColor(Color.black.opacity(0.3))
                        .font(.system(size: 16))
                )

            // Title + subtitle stacked vertically
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    // Strikethrough when checked — a common real-world pattern
                    .strikethrough(isChecked, color: Color.black.opacity(0.3))
                    .animation(.easeInOut(duration: 0.2), value: isChecked)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Checkbox(isChecked: $isChecked)
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
    // Each row has its own independent state.
    // `@State` here lives in the parent — the rows read/write it via `$binding`.
    @State private var checked1 = false
    @State private var checked2 = false
    @State private var checked3 = false

    var body: some View {
        ZStack {
            Color(hex: "#F7F7F7")
                .ignoresSafeArea()

            VStack(spacing: 24) {

                // Standalone checkbox up top — the component in isolation
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

                // Real-world list context
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
