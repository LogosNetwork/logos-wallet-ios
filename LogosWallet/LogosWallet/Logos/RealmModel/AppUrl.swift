//
//  AppUrl
//  LogosWallet
//
//  Created by Ben Kray on 9/25/18.
//  Copyright © 2018 Planar Form. All rights reserved.
//

import RealmSwift

class AppUrl: Object {

    static let defaultNode = "http://107.22.128.62:55000"
    static let defaultMqtt = "wss://18.235.68.120:8443/mqtt"
    @objc dynamic var nodeUrl: String = AppUrl.defaultNode
    @objc dynamic var walletServerUrl: String = AppUrl.defaultMqtt

}
