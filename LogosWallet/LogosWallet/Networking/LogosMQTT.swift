//
//  LogosMQTT.swift
//  LogosWallet
//
//  Created by Ben Kray on 12/9/18.
//  Copyright © 2018 Planar Form. All rights reserved.
//

import Foundation
import MQTTClient

class LogosMQTT: NSObject {

    static let shared = LogosMQTT()
    let session: MQTTSession
    let host = "18.235.68.120"
    let port: UInt32 = 8443
    var onConnect: (() -> Void)?
    var onDisconnect: (() -> Void)?

    var status: MQTTSessionStatus {
        return self.session.status
    }

    var url: URL {
        return URL(string: "wss://\(self.host):\(self.port)/mqtt")!
    }

    override init() {
        self.session = MQTTSession()
        super.init()

        let transport = MQTTWebsocketTransport()
        transport.url = self.url

        self.session.transport = transport
        self.session.delegate = self
        self.session.cleanSessionFlag = true

        MQTTLog.setLogLevel(.error)
    }

    func connect() {
        self.session.connect()
    }

    func disconnect() {
        self.session.disconnect()
    }

    func subscribe(to accounts: [String]) {
        guard self.status == .connected else {
            return
        }
        accounts.forEach {
            self.session.subscribe(toTopic: "account/\($0)", at: .exactlyOnce)
        }
    }

    func setupSubscriptions() {
        guard self.status == .connected else {
            return
        }
        self.session.subscribe(toTopic: "batchBlock", at: .exactlyOnce)
        self.session.subscribe(toTopic: "microEpoch", at: .exactlyOnce)
        self.session.subscribe(toTopic: "epoch", at: .exactlyOnce)
    }

}

extension LogosMQTT: MQTTSessionDelegate {

    func connected(_ session: MQTTSession!) {
        self.onConnect?()
        Lincoln.log("MQTT connection established @ \(self.url.absoluteString)", inConsole: true)

        self.setupSubscriptions()
    }

    func connectionError(_ session: MQTTSession!, error: Error!) {
        Lincoln.log("Connection error")
        Lincoln.log(error.localizedDescription)
    }

    func connectionRefused(_ session: MQTTSession!, error: Error!) {
        Lincoln.log("Connection refused")
        Lincoln.log(error.localizedDescription)
    }

    func connectionClosed(_ session: MQTTSession!) {
        self.onDisconnect?()
        Lincoln.log("Connection closed")
    }

    func subAckReceived(_ session: MQTTSession!, msgID: UInt16, grantedQoss qoss: [NSNumber]!) {
        Lincoln.log("Subscription acknowledged: \(msgID)")
    }

    func newMessage(_ session: MQTTSession!, data: Data!, onTopic topic: String!, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        guard let topic = topic else {
            return
        }

        Lincoln.log("MQTT message received from topic: \(topic ?? "")", inConsole: true)
        if let message = String(data: data, encoding: .utf8) {
            Lincoln.log("Message: \(message)", inConsole: true)
        }

        if topic.contains("account/") {
            let account = topic.replacingOccurrences(of: "account/", with: "")
            BlockHandler.shared.handleIncoming(blockData: data, for: account)
        }
    }
}
