//
//  OneInchLimitOrderServicing.swift
//  TangemExchange
//
//  Created by Sergey Balashov on 23.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol OneInchLimitOrderServicing {
    func ordersForAddress(blockchain: ExchangeBlockchain, parameters: OrdersForAddressParameters) async -> Result<[LimitOrder], ExchangeInchError>
    func allOrders(blockchain: ExchangeBlockchain, parameters: AllOrdersParameters) async -> Result<[LimitOrder], ExchangeInchError>
    func countOrders(blockchain: ExchangeBlockchain, statuses: [ExchangeOrderStatus]) async -> Result<CountLimitOrders, ExchangeInchError>
    func events(blockchain: ExchangeBlockchain, limit: Int) async -> Result<[EventsLimitOrder], ExchangeInchError>
    func hasActiveOrdersWithPermit(blockchain: ExchangeBlockchain, walletAddress: String, tokenAddress: String) async -> Result<Bool, ExchangeInchError>
}
