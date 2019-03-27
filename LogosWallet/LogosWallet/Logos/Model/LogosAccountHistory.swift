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
    let history: [TransactionRequest]
    let previous: String?
}

struct TransactionRequest: Codable {
    let type: String
    let origin: String
    let previous, fee, sequence, signature: String
    let work, next, hash, requestBlockHash: String
    let requestBlockIndex: String
    let numberTransactions: String?
    let transactions: [Transaction]?
    let timestamp: String
    let tokenID: String?
    let transaction: Transaction?
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

struct Transaction: Codable {
    let destination: String
    let amount: String
}

extension TransactionRequest {

    func isReceive(of account: String) -> Bool {
        return origin != account
    }

    func amountTotal(for account: String) -> NSDecimalNumber {
        if let transaction = self.transaction {
            return transaction.amount.decimalNumber
        } else {
            let transactions: [Transaction]
            if self.isReceive(of: account) {
                transactions = self.transactions?.compactMap { $0 }.filter { $0.destination == account } ?? []
            } else {
                transactions = self.transactions ?? []
            }
            return transactions.reduce(0, { (result, transaction) -> NSDecimalNumber in
                result.adding(transaction.amount.decimalNumber)
            })
        }
    }
}
