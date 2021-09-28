//
//  CreateWalletAndReadOriginCardTask.swift
//  Tangem Tap
//
//  Created by Andrew Son on 27.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import TangemSdk

class CreateWalletAndReadOriginCardTask: CardSessionRunnable {
    
    func run(in session: CardSession, completion: @escaping CompletionResult<OriginCard>) {
        let createWalletsTask = CreateMultiWalletTask(curves: [.secp256k1, .ed25519, .secp256r1])
        createWalletsTask.run(in: session) { result in
            switch result {
            case .success:
                self.readOriginCard(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func readOriginCard(in session: CardSession, completion: @escaping CompletionResult<OriginCard>) {
        let linkingCommand = StartOriginCardLinkingCommand()
        linkingCommand.run(in: session) { result in
            switch result {
            case .success(let originCard):
                completion(.success(originCard))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}