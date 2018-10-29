//
//  SubscribedTransaction.swift
//  LogosWallet
//
//  Created by Ben Kray on 10/28/18.
//  Copyright © 2018 Planar Form. All rights reserved.
//

import Foundation

struct SubscribedTransaction: Codable {

    let account: String
    let amount: String
    // TODO: Change to codable StateBlock
    let block: String
    let hash: String
    let isSend: String

}
