//
//  ServicesManager.swift
//  Tangem
//
//  Created by Alexander Osokin on 13.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class ServicesManager {
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository
    @Injected(\.exchangeService) private var exchangeService: ExchangeService
    @Injected(\.walletConnectServiceProvider) private var walletConnectServiceProvider: WalletConnectServiceProviding
    @Injected(\.supportChatService) private var supportChatService: SupportChatServiceProtocol
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private var bag = Set<AnyCancellable>()

    func initialize() {
        exchangeService.initialize()
        walletConnectServiceProvider.initialize()
        supportChatService.initialize()
        tangemApiService.initialize()
    }
}

protocol Initializable {
    func initialize()
}
