//
//  ExchangeReferrerAccount.swift
//  TangemExchange
//
//  Created by Sergey Balashov on 09.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeReferrerAccount {
    public let address: String
    // Value from 0.0 to 3.0
    public let fee: Decimal

    public init(address: String, fee: Decimal) {
        self.address = address
        self.fee = fee
    }
}
