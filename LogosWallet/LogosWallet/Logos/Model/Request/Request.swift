//
//  Request.swift
//  LogosWallet
//
//  Created by Ben Kray on 3/26/19.
//  Copyright © 2019 Planar Form. All rights reserved.
//

import Foundation

// Base class for all Request types

class Request {

    enum RequestType: UInt8 {
        case send
        case change
        case tokenSend = 14
        case unknown = 0xff

        var data: Data {
            return Data(bytes: [self.rawValue])
        }

        var string: String {
            switch self {
            case .send:
                return "send"
            case .change:
                return "change"
            case .tokenSend:
                return "token_send"
            case .unknown:
                return "unknown"

            }
        }

        static func from(string: String) -> RequestType? {
            switch string {
            case RequestType.send.string:
                return .send
            case RequestType.change.string:
                return .change
            case RequestType.unknown.string:
                return .unknown
            default:
                return nil
            }
        }
    }

    var hash = ""
    var origin = ""
    var previous = ""
    var sequence: NSDecimalNumber = 0
    var type: RequestType = .unknown
    var fee: NSDecimalNumber = 0
    var signature = ""
    var work = ""

    var json: String {
        return ""
    }

    func sign(with keys: KeyPair) -> Bool {
        guard
            let hash = self.hash.hexData,
            let signatureData = NaCl.sign(hash, secret: keys.secretKey)
        else {
            return false
        }

        self.signature = signatureData.hexString
        return NaCl.verify(hash, signature: signatureData, publicKey: keys.publicKey)
    }
}
