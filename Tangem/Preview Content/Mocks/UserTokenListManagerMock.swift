//
//  UserTokenListManagerMock.swift
//  Tangem
//
//  Created by Sergey Balashov on 25.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct UserTokenListManagerMock: UserTokenListManager {
    var didPerformInitialLoading: Bool { false }

    func update(userWalletId: Data) {}

    func update(_ type: CommonUserTokenListManager.UpdateType) {}

    func updateLocalRepositoryFromServer(result: @escaping (Result<UserTokenList, Error>) -> Void) {}

    func getEntriesFromRepository() -> [StorageEntry] { [] }

    func clearRepository(completion: @escaping () -> Void) {}
}
