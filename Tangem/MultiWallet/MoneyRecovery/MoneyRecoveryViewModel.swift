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
        case found(amount: Amount)
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
        
        self.moneyRecoveryService.recover()
            .sink { [unowned self] _ in
                guard case .found = self.state else {
                    self.state = .nothing
                    return
                }
            } receiveValue: { [unowned self] blockchainAmount in
                let amount = blockchainAmount.amount
                
                if !amount.isZero {
                    self.state = .found(amount: amount)
                }
            }
            .store(in: &bag)
    }
    
    func send() {
        showSendView = true
    }
}
