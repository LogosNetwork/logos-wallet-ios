//
//  Block.swift
//  LogosWallet
//
//  Created by Ben Kray on 12/6/18.
//  Copyright © 2018 Planar Form. All rights reserved.
//

import Foundation

/*
 {
 "type": "send",
 "account": "lgs_1rbazoy99ubxfhxqtqpy3cfswu8enkjehzo6anxgmfyfku86nu3ojorq6mgc",
 "previous": "0000000000000000000000000000000000000000000000000000000000000000",
 "representative": "lgs_1111111111111111111111111111111111111111111111111111hifc8npp",
 "amount": "1000000000000000000000000000000",
 "transaction_fee": "10000000000000000000000",
 "link": "F596B8CA96DDD72A18EF5AA556B60591BFF5B7676AC9F9CA5A48F961180E6DC4",
 "link_as_account": "lgs_3xepq57bfqgq7aegypo7ctu1d6fzypupgtpbz977nk9se6e1wug6whnitmxs",
 "signature": "1E050E14AC8BCB6944BFFC0F618D2E7BFDA19F77E944B469556F43F0415382F8D3E39AEF6A7364881E3E8BAB61206FE1DB63916E9CAECBF89627069559C9E404",
 "work": "0000000000000000",
 "timestamp": "1544161462705"
 }
 */
struct Block: Codable {

    var type: String
    var account: String
    var previous: String
    var representative: String
    var amount: String
    var transactionFee: String
    var link: String
    var linkAsAccount: String
    var signature: String
    var work: String
    var timestamp: String

    enum CodingKeys: String, CodingKey {
        case type
        case account
        case previous
        case representative
        case amount
        case link
        case linkAsAccount = "link_as_account"
        case transactionFee = "transaction_fee"
        case signature
        case work
        case timestamp
    }
    
}
