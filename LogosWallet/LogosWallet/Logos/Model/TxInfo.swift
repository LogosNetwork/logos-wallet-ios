//
//  TxInfo.swift
//  LogosWallet
//
//  Created by Ben Kray on 1/31/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation

struct TxInfo {
    var tokenID: String?
    var recipientName: String
    var recipientAddress: String
    var amount: String
    var account: LogosAccount

    var remainingBalance: String {
        if let tokenID = self.tokenID, let tokenInfo = self.account.info?.tokens?[tokenID] {
            let feeRate = LogosTokenManager.shared.tokenAccounts[tokenID]?.feeRate.decimalNumber ?? 0
            if let decimals = LogosTokenManager.shared.tokenAccounts[tokenID]?.decimals {
                let amount = self.amount.decimalNumber.rawValue(decimals)
                return tokenInfo.balance.decimalNumber.subtracting(amount).subtracting(feeRate).formattedValue(decimals).stringValue.formattedBalance
            } else {
                return tokenInfo.balance.decimalNumber.subtracting(self.amount.decimalNumber).subtracting(feeRate).stringValue.formattedBalance
            }
        } else if let balance = self.account.info?.balance.decimalNumber {
            let rawAmount = amount.decimalNumber.lgsRawValue
            return balance.subtracting(rawAmount).mlgsString
        } else {
            return "--"
        }
    }
}
