//
//  SocketManager.swift
//  LogosWallet
//
//  Created by Ben Kray on 8/23/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation
import Starscream
import RxSwift

class SocketManager {

    private(set) var accountInfoSubject = PublishSubject<AccountInfoResponse>()
    private(set) var webSocket: WebSocket

    /// After this callback is invoked, it should be set to nil to avoid it firing more than once.
    private var onConnect: (() -> Void)?

    static let shared = SocketManager()

    // MARK: - Object Lifeycle

    init() {
        let url = LogosMQTT.shared.url
        self.webSocket = WebSocket(url: url)
        self.setupWebSocket()
    }

    // MARK: - Setup

    private func setupWebSocket() {
        self.webSocket.onConnect = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            Lincoln.log("Socket connected @ \(strongSelf.webSocket.currentURL.absoluteString)")
            strongSelf.onConnect?()
            strongSelf.onConnect = nil
        }

        self.webSocket.onDisconnect = { error in
            Lincoln.log("Socket disconnected")
            if let error = error {
                Lincoln.log("Socket disconnect error: \(error.localizedDescription)")
            }
        }

        self.webSocket.onText = { [weak self] message in
            self?.handle(message)
        }
    }

    // MARK: - Socket Open/Close

    func openConnection(_ completion: (() -> Void)? = nil) {
//        guard !self.webSocket.isConnected else {
//            return
//        }
//
//        Lincoln.log("Opening socket connection @ \(self.webSocket.currentURL.absoluteString)...")
//        self.connectAndPerform(completion)
    }

    func closeConnection() {
        guard self.webSocket.isConnected else {
            return
        }

        self.webSocket.disconnect()
    }


    // MARK: - API

    @discardableResult
    func changeSocketUrl(to url: String) -> Bool {
        guard let newUrl = URL(string: url) else {
            return false
        }
        NetworkAdapter.baseNodeUrl = newUrl
        self.webSocket.disconnect()
        self.webSocket = WebSocket(url: newUrl)
        self.setupWebSocket()
        self.openConnection()
        return true
    }

    func action(_ action: LogosService) {
        guard self.webSocket.isConnected else {
            self.connectAndPerform { [weak self] in
                self?.action(action)
            }
            return
        }

        if let payload = action.payload {
            Lincoln.log("Socket write:\n\(payload)", inConsole: true)
            self.webSocket.write(string: payload)
        }
    }

    // MARK: - Helpers

    private func connectAndPerform(_ completion: (() -> Void)? = nil) {
//        self.webSocket.connect()
//        self.onConnect = completion
    }

    private func handle(_ message: String?) {
        guard let message = message,
            let data = message.data(using: .utf8) else {
                return
        }

        Lincoln.log("Socket message received: \(message)")

        if let accountInfo = Decoda.decode(AccountInfoResponse.self, from: data) {
            self.accountInfoSubject.onNext(accountInfo)
        }

    }
}

struct Decoda {

    static func decode<T: Decodable>(_ type: T.Type, strategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase, from data: Data) -> T? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = strategy
        do {
            let decoded = try decoder.decode(type, from: data)
            return decoded
        } catch {
            Lincoln.log(error.localizedDescription)
        }
        return nil
    }

}

enum LogosService {

    case accountInfo(account: String)
    case process(block: BlockAdapter)
    case subscribe(account: String)

    var payload: String? {
        switch self {
        case .accountInfo(let account):
            return self.params(for: "account_info", params: ["account": account])
        case .process(let block):
            // TODO: use encode
            guard let jsonData = try? JSONSerialization.data(withJSONObject: block.json, options: []),
                let blockString = String(data: jsonData, encoding: .ascii) else { return nil }
            return self.params(for: "process", params: ["block": blockString])
        case .subscribe(let account):
            return self.params(for: "account_subscribe", params: ["account": account])
        }
    }

    fileprivate func params(for action: String, params: [String: Any] = [:]) -> String? {
        var result: [String: Any] = ["action": action, "logos": ""]
        result.merge(params) { (current, _) in current }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: result, options: [])
            return String(data: jsonData, encoding: .utf8)
        } catch {
            return nil
        }
    }

}
