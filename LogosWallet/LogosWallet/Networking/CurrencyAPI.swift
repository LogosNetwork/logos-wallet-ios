//
//  CurrencyAPI.swift
//  LogosWallet
//
//  Created by Ben Kray on 2/12/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation

struct CurrencyAPI {
    static let baseURL = "https://api.coinmarketcap.com/v1/ticker/nano/?convert="
    
    static func getCurrencyInfo(for currency: Currency, completion: @escaping (Double?) -> Void) {
        let url = baseURL + currency.rawValue
        Networking.shared.get(url: url) { response in
            guard response.result.isSuccess else {
                completion(nil)
                return
            }
            guard let json = response.result.value as? [[String: Any]], let info = json.first else {
                completion(nil)
                return
            }
            guard let stringValue = info["price_\(currency.rawValue)"] as? String, let value = Double(stringValue) else {
                completion(nil)
                return
            }
            completion(value)
        }
    }
}
