//
//  StateBlockTests
//  LogosWalletTests
//
//  Created by Ben Kray on 2/9/19.
//  Copyright © 2019 Planar Form. All rights reserved.
//

import XCTest
@testable import LogosWallet

class StateBlockTests: XCTestCase {

    private let publicKeyData = "B0311EA55708D6A53C75CDBF88300259C6D018522FE3D4D0A242E431F9E8B6D0".hexData
    private let privateKeyData = "34F0A37AAD20F4A260F0A5B3CB3D7FB50673212263E58A380BC10474BB039CE4".hexData
    private lazy var keyPair = KeyPair(publicKey: self.publicKeyData!, secretKey: self.privateKeyData!)

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    /*
     {'hash': 'DEA67B610E18713D30C0208398640CF28E3C8C42FB340F7D39BC0EDD7B4E72E2',
     'block': '{\n    "account": "lgs_3e3j5tkog48pnny9dmfzj1r16pg8t1e76dz5tmac6iq689wyjfpiij4txtdo",\n    "previous": "92997BBEE52E67FC2A73A2D276292D5BD68368F3DBE40B0122397E3BEE5F11AF",\n    "sequence": "65",\n    "transaction_type": "send",\n    "transaction_fee": "10000000000000000000000",\n    "signature": "AD039557F2D8B28692BAA50C6AD0C3EA7C4CB1603B2F1E108346BDDA6DA6FAB4E93E52B90952651784CC79ED247E270DBF273403E87B80DF6B0FDDC7DF651907",\n    "work": "21584029440",\n    "number_transactions": "1",\n    "transactions": [\n        {\n            "target": "lgs_1uppzmc7pb3uqjecizszec634mrzrrz3zf4nc89hwujyomc671yr5s1ad39b",\n            "amount": "2000000000000000000000000503"\n        }\n    ],\n    "hash": "DEA67B610E18713D30C0208398640CF28E3C8C42FB340F7D39BC0EDD7B4E72E2"\n}\n'}
     */
    func testBlockCreate() {
        var block = StateBlock(type: .send)
        block.account = "lgs_3e3j5tkog48pnny9dmfzj1r16pg8t1e76dz5tmac6iq689wyjfpiij4txtdo"
        block.previous = "92997BBEE52E67FC2A73A2D276292D5BD68368F3DBE40B0122397E3BEE5F11AF"
        block.sequence = "65".decimalNumber
        block.transactionFee = "10000000000000000000000".decimalNumber
        block.transactions = [
            MultiSendTransaction(target: "lgs_1uppzmc7pb3uqjecizszec634mrzrrz3zf4nc89hwujyomc671yr5s1ad39b", amount: "2000000000000000000000000503".decimalNumber)
        ]
        let didBuild = block.build(with: self.keyPair)
        XCTAssertTrue(didBuild)
        XCTAssertEqual(block.hash, "DEA67B610E18713D30C0208398640CF28E3C8C42FB340F7D39BC0EDD7B4E72E2")
        XCTAssertEqual(block.signature, "AD039557F2D8B28692BAA50C6AD0C3EA7C4CB1603B2F1E108346BDDA6DA6FAB4E93E52B90952651784CC79ED247E270DBF273403E87B80DF6B0FDDC7DF651907")
    }

}
