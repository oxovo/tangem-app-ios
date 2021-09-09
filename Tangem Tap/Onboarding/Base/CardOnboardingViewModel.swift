//
//  CardOnboardingViewModel.swift
//  Tangem Tap
//
//  Created by Andrew Son on 24.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

class CardOnboardingViewModel: ViewModel {
    
    enum Content {
        case notScanned, singleCard, twin, wallet
        
        static func content(for cardModel: CardViewModel) -> Content {
            let card = cardModel.cardInfo.card
            if card.isTwinCard {
                return .twin
            }
            if card.isTangemWallet {
                return .wallet
            }
            
            return .singleCard
        }
        
        static func content(for steps: OnboardingSteps) -> Content {
            switch steps {
            case .singleWallet: return .singleCard
            case .twins: return .twin
            case .wallet: return .wallet
            }
        }
        
        var navbarTitle: LocalizedStringKey {
            switch self {
            case .notScanned: return ""
            case .singleCard: return "Activating card"
            case .twin: return "Tangem Twin"
            case .wallet: return "Tangem Wallet"
            }
        }
    }
    
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var userPrefsService: UserPrefsService!
    
    let isFromMainScreen: Bool
    
    var isTermsOfServiceAccepted: Bool { userPrefsService.isTermsOfServiceAccepted }
    
    @Published var content: Content
    @Published var toMain: Bool = false
    
    private var resetSubscription: AnyCancellable?
    
    init() {
        self.isFromMainScreen = false
        self.content = .notScanned
    }
    
    init(cardModel: CardViewModel) {
        isFromMainScreen = true
        content = .content(for: cardModel)
    }
    
    init(input: CardOnboardingInput) {
        isFromMainScreen = true
        content = .content(for: input.steps)
//        self.input = input
    }
    
    func bind() {
        resetSubscription = navigation.$onboardingReset
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { shouldReset in
//                guard shouldReset else { return }
                self.navigation.onboardingReset = false
                withAnimation {
                    self.content = .notScanned
                }
            }
    }
    
    func reset() {
        guard isFromMainScreen else {
            return
        }
        
        content = .notScanned
    }
    
    func processScannedCard(with input: CardOnboardingInput) {
        guard input.steps.needOnboarding else {
            processToMain()
            return
        }
        
        var input = input
        input.successCallback = processToMain
        let content: Content = .content(for: input.steps)
        
        switch content {
        case .singleCard:
            input.currentStepIndex = 1
            assembly.makeNoteOnboardingViewModel(with: input)
        case .twin:
            assembly.makeTwinOnboardingViewModel(with: input)
        default:
            break
        }
        
        withAnimation {
            self.content = content
        }
    }
    
    private func processToMain() {
        if isFromMainScreen {
            navigation.mainToCardOnboarding = false
            return
        }
        navigation.readToMain = true
        toMain = true
    }
    
}