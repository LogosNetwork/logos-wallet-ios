//
//  Block.swift
//  LogosWallet
//
//  Created by Ben Kray on 12/6/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation

struct TransactionBlock: Codable {
    let account, previous, sequence, transactionType: String
    let transactionFee, signature, numberTransactions: String
    let transactions: [Transaction]
    let hash, timestamp, batchHash: String
    let indexInBatch, batchBlockHash, prevHash: String

    enum CodingKeys: String, CodingKey {
        case account, previous, sequence
        case transactionType = "transaction_type"
        case transactionFee = "transaction_fee"
        case signature
        case numberTransactions = "number_transactions"
        case transactions, hash
        case batchHash = "batch_hash"
        case indexInBatch = "index_in_batch"
        case timestamp, batchBlockHash, prevHash
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.account = try container.decode(String.self, forKey: .account)
        self.previous = try container.decode(String.self, forKey: .previous)
        self.sequence = try container.decode(String.self, forKey: .sequence)
        self.transactionType = try container.decode(String.self, forKey: .transactionType)
        self.transactionFee = try container.decode(String.self, forKey: .transactionFee)
        self.signature = try container.decode(String.self, forKey: .signature)
        self.numberTransactions = try container.decode(String.self, forKey: .numberTransactions)
        self.transactions = try container.decode([Transaction].self, forKey: .transactions)
        self.hash = try container.decode(String.self, forKey: .hash)
        self.batchHash = try container.decodeIfPresent(String.self, forKey: .batchHash) ?? ""
        self.indexInBatch = try container.decodeIfPresent(String.self, forKey: .indexInBatch) ?? ""
        self.timestamp = try container.decodeIfPresent(String.self, forKey: .timestamp) ?? ""
        self.batchBlockHash = try container.decodeIfPresent(String.self, forKey: .batchBlockHash) ?? ""
        self.prevHash = try container.decodeIfPresent(String.self, forKey: .prevHash) ?? ""
    }

    func simpleBlock(account: String) -> SimpleBlockBridge {
        let block = SimpleBlock()
        block.blockHash = self.hash
        block.type = self.transactionType
        block.account = self.account
        let transaction: Transaction?
        if self.isReceive(of: account) {
            transaction = self.transactions.first { $0.target == account }
        } else {
            transaction = transactions.first
        }
        block.amount = transaction?.amount ?? "--"
        block.target = transaction?.target ?? "--"
        return block
    }
}

extension TransactionBlock {

    func isReceive(of owner: String) -> Bool {
        return self.account != owner
    }

}

struct Transaction: Codable {
    let target, amount, blockHash: String

    enum CodingKeys: String, CodingKey {
        case target, amount, blockHash
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.target = try container.decode(String.self, forKey: .target)
        self.amount = try container.decode(String.self, forKey: .amount)
        self.blockHash = try container.decodeIfPresent(String.self, forKey: .blockHash) ?? ""
    }
}

struct AccountHistory: Codable {
    let account: String
    let history: [TransactionBlock]
}
