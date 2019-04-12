//
//  LogosAccountInfo.swift
//  LogosWallet
//
//  Created by Ben Kray on 3/19/19.
//  Copyright © 2019 Planar Form. All rights reserved.
//

import Foundation

struct LogosAccountInfo: Codable {
    let type, frontier, receiveTip, openBlock: String
    let representativeBlock, balance, modifiedTimestamp, requestCount: String
    let sequence: String
    let tokens: [String: Token]?

    enum CodingKeys: String, CodingKey {
        case type, frontier
        case receiveTip = "receive_tip"
        case openBlock = "open_block"
        case representativeBlock = "representative_block"
        case balance
        case modifiedTimestamp = "modified_timestamp"
        case requestCount = "request_count"
        case sequence, tokens
    }
}

extension LogosAccountInfo: AccountCarouselAdapter {

    var name: String {
        return "Logos"
    }

    var symbol: String {
        return "LGS"
    }

    var accountBalance: String {
        return self.formattedBalance
    }

}

struct Token: Codable {
    let whitelisted, frozen, balance: String
}

extension LogosAccountInfo {
    var mlgsBalance: String {
        return self.balance.decimalNumber.mlgsString
    }

    var formattedBalance: String {
        return self.mlgsBalance.formattedAmount
    }
}

struct TokenAccount: AccountCarouselAdapter {
    let accountBalance: String
    let name: String
    let symbol: String
    var tokenID: String? = nil
}
