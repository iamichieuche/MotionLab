//
//  PaymentMethod.swift
//  MotionLab
//
//  Experiment 03 — Onboarding Flow
//
//  Shared payment method model used by AddMoneyView, ChangePaymentMethodView,
//  and SelectBankView. Single source of truth for what's selected.

import SwiftUI

enum PaymentMethod: Equatable {
    case applePay
    case easyBankTransfer(bank: String)
    case chequeDeposit
    case cashDeposit
    case regularBankTransfer
    case fromAnotherMonzo
    case internationalTransfer

    // Primary display label shown in the payment row
    var displayName: String {
        switch self {
        case .applePay:                        return "Apple Pay"
        case .easyBankTransfer(let bank):      return bank
        case .chequeDeposit:                   return "Cheque deposit"
        case .cashDeposit:                     return "Cash deposit"
        case .regularBankTransfer:             return "Regular bank transfer"
        case .fromAnotherMonzo:                return "From another Monzo"
        case .internationalTransfer:           return "International bank transfer"
        }
    }

    // Secondary label shown below displayName (nil hides the subtitle line)
    var subtitle: String? {
        switch self {
        case .applePay:                        return nil
        case .easyBankTransfer:                return "Easy bank transfer"
        case .chequeDeposit:                   return "Up to £500"
        case .cashDeposit:                     return "PayPoint or Post Office"
        case .regularBankTransfer:             return nil
        case .fromAnotherMonzo:                return nil
        case .internationalTransfer:           return nil
        }
    }

    var iconName: String {
        switch self {
        case .applePay:                        return "apple.logo"
        case .easyBankTransfer:                return "building.columns"
        case .chequeDeposit:                   return "doc.text"
        case .cashDeposit:                     return "banknote"
        case .regularBankTransfer:             return "arrow.left.arrow.right"
        case .fromAnotherMonzo:                return "m.circle"
        case .internationalTransfer:           return "globe"
        }
    }
}
