//
//  PersistentStore.swift
//  LogosWallet
//
//  Created by Ben Kray on 1/5/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation
import RealmSwift

struct PersistentStore {
    
    static func handleMigration() {
        let config = Realm.Configuration(
            schemaVersion: 3,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 3 {
                    migration.enumerateObjects(ofType: LogosAccount.className(), { (old, new) in
                        guard
                            let old = old,
                            let new = new,
                            let oldBalance = old["balance"] as? Double
                        else {
                            return
                        }
                        // new balance is stored as string
                        let oldBalanceNumber = NSDecimalNumber(decimal: Decimal(oldBalance))
                        new["balance"] = oldBalanceNumber.mlgsAmount.rawString
                    })
                }
        })
        Realm.Configuration.defaultConfiguration = config
    }
    
    // MARK: - Accounts

    static func remove(account: LogosAccount) {
        try? Realm().delete(account)
    }
    
    static func getAccounts() -> [LogosAccount] {
        do {
            return try Array(Realm().objects(LogosAccount.self))
        } catch {
            Lincoln.log("Error getting accounts: \(error.localizedDescription)")
            return []
        }
    }
    
    static func addAccount(name: String, address: String, index: Int) {
        let account = LogosAccount()
        account.name = name
        account.address = address
        account.index = index
        add(account)
        Lincoln.log("Account '\(name)' saved", inConsole: true)
    }
    
    // MARK: - Address Book
    
    static func getAddressEntries() -> [AddressEntry] {
        do {
            return try Array(Realm().objects(AddressEntry.self))
        } catch {
            return []
        }
    }
    
    static func addAddressEntry(_ name: String, address: String) {
        let entry = AddressEntry()
        entry.address = address
        entry.name = name
        add(entry)
        Lincoln.log("Address entry '\(name)' saved", inConsole: true)
    }
    
    static func removeAddressEntry(_ entry: AddressEntry) {
        do {
            let realm = try Realm()
            try realm.write {
                realm.delete(entry)
            }
        } catch {
            
        }
    }
    
    static func updateAddressEntry(address: String, name: String, originalAddress: String) {
        do {
            let realm = try Realm()
            try realm.write {
                guard let result = realm.objects(AddressEntry.self).filter("address == %@", originalAddress).first else { return }
                result.name = name
                result.address = address
            }
        } catch {
            
        }
    }

    // MARK: - Helpers
    
    static func clearAll() {
        do {
            let realm = try Realm()
            try realm.write {
                realm.deleteAll()
            }
        } catch {
            
        }
    }
    
    static func write(_ closure: () -> Void) {
        do {
            let realm = try Realm()
            try realm.write {
                closure()
            }
        } catch {
            
        }
    }
    
    static func add(_ record: Object) {
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(record)
            }
        } catch { }
    }
}
