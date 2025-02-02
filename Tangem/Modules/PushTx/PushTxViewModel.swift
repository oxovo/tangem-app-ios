//
//  PushTxViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 14/06/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine

class PushTxViewModel: ObservableObject {
    var destination: String { transaction.destinationAddress }

    var previousTotal: String {
        isFiatCalculation ?
            walletModel.getFiat(for: previousTotalAmount, roundingType: .default(roundingMode: .down))?.description ?? "" :
            previousTotalAmount.value.description
    }

    var currency: String {
        isFiatCalculation ? AppSettings.shared.selectedCurrencyCode : transaction.amount.currencySymbol
    }

    var walletTotalBalanceDecimals: String {
        let amount = walletModel.wallet.amounts[amountToSend.type]
        return isFiatCalculation ? walletModel.getFiat(for: amount, roundingType: .default(roundingMode: .down))?.description ?? ""
            : amount?.value.description ?? ""
    }

    var walletTotalBalanceFormatted: String {
        let amount = walletModel.wallet.amounts[amountToSend.type]
        let value = getDescription(for: amount, isFiat: isFiatCalculation)
        return Localization.commonBalance(value)
    }

    var walletModel: WalletModel {
        cardViewModel.walletModels.first(where: { $0.blockchainNetwork == blockchainNetwork })!
    }

    var previousFeeAmount: Amount { transaction.fee }

    var previousTotalAmount: Amount {
        previousFeeAmount + transaction.amount
    }

    var newFee: String {
        newTransaction?.fee.description ?? "Not loaded"
    }

    @Published var amountHint: TextHint?
    @Published var sendError: AlertBinder?

    @Published var isFeeLoading: Bool = false
    @Published var isSendEnabled: Bool = false

    @Published var canFiatCalculation: Bool = true
    @Published var isFiatCalculation: Bool = false
    @Published var isFeeIncluded: Bool = false

    @Published var amountToSend: Amount
    @Published var selectedFeeLevel: Int = 1
    @Published var fees: [Amount] = []
    @Published var selectedFee: Amount? = nil

    @Published var additionalFee: String = ""
    @Published var sendTotal: String = ""
    @Published var sendTotalSubtitle: String = ""

    @Published var shouldAmountBlink: Bool = false

    let cardViewModel: CardViewModel
    let blockchainNetwork: BlockchainNetwork
    var transaction: BlockchainSdk.Transaction

    lazy var amountDecimal: String = "\(walletModel.getFiat(for: amountToSend, roundingType: .default(roundingMode: .down)) ?? 0)"
    lazy var amount: String = transaction.amount.description
    lazy var previousFee: String = transaction.fee.description

    private var emptyValue: String {
        getDescription(for: Amount.zeroCoin(for: blockchainNetwork.blockchain), isFiat: isFiatCalculation)
    }

    private var bag: Set<AnyCancellable> = []
    @Published private var newTransaction: BlockchainSdk.Transaction?

    private unowned let coordinator: PushTxRoutable

    init(
        transaction: BlockchainSdk.Transaction,
        blockchainNetwork: BlockchainNetwork,
        cardViewModel: CardViewModel,
        coordinator: PushTxRoutable
    ) {
        self.coordinator = coordinator
        self.blockchainNetwork = blockchainNetwork
        self.cardViewModel = cardViewModel
        self.transaction = transaction
        amountToSend = transaction.amount
        additionalFee = emptyValue
        sendTotal = emptyValue
        sendTotalSubtitle = emptyValue

        bind()
        fillPreviousTxInfo(isFiat: isFiatCalculation)
        loadNewFees()
    }

