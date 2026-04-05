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
//  SF Symbol placeholder: sterlingsign, coins stacked horizontally with spring physics.

import SwiftUI

// MARK: - Chip Model

enum MoneyChip: String, CaseIterable, Identifiable {
    case hundred     = "£100"
    case twoFifty    = "£250"
    case fiveHundred = "£500"
    case oneThousand = "£1,000"
    case other       = "Other"

    var id: String { rawValue }

    var coinCount: Int {
        switch self {
        case .hundred:      return 1
        case .twoFifty:     return 2
        case .fiveHundred:  return 3
        case .oneThousand:  return 5
        case .other:        return 0
        }
    }

    var displayAmount: String {
        switch self {
        case .hundred:      return "100"
        case .twoFifty:     return "250"
        case .fiveHundred:  return "500"
        case .oneThousand:  return "1,000"
        case .other:        return ""
        }
    }
}

// MARK: - Root View

struct AddMoneyView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedChip: MoneyChip = .twoFifty
    @State private var coins: [UUID] = [UUID(), UUID()]   // £250 = 2 coins
    @State private var amountText: String = "250"

    // FocusState drives the keyboard — setting true opens it, false dismisses it.
    @FocusState private var amountFocused: Bool

    @State private var hapticTrigger:  Int = 0
    @State private var coinGeneration: Int = 0

    // Payment method — drives the payment row and footer button
    @State private var selectedPaymentMethod: PaymentMethod = .applePay

    // Navigation / presentation
    @State private var showPaymentSheet:        Bool = false
    @State private var navigateToSuccess:       Bool = false
    @State private var showChangePaymentSheet:  Bool = false

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    coinStack
                        .id("top")
                    headerText
                    paymentField
                        .id("payment")
                    paymentMethodRow
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
            }
            .background(Color.page.ignoresSafeArea())
            // safeAreaInset docks the footer AND participates in keyboard avoidance —
            // it rides up with the keyboard, ScrollView shrinks to fill the remaining space.
            .safeAreaInset(edge: .bottom) { footer }
            .onChange(of: amountFocused) { _, focused in
                if focused {
                    withAnimation(.spring(duration: 0.4, bounce: 0.1)) {
                        proxy.scrollTo("payment", anchor: .top)
                    }
                } else {
                    // Delay scroll-back so the keyboard dismissal animation starts first —
                    // two things snapping at once felt abrupt.
                    Task {
                        try? await Task.sleep(for: .milliseconds(200))
                        withAnimation(.spring(duration: 0.4, bounce: 0.1)) {
                            proxy.scrollTo("top", anchor: .top)
                        }
                    }
                }
            }
            // Reformat amountText as the user types, inserting thousand separators.
            // guard amountFocused prevents reformatting when preset chips set the value.
            .onChange(of: amountText) { _, newValue in
                guard amountFocused else { return }
                let digits = newValue.filter { $0.isNumber }
                guard !digits.isEmpty else { return }
                if let number = Int(digits) {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .decimal
                    formatter.locale = Locale(identifier: "en_GB")
                    amountText = formatter.string(from: NSNumber(value: number)) ?? digits
                } else {
                    amountText = digits
                }
            }
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Skip") { dismiss() }
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: hapticTrigger)
        // Mock payment sheet
        .sheet(isPresented: $showPaymentSheet) {
            MockApplePaySheet(amount: amountText) {
                showPaymentSheet = false
                Task {
                    try? await Task.sleep(for: .milliseconds(350))
                    navigateToSuccess = true
                }
            }
        }
        // Success screen
        .navigationDestination(isPresented: $navigateToSuccess) {
            MoneyAddedView(amount: amountText)
        }
        // Payment method picker — presented as a sheet so the entire stack collapses
        // at once when a method is selected, with no intermediate pop animation.
        .sheet(isPresented: $showChangePaymentSheet) {
            NavigationStack {
                ChangePaymentMethodView(selectedPaymentMethod: $selectedPaymentMethod)
            }
        }
        // AddMoneyView owns sheet dismissal for the "See all banks" path.
        // When SelectBankView sets the method binding, we see the change here and
        // close the sheet directly — no intermediate ChangePaymentMethodView flash.
        .onChange(of: selectedPaymentMethod) { _, newValue in
            guard showChangePaymentSheet else { return }
            if case .easyBankTransfer = newValue {
                showChangePaymentSheet = false
            }
        }
    }

    // MARK: - Coin Stack

    var coinStack: some View {
        HStack(spacing: -58) {
            ForEach(Array(coins.enumerated()), id: \.element) { index, _ in
                coinItem(index: index)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: 112)
    }

    @ViewBuilder
    private func coinItem(index: Int) -> some View {
        let transition = AnyTransition.asymmetric(
            insertion: .scale(scale: 0, anchor: .leading).combined(with: .opacity),
            removal:   .scale(scale: 0, anchor: .leading).combined(with: .opacity)
        )
        CoinView(
            index:       index,
            isFirstCoin: index == 0,
            isTopCoin:   index == coins.count - 1
        )
        .zIndex(Double(index))
        .transition(transition)
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

            // Amount display.
            //
            // A hidden TextField captures input; a Text view renders the formatted
            // value. This gives us full visual control while the system handles
            // keyboard management and text binding.
            //
            // Focus indicator: a subtle teal border fades in when amountFocused
            // is true — the user always knows the field is active.
            // Real TextField — native cursor positioning, drag, tap-to-place.
            // £ prefix and .00 suffix are fixed Text views; amountText holds
            // only the number (e.g. "1,000") so formatting logic stays clean.
            // .tint sets the cursor colour to our accent teal.
            HStack(alignment: .center, spacing: 2) {
                Text("£")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(amountText.isEmpty ? Color.contentDisabled : Color.content)

                TextField("0", text: $amountText)
                    .keyboardType(.numberPad)
                    .focused($amountFocused)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(Color.content)
                    .tint(Color.fillAccent)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(minWidth: 24)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: amountText)

                Text(".00")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(Color.contentSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .onTapGesture {
                // Always fire a haptic on field tap, regardless of current chip state
                hapticTrigger += 1
                if selectedChip != .other { selectedChip = .other }
                amountFocused = true
            }

            Divider()
                .padding(.horizontal, 16)

            // Chip row — centered
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
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.backgroundSecondary)
        )
    }

    // MARK: - Payment Method Row
    //
    // Adapts to show whichever payment method is currently selected.
    // The "Change" button opens ChangePaymentMethodView via navigationDestination.

    var paymentMethodRow: some View {
        HStack(spacing: 16) {

            // Icon / badge — Apple logo badge when Apple Pay, SF Symbol otherwise
            if selectedPaymentMethod == .applePay {
                HStack(spacing: 4) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Pay")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(Color.content)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.backgroundSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.content.opacity(0.2), lineWidth: 1)
                        )
                )
            } else if case .easyBankTransfer(let bankName) = selectedPaymentMethod {
                BankIconView(
                    name: bankName,
                    initial: String(bankName.prefix(1)),
                    color: .gray,
                    assetName: bankName.lowercased().replacingOccurrences(of: " ", with: "_") + "_logo"
                )
            } else {
                Image(systemName: selectedPaymentMethod.iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.content)
                    .frame(width: 40, height: 32)
            }

            // Labels
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedPaymentMethod.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.content)

                if let sub = selectedPaymentMethod.subtitle {
                    Text(sub)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.contentSecondary)
                }
            }

            Spacer()

            Button("Change") {
                showChangePaymentSheet = true
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.fillAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color(red: 117/255, green: 129/255, blue: 126/255).opacity(0.1)))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.backgroundSecondary)
        )
        .animation(.easeInOut(duration: 0.2), value: selectedPaymentMethod)
    }

    // MARK: - Footer

    var footer: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.contentSecondary)
                    .frame(width: 24, height: 24)

                (
                    Text("You're covered by the ")
                    + Text("Financial Services Compensation Scheme").foregroundStyle(Color.fillAccent)
                    + Text(" (FSCS) up to £120,000")
                )
                .font(.system(size: 12))
                .foregroundStyle(Color.contentSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.fill)
            )

            if selectedPaymentMethod == .applePay {
                Button { showPaymentSheet = true } label: {
                    HStack(spacing: 5) {
                        Text("Add money with")
                            .font(.system(size: 18, weight: .medium))
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18, weight: .medium))
                        Text("Pay")
                            .font(.system(size: 18, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Capsule().fill(Color.black))
                }
                .buttonStyle(PressScaleButtonStyle())
            } else {
                Button { showPaymentSheet = true } label: {
                    Text("Add money")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Capsule().fill(Color.fillAccent))
                }
                .buttonStyle(PressScaleButtonStyle())
            }
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
    }

    // MARK: - Helpers

    func selectChip(_ chip: MoneyChip) {
        selectedChip  = chip
        hapticTrigger += 1

        if chip == .other {
            amountText    = ""
            amountFocused = true
            return
        }

        amountFocused = false
        amountText    = chip.displayAmount

        coinGeneration += 1
        let gen      = coinGeneration
        let newCount = chip.coinCount
        let oldCount = coins.count

        if newCount > oldCount {
            for i in 0..<(newCount - oldCount) {
                Task {
                    try? await Task.sleep(for: .seconds(Double(i) * 0.07))
                    guard gen == coinGeneration else { return }
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.58)) {
                        coins.append(UUID())
                    }
                }
            }
        } else if newCount < oldCount {
            for i in 0..<(oldCount - newCount) {
                Task {
                    try? await Task.sleep(for: .seconds(Double(i) * 0.06))
                    guard gen == coinGeneration else { return }
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                        if coins.count > newCount { coins.removeLast() }
                    }
                }
            }
        }
    }
}

