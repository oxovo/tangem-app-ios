//
//  MoneyRecoveryViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 16.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemSdk

class MoneyRecoveryViewModel: ViewModel, ObservableObject {
    enum State {
        case checking
        case found(amount: Amount, blockchain: Blockchain)
        case nothing
    }
    
    struct RecoveryBlockchain: Hashable {
        let blockchain: Blockchain
        let derivationPath: DerivationPath?
        var amount: String
    }
    
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    var moneyRecoveryService: MoneyRecoveryService!
    
    var card: CardViewModel!
    
    var foundBlockchain: Blockchain? {
        guard case let .found(_, blockchain) = state else {
            return nil
        }
        return blockchain
    }
    
    var walletManager: WalletManager? {
        guard let foundBlockchain = foundBlockchain else {
            return nil
        }
        
        return moneyRecoveryService.walletManagers.first(where: { $0.wallet.blockchain == foundBlockchain })
    }
    
    var walletModel: WalletModel? {
        guard let walletManager = walletManager else {
            return nil
        }
        
        return assembly.makeWalletModels(walletManagers: [walletManager], cardInfo: card.cardInfo).first
    }
    
    @Published var state: State = .checking
    @Published var recoveryBlockchains: [RecoveryBlockchain] = []
    @Published var showSendView: Bool = false
    
    private var bag: Set<AnyCancellable> = []
    
    func didAppear() {
        self.recoveryBlockchains = moneyRecoveryService.walletManagers.map {
            RecoveryBlockchain(
                blockchain: $0.wallet.blockchain,
                derivationPath: $0.wallet.derivationPath,
                amount: ""
            )
        }
        
        self.moneyRecoveryService
            .recover()
            .collect(0)
            .sink { [unowned self] _ in
                guard case .found = self.state else {
                    self.state = .nothing
                    return
                }
            } receiveValue: { [unowned self] blockchainAmounts in
                if let blockchainAmount = blockchainAmounts.first {
                    self.state = .found(amount: blockchainAmount.amount, blockchain: blockchainAmount.blockchain)
                }
            }
            .store(in: &bag)
        
        $state
            .compactMap { state -> Amount? in
                guard case let .found(amount, _) = state else {
                    return nil
                }
                return amount
            }
            .setFailureType(to: Error.self)
            .flatMap { [unowned self] amount -> AnyPublisher<[Amount], Error> in
                guard let walletManager = walletManager else {
                    return .anyFail(error: WalletError.empty)
                }

                return walletManager
                    .getFee(amount: amount, destination: "0x65Ed63264AF16D2091fe9Cfe94d31B4B05713E2e")
                    .eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { _ in
                
            }, receiveValue: { amounts in
                print(amounts)
            })
            .store(in: &bag)
            
            
    }
    
    func send() {
        showSendView = true
    }
}
