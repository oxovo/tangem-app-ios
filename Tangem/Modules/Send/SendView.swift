//
//  SendView.swift
//  Tangem
//
//  Created by Alexander Osokin on 18.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk
import BlockchainSdk
import Moya

struct SendView: View {
    @ObservedObject var viewModel: SendViewModel

    private var addressHint: String {
        Localization.sendDestinationHintAddress
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0.0) {
                    HStack {
                        Text(Localization.sendTitleCurrencyFormat(viewModel.amountToSend.currencySymbol))
                            .font(Font.system(size: 30.0, weight: .bold, design: .default))
                            .foregroundColor(Color.tangemGrayDark6)
                        Spacer()
                    }
                    .padding(.bottom)
                    TextInputField(
                        placeholder: self.addressHint,
                        text: self.$viewModel.destination,
                        suplementView: {
                            if !viewModel.isSellingCrypto {
                                pasteAddressButton

                                CircleActionButton(
                                    action: viewModel.openQRScanner,
                                    diameter: 34,
                                    backgroundColor: Colors.Button.paste,
                                    systemImageName: "qrcode.viewfinder",
                                    imageColor: .white
                                )
                                .accessibility(label: Text(Localization.voiceOverScanQrWithAddress))
                                .cameraAccessDeniedAlert($viewModel.showCameraDeniedAlert)
                            }
                        },
                        message: self.viewModel.destinationHint?.message ?? " ",
                        isErrorMessage: self.viewModel.destinationHint?.isError ?? false
                    )
                    .disabled(viewModel.isSellingCrypto)

                    if viewModel.isAdditionalInputEnabled {
                        if case .memo = viewModel.additionalInputFields {
                            TextInputField(
                                placeholder: Localization.sendExtrasHintMemo,
                                text: self.$viewModel.memo,
                                clearButtonMode: .whileEditing,
                                message: self.viewModel.memoHint?.message ?? "",
                                isErrorMessage: self.viewModel.memoHint?.isError ?? false
                            )
                            .transition(.opacity)
                        }

                        if case .destinationTag = viewModel.additionalInputFields {
                            TextInputField(
                                placeholder: Localization.sendExtrasHintDestinationTag,
                                text: self.$viewModel.destinationTagStr,
                                keyboardType: .numberPad,
                                clearButtonMode: .whileEditing,
                                message: self.viewModel.destinationTagHint?.message ?? "",
                                isErrorMessage: self.viewModel.destinationTagHint?.isError ?? false
                            )
                            .transition(.opacity)
                        }
                    }

                    Group {
                        HStack {
                            CustomTextField(
                                text: self.$viewModel.amountText,
                                isResponder: Binding.constant(nil),
                                actionButtonTapped: self.$viewModel.maxAmountTapped,
                                defaultStringToClear: "0",
                                handleKeyboard: true,
                                actionButton: Localization.sendMaxAmountLabel,
                                keyboard: UIKeyboardType.decimalPad,
                                textColor: viewModel.isSellingCrypto ? UIColor.tangemGrayDark6.withAlphaComponent(0.6) : UIColor.tangemGrayDark6,
                                font: UIFont.systemFont(ofSize: 38.0, weight: .light),
                                placeholder: "",
                                decimalCount: self.viewModel.inputDecimalsCount
                            )
                            .disabled(viewModel.isSellingCrypto)

                            Button(action: {
                                self.viewModel.isFiatCalculation.toggle()
                            }) {
                                HStack(alignment: .center, spacing: 8.0) {
                                    Text(self.viewModel.currencyUnit)
                                        .font(Font.system(size: 38.0, weight: .light, design: .default))
                                        .foregroundColor(!viewModel.isSellingCrypto ?
                                            Color.tangemBlue : Color.tangemGrayDark6.opacity(0.5))

                                    if viewModel.isFiatConvertingAvailable {
                                        Image(systemName: "arrow.up.arrow.down")
                                            .font(Font.system(size: 17.0, weight: .regular, design: .default))
                                            .foregroundColor(Color.tangemBlue)
                                    }
                                }
                            }
                            .disabled(!viewModel.isFiatConvertingAvailable)
                        }
                        .padding(.top, 25.0)
                        Separator()
                        HStack {
                            Text(self.viewModel.amountHint?.message ?? " ")
                                .font(Font.system(size: 13.0, weight: .medium, design: .default))
                                .foregroundColor((self.viewModel.amountHint?.isError ?? false) ?
                                    Color.red : Color.tangemGrayDark)
                            Spacer()
                            Text(self.viewModel.walletTotalBalanceFormatted)
                                .font(Font.system(size: 13.0, weight: .medium, design: .default))
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .foregroundColor(Color.tangemGrayDark)
                        }
                    }
                    if self.viewModel.shouldShowNetworkBlock {
                        Group {
                            HStack {
                                Text(Localization.sendNetworkFeeTitle)
                                    .font(Font.system(size: 14.0, weight: .medium, design: .default))
                                    .foregroundColor(Color.tangemGrayDark6)
                                Spacer()
                                Button(action: {
                                    withAnimation {
                                        self.viewModel.isNetworkFeeBlockOpen.toggle()
                                    }
                                }) {
                                    if !viewModel.isSellingCrypto {
                                        Image(systemName: self.viewModel.isNetworkFeeBlockOpen ? "chevron.up" : "chevron.down")
                                            .font(Font.system(size: 14.0, weight: .medium, design: .default))
                                            .foregroundColor(Color.tangemGrayDark6)
                                            .padding([.vertical, .leading])
                                    }
                                }
                                .accessibility(label: Text(self.viewModel.isNetworkFeeBlockOpen ? Localization.voiceOverCloseNetworkFeeSettings : Localization.voiceOverOpenNetworkFeeSettings))
                                .disabled(viewModel.isSellingCrypto)
                            }
                            if self.viewModel.isNetworkFeeBlockOpen || viewModel.isSellingCrypto {
                                VStack(spacing: 16.0) {
                                    if self.viewModel.shoudShowFeeSelector {
                                        PickerView(
                                            contents: [
                                                Localization.sendFeePickerLow,
                                                Localization.sendFeePickerNormal,
                                                Localization.sendFeePickerPriority,
                                            ],
                                            selection: self.$viewModel.selectedFeeLevel
                                        )
                                    }
                                    if self.viewModel.shoudShowFeeIncludeSelector {
                                        Toggle(isOn: self.$viewModel.isFeeIncluded) {
                                            Text(Localization.sendFeeIncludeDescription)
                                                .font(Font.system(size: 13.0, weight: .medium, design: .default))
                                                .foregroundColor(Color.tangemGrayDark6)
                                        }.tintCompat(.tangemBlue)
                                    }
                                }
                                .padding(.vertical, 8.0)
                                .transition(.opacity)
                            }
                        }
                    }

                    Spacer()

                    VStack(spacing: 8.0) {
                        HStack {
                            Text(Localization.sendAmountLabel)
                                .font(Font.system(size: 14.0, weight: .medium, design: .default))
                                .foregroundColor(Color.tangemGrayDark6)
                            Spacer()
                            Text(self.viewModel.sendAmount)
                                .font(Font.system(size: 14.0, weight: .medium, design: .default))
                                .fixedSize(horizontal: false, vertical: true)
                                .foregroundColor(Color.tangemGrayDark6)
                        }
                        HStack {
                            Text(Localization.sendFeeLabel)
                                .font(Font.system(size: 14.0, weight: .medium, design: .default))
                                .foregroundColor(Color.tangemGrayDark)
                            Spacer()
                            if self.viewModel.isFeeLoading {
                                ActivityIndicatorView(color: UIColor.tangemGrayDark)
                                    .offset(x: 8)
                            } else {
                                Text(self.viewModel.sendFee)
                                    .font(Font.system(size: 14.0, weight: .medium, design: .default))
                                    .foregroundColor(Color.tangemGrayDark)
                                    .frame(height: 20)
                            }
                        }
                        Color.tangemGrayLight5
                            .frame(width: nil, height: 1.0, alignment: .center)
                            .padding(.vertical, 8.0)
                        HStack {
                            Text(Localization.sendTotalLabel)
                                .font(Font.system(size: 20.0, weight: .bold, design: .default))
                                .foregroundColor(Color.tangemGrayDark6)
                            Spacer()
                            Text(self.viewModel.sendTotal)
                                .font(Font.system(size: 20.0, weight: .bold, design: .default))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .fixedSize(horizontal: false, vertical: true)
                                .foregroundColor(Color.tangemGrayDark6)
                        }
                        if !viewModel.isSellingCrypto {
                            HStack {
                                Spacer()
                                Text(self.viewModel.sendTotalSubtitle)
                                    .font(Font.system(size: 14.0, weight: .bold, design: .default))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .foregroundColor(Color.tangemGrayDark)
                            }
                        }
                    }
                    WarningListView(warnings: viewModel.warnings, warningButtonAction: {
                        self.viewModel.warningButtonAction(at: $0, priority: $1, button: $2)
                    })
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 16)