// MARK: - Coin View

struct CoinView: View {

    var index:       Int  = 0
    var isFirstCoin: Bool = false
    var isTopCoin:   Bool = true

    // Specular rim highlight
    @State private var rimGlow: Double = 0


    // Top-right sparkle (last coin only)
    @State private var s1Scale:    CGFloat = 0.1
    @State private var s1Opacity:  Double  = 0
    @State private var s1Rotation: Double  = 0

    // Bottom-left sparkle (first coin only)
    @State private var s2Scale:    CGFloat = 0.1
    @State private var s2Opacity:  Double  = 0
    @State private var s2Rotation: Double  = 0

    var body: some View {
        ZStack {
            Image("subs_coin")
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                // Specular rim highlight — a warm radial glow on the left rim,
                // exactly where light catches the curved edge in the Monzo design.
                // Masked to coin shape so it never bleeds outside.
                .overlay(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.85),
                            Color(red: 1, green: 0.72, blue: 0.55).opacity(0.5),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.18, y: 0.48),
                        startRadius: 1,
                        endRadius: 22
                    )
                    .mask(Image("subs_coin").resizable().scaledToFit())
                    .opacity(rimGlow)
                    .allowsHitTesting(false)
                )
                // Depth shadow on back coins — right portion darkens behind overlap
                .overlay(
                    Group {
                        if !isTopCoin {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear,               location: 0.0),
                                    .init(color: .black.opacity(0.18), location: 0.45),
                                    .init(color: .black.opacity(0.52), location: 1.0),
                                ],
                                startPoint: UnitPoint(x: 0.15, y: 0.5),
                                endPoint:   .trailing
                            )
                            .mask(Image("subs_coin").resizable().scaledToFit())
                        }
                    }
                )
                .shadow(
                    color: .black.opacity(isTopCoin ? 0.40 : 0.22),
                    radius: isTopCoin ? 14 : 8,
                    x: isTopCoin ? 4 : 2,
                    y: isTopCoin ? 10 : 6
                )

            // Top-right sparkle — last coin only
            if isTopCoin {
                CoinSparkle()
                    .frame(width: 14, height: 14)
                    .scaleEffect(s1Scale)
                    .opacity(s1Opacity)
                    .rotationEffect(.degrees(s1Rotation))
                    .offset(x: 38, y: -30)
            }

            // Bottom-left sparkle — first coin only
            if isFirstCoin {
                CoinSparkle()
                    .frame(width: 11, height: 11)
                    .scaleEffect(s2Scale)
                    .opacity(s2Opacity)
                    .rotationEffect(.degrees(s2Rotation))
                    .offset(x: -32, y: 28)
            }
        }
        .frame(width: 90, height: 90)
        .onAppear { startAnimations() }
    }

    private func startAnimations() {
        // Stagger each coin's rim glow so they never pulse in sync
        Task {
            try? await Task.sleep(for: .milliseconds(Int(Double(index) * 380)))
            pulseRim()
        }
        if isTopCoin   { twinkle1() }
        if isFirstCoin {
            Task {
                try? await Task.sleep(for: .milliseconds(700))
                twinkle2()
            }
        }
    }

    // Rim glow — fades in slowly, holds, fades out, waits, repeats
    private func pulseRim() {
        rimGlow = 0
        withAnimation(.easeIn(duration: 0.5))  { rimGlow = 1.0 }
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(.easeOut(duration: 0.7)) { rimGlow = 0 }
        }
        Task {
            try? await Task.sleep(for: .milliseconds(Int.random(in: 2800...4500)))
            pulseRim()
        }
    }

    // Top-right sparkle (last coin)
    private func twinkle1() {
        s1Scale = 0.1; s1Opacity = 0; s1Rotation = 0
        withAnimation(.spring(duration: 0.32, bounce: 0.35)) { s1Scale   = 1.0 }
        withAnimation(.easeOut(duration: 0.22))              { s1Opacity = 1.0 }
        withAnimation(.linear(duration: 0.55))               { s1Rotation = 45 }
        Task {
            try? await Task.sleep(for: .milliseconds(360))
            withAnimation(.easeIn(duration: 0.28)) { s1Opacity = 0; s1Scale = 0.5 }
        }
        Task {
            try? await Task.sleep(for: .milliseconds(Int.random(in: 2400...4200)))
            twinkle1()
        }
    }

    // Bottom-left sparkle (first coin)
    private func twinkle2() {
        s2Scale = 0.1; s2Opacity = 0; s2Rotation = 0
        withAnimation(.spring(duration: 0.30, bounce: 0.35)) { s2Scale   = 0.85 }
        withAnimation(.easeOut(duration: 0.20))              { s2Opacity = 0.85 }
        withAnimation(.linear(duration: 0.50))               { s2Rotation = 45 }
        Task {
            try? await Task.sleep(for: .milliseconds(340))
            withAnimation(.easeIn(duration: 0.26)) { s2Opacity = 0; s2Scale = 0.4 }
        }
        Task {
            try? await Task.sleep(for: .milliseconds(Int.random(in: 2600...4400)))
            twinkle2()
        }
    }
}

