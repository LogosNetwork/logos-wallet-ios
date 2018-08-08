//
//  AccountInfoResponse.swift
//  LogosWallet
//
//  Created by Ben Kray on 8/7/18.
//  Copyright © 2018 Planar Form. All rights reserved.
//

import Foundation

struct AccountInfoResponse: Codable {
    let frontier: String
    let openBlock: String
    let representativeBlock: String
    let balance: String
    let modifiedTimestamp: String
    let blockCount: String
}
