//
//  Currency.swift
//  LogosWallet
//
//  Created by Ben Kray on 2/10/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation

enum Currency: String {
    case aud
    case brl
    case cad
    case chf
    case clp
    case cny
    case czk
    case dkk
    case eur
    case gbp
    case hkd
    case huf
    case idr
    case ils
    case inr
    case jpy
    case krw
    case mxn
    case myr
    case nok
    case nzd
    case php
    case pkr
    case pln
    case rub
    case sek
    case sgd
    case thb
    case twd
    case usd
    case zar
    
    static var all: [Currency] {
        return [.usd, .eur, .jpy, .krw, .aud, .brl, .cad, .chf, .clp, .cny, .czk, .dkk, .gbp, .hkd, .huf, .idr, .ils, .inr, .mxn, .myr, .nok, .nzd, .php, .pkr, . pln, .rub, .sek, .sgd, .thb, .twd, .zar]
    }

    var denomination: String {
        return self.rawValue.uppercased() + " (\(self.symbol))"
    }
    
    var precision: Int {
        switch self {
        case .jpy, .krw: return 0
        default: return 2
        }
    }
    
    var symbol: String {
        switch self {
        case .usd, .sgd, .cad, .hkd, .nzd, .mxn, .clp: return "$"
        case .eur: return "€"
        case .jpy, .cny: return "¥"
        case .krw: return "₩"
        case .aud: return "AU$"
        case .brl: return "R$"
        case .chf: return "CHF"
        case .czk: return "Kč"
        case .dkk, .nok, .sek: return "kr"
        case .gbp: return "£"
        case .huf: return "Ft"
        case .idr: return "Rp"
        case .ils: return "₪"
        case .inr: return "INR"
        case .myr: return "RM"
        case .php: return "₱"
        case .pkr: return "₨"
        case .pln: return "zł"
        case .rub: return "₽"
        case .thb: return "฿"
        case .twd: return "NT$"
        case .zar: return "R"
        }
    }
    
    /// Converts a LGS (either raw or mlgs) amount to the user's selected 'secondary' currency.
    func convert(_ value: BDouble, isRaw: Bool = true) -> String {
        let value = isRaw ? value.toMlgsValue : value
        let convertedValue = Currency.secondaryConversionRate * value
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = self.precision
        numberFormatter.minimumFractionDigits = self.precision
        numberFormatter.numberStyle = .decimal


        let numberValue = NSNumber(value: Double(convertedValue.decimalDescription)!)
        return numberFormatter.string(from: numberValue) ?? "--"
    }

    func setRate(_ rate: Double) {
        UserDefaults.standard.set(rate, forKey: .kSecondaryConversionRate)
    }
    
    func setAsSecondaryCurrency(with rate: Double) {
        UserDefaults.standard.set(self.rawValue, forKey: .kSecondaryCurrency)
        UserDefaults.standard.set(rate, forKey: .kSecondaryConversionRate)
    }

    static func setSecondary(_ selected: Bool) {
        if selected {
            UserDefaults.standard.set(true, forKey: .kSecondarySelected)
        } else {
            UserDefaults.standard.removeObject(forKey: .kSecondarySelected)
        }
    }
    
    static var secondary: Currency {
        let currRaw = UserDefaults.standard.value(forKey: .kSecondaryCurrency) as? String ?? ""
        return Currency(rawValue: currRaw) ?? .usd
    }
    
    static var secondaryConversionRate: Double {
        let rate = UserDefaults.standard.value(forKey: .kSecondaryConversionRate) as? Double ?? 1.0
        return Currency.secondary == .usd ? rate * 3.14 : rate
    }

    static var isSecondarySelected: Bool {
        return UserDefaults.standard.value(forKey: .kSecondarySelected) != nil
    }
}

extension String {
    static let kSecondaryCurrency: String = "kSecondaryCurrency"
    static let kSecondaryConversionRate: String = "kSecondaryConversionRate"
    static let kSecondarySelected: String = "kCurrencySelected"
}
