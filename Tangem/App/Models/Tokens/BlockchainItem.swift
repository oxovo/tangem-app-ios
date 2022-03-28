//
//  BlockchainItem.swift
//  Tangem
//
//  Created by Andrey Chukavin on 28.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemSdk

struct BlockchainInfo: Hashable {
    let blockchain: Blockchain
 
    var derivationPath: DerivationPath? {
        _derivationPath ?? blockchain.derivationPath
    }
    
    var hasExplicitDerivation: Bool {
        _derivationPath != nil
    }
    
    private let _derivationPath: DerivationPath?

    init(_ blockchain: Blockchain, derivationPath: DerivationPath? = nil ) {
        self.blockchain = blockchain
        self._derivationPath = derivationPath
    }
}

extension BlockchainInfo: Codable {
    enum CodingKeys: String, CodingKey {
        case blockchain = "blockchain"
        case _derivationPath = "derivationPath"
    }
}