                    sendButton
                }
                .padding(16)
                .frame(
                    minWidth: geometry.size.width,
                    maxWidth: geometry.size.width,
                    minHeight: geometry.size.height,
                    maxHeight: .infinity,
                    alignment: .top
                )
            }
        }
        .onAppear {
            self.viewModel.onAppear()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)) { _ in
                viewModel.onBecomingActive()
        }
    }

    @ViewBuilder private var pasteAddressButton: some View {
        if #available(iOS 16.0, *) {
            PasteButton(payloadType: String.self) { strings in
                DispatchQueue.main.async {
                    viewModel.pasteClipboardTapped(strings)
                }
            }
            .tint(Colors.Button.paste)
            .labelStyle(.iconOnly)
            .buttonBorderShape(.capsule)
        } else {
            CircleActionButton(
                action: { viewModel.pasteClipboardTapped() },
                diameter: 34,
                backgroundColor: Colors.Button.paste,
                systemImageName: viewModel.validatedClipboard == nil ? "doc.on.clipboard" : "doc.on.clipboard.fill",
                imageColor: .white,
                isDisabled: viewModel.validatedClipboard == nil
            )
            .accessibility(label: Text(self.viewModel.validatedClipboard == nil ? Localization.voiceOverNothingToPaste : Localization.voiceOverPasteFromClipboard))
            .disabled(self.viewModel.validatedClipboard == nil)
        }
    }

    @ViewBuilder private var sendButton: some View {
        MainButton(
            title: Localization.walletButtonSend,
            icon: .leading(Assets.arrowRightMini),
            isDisabled: !viewModel.isSendEnabled,
            action: viewModel.send
        )
        .padding(.top, 16.0)
        .alert(item: $viewModel.error) { $0.alert }
    }
}

struct ExtractView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SendView(viewModel: .init(
                amountToSend: Amount(
                    with: PreviewCard.ethereum.blockchain!,
                    type: .token(value: Token(name: "DAI", symbol: "DAI", contractAddress: "0xdwekdn32jfne", decimalCount: 18)),
                    value: 0.0
                ),
                destination: "Target",
                blockchainNetwork: PreviewCard.ethereum.blockchainNetwork!,
                cardViewModel: PreviewCard.ethereum.cardModel,
                coordinator: SendCoordinator()
            ))
            .previewLayout(.iphone7Zoomed)

            SendView(viewModel: .init(
                amountToSend: Amount(
                    with: PreviewCard.ethereum.blockchain!,
                    type: .token(value: Token(name: "DAI", symbol: "DAI", contractAddress: "0xdwekdn32jfne", decimalCount: 18)),
                    value: 0.0
                ),
                blockchainNetwork: PreviewCard.ethereum.blockchainNetwork!,
                cardViewModel: PreviewCard.ethereum.cardModel,
                coordinator: SendCoordinator()
            ))
            .previewLayout(.iphone7Zoomed)
        }
    }
}
