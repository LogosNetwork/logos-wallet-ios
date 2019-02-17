//
// AccountHistory.swift
//
// Created by JSON Bourne on 01/13/2018.
// Copyright © 2018 . All rights reserved.

import Foundation

struct AccountBalance {
    var pending: Double
    var balance: Double
    
    init(json: [String: Any]?) {
        pending = Double(json?["pending"] as? String ?? "0.0") ?? 0.0
        balance = Double(json?["balance"] as? String ?? "0.0") ?? 0.0
    }
}

