//
//  MoneyRecoveryService.swift
//  Tangem
//
//  Created by Andrey Chukavin on 14.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemSdk

@available(iOS 13.0, *)
class MoneyRecoveryService {
    struct BlockchainAmount {
        let blockchain: Blockchain
        let amount: Amount
    }
    
    private let cardInfo: CardInfo
    private let walletManagerFactory: WalletManagerFactory
    let amountType: Amount.AmountType
    let blockchain: Blockchain
    private let otherBlockchains: [Blockchain]
    
    private var subject = PassthroughSubject<BlockchainAmount, Never>()
    private var numberOfAmountsChecked = 0
    
    lazy var otherTokens: [Blockchain: BlockchainSdk.Token] = {
        guard case let .token(token) = amountType else {
            return [:]
        }

        let otherTokens: [Blockchain: BlockchainSdk.Token]
        let supportedTokenItems = SupportedTokenItems()
        return supportedTokenItems
            .tokens(symbol: token.symbol, name: token.name, blockchains: otherBlockchains)
            .mapValues {
                BlockchainSdk.Token(
                    name: $0.name,
                    symbol: $0.symbol,
                    contractAddress: $0.contractAddress,
                    decimalCount: $0.decimalCount,
                    customIconUrl: $0.customIconUrl,
                    blockchain: $0.blockchain,
                    derivationPath: self.blockchain.derivationPath
                )
            }
    }()
    
    lazy var walletManagers: [WalletManager] = {
        return otherBlockchains.compactMap { otherBlockchain in
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
            
            if case let .token(token) = amountType {
                if let otherNetworkToken = otherTokens[otherBlockchain] {
                    walletManager?.addToken(otherNetworkToken)
                } else {
                    return nil
                }
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
    
    func recover() -> AnyPublisher<BlockchainAmount, Never> {
        subject.send(completion: .finished)
        subject = PassthroughSubject()
        
        numberOfAmountsChecked = 0
        
//        let otherTokens = self.otherTokens
        
        walletManagers.forEach { walletManager in
            walletManager.update { [weak self] result in
                guard let self = self else { return }
                
                self.numberOfAmountsChecked += 1

                
                let wallet = walletManager.wallet
                let blockchain = wallet.blockchain
                
                let amount: Amount?
                switch self.amountType {
                case .coin:
                    amount = wallet.amounts[self.amountType]
                case .token:
                    let otherToken = self.otherTokens[blockchain]!
                    amount = wallet.amounts[.token(value: otherToken)]
                case .reserve:
                    return
                }
                
                if let amount = amount, !amount.isZero {
                    self.subject.send(BlockchainAmount(blockchain: blockchain, amount: amount))
                }
                
                if self.numberOfAmountsChecked == self.walletManagers.count {
                    self.subject.send(completion: .finished)
                }
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
}
