//
//  DerivedBlockchain.swift
//  Tangem
//
//  Created by Andrey Chukavin on 15.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

#if !CLIP
import BlockchainSdk
#endif


struct DerivedBlockchain: Equatable, Hashable, Codable {
    let blockchain: Blockchain
    let derivationPath: DerivationPath?
}

extension DerivedBlockchain {
    init(_ blockchain: Blockchain) {
        self.blockchain = blockchain
        self.derivationPath = blockchain.derivationPath
    }
}
