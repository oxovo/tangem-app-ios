//
//  CardBalanceOperation.swift
//  Tangem
//
//  Created by Gennady Berezovsky on 04.10.18.
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

class CardBalanceOperation: AsynchronousOperation {
    
    let balanceFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.minimumIntegerDigits = 1
        numberFormatter.maximumFractionDigits = 8
        numberFormatter.minimumFractionDigits = 2
        return numberFormatter
    }()
    
    var card: Card
    var completion: (Result<Card>) -> Void
    
    let operationQueue = OperationQueue()
    
    init(card: Card, completion: @escaping (Result<Card>) -> Void) {
        self.card = card
        self.completion = completion
        
        operationQueue.maxConcurrentOperationCount = 1
    }
    
    override func main() {
        loadMarketCapInfo()
    }
    
    func loadMarketCapInfo() {
        let coinMarketOperation = CoinMarketOperation(network: CoinMarketNetwork.btc) { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.handleMarketInfoLoaded(priceUSD: value)
            case .failure(let error):
                self?.failOperationWith(error: String(describing: error))
            }
            
        }
        operationQueue.addOperation(coinMarketOperation)
    }
    
    func handleMarketInfoLoaded(priceUSD: Double) {
        fatalError("Override this method")
    }
    
    override func cancel() {
        super.cancel()
        operationQueue.cancelAllOperations()
    }
    
    internal func completeOperation() {
        guard !isCancelled else {
            return
        }
        
        completion(.success(card))
        finish()
    }
    
    internal func failOperationWith(error: Error) {
        guard !isCancelled else {
            return
        }
        
        completion(.failure(error))
        finish()
    }
    
}
