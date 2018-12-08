//
//  AccountsViewModel.swift
//  LogosWallet
//
//  Created by Ben Kray on 1/13/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation

struct AccountsViewModel {
    
    private(set) var balanceValue: String = ""
    private(set) var currencyValue: String
    private(set) var isShowingSecondary: Bool = false
    
    init() {
        currencyValue = CURRENCY_NAME
        balanceValue = self.getTotalLGS()
    }
    
    mutating func toggleCurrency() {
        if isShowingSecondary {
            currencyValue = CURRENCY_NAME
            balanceValue = self.getTotalLGS()
        } else {
            currencyValue = Currency.secondary.denomination
            let total = WalletManager.shared.accounts.reduce(BDouble(0.0), { (result, account) in
                result + (BDouble(account.balance) ?? 0.0)
            })
            balanceValue = Currency.secondary.convert(total)
        }
        isShowingSecondary = !isShowingSecondary
    }
    
    func getTotalLGS() -> String {
        let total = WalletManager.shared.accounts.reduce(Double(0.0), { (result, account) in
            result + (Double(account.balance.bNumber.toMlgs) ?? 0.0)
        })
        return String(total).trimTrailingZeros()
    }
}
