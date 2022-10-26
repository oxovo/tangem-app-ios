//
//  FeatureProvider.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Provider

// Use this provider for your feature
// Will be expand for control availability version
enum FeatureProvider {
    static func isAvailable(_ toggle: FeatureToggle) -> Bool {
        EnvironmentProvider.shared.availableFeatures.contains(toggle)
    }
}

// MARK: - Keys

enum FeatureToggle: String, Hashable, CaseIterable {
    case test
    
    var name: String {
        switch self {
        case .test: return "Test (will be able in future)"
        }
    }
}
