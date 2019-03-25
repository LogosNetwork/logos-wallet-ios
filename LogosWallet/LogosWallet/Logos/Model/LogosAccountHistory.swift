//
//  LogosAccountHistory.swift
//  LogosWallet
//
//  Created by Ben Kray on 3/24/19.
//  Copyright © 2019 Planar Form. All rights reserved.
//

import Foundation

struct LogosAccountHistory: Codable {
    let account: String
    let history: [HistoryTransactionBlock]
    let previous: String
}

struct HistoryTransactionBlock: Codable {
    let type: String
    let origin: String
    let previous, fee, sequence, signature: String
    let work, next, hash, requestBlockHash: String
    let requestBlockIndex: String
    let numberTransactions: String?
    let transactions: [HistoryTransaction]?
    let timestamp: String
    let tokenID: String?
    let transaction: HistoryTransaction?
    let tokenFee: String?

    enum CodingKeys: String, CodingKey {
        case type, origin, previous, fee, sequence, signature, work, next, hash
        case requestBlockHash = "request_block_hash"
        case requestBlockIndex = "request_block_index"
        case numberTransactions = "number_transactions"
        case transactions, timestamp
        case tokenID = "token_id"
        case transaction
        case tokenFee = "token_fee"
    }
}

struct HistoryTransaction: Codable {
    let destination: String
    let amount: String
}
