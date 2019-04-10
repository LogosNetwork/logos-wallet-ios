//
//  LogosTokenAccountInfo.swift
//  LogosWallet
//
//  Created by Ben Kray on 3/31/19.
//  Copyright © 2019 Planar Form. All rights reserved.
//

import Foundation

struct LogosTokenAccountInfo: Codable {
    let tokenBalance, totalSupply, tokenFeeBalance, symbol: String
    let name, issuerInfo, feeRate, feeType: String
    let controllers: [Controller]
//    let settings: [String]
    let issuanceRequest, type, sequence, requestCount: String
    let frontier, receiveTip, balance: String

    enum CodingKeys: String, CodingKey {
        case tokenBalance = "token_balance"
        case totalSupply = "total_supply"
        case tokenFeeBalance = "token_fee_balance"
        case symbol, name
        case issuerInfo = "issuer_info"
        case feeRate = "fee_rate"
        case feeType = "fee_type"
        case controllers
//        case settings
        case issuanceRequest = "issuance_request"
        case type, sequence
        case requestCount = "request_count"
        case frontier
        case receiveTip = "receive_tip"
        case balance
    }
}

struct Controller: Codable {
    let account: String
    let privileges: [String]
}
