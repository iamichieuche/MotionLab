//
//  AddMoneyView.swift
//  MotionLab
//
//  Experiment 03 — Onboarding Flow, Screen 3
//
//  Built from Figma node 36:4826 (file: jmaSq07PeuWliZKQLJo7sx).
//  Background, chips, typography, and footer layout all match the design.
//
//  Coin stack replaces the Figma illustration — real asset coming later.
//  SF Symbol placeholder: sterlingsign.circle.fill, stacked with spring physics.

import SwiftUI

// MARK: - Chip Model

enum MoneyChip: String, CaseIterable, Identifiable {
    case five    = "£5"
    case twenty  = "£20"
    case fifty   = "£50"
    case hundred = "£100"
    case other   = "Other"

    var id: String { rawValue }

    var coinCount: Int {
        switch self {
        case .five:    return 1
        case .twenty:  return 2
        case .fifty:   return 3
        case .hundred: return 5
        case .other:   return 0
        }
    }

    var displayAmount: String {
        switch self {
        case .five:    return "5"
        case .twenty:  return "20"
        case .fifty:   return "50"
        case .hundred: return "100"
        case .other:   return "0"
        }
    }
}

// MARK: - Root View

struct AddMoneyView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedChip: MoneyChip = .twenty

    // Stable UUID array — each UUID represents one coin in the stack.
    // Using UUIDs (rather than ForEach(0..<count)) gives SwiftUI a stable
    // identity for each coin so it can animate insertions and removals
    // independently, rather than just re-rendering the whole stack.
    @State private var coins: [UUID] = [UUID(), UUID()]   // £20 = 2 coins by default

    // Incrementing this Int triggers .sensoryFeedback on each chip tap.
    // Declarative haptics: the modifier fires whenever the value changes,
    // so you never need to call UIImpactFeedbackGenerator imperatively.
    @State private var hapticTrigger: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#F2F8F3").ignoresSafeArea()

            // Scrollable content with bottom padding to clear the footer
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    coinStack
                    headerText
                    paymentField
                    applePayRow
                    Spacer(minLength: 200)
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
            }

            footer
        }
        .navigationBarHidden(true)
        .overlay(alignment: .top) { navBar }
        .sensoryFeedback(.impact(weight: .medium), trigger: hapticTrigger)
    }

    // MARK: - Navigation Bar

    // Custom nav bar to match Figma — native nav bar hidden.
    // Uses .overlay(alignment: .top) so it sits above the scroll content
    // without affecting layout (no VStack nesting needed).
    var navBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.content)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(Color(hex: "#F2F8F3").opacity(0.9))
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                    )
            }
            .buttonStyle(PressScaleButtonStyle())

            Spacer()

            Button("Skip") {
                dismiss()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.content)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(Color(hex: "#F2F8F3").opacity(0.9))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
    }

    // MARK: - Coin Stack

    // Placeholder illustration. Each coin is a stacked SF Symbol circle.
    // Offset stacking: coin[0] is the bottom, each subsequent coin sits 8pt higher.
    //
    // Insertion transition: new coin springs in from above (offset -24pt → 0)
    // Removal transition:   top coin springs up and fades out (0 → offset -24pt)
    //
    // .spring(response:dampingFraction:) controls the feel:
    //   response   = duration of the spring in seconds
    //   dampingFraction = 1.0 is critically damped (no bounce), < 1.0 bounces
    var coinStack: some View {
        ZStack {
            ForEach(Array(coins.enumerated()), id: \.element) { index, _ in
                CoinView()
                    .offset(y: CGFloat(-index) * 8)
                    .zIndex(Double(index))
                    .transition(
                        .asymmetric(
                            // New coins spring down from above
                            insertion: .offset(y: -28).combined(with: .opacity),
                            // Removed coins spring up and vanish
                            removal:   .offset(y: -28).combined(with: .opacity)
                        )
                    )
            }
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .padding(.top, 60) // breathing room below nav bar
    }

    // MARK: - Header Text

    var headerText: some View {
        VStack(spacing: 16) {
            Text("Add money into your\nMonzo account")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.content)
                .multilineTextAlignment(.center)

            Text("Start with an amount that works for you.")
                .font(.system(size: 16))
                .foregroundStyle(Color.contentSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Payment Field

    var paymentField: some View {
        VStack(spacing: 0) {

            // Amount display
            Text("£\(selectedChip.displayAmount == "0" ? "0" : selectedChip.displayAmount).00")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(Color.content)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                // .contentTransition animates the number changing — SwiftUI
                // knows the text changed and cross-fades between the values.
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: selectedChip)

            Divider()
                .padding(.horizontal, 16)

            // Chip row
            // ScrollView(.horizontal) lets chips overflow on smaller screens
            // without wrapping — consistent with Figma's single-row layout.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MoneyChip.allCases) { chip in
                        ChipButton(
                            label: chip.rawValue,
                            isSelected: selectedChip == chip
                        ) {
                            selectChip(chip)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.backgroundSecondary)
        )
    }

    // MARK: - Apple Pay Row

    var applePayRow: some View {
        HStack(spacing: 16) {
            // Apple Pay logo approximation using SF Symbol
            Image(systemName: "applelogo")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.content)
                .frame(width: 32, height: 32)

            Text("Apple Pay")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.content)

            Spacer()

            Button("Change") { }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.fillAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(Color.fillAccent.opacity(0.1))
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.backgroundSecondary)
        )
    }

    // MARK: - Footer

    // Docked footer that sits above the home indicator.
    // The gradient mask above it fades the scroll content out so
    // content doesn't hard-clip — matches the Figma footer pattern.
    var footer: some View {
        VStack(spacing: 16) {
            // FSCS callout
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.contentSecondary)
                    .frame(width: 24, height: 24)

                // AttributedString lets us colour part of the text differently
                // without splitting into multiple Text views.
                Text(fscsText)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.content)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.fill)
            )

            // Primary CTA — Apple Pay
            Button {
                // Apple Pay action
            } label: {
                HStack(spacing: 4) {
                    Text("Pay with")
                        .font(.system(size: 18, weight: .medium))
                    Image(systemName: "applelogo")
                        .font(.system(size: 18, weight: .medium))
                    Text("Pay")
                        .font(.system(size: 18, weight: .medium))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Capsule().fill(Color.black))
            }
            .buttonStyle(PressScaleButtonStyle())

            // Secondary CTA
            Button {
                // Other payment method action
            } label: {
                Text("Other payment method")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.content)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        Capsule().fill(Color.fill)
                    )
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
        .padding(.top, 32)
        .background(
            // Gradient mask above the footer fades the scroll content out
            // — prevents a hard clip edge when content scrolls behind it.
            // This uses a VStack with a gradient-masked rectangle on top
            // to fade from transparent → background colour.
            Rectangle()
                .fill(Color(hex: "#F2F8F3"))
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [
                            Color(hex: "#F2F8F3").opacity(0),
                            Color(hex: "#F2F8F3"),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 48)
                    .offset(y: -48)
                }
        )
    }

    // MARK: - Helpers

    // Chip selection: update selected chip, animate coin count change
    func selectChip(_ chip: MoneyChip) {
        let newCount = chip.coinCount
        let oldCount = coins.count

        selectedChip = chip
        hapticTrigger += 1

        withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
            if newCount > oldCount {
                for _ in 0..<(newCount - oldCount) {
                    coins.append(UUID())
                }
            } else if newCount < oldCount {
                coins.removeLast(oldCount - newCount)
            }
        }
    }

    // AttributedString for the FSCS callout — "Financial Services
    // Compensation Scheme" gets the accent colour.
    // AttributedString is Swift's type-safe attributed text — no NSAttributedString needed.
    var fscsText: AttributedString {
        var str = AttributedString("You're covered by the Financial Services Compensation Scheme (FSCS) up to £120,000")
        if let range = str.range(of: "Financial Services Compensation Scheme") {
            str[range].foregroundColor = UIColor(Color.fillAccent)
        }
        return str
    }
}

// MARK: - Coin View

struct CoinView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#F7D84E"), Color(hex: "#D4A800")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)

            Image(systemName: "sterlingsign")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(hex: "#8B6A00"))
        }
        .frame(width: 56, height: 56)
    }
}

// MARK: - Chip Button

struct ChipButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(Color.content)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                // Overlay stroke for selected state — cleaner than border modifier
                // since it doesn't affect layout or change the view's size.
                .background(
                    Capsule()
                        .fill(Color(hex: "#F2F8F3"))
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    isSelected ? Color.fillAccent : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .shadow(
                            color: isSelected ? Color.black.opacity(0.16) : .clear,
                            radius: 8, x: 0, y: 2
                        )
                )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

#Preview {
    NavigationStack {
        AddMoneyView()
    }
}
