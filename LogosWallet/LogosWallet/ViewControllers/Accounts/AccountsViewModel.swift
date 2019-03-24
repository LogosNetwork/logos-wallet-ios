//
//  AccountsViewModel.swift
//  LogosWallet
//
//  Created by Ben Kray on 1/13/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation

struct AccountsViewModel {

    fileprivate var totalLGS: NSDecimalNumber {
        let total = WalletManager.shared.accounts.reduce(NSDecimalNumber(decimal: 0.0), { (result, account) in
            result.adding(account.info.balance.decimalNumber)
        })
        return total
    }

    var currencyValue: String {
        if self.isShowingSecondary == true {
            return Currency.secondary.denomination
        } else {
            return CURRENCY_NAME
        }
    }
    var balanceValue: String {
        if !isShowingSecondary {
            return self.totalLGS.mlgsString.formattedAmount
        } else {
            return Currency.secondary.convert(self.totalLGS)
        }
    }
    var isShowingSecondary: Bool {
        return Currency.isSecondarySelected
    }
    
    mutating func toggleCurrency() {
        Currency.setSecondary(!self.isShowingSecondary)
    }

}
