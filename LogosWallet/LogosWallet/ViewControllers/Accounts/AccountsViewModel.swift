//
//  AccountsViewModel.swift
//  LogosWallet
//
//  Created by Ben Kray on 1/13/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation

struct AccountsViewModel {
    
    var currencyValue: String {
        if self.isShowingSecondary == true {
            return Currency.secondary.denomination
        } else {
            return CURRENCY_NAME
        }
    }
    var balanceValue: String {
        if !isShowingSecondary {
            return self.getTotalLGS()
        } else {
            let total = WalletManager.shared.accounts.reduce(BDouble(0.0), { (result, account) in
                result + (BDouble(account.balance) ?? 0.0)
            })
            return Currency.secondary.convert(total)
        }
    }
    var isShowingSecondary: Bool {
        return Currency.isSecondarySelected
    }
    
    mutating func toggleCurrency() {
        Currency.setSecondary(!self.isShowingSecondary)
    }
    
    func getTotalLGS() -> String {
        let total = WalletManager.shared.accounts.reduce(Double(0.0), { (result, account) in
            result + (Double(account.balance.bNumber.toMlgs) ?? 0.0)
        })
        return String(total).trimTrailingZeros()
    }
}