    func onSend() {
        send {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                let alert = AlertBuilder.makeSuccessAlert(message: Localization.sendTransactionSuccess) { [weak self] in
                    self?.dismiss()
                }

                self?.sendError = alert
            }
        }
    }

    func send(_ callback: @escaping () -> Void) {
        guard
            let tx = newTransaction,
            let previousTxHash = transaction.hash,
            let pusher = walletModel.walletManager as? TransactionPusher
        else {
            return
        }

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addLoadingView()
        pusher.pushTransaction(with: previousTxHash, newTransaction: tx, signer: cardViewModel.signer)
            .delay(for: 0.5, scheduler: DispatchQueue.main)
            .sink(receiveCompletion: { [unowned self] completion in
                appDelegate.removeLoadingView()

                if case .failure(let error) = completion {
                    if error.toTangemSdkError().isUserCancelled {
                        return
                    }

                    AppLog.shared.error(error: error, params: [
                        .blockchain: self.walletModel.wallet.blockchain.displayName,
                        .action: Analytics.ParameterValue.pushTx.rawValue,
                    ])
                    self.sendError = SendError(error, openMailAction: openMail).alertBinder
                } else {
                    walletModel.startUpdatingTimer()

                    Analytics.log(
                        event: .transactionIsPushed,
                        params: [
                            .currencyCode: self.blockchainNetwork.blockchain.currencySymbol,
                            .blockchain: self.blockchainNetwork.blockchain.displayName,
                        ]
                    )

                    callback()
                }

            }, receiveValue: { _ in })
            .store(in: &bag)
    }

    private func getDescription(for amount: Amount?, isFiat: Bool) -> String {
        isFiat ?
            walletModel.getFiatFormatted(for: amount, roundingType: .default(roundingMode: .down)) ?? "" :
            amount?.description ?? emptyValue
    }

    private func bind() {
        AppLog.shared.debug("\n\nCreating push tx view model subscriptions \n\n")

        bag.removeAll()

        walletModel
            .$rates
            .map { [unowned self] newRates -> Bool in
                return newRates[self.amountToSend.currencySymbol] != nil
            }
            .weakAssign(to: \.canFiatCalculation, on: self)
            .store(in: &bag)

        $isFiatCalculation
            .sink { [unowned self] isFiat in
                self.fillPreviousTxInfo(isFiat: isFiat)
                self.fillTotalBlock(tx: self.newTransaction, isFiat: isFiat)
                self.updateFeeLabel(fee: self.selectedFee, isFiat: isFiat)
            }
            .store(in: &bag)

        $selectedFeeLevel
            .map { [unowned self] feeLevel -> Amount? in
                guard self.fees.count > feeLevel else {
                    return nil
                }

                let fee = self.fees[feeLevel]
                return fee
            }
            .weakAssign(to: \.selectedFee, on: self)
            .store(in: &bag)

        $fees
            .dropFirst()
            .map { [unowned self] values -> Amount? in
                guard values.count > self.selectedFeeLevel else { return nil }

                return values[self.selectedFeeLevel]
            }
            .weakAssign(to: \.selectedFee, on: self)
            .store(in: &bag)

        $isFeeIncluded
            .dropFirst()
            .map { [unowned self] isFeeIncluded in
                self.updateAmount(isFeeIncluded: isFeeIncluded, selectedFee: self.selectedFee)
                self.shouldAmountBlink = true
            }
            .sink(receiveValue: { _ in })
            .store(in: &bag)

        $selectedFee
            .dropFirst()
            .combineLatest($isFeeIncluded)
            .map { [unowned self] fee, isFeeIncluded -> (BlockchainSdk.Transaction?, Amount?) in
                var errorMessage: String?
                defer {
                    self.amountHint = errorMessage == nil ? nil : .init(isError: true, message: errorMessage!)
                }

                guard let fee = fee else {
                    errorMessage = BlockchainSdkError.failedToLoadFee.localizedDescription
                    return (nil, fee)
                }

                guard fee > self.transaction.fee else {
                    errorMessage = BlockchainSdkError.feeForPushTxNotEnough.localizedDescription
                    return (nil, fee)
                }

                let newAmount = isFeeIncluded ? self.transaction.amount + self.previousFeeAmount - fee : self.transaction.amount

                var tx: BlockchainSdk.Transaction?

                do {
                    tx = try walletModel.walletManager.createTransaction(
                        amount: newAmount,
                        fee: fee,
                        destinationAddress: self.destination
                    )
                } catch {
                    errorMessage = error.localizedDescription
                }

                self.updateAmount(isFeeIncluded: isFeeIncluded, selectedFee: fee)
                return (tx, fee)
            }
            .sink(receiveValue: { [unowned self] txFee in
                let tx = txFee.0
                let fee = txFee.1
                self.newTransaction = tx
                self.isSendEnabled = tx != nil
                self.fillTotalBlock(tx: tx, isFiat: self.isFiatCalculation)
                self.updateFeeLabel(fee: fee)

            })
            .store(in: &bag)
    }

    private func loadNewFees() {
        guard
            let pusher = walletModel.walletManager as? TransactionPusher,
            let txHash = transaction.hash
        else {
            return
        }

        isFeeLoading = true
        pusher.getPushFee(for: txHash)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isFeeLoading = false
                if case .failure(let error) = completion {
                    AppLog.shared.debug("Failed to load fee error: \(error.localizedDescription)")
                    self?.amountHint = .init(isError: true, message: error.localizedDescription)
                }
            }, receiveValue: { [weak self] fees in
                self?.fees = fees
            })
            .store(in: &bag)
    }

    private func fillPreviousTxInfo(isFiat: Bool) {
        amount = getDescription(for: amountToSend, isFiat: isFiat)
        amountDecimal = isFiat ? walletModel.getFiat(for: amountToSend, roundingType: .default(roundingMode: .down))?.description ?? "" : amountToSend.value.description
        previousFee = getDescription(for: previousFeeAmount, isFiat: isFiat)
    }

    private func updateFeeLabel(fee: Amount?, isFiat: Bool? = nil) {
        let isFiat = isFiat ?? isFiatCalculation
        if let fee = fee {
            additionalFee = getDescription(for: fee - previousFeeAmount, isFiat: isFiat)
        } else {
            additionalFee = getDescription(for: Amount.zeroCoin(for: blockchainNetwork.blockchain), isFiat: isFiat)
        }
    }

    private func updateAmount(isFeeIncluded: Bool, selectedFee: Amount?) {
        amountToSend = isFeeIncluded && selectedFee != nil ?
            transaction.amount + previousFeeAmount - selectedFee! :
            transaction.amount
        fillPreviousTxInfo(isFiat: isFiatCalculation)
    }

    private func fillTotalBlock(tx: BlockchainSdk.Transaction? = nil, isFiat: Bool) {
        guard let fee = tx?.fee else {
            sendTotal = emptyValue
            sendTotalSubtitle = emptyValue
            return
        }

        let totalAmount = transaction.amount + fee
        var totalFiatAmount: Decimal?

        if let fiatAmount = walletModel.getFiat(for: amountToSend, roundingType: .default(roundingMode: .down)), let fiatFee = walletModel.getFiat(for: fee, roundingType: .default(roundingMode: .down)) {
            totalFiatAmount = fiatAmount + fiatFee
        }

        let totalFiatAmountFormatted = totalFiatAmount?.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)

        if isFiat {
            sendTotal = totalFiatAmountFormatted ?? emptyValue
            sendTotalSubtitle = amountToSend.type == fee.type ?
                Localization.sendTotalSubtitleFormat(totalAmount.description) :
                Localization.sendTotalSubtitleAssetFormat(
                    amountToSend.description,
                    fee.description
                )
        } else {
            sendTotal = (amountToSend + fee).description
            sendTotalSubtitle = totalFiatAmountFormatted == nil ? emptyValue : Localization.sendTotalSubtitleFiatFormat(
                totalFiatAmountFormatted!,
                walletModel.getFiatFormatted(for: fee, roundingType: .default(roundingMode: .down))!
            )
        }
    }
}

// MARK: - Navigation

extension PushTxViewModel {
    func openMail(with error: Error) {
        let emailDataCollector = PushScreenDataCollector(
            userWalletEmailData: cardViewModel.emailData,
            walletModel: walletModel,
            amountToSend: amountToSend,
            feeText: newFee,
            pushingFeeText: selectedFee?.description ?? .unknown,
            destination: transaction.destinationAddress,
            source: transaction.sourceAddress,
            amountText: amount,
            pushingTxHash: transaction.hash ?? .unknown,
            lastError: error
        )

        let recipient = cardViewModel.emailConfig?.recipient ?? EmailConfig.default.recipient
        coordinator.openMail(with: emailDataCollector, recipient: recipient)
    }

    func dismiss() {
        coordinator.dismiss()
    }
}
