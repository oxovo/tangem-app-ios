//
//  Card+Preview.swift
//  Tangem
//
//  Created by Alexander Osokin on 13.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

extension Card {
    static var card: Card = fromJson(cardJson)

    private static func fromJson(_ json: String) -> Card {
        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder.tangemSdkDecoder
        decoder.keyDecodingStrategy = .useDefaultKeys
        do {
            let card = try decoder.decode(Card.self, from: jsonData)
            return card
        } catch {
            guard let error = error as? DecodingError else {
                fatalError(error.localizedDescription)
            }
            if case DecodingError.keyNotFound(_, let context) = error {
                fatalError(context.debugDescription)
            }
            fatalError(error.errorDescription ?? error.localizedDescription)
        }
    }

    private static let cardJson =
        """
        {
          "linkedTerminalStatus" : "none",
          "supportedCurves" : [
            "secp256k1",
            "ed25519",
            "secp256r1"
          ],
          "cardPublicKey" : "0400D05BCAC34B58AA48BF998FB68667A3112262275200431EA235EC4616A15287B5D21F15E45740AB6B829F415950DBC7A68493DCF5FD270C8CAAB0E975E9A0D9",
          "settings" : {
            "isSettingPasscodeAllowed" : true,
            "maxWalletsCount" : 36,
            "isOverwritingIssuerExtraDataRestricted" : false,
            "isResettingUserCodesAllowed" : true,
            "isLinkedTerminalEnabled" : true,
            "securityDelay" : 3000,
            "isSettingAccessCodeAllowed" : false,
            "supportedEncryptionModes" : [
              "strong",
              "fast",
              "none"
            ],
            "isPermanentWallet" : true,
            "isSelectBlockchainAllowed" : true,
            "isIssuerDataProtectedAgainstReplay" : true,
            "isHDWalletAllowed" : true,
            "isFilesAllowed" : true,
            "isBackupAllowed" : true
          },
          "issuer" : {
            "name" : "TANGEM AG",
            "publicKey" : "0456E7C3376329DFAE7388DF1695670386103C92486A87644FA9E512C9CF4E92FE970EFDFBB7A35446F2A937505E6C70D78E965533B31C252B607F3C6B3112B603"
          },
          "firmwareVersion" : {
            "minor" : 12,
            "patch" : 0,
            "major" : 4,
            "stringValue" : "4.12r",
            "type" : "r"
          },
          "batchId" : "CB79",
          "attestation" : {
            "cardKeyAttestation" : "verified",
            "walletKeysAttestation" : "verified",
            "firmwareAttestation" : "skipped",
            "cardUniquenessAttestation" : "skipped"
          },
          "manufacturer" : {
            "name" : "TANGEM",
            "manufactureDate" : "2021-04-01",
            "signature" : "1671A9AB2D9D5B99177E841C8DC35842452A095088CD01B48D753631571AAB21EEAC0F96BC87142268C32EFB3AF8A8C80DB55BE6D1970FAFBC72E00F896F69EA"
          },
          "cardId" : "CB79000000018201",
          "wallets" : [
            {
              "publicKey" : "FA3F41EE40DAB4DB96B4AD5BEC697A552EEB1AACF2C6A10B1B37A9A724608533",
              "totalSignedHashes" : 1,
              "curve" : "ed25519",
              "settings" : {
                "isPermanent" : false
              },
              "index" : 0,
              "hasBackup" : false,
              "derivedKeys" : []
            },
            {
              "publicKey" : "0440C533E007D029C1F345CA70A9F6016EC7A95C775B6320AE84248F20B647FBBD90FF56A2D9C3A1984279ED2367274A49079789E130444541C2F15907D5570B49",
              "totalSignedHashes" : 0,
              "curve" : "secp256k1",
              "settings" : {
                "isPermanent" : true
              },
              "index" : 1,
              "hasBackup" : false,
              "derivedKeys" : []
            },
            {
              "publicKey" : "04DDFACEF55A95EAB2CDCC8E86CE779342D2E2A53CF8F0F20BF2B248336AE3EEA6DD62D1F4C5420A71D6212073B136034CDC878DAD3AE3FDFA3360E6FE6184F470",
              "totalSignedHashes" : 0,
              "curve" : "secp256r1",
              "settings" : {
                "isPermanent" : true
              },
              "index" : 2,
              "hasBackup" : false,
              "derivedKeys" : []
            }
          ],
          "isPasscodeSet" : true,
          "isAccessCodeSet" : true,
          "backupStatus" : {
              "status" : "noBackup"
          }
        }
        """
}