// MARK: - Coin Sparkle Shape

private struct CoinSparkle: View {
    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let outer = min(cx, cy)
            let inner = outer * 0.18

            var path = Path()
            for i in 0..<8 {
                let angle = Double(i) * .pi / 4 - .pi / 2
                let r     = i % 2 == 0 ? outer : inner
                let pt    = CGPoint(x: cx + CGFloat(cos(angle)) * r,
                                    y: cy + CGFloat(sin(angle)) * r)
                i == 0 ? path.move(to: pt) : path.addLine(to: pt)
            }
            path.closeSubpath()
            ctx.fill(path, with: .color(.white))
        }
        .shadow(color: .white.opacity(0.9), radius: 5)
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
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.page)
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
                        // Animate the border and shadow appearing/disappearing
                        .animation(.easeInOut(duration: 0.15), value: isSelected)
                )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

// MARK: - Revolut-Style Pay Button
//
// A single black capsule with two zones:
//   Left: "Add money with [Apple logo] Pay"
//   Right (separated by a hairline): mini Monzo card thumbnail
//
// This approach lets the user see at a glance which card will be charged —
// same pattern as Revolut's payment button. The actual PKPaymentButton
// (PKAddMoneyButton.swift) is available separately if needed for production.

struct RevolutStylePayButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Apple Pay label
                HStack(spacing: 5) {
                    Text("Add money with")
                        .font(.system(size: 15, weight: .medium))
                    Image(systemName: "apple.logo")
                        .font(.system(size: 15, weight: .medium))
                    Text("Pay")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)

                // Hairline separator
                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 1, height: 24)

                // Mini Monzo card thumbnail
                MiniMonzoCard()
                    .padding(.horizontal, 16)
            }
            .frame(height: 52)
            .background(Capsule().fill(Color.black))
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

