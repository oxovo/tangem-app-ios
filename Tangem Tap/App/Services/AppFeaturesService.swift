//
//  AppFeaturesService.swift
//  Tangem Tap
//
//  Created by Alexander Osokin on 21.10.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class AppFeaturesService {
    func getFeatures(for card: Card) -> AppFeatures {
        if let issuerName = card.cardData?.issuerName,
           issuerName.lowercased() == "start2coin" {
            return .none
        }
        
        if let blockhainName = card.cardData?.blockchainName,
           blockhainName.lowercased() == "btc" {
            return .exceptPayId
        }
        
//        if let productMask = card.cardData?.productMask, //todo for twins
//           productMask.contains(.twin) {
//            return .exceptPayId
//        }
        
        return .all
    }
    
    
    func isPayIDSupported(for card: Card) -> Bool {
        if getFeatures(for: card).contains(.payID) {
            return true
        }
        
        return false
    }
    
    func isTopupSupported(for card: Card) -> Bool {
        if getFeatures(for: card).contains(.topup) {
            return true
        }
        
        return false
    }
}


enum AppFeature: String, Option {
    case payID
    case topup
    case pins
    case linkedTerminal
}

extension Set where Element == AppFeature {
    static var all: Set<AppFeature> {
        return Set(Element.allCases)
    }
    
    static var none: Set<AppFeature> {
        return Set()
    }
    
    static var exceptPayId: Set<AppFeature> {
        var features = all
        features.remove(.payID)
        return features
    }
}

typealias AppFeatures = Set<AppFeature>
