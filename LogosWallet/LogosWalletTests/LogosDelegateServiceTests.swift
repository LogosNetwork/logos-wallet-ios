//
//  LogosDelegateServiceTests.swift
//  LogosWalletTests
//
//  Created by Ben Kray on 12/12/18.
//  Copyright © 2018 Planar Form. All rights reserved.
//

import XCTest
@testable import LogosWallet

class LogosDelegateServiceTests: XCTestCase {

    override func tearDown() {
        LogosDelegateService.accountInfo = nil
        super.tearDown()
    }

    // 78B10253DF8914BD54CC5A479B447AB2CC7066425B6FDB5229C4E0215544A0D2
    // We take the last two digits of the public key 'D2'
    // We convert 'D2' from hexadecimal (base-16) to decimal
    // 'D2' = 210
    // Finally we Mod 210 with 32 to give us 18
    func testLoadBalancedIndexWithPublicKey() {
        let accountInfo = AccountInfo()
        accountInfo.address = "lgs_1y7j1bbxz4anqocerpk9mf49oepeg3m66puhufb4mj9167cnba8k8iop855i"
        accountInfo.frontier = ZERO_AMT

        LogosDelegateService.accountInfo = accountInfo
        XCTAssertEqual(LogosDelegateService.loadBalancedIndex(), 18)
    }

    func testLoadBalancedIndexWithFrontier() {
        let accountInfo = AccountInfo()
        accountInfo.address = "lgs_1y7j1bbxz4anqocerpk9mf49oepeg3m66puhufb4mj9167cnba8k8iop855i"
        accountInfo.frontier = "534E605120F28BE452E8083B8E2B961FA9D5EEBFD9BA94305AF62690B4AC2DD3"

        LogosDelegateService.accountInfo = accountInfo
        XCTAssertEqual(LogosDelegateService.loadBalancedIndex(), 19)
    }
}
