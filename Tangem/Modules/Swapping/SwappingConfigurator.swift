//
//  SwappingConfigurator.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemExchange
import BlockchainSdk

/// Helper for configure `SwappingViewModel`
struct SwappingConfigurator {
    private let factory: SwappingDependenciesFactoring

    init(factory: SwappingDependenciesFactoring) {
        self.factory = factory
    }

    func createModule(input: InputModel, coordinator: SwappingRoutable) -> SwappingViewModel {
        SwappingViewModel(
            exchangeManager: factory.exchangeManager(source: input.source, destination: input.destination),
            swappingDestinationService: factory.swappingDestinationService,
            tokenIconURLBuilder: factory.tokenIconURLBuilder,
            transactionSender: factory.transactionSender,
            userWalletModel: factory.userWalletModel,
            currencyMapper: factory.currencyMapper,
            blockchainNetwork: factory.walletModel.blockchainNetwork,
            coordinator: coordinator
        )
    }
}

extension SwappingConfigurator {
    struct InputModel {
        let userWalletModel: UserWalletModel
        let walletModel: WalletModel
        let sender: TransactionSender
        let signer: TransactionSigner
        let source: Currency
        let destination: Currency?

        init(
            userWalletModel: UserWalletModel,
            walletModel: WalletModel,
            sender: TransactionSender,
            signer: TransactionSigner,
            source: Currency,
            destination: Currency? = nil
        ) {
            self.userWalletModel = userWalletModel
            self.walletModel = walletModel
            self.sender = sender
            self.signer = signer
            self.source = source
            self.destination = destination
        }
    }
}
