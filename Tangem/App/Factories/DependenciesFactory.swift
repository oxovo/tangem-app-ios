//
//  DependenciesFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemExchange
import BlockchainSdk

struct DependenciesFactory {
    func createSwappingDestinationService(walletModel: WalletModel) -> SwappingDestinationServing {
        SwappingDestinationService(walletModel: walletModel, mapper: createCurrencyMapper())
    }

    func createCurrencyMapper() -> CurrencyMapping {
        CurrencyMapper()
    }

    func createTokenIconURLBuilder() -> TokenIconURLBuilding {
        TokenIconURLBuilder(baseURL: CoinsResponse.baseURL)
    }

    func createExchangeManager(
        walletModel: WalletModel,
        signer: TransactionSigner,
        source: Currency,
        destination: Currency?
    ) -> ExchangeManager {
        let networkService = BlockchainNetworkService(walletModel: walletModel, signer: signer)

        return TangemExchangeFactory().createExchangeManager(
            transactionBuilder: networkService,
            blockchainInfoProvider: networkService,
            source: source,
            destination: destination
        )
    }

    func createUserWalletsListProvider(walletModel: WalletModel) -> UserWalletsListProviding {
        UserWalletsListProvider(walletModel: walletModel)
    }
}
