//
//  ExchangeDataModel.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 08.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeDataModel {
    public let gas: Int
    /// WEI
    public let gasPrice: Int
    public let txData: Data

    public let sourceAddress: String
    public let destinationAddress: String

    /// WEI
    public let value: Decimal

    /// WEI
    public let sourceCurrencyAmount: Decimal
    public let destinationCurrencyAmount: Decimal

    /// Contract address
    public let sourceTokenAddress: String?
    /// Contract address
    public let destinationTokenAddress: String?

    public init(exchangeData: ExchangeData) throws {
        guard let gasPrice = Int(exchangeData.tx.gasPrice),
              let sourceCurrencyAmount = Decimal(string: exchangeData.fromTokenAmount),
              let destinationCurrencyAmount = Decimal(string: exchangeData.toTokenAmount),
              let value = Decimal(string: exchangeData.tx.value) else {
            throw OneInchExchangeProvider.Errors.incorrectDataFormat
        }

        self.gasPrice = gasPrice
        self.sourceCurrencyAmount = sourceCurrencyAmount
        self.destinationCurrencyAmount = destinationCurrencyAmount
        self.value = value

        gas = exchangeData.tx.gas
        txData = Data(hexString: exchangeData.tx.data)
        sourceAddress = exchangeData.tx.from
        destinationAddress = exchangeData.tx.to
        sourceTokenAddress = exchangeData.fromToken.address
        destinationTokenAddress = exchangeData.toToken.address
    }
}
