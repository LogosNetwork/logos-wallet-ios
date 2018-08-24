//
//  SocketManager.swift
//  LogosWallet
//
//  Created by Ben Kray on 8/23/18.
//  Copyright © 2018 Planar Form. All rights reserved.
//

import Foundation
import SwiftWebSocket

enum LogosService {

    case accountInfo(account: String)

    var payload: String? {
        switch self {
        case .accountInfo(let account):
            return self.params(for: "account_info", params: ["account": account])
        }
    }

    static var url: String {
        return "ws://34.201.126.140:443"
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

class SocketManager {

    private var webSocket: WebSocket

    var state: WebSocketReadyState {
        return self.webSocket.readyState
    }

    static let shared = SocketManager()

    // MARK: - Object Lifeycle

    init() {
        self.webSocket = WebSocket(LogosService.url)
        self.webSocket.allowSelfSignedSSL = true
        self.setupWebSocket()
    }

    // MARK: - Setup

    private func setupWebSocket() {
        self.webSocket.event.open = {
            Lincoln.log("Socket opened")
        }

        self.webSocket.event.close = { code, reason, _ in
            Lincoln.log("Socket closed.\nCode: \(code)\nReason: \(reason)")
        }

        self.webSocket.event.message = { [weak self] message in
            self?.handle(message as? String)
        }

        self.webSocket.event.error = { error in
            Lincoln.log("Socket Error: \(error.localizedDescription)")
        }

        self.webSocket.event.end = { code, reason, _, error in
            Lincoln.log("Socket End.\nCode: \(code)\nReason: \(reason)\nError: \(error?.localizedDescription ?? "")")
        }
    }

    // MARK: - Socket Open/Close

    func openConnection() {
        guard self.webSocket.readyState != .open else {
            return
        }

        self.webSocket.open()
    }

    func closeConnection() {
        guard self.webSocket.readyState != .closed || self.webSocket.readyState != .closing else {
            return
        }

        self.webSocket.close()
    }


    // MARK: - API

    func action(_ action: LogosService, completion: (String?) -> Void) {
        
    }

    // MARK: - Helpers

    private func handle(_ message: String?) {
        guard let message = message,
            let _ = message.data(using: .utf8) else {
                return
        }

        Lincoln.log("Socket Message Received: \(message)")
    }
}