// MARK: - Mini Monzo Card
//
// A small thumbnail of the Monzo hot-coral card shown in the Revolut-style button.
// 36×23pt at a 1.565:1 ratio (matches the real card proportions).

struct MiniMonzoCard: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#FF6849"), Color(hex: "#D94020")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Chip placeholder
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.35))
                .frame(width: 10, height: 7)
                .padding(5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .frame(width: 36, height: 23)
        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Mock Apple Pay Sheet
//
// Simulates the native Apple Pay confirmation UI.
// Tapping "Pay with Face ID" calls onConfirm, which dismisses the sheet and
// navigates to MoneyAddedView.

struct MockApplePaySheet: View {
    @Environment(\.dismiss) private var dismiss
    let amount: String
    let onConfirm: () -> Void

    @State private var isConfirming = false
    @State private var confirmHaptic: Int = 0

    private var formattedAmount: String {
        let digits = amount.filter { $0.isNumber }
        guard let n = Int(digits) else { return "0.00" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_GB")
        return (formatter.string(from: NSNumber(value: n)) ?? "\(n)") + ".00"
    }

    var body: some View {
        VStack(spacing: 0) {

            // Drag indicator
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Merchant header
            VStack(spacing: 8) {
                // Monzo logo stand-in
                ZStack {
                    Circle()
                        .fill(Color(hex: "#FF6849"))
                        .frame(width: 56, height: 56)
                    Text("M")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text("Monzo")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("Business account")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 24)

            Divider()

            // Amount row
            HStack {
                Text("Total")
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
                Spacer()
                Text("£\(formattedAmount)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider()

            // Payment card row
            HStack(spacing: 12) {
                MiniMonzoCard()
                    .scaleEffect(1.4)
                    .frame(width: 50, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Pay")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                    Text("Visa •••• 1234")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider()

            Spacer(minLength: 24)

            // Pay with Face ID button
            Button {
                guard !isConfirming else { return }
                isConfirming   = true
                confirmHaptic += 1
                onConfirm()
            } label: {
                HStack(spacing: 8) {
                    if isConfirming {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "faceid")
                            .font(.system(size: 18, weight: .medium))
                        Text("Pay with Face ID")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Capsule().fill(Color.black))
            }
            .buttonStyle(PressScaleButtonStyle())
            .padding(.horizontal, 24)
            .disabled(isConfirming)

            // Cancel
            Button("Cancel") { dismiss() }
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .padding(.vertical, 16)
        }
        .padding(.bottom, 8)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)   // we draw our own
        .sensoryFeedback(.success, trigger: confirmHaptic)
    }
}

#Preview {
    NavigationStack {
        AddMoneyView()
    }
}
