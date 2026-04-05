//
//  ChangePaymentMethodView.swift
//  MotionLab
//
//  Experiment 03 — Onboarding Flow
//
//  Built from Figma node 48:1121.
//  Presented as a sheet from AddMoneyView with its own NavigationStack.
//
//  Navigation contract:
//  • Direct method rows call dismiss() to close the sheet immediately.
//  • "See all banks" pushes SelectBankView; AddMoneyView watches the binding
//    and closes the sheet when a bank is set — no pop flash.

import SwiftUI

// MARK: - View

struct ChangePaymentMethodView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPaymentMethod: PaymentMethod

    @State private var navigateToSelectBank = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {

                // MARK: — Apple Pay (standalone at top)
                MethodCard {
                    MethodRow(
                        icon: applePayIcon,
                        title: "Apple Pay",
                        subtitle: "Usually arrives instantly",
                        badge: nil,
                        isSelected: selectedPaymentMethod == .applePay,
                        showChevron: true
                    ) {
                        selectedPaymentMethod = .applePay
                        dismiss()
                    }
                }

                // MARK: — Easy bank transfer
                MethodCard {
                    VStack(alignment: .leading, spacing: 12) {

                        // Section header with pill
                        HStack {
                            Text("Easy bank transfer")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.content)
                            Spacer()
                            Text("Instant & secure")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color(hex: "#34C759")))
                        }

                        // Description
                        Group {
                            Text("Transfer money from another bank account quickly and securely, without having to enter your Monzo account details. ")
                            + Text("Learn more").foregroundStyle(Color.fillAccent)
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(Color.contentSecondary)

                        Divider()

                        // Preset banks
                        BankMethodRow(
                            bank: Bank(name: "NatWest", initial: "N", color: Color(hex: "#42145F"), assetName: "natwest_logo"),
                            isSelected: {
                                if case .easyBankTransfer("NatWest") = selectedPaymentMethod { return true }
                                return false
                            }()
                        ) {
                            selectedPaymentMethod = .easyBankTransfer(bank: "NatWest")
                            dismiss()
                        }

                        Divider().padding(.leading, 56)

                        BankMethodRow(
                            bank: Bank(name: "Chase", initial: "C", color: Color(hex: "#005EB8"), assetName: "chase_logo"),
                            isSelected: {
                                if case .easyBankTransfer("Chase") = selectedPaymentMethod { return true }
                                return false
                            }()
                        ) {
                            selectedPaymentMethod = .easyBankTransfer(bank: "Chase")
                            dismiss()
                        }

                        Divider()

                        // See all banks — navigates deeper; AddMoneyView closes sheet on selection
                        Button {
                            navigateToSelectBank = true
                        } label: {
                            Text("See all banks")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.fillAccent)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }

                // MARK: — Deposits
                MethodCard {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Deposits")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.content)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 12)

                        Divider().padding(.horizontal, 16)

                        MethodRow(
                            icon: tealIcon("doc.text.fill"),
                            title: "Cheque deposit",
                            subtitle: "In-app up to £500, or by post",
                            badge: nil,
                            isSelected: selectedPaymentMethod == .chequeDeposit,
                            showChevron: true
                        ) {
                            selectedPaymentMethod = .chequeDeposit
                            dismiss()
                        }

                        Divider().padding(.leading, 72)

                        MethodRow(
                            icon: tealIcon("banknote.fill"),
                            title: "Cash deposit",
                            subtitle: "Pay in at a PayPoint or Post Office",
                            badge: nil,
                            isSelected: selectedPaymentMethod == .cashDeposit,
                            showChevron: true
                        ) {
                            selectedPaymentMethod = .cashDeposit
                            dismiss()
                        }
                    }
                }

                // MARK: — Other ways
                MethodCard {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Other ways to add money")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.content)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 12)

                        Divider().padding(.horizontal, 16)

                        MethodRow(
                            icon: tealIcon("building.columns.fill"),
                            title: "Regular bank transfer",
                            subtitle: "Done in your other banking app",
                            badge: nil,
                            isSelected: selectedPaymentMethod == .regularBankTransfer,
                            showChevron: true
                        ) {
                            selectedPaymentMethod = .regularBankTransfer
                            dismiss()
                        }

                        Divider().padding(.leading, 72)

                        MethodRow(
                            icon: tealIcon("arrow.left.arrow.right"),
                            title: "From another Monzo account",
                            subtitle: "Move between your accounts and pots",
                            badge: nil,
                            isSelected: selectedPaymentMethod == .fromAnotherMonzo,
                            showChevron: true
                        ) {
                            selectedPaymentMethod = .fromAnotherMonzo
                            dismiss()
                        }

                        Divider().padding(.leading, 72)

                        MethodRow(
                            icon: tealIcon("globe"),
                            title: "International bank transfer",
                            subtitle: "Receive money from another country",
                            badge: nil,
                            isSelected: selectedPaymentMethod == .internationalTransfer,
                            showChevron: true
                        ) {
                            selectedPaymentMethod = .internationalTransfer
                            dismiss()
                        }
                    }
                }

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(Color.page.ignoresSafeArea())
        .navigationTitle("Add money")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                }
            }
        }
        .navigationDestination(isPresented: $navigateToSelectBank) {
            // Pass dismiss() as onClose so SelectBankView's X closes the whole sheet,
            // not just pops within the NavigationStack.
            SelectBankView(
                selectedPaymentMethod: $selectedPaymentMethod,
                onClose: { dismiss() }
            )
        }
    }

    // MARK: - Icon helpers

    // Apple Pay: Apple logo in a dark rounded-square badge
    private var applePayIcon: AnyView {
        AnyView(
            HStack(spacing: 3) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 13, weight: .semibold))
                Text("Pay")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Color.content)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.content.opacity(0.2), lineWidth: 1)
                    )
            )
        )
    }

    // Teal icon — used for Deposits and Other ways rows
    private func tealIcon(_ systemName: String) -> AnyView {
        AnyView(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.fillAccent)
                    .frame(width: 40, height: 40)
                Image(systemName: systemName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
            }
        )
    }
}

// MARK: - Method Card

private struct MethodCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.backgroundSecondary)
        )
    }
}

// MARK: - Method Row (Deposits / Other ways / Apple Pay)

private struct MethodRow: View {
    let icon:        AnyView
    let title:       String
    let subtitle:    String?
    let badge:       String?   // small pill label like "Instant"
    let isSelected:  Bool
    let showChevron: Bool
    let action:      () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                icon

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.content)

                    if let sub = subtitle {
                        Text(sub)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.contentSecondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.fillAccent)
                } else if let badge {
                    Text(badge)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(hex: "#34C759")))
                } else if showChevron {
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

// MARK: - Bank Method Row (Easy bank transfer section)

private struct BankMethodRow: View {
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
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

#Preview {
    NavigationStack {
        ChangePaymentMethodView(selectedPaymentMethod: .constant(.applePay))
    }
}
