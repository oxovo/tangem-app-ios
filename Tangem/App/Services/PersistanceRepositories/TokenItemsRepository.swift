//
//  TokenItemsRepository.swift
//  Tangem
//
//  Created by Alexander Osokin on 28.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class TokenItemsRepository {
    private let persistanceStorage: PersistentStorage
    private let lockQueue = DispatchQueue(label: "token_items_repo_queue")
    
    internal init(persistanceStorage: PersistentStorage) {
        self.persistanceStorage = persistanceStorage
    }
    
    deinit {
        print("TokenItemsRepository deinit")
    }
    
    func append(_ tokenItem: TokenItem, for cardId: String) {
        lockQueue.sync {
            var items = fetch(for: cardId)
            
            if items.contains(tokenItem) {
                return
            }
            
            items.append(tokenItem)
            save(items, for: cardId)
        }
    }
    
    func append(_ tokenItems: [TokenItem], for cardId: String) {
        lockQueue.sync {
            var items = fetch(for: cardId)
            
            for tokenItem in tokenItems {
                if !items.contains(tokenItem) {
                    items.append(tokenItem)
                }
            }

            save(items, for: cardId)
        }
    }
    
    func remove(_ tokenItem: TokenItem, for cardId: String) {
        lockQueue.sync {
            var items = fetch(for: cardId)
            items.remove(tokenItem)
            save(items, for: cardId)
        }
    }
    
    func removeAll(for cardId: String) {
        lockQueue.sync {
            save([], for: cardId)
        }
    }
    
    func getItems(for cardId: String) -> [TokenItem] {
        lockQueue.sync {
            fetch(for: cardId)
        }
    }
    
    private func fetch(for cardId: String) -> [TokenItem] {
        let fetched: [TokenItem] = (try? persistanceStorage.value(for: .wallets(cid: cardId))) ?? []
        //Migration to separate networks/tokens storage
        let tokenBlokchains = fetched.compactMap { $0.token?.blockchain }
        let blockchains = fetched.filter { $0.isBlockchain }.map { $0.blockchain }
        let missingTokenBlokchains = Set(tokenBlokchains).subtracting(blockchains)
        if !missingTokenBlokchains.isEmpty {
            let blockchainItems: [TokenItem] = missingTokenBlokchains.map { .blockchain(.init(blockchain: $0)) }
            let combinedItems = fetched + blockchainItems
            save(combinedItems, for: cardId)
            return combinedItems
        }
        
        return fetched
    }
    
    private func save(_ items: [TokenItem], for cardId: String) {
        try? persistanceStorage.store(value: items, for: .wallets(cid: cardId))
    }
}
