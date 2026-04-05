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
    let id        = UUID()
    let name:     String
    let initial:  String
    let color:    Color    // brand color fallback if asset is missing
    let assetName: String  // image asset name in Assets.xcassets
}

// MARK: - View

struct SelectBankView: View {
    @Binding var selectedPaymentMethod: PaymentMethod
    var onClose: (() -> Void)? = nil   // closes the whole sheet; nil in previews

    private let banks: [Bank] = [
        Bank(name: "HSBC",       initial: "H", color: Color(hex: "#DB0011"), assetName: "hsbc_logo"),
        Bank(name: "Halifax",    initial: "H", color: Color(hex: "#005EB8"), assetName: "halifax_logo"),
        Bank(name: "NatWest",    initial: "N", color: Color(hex: "#42145F"), assetName: "natwest_logo"),
        Bank(name: "Nationwide", initial: "N", color: Color(hex: "#1F3C88"), assetName: "nationwide_logo"),
        Bank(name: "Revolut",    initial: "R", color: Color(hex: "#191C1F"), assetName: "revolut_logo"),
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
// Uses a bundled image asset (e.g. "bank_hsbc" in Assets.xcassets).
// Falls back to a branded-color square with bold initial if the asset is missing.
// To add real logos: drag PNGs into Assets.xcassets named bank_hsbc, bank_halifax,
// bank_natwest, bank_nationwide, bank_revolut.

struct BankIconView: View {
    let bank: Bank

    var body: some View {
        if let uiImage = UIImage(named: bank.assetName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
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
}

// Convenience init so ChangePaymentMethodView can pass inline bank data
extension BankIconView {
    init(name: String, initial: String, color: Color, assetName: String) {
        self.bank = Bank(name: name, initial: initial, color: color, assetName: assetName)
    }
}

#Preview {
    NavigationStack {
        SelectBankView(selectedPaymentMethod: .constant(.applePay))
    }
}
