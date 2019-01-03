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
    private(set) var url: URL {
        get {
            if let url = UserDefaults.standard.url(forKey: "mqttUrl") {
                return url
            } else {
                return URL(string: "wss://pla.bs:8443/mqtt")!
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "mqttUrl")
        }
    }
    var onConnect: (() -> Void)?
    var onDisconnect: (() -> Void)?

    var status: MQTTSessionStatus {
        return self.session.status
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
        guard self.session.status != .connected else {
            return
        }

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
            Lincoln.log("Subscribing to \($0)", inConsole: true)
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

    @discardableResult
    func changeMQTTUrl(to mqttUrl: String) -> Bool {
        guard let url = URL(string: mqttUrl) else {
            return false
        }

        self.session.disconnect()

        self.url = url
        let transport = MQTTWebsocketTransport()
        transport.url = url
        self.session.transport = transport
        self.connect()
        // onConnect should be fired by callback set in AccountsCoordinator

        return true
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
        Lincoln.log("Subscription acknowledged: \(msgID)", inConsole: true)
    }

    func newMessage(_ session: MQTTSession!, data: Data!, onTopic topic: String!, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        guard let topic = topic else {
            return
        }

        Lincoln.log("MQTT message received from topic: \(topic)", inConsole: true)
        if let message = String(data: data, encoding: .utf8) {
            Lincoln.log("Message: \(message)", inConsole: true)
        }

        if topic.contains("account/") {
            let account = topic.replacingOccurrences(of: "account/", with: "")
            BlockHandler.shared.handleIncoming(blockData: data, for: account)
        }
    }
}
