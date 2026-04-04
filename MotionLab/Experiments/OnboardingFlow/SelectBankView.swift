//
//  SelectBankView.swift
//  MotionLab
//
//  Experiment 03 — Onboarding Flow
//
//  Built from Figma node 48:1168.
//  "Select your bank" sheet — presented inside the ChangePaymentMethodView NavigationStack.
//
//  Navigation contract: this view does NOT call dismiss(). AddMoneyView watches
//  selectedPaymentMethod and dismisses the sheet when it sees a bank transfer selected.
//  This gives a clean one-step collapse with no intermediate pop flash.

import SwiftUI

// MARK: - Bank Model

struct Bank: Identifiable {
    let id       = UUID()
    let name:    String
    let initial: String
    let color:   Color   // brand color used as icon background
}

// MARK: - View

struct SelectBankView: View {
    @Binding var selectedPaymentMethod: PaymentMethod

    private let banks: [Bank] = [
        Bank(name: "HSBC",       initial: "H", color: Color(hex: "#DB0011")),
        Bank(name: "Halifax",    initial: "H", color: Color(hex: "#005EB8")),
        Bank(name: "NatWest",    initial: "N", color: Color(hex: "#42145F")),
        Bank(name: "Nationwide", initial: "N", color: Color(hex: "#1F3C88")),
        Bank(name: "Revolut",    initial: "R", color: Color(hex: "#191C1F")),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(Array(banks.enumerated()), id: \.element.id) { index, bank in
                    BankRow(
                        bank: bank,
                        isSelected: {
                            if case .easyBankTransfer(let b) = selectedPaymentMethod { return b == bank.name }
                            return false
                        }()
                    ) {
                        // Setting the binding is enough — AddMoneyView closes the sheet.
                        selectedPaymentMethod = .easyBankTransfer(bank: bank.name)
                    }

                    if index < banks.count - 1 {
                        Divider()
                            .padding(.leading, 72)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.backgroundSecondary)
            )
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(Color.page.ignoresSafeArea())
        .navigationTitle("Select your bank")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { /* AddMoneyView closes the sheet */ }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.fillAccent)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Help") { }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.fillAccent)
            }
        }
    }
}

// MARK: - Bank Row

private struct BankRow: View {
    let bank:       Bank
    let isSelected: Bool
    let action:     () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                BankIconView(bank: bank)

                Text(bank.name)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.content)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.fillAccent)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.contentDisabled)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

// MARK: - Bank Icon View
//
// Approximates a real bank logo using brand color + bold initial letter.
// Consistent across SelectBankView and ChangePaymentMethodView.
// Replace with Image(bankName) once real assets are available.

struct BankIconView: View {
    let bank: Bank

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(bank.color)
                .frame(width: 40, height: 40)

            Text(bank.initial)
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(.white)
        }
    }
}

// Convenience init so ChangePaymentMethodView can construct icons inline
extension BankIconView {
    init(name: String, initial: String, color: Color) {
        self.bank = Bank(name: name, initial: initial, color: color)
    }
}

#Preview {
    NavigationStack {
        SelectBankView(selectedPaymentMethod: .constant(.applePay))
    }
}
