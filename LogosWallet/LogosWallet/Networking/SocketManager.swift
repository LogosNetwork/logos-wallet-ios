//
//  SocketManager.swift
//  LogosWallet
//
//  Created by Ben Kray on 8/23/18.
//  Copyright © 2018 Planar Form. All rights reserved.
//

import Foundation
import Starscream

enum LogosService {

    case accountInfo(account: String)

    var payload: String? {
        switch self {
        case .accountInfo(let account):
            return self.params(for: "account_info", params: ["account": account])
        }
    }

    static var url: URL {
        return URL(string: "ws://34.201.126.140:443")!
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

    private(set) var webSocket: WebSocket

    static let shared = SocketManager()

    // MARK: - Object Lifeycle

    init() {
        self.webSocket = WebSocket(url: LogosService.url)
        self.setupWebSocket()
    }

    // MARK: - Setup

    private func setupWebSocket() {
        self.webSocket.onConnect = {
            Lincoln.log("Socket connected")
        }

        self.webSocket.onDisconnect = { error in
            Lincoln.log("Socket disconnected")
            if let error = error {
                Lincoln.log("Socket Disconnect error: \(error.localizedDescription)")
            }
        }

        self.webSocket.onText = { [weak self] message in
            self?.handle(message)
        }
    }

    // MARK: - Socket Open/Close

    func openConnection() {
        guard !self.webSocket.isConnected else {
            return
        }

        Lincoln.log("Opening socket connection @ \(self.webSocket.request.url?.absoluteString ?? "")...")
        self.webSocket.connect()
    }

    func closeConnection() {
        guard self.webSocket.isConnected else {
            return
        }

        self.webSocket.disconnect()
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
