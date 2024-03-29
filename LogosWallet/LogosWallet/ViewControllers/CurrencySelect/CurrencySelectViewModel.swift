//
//  CurrencySelectViewModel.swift
//  LogosWallet
//
//  Created by Ben Kray on 2/11/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation

struct CurrencySelectViewModel {
    private(set) var currencies: [Currency] = Currency.all
    
    subscript(_ index: Int) -> Currency? {
        guard index < currencies.count else { return nil }
        return currencies[index]
    }
}
