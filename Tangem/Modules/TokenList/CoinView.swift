//
//  CoinView.swift
//  Tangem
//
//  Created by Alexander Osokin on 17.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Kingfisher

struct CoinView: View {
    @ObservedObject var model: CoinViewModel
    var subtitle: String = Localization.currencySubtitleExpanded

    let iconWidth: Double = 46

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                IconView(url: model.imageURL, size: CGSize(width: iconWidth, height: iconWidth), forceKingfisher: true)
                    .padding(.trailing, 14)

                VStack(alignment: .leading, spacing: 6) {
                    Group {
                        Text(model.name)
                            .foregroundColor(.tangemGrayDark6)
                            + Text(symbolFormatted)
                            .foregroundColor(Color(hex: "#A9A9AD")!)
                    }
                    .lineLimit(1)
                    .font(.system(size: 17, weight: .medium, design: .default))

                    VStack {
                        if isExpanded {
                            Text(subtitle)
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#A9A9AD")!)

                            Spacer()
                        } else {
                            HStack(spacing: 5) {
                                ForEach(model.items) {
                                    CoinItemView(model: $0, arrowWidth: iconWidth).icon
                                }
                            }
                        }
                    }.frame(height: 20)
                }

                Spacer(minLength: 0)

                chevronView
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isExpanded.toggle()
            }

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(model.items) { CoinItemView(model: $0, arrowWidth: iconWidth) }
                }
            }
        }
        .padding(.vertical, 10)
        .animation(nil) // Disable animations on scroll reuse
    }

    private var symbolFormatted: String { " (\(model.symbol))" }
    @State private var isExpanded = false

    private var chevronView: some View {
        Image(systemName: "chevron.down")
            .font(.system(size: 17, weight: .medium, design: .default))
            .rotationEffect(isExpanded ? Angle(degrees: 180) : .zero)
            .foregroundColor(Color(hex: "#CCCCCC")!)
            .padding(.vertical, 4)
    }
}

struct CurrencyView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StatefulPreviewWrapper(false) {
                CoinView(model: CoinViewModel(
                    imageURL: nil,
                    name: "Tether",
                    symbol: "USDT",
                    items: [
                        CoinItemViewModel(
                            tokenItem: .blockchain(.ethereum(testnet: false)),
                            isReadonly: false,
                            isSelected: $0,
                            position: .first
                        ),
                        CoinItemViewModel(
                            tokenItem: .blockchain(.ethereum(testnet: false)),
                            isReadonly: false,
                            isSelected: $0,
                            position: .middle
                        ),
                        CoinItemViewModel(
                            tokenItem: .blockchain(.ethereum(testnet: false)),
                            isReadonly: false,
                            isSelected: $0,
                            position: .last
                        ),
                    ]
                ))
            }

            StatefulPreviewWrapper(false) {
                CoinView(model: CoinViewModel(
                    imageURL: nil,
                    name: "Very Long Name of The Token",
                    symbol: "VLNOFT",
                    items: [
                        CoinItemViewModel(
                            tokenItem: .blockchain(.ethereum(testnet: false)),
                            isReadonly: false,
                            isSelected: $0,
                            position: .first
                        ),
                        CoinItemViewModel(
                            tokenItem: .blockchain(.ethereum(testnet: false)),
                            isReadonly: false,
                            isSelected: $0,
                            position: .middle
                        ),
                        CoinItemViewModel(
                            tokenItem: .blockchain(.ethereum(testnet: false)),
                            isReadonly: false,
                            isSelected: $0,
                            position: .last
                        ),
                    ]
                ))
            }

            Spacer()
        }
        .padding()
    }
}
