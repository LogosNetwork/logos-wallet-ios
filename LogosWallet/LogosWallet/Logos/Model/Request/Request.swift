//
//  Request.swift
//  LogosWallet
//
//  Created by Ben Kray on 3/26/19.
//  Copyright © 2019 Planar Form. All rights reserved.
//

import Foundation

// Base class for all Request types

class Request: RequestAdapter {

    enum RequestType: UInt8 {
        case send
        case change
        case tokenSend = 15
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

    var originData: Data? {
        return WalletUtil.derivePublic(from: self.origin)?.hexData
    }
    var previousData: Data? {
        return self.previous.hexData
    }
    var sequenceData: Data? {
        return self.sequence.hexString?.leftPadding(toLength: 8, withPad: "0").hexData
    }
    var feeData: Data? {
        return self.fee.hexString?.leftPadding(toLength: 32, withPad: "0").hexData
    }

    var json: [String: Any] {
        return [
            "hash": self.hash,
            "type": self.type.string,
            "origin": self.origin,
            "previous": self.previous,
            "signature": self.signature,
            "work": self.work,
            "fee": self.fee.stringValue,
            "sequence": self.sequence.stringValue,
        ]
    }

    func sign(with keys: KeyPair) -> Bool {
        guard
            let hashItems = self.hashItems,
            let hash = NaCl.digest(hashItems, outputLength: HASH_BYTES),
            let signatureData = NaCl.sign(hash, secret: keys.secretKey)
        else {
            return false
        }

        self.hash = hash.hexString.uppercased()
        self.signature = signatureData.hexString.uppercased()
        return NaCl.verify(hash, signature: signatureData, publicKey: keys.publicKey)
    }

    var hashItems: [Data]? {
        guard
            let originData = self.originData,
            let previousData = self.previousData,
            let feeData = self.feeData,
            let sequenceData = self.sequenceData
        else {
            return nil
        }

        return [
            self.type.data,
            originData,
            previousData,
            feeData,
            sequenceData.byteSwap()
        ]
    }

}
