//
//  Cryptography.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 3/21/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import CryptoKit
import Foundation

class Cryptography: NSObject {

    class func encrypt(text: String) -> String? {
        if let dataDecrypted = text.data(using: .utf8) {
            if let dataEncrypted = encrypt(data: dataDecrypted) {
                return dataEncrypted.base64EncodedString()
            }
        }

        return nil
    }

    
    class func decrypt(text: String) -> String? {
        if let dataEncrypted = Data(base64Encoded: text) {
            if let dataDecrypted = decrypt(data: dataEncrypted) {
                return String(data: dataDecrypted, encoding: .utf8)
            }
        }

        return nil
    }

    // MARK: -
    class func encrypt(data: Data) -> Data? {

        return try? encrypt(data: data, key: ChatrApp.getCryptoKey())
    }

    class func decrypt(data: Data) -> Data? {

        return try? decrypt(data: data, key: ChatrApp.getCryptoKey())
    }

    // MARK: -
    private class func encrypt(data: Data, key: String) throws -> Data {
        let cryptedBox = try ChaChaPoly.seal(data, using: symmetricKey(key))
        let sealedBox = try ChaChaPoly.SealedBox(combined: cryptedBox.combined)

        return sealedBox.combined
    }

    private class func decrypt(data: Data, key: String) throws -> Data {

        let sealedBox = try ChaChaPoly.SealedBox(combined: data)
        let decryptedData = try ChaChaPoly.open(sealedBox, using: symmetricKey(key))

        return decryptedData
    }

    //---------------------------------------------------------------------------------------------------------------------------------------------
    private class func symmetricKey(_ key: String) -> SymmetricKey {

        let dataKey = key.data(using: .utf8)!
        let hash256 = SHA256.hash(data: dataKey)
        return SymmetricKey(data: hash256)
    }
}
