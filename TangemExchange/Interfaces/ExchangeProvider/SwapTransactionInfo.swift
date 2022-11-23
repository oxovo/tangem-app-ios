//
//  SwapTransactionInfo.swift
//  TangemExchange
//
//  Created by Sergey Balashov on 23.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct SwapTransactionInfo {
    let currency: Currency
    let destination: String
    let amount: Decimal
    let oneInchTxData: Data
}
