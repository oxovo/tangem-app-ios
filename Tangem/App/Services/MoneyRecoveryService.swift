//
//  MoneyRecoveryService.swift
//  Tangem
//
//  Created by Andrey Chukavin on 14.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

@available(iOS 13.0, *)
class MoneyRecoveryService {
    private let cardInfo: CardInfo
    private let walletManagerFactory: WalletManagerFactory
    private let amountType: Amount.AmountType
    private let blockchain: Blockchain
    private let otherBlockchains: [Blockchain]
    
    
    private lazy var walletManagers: [WalletManager] = {
        otherBlockchains.compactMap { otherBlockchain in
            guard
                let wallet = cardInfo.card.wallets.first(where: { $0.curve == blockchain.curve })
            else {
                return nil
            }
            
            let derivationPath = blockchain.derivationPath
            
            let derivedKey: ExtendedPublicKey?
            if let derivationPath = derivationPath {
                derivedKey = cardInfo.derivedKeys[wallet.publicKey]?[derivationPath]
            } else {
                derivedKey = nil
            }
            
            let walletManager = try? walletManagerFactory.makeWalletManager(
                cardId: cardInfo.card.cardId,
                blockchain: otherBlockchain,
                seedKey: wallet.publicKey,
                derivedKey: derivedKey,
                derivationPath: derivationPath
            )
            
            print(walletManager?.wallet.address)
            
            if case let .token(token) = amountType {
                walletManager?.addToken(token)
            }
            
            return walletManager
        }
    }()
    
    init(
        cardInfo: CardInfo,
        walletManagerFactory: WalletManagerFactory,
        amountType: Amount.AmountType,
        blockchain: Blockchain,
        otherBlockchains: [Blockchain]
    ) {
        self.cardInfo = cardInfo
        self.walletManagerFactory = walletManagerFactory
        self.amountType = amountType
        self.blockchain = blockchain
        self.otherBlockchains = otherBlockchains
    }
    
    func recover() {
        walletManagers.forEach { walletManager in
            walletManager.update { [weak self] result in
                guard let self = self else { return }
                
                print("=========================")
                print(result)
//                print(walletManager.wallet.amounts[.coin])
                print(walletManager.wallet.amounts[self.amountType])
            }
        }
    }
}
