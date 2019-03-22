//
//  Storage.swift
//  LogosWallet
//
//  Created by Ben Kray on 3/21/19.
//  Copyright © 2019 Planar Form. All rights reserved.
//

import Foundation

class Storage {

    static var documentsUrl: URL {
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            return url
        } else {
            fatalError("Could not get url to documents")
        }
    }

    fileprivate init() { }

    static func store<T: Encodable>(_ object: T, as fileName: String, directoryPath: String? = nil) {
        DispatchQueue.global(qos: .userInitiated).async {
            let encoder = JSONEncoder()
            do {
                let filePath: String
                if let directoryPath = directoryPath {
                    let path = self.documentsUrl.path + "/\(directoryPath)"
                    if !FileManager.default.fileExists(atPath: path) {
                        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false)
                    }
                    filePath = directoryPath + "/\(fileName)"
                } else {
                    filePath = fileName
                }
                let url = self.documentsUrl.appendingPathComponent(filePath, isDirectory: false)
                let data = try encoder.encode(object)
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
                FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil)
            } catch {

            }
        }
    }

    static func retrieve<T: Decodable>(_ fileName: String, as type: T.Type) -> T? {
        let url = self.documentsUrl.appendingPathComponent(fileName, isDirectory: false)
        if !FileManager.default.fileExists(atPath: url.path) {
            return nil
        }

        if let data = FileManager.default.contents(atPath: url.path) {
            let decoder = JSONDecoder()
            do {
                let model = try decoder.decode(type, from: data)
                return model
            } catch {
                return nil
            }
        } else {
            return nil
        }
    }

    static func clearAll() {
        let contents = try? FileManager.default.contentsOfDirectory(at: self.documentsUrl, includingPropertiesForKeys: nil, options: [])
        contents?
            .compactMap { $0 }
            .forEach { try? FileManager.default.removeItem(at: $0) }
    }

}
