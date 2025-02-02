//
//  SwappingModulesFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemExchange

protocol SwappingModulesFactory {
    func makeSwappingViewModel(coordinator: SwappingRoutable) -> SwappingViewModel
    func makeSwappingTokenListViewModel(coordinator: SwappingTokenListRoutable) -> SwappingTokenListViewModel
    func makeSwappingPermissionViewModel(
        inputModel: SwappingPermissionInputModel,
        coordinator: SwappingPermissionRoutable
    ) -> SwappingPermissionViewModel
    func makeSwappingSuccessViewModel(
        inputModel: SwappingSuccessInputModel,
        coordinator: SwappingSuccessRoutable
    ) -> SwappingSuccessViewModel
}
