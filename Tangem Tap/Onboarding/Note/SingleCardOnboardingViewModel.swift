//
//  OnboardingViewModel.swift
//  Tangem Tap
//
//  Created by Andrew Son on 03/08/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk
import Combine

class SingleCardOnboardingViewModel: OnboardingTopupViewModel<SingleCardOnboardingStep> {
    
    weak var cardsRepository: CardsRepository!
    weak var stepsSetupService: OnboardingStepsSetupService!
    weak var userPrefsService: UserPrefsService!
    weak var imageLoaderService: CardImageLoaderService!
    
    @Published var cardImage: UIImage?
    @Published var isCardScanned: Bool = true

    override var currentProgress: CGFloat {
        CGFloat(currentStep.progressStep) / CGFloat(numberOfSteps)
    }
    
    var shopURL: URL { Constants.shopURL }
    
    override var currentStep: SingleCardOnboardingStep {
        guard currentStepIndex < steps.count else {
            return assembly.isPreview ? .createWallet : .welcome
        }

        return steps[currentStepIndex]
    }
    
    private(set) var numberOfSteps: Int
    
    private var bag: Set<AnyCancellable> = []
    private var previewUpdateCounter: Int = 0
    private var walletCreatedWhileOnboarding: Bool = false
    private var scheduledUpdate: DispatchWorkItem?
    
    override init(exchangeService: ExchangeService, input: OnboardingInput) {
        cardImage = input.cardImage
        numberOfSteps = SingleCardOnboardingStep.maxNumberOfSteps(isNote: input.cardModel.cardInfo.card.isTangemNote)
        super.init(exchangeService: exchangeService, input: input)
        
        if case let .singleWallet(steps) = input.steps {
            self.steps = steps
        } else {
            fatalError("Wrong onboarding steps passed to initializer")
        }
    }
        
    // MARK: Functions

    override func goToNextStep() {
        super.goToNextStep()
        stepUpdate()
    }
    
    override func reset(includeInResetAnim: (() -> Void)? = nil) {
        super.reset {
            self.isCardScanned = false
        }
    }
    
    override func mainButtonAction() {
        switch currentStep {
        case .welcome:
            if assembly.isPreview {
                goToNextStep()
                withAnimation {
                    isNavBarVisible = true
                    isCardScanned = true
                }
            }
        case .createWallet:
            сreateWallet()
        case .topup:
            navigation.onboardingToBuyCrypto = true
        case .successTopup:
            if assembly.isPreview {
                reset()
            }
        case .success:
            goToNextStep()
        }
    }
    
    override func supplementButtonAction() {
        switch currentStep {
        case .topup:
            isAddressQrBottomSheetPresented = true
        default:
            break
        }
    }
    
    override func setupCardsSettings(animated: Bool, isContainerSetup: Bool) {
        mainCardSettings = .init(targetSettings: SingleCardOnboardingCardsLayout.main.cardAnimSettings(for: currentStep,
                                                                                                       containerSize: containerSize,
                                                                                                       animated: animated),
                                 intermediateSettings: nil)
        supplementCardSettings = .init(targetSettings: SingleCardOnboardingCardsLayout.supplementary.cardAnimSettings(for: currentStep, containerSize: containerSize, animated: animated), intermediateSettings: nil)
    }
    
    private func сreateWallet() {
        isMainButtonBusy = true
        
        if assembly.isPreview {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.cardModel = Assembly.PreviewCard.scanResult(for: .cardanoNoteEmptyWallet, assembly: self.assembly).cardModel!
                self.updateCardBalanceText(for: self.cardModel.walletModels!.first!)
                self.isMainButtonBusy = false
                self.goToNextStep()
            }
            return
        }
        
        let card = cardModel.cardInfo.card
        
        Deferred {
            Future { (promise: @escaping Future<Void, Error>.Promise) in
                self.cardModel.createWallet { [weak self] result in
                    switch result {
                    case .success:
                        self?.updateCardBalance()
                        promise(.success(()))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .combineLatest(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification).setFailureType(to: Error.self))
        .sink { completion in
            if case let .failure(error) = completion {
                print("Failed to create wallet. \(error)")
            }
        } receiveValue: { [weak self] (_, _) in
            self?.walletCreatedWhileOnboarding = true
            if card.isTangemNote {
                self?.userPrefsService.cardsStartedActivation.append(card.cardId)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.isMainButtonBusy = false
                self?.goToNextStep()
            }
        }
        .store(in: &bag)

        
    }
    
    private func stepUpdate() {
        switch currentStep {
        case .topup:
            if walletCreatedWhileOnboarding {
                return
            }
            
            withAnimation {
                isBalanceRefresherVisible = true
            }
            updateCardBalance()
        case .successTopup:
            withAnimation {
                refreshButtonState = .doneCheckmark
            }
            fallthrough
        case .success:
            shouldFireConfetti = true
        default:
            break
        }
    }
    
    private func readPreviewCard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let previewModel = Assembly.PreviewCard.scanResult(for: .ethEmptyNote, assembly: self.assembly).cardModel!
            self.cardModel = previewModel
            self.stepsSetupService.steps(for: previewModel.cardInfo)
                .sink { _ in }
                    receiveValue: { [weak self] steps in
                        if case let .singleWallet(singleSteps) = steps {
                            self?.steps = singleSteps
                        }
                        self?.goToNextStep()
                        self?.isMainButtonBusy = false
                }
                .store(in: &self.bag)

        }
    }
    
}
