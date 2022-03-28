//
//  WalletManagerAssembly.swift
//  Tangem
//
//  Created by Alexander Osokin on 25.11.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

class WalletManagerAssembly {
    let factory: WalletManagerFactory
    let tokenItemsRepository: TokenItemsRepository
    
    init(factory: WalletManagerFactory, tokenItemsRepository: TokenItemsRepository) {
        self.factory = factory
        self.tokenItemsRepository = tokenItemsRepository
    }

    func makeAllWalletManagers(for cardInfo: CardInfo) -> [WalletManagerInfo] {
        //If this card is Twin, return twinWallet
        if cardInfo.card.isTwinCard {
            if let savedPairKey = cardInfo.twinCardInfo?.pairPublicKey,
               let publicKey = cardInfo.card.wallets.first?.publicKey,
               let twinManager = try? factory.makeTwinWalletManager(from: cardInfo.card.cardId,
                                                                    walletPublicKey: publicKey,
                                                                    pairKey: savedPairKey,
                                                                    isTestnet: false) {
                
                let info = WalletManagerInfo(manager: twinManager, isHidden: false)
                return [info]
            }
            
            //temp for bugged case
            if cardInfo.twinCardInfo?.pairPublicKey == nil,
               let wallet = cardInfo.card.wallets.first,
               let bitcoinManager = try? factory.makeWalletManager(cardId: cardInfo.card.cardId,
                                                                   blockchain: .bitcoin(testnet: false),
                                                                   walletPublicKey: wallet.publicKey ) {
                let info = WalletManagerInfo(manager: bitcoinManager, isHidden: false)
                return [info]
            }
            
            return []
        }
        
        //If this card supports multiwallet feature, load all saved tokens from persistent storage
        if cardInfo.isMultiWallet {
            var infos: [WalletManagerInfo] = []
            let tokenItems = tokenItemsRepository.getItems(for: cardInfo.card.cardId)
            
            if !tokenItems.isEmpty {
                //Load tokens if exists
                let savedBlockchainInfos = tokenItems.compactMap { $0.blockchainInfo }
                let savedTokens = tokenItems.compactMap { $0.token }
                let groupedTokens = Dictionary(grouping: savedTokens, by: { $0.blockchain })
                
                infos.append(contentsOf: makeWalletManagers(from: cardInfo, blockchainInfos: savedBlockchainInfos
                    .sorted{$0.blockchain.displayName < $1.blockchain.displayName}))
                
                groupedTokens.forEach { tokenGroup in
                    infos.forEach { info in
                        if info.manager.wallet.blockchain == tokenGroup.key {
                            info.manager.addTokens(tokenGroup.value)
                        }
                    }
                }
            }
            
            //Try found default card wallet
            if let nativeWalletManagerInfo = makeNativeWalletManager(from: cardInfo),
               !infos.contains(where: { $0.manager.wallet.blockchain == nativeWalletManagerInfo.manager.wallet.blockchain }) {
                infos.append(nativeWalletManagerInfo)
            }
            
            return infos
        }
        
        //Old single walled ada cards or Tangem Notes
        if let nativeWalletManagerInfo = makeNativeWalletManager(from: cardInfo) {
            return [nativeWalletManagerInfo]
        }
        
        return []
    }
    
    ///Try to make WalletManagers for blockchains with suitable wallet
    func makeWalletManagers(from cardInfo: CardInfo, blockchainInfos: [BlockchainInfo]) -> [WalletManagerInfo] {
        // Additional blockchainInfos for non-validated evm blockchains
        let additionalInfos = blockchainInfos.compactMap { info -> BlockchainInfo? in
            if cardInfo.card.settings.isHDWalletAllowed, info.blockchain.isEvmBlockchain,
               !info.hasExplicitDerivation {
                let unifiedPath = Blockchain.getDefaultEvmDerivation(isTestnet: cardInfo.isTestnet)
                return BlockchainInfo(info.blockchain, derivationPath: unifiedPath)
            }
            
            return nil
        }
        
        let fullInfos = blockchainInfos + additionalInfos
        
        return fullInfos.compactMap { info -> WalletManagerInfo? in
            if let wallet = cardInfo.card.wallets.first(where: { $0.curve == info.blockchain.curve }),
               let manager = makeWalletManager(cardId: cardInfo.card.cardId,
                                               walletPublicKey: wallet.publicKey,
                                               blockchainInfo: info,
                                               isHDWalletAllowed: cardInfo.card.settings.isHDWalletAllowed,
                                               derivedKeys: cardInfo.derivedKeys[wallet.publicKey] ?? [:]) {
                
                let hasCopy = additionalInfos.contains(where: { $0.blockchain == info.blockchain })
                return WalletManagerInfo(manager: manager, isHidden: hasCopy)
            }
            return nil
        }
    }
    
    func makeWalletManagers(from cardDto: SavedCard, blockchainInfos: [BlockchainInfo]) -> [WalletManagerInfo] {
        return blockchainInfos.compactMap { info in
            if let wallet = cardDto.wallets.first(where: { $0.curve == info.blockchain.curve }),
               let manager = makeWalletManager(cardId: cardDto.cardId,
                                               walletPublicKey: wallet.publicKey,
                                               blockchainInfo: info,
                                               isHDWalletAllowed: wallet.isHdWalletAllowed,
                                               derivedKeys: cardDto.getDerivedKeys(for: wallet.publicKey)) {
                return WalletManagerInfo(manager: manager, isHidden: false)
            }
            
            return nil
        }
    }
    
    private func makeWalletManager(cardId: String,
                                   walletPublicKey: Data,
                                   blockchainInfo: BlockchainInfo,
                                   isHDWalletAllowed: Bool,
                                   derivedKeys: [DerivationPath: ExtendedPublicKey]) -> WalletManager? {
        let blockchain = blockchainInfo.blockchain
        if isHDWalletAllowed, let derivationPath = blockchainInfo.derivationPath,
           blockchain.curve == .secp256k1 || blockchain.curve == .ed25519  {
            guard let derivedKey = derivedKeys[derivationPath] else { return nil }
            
            return try? factory.makeWalletManager(cardId: cardId,
                                                  blockchain: blockchain,
                                                  seedKey: walletPublicKey,
                                                  derivedKey: derivedKey,
                                                  derivationPath: derivationPath)
        } else {
            return try? factory.makeWalletManager(cardId: cardId,
                                                  blockchain: blockchain,
                                                  walletPublicKey: walletPublicKey)
        }
    }
    
    /// Try to load native walletmanager from card
    private func makeNativeWalletManager(from cardInfo: CardInfo) -> WalletManagerInfo? {
        if let defaultBlockchain = cardInfo.defaultBlockchain,
           let info = makeWalletManagers(from: cardInfo, blockchainInfos: [.init(defaultBlockchain)]).first {
            if let defaultToken = cardInfo.defaultToken {
                info.manager.addToken(defaultToken)
            }
            
            return info
        }
        
        return nil
    }
}


struct WalletManagerInfo {
    let manager: WalletManager
    let isHidden: Bool
}
