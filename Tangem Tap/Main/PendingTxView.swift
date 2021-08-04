//
//  PendingTxView.swift
//  Tangem Tap
//
//  Created by Alexander Osokin on 14.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI


struct PendingTxView: View, Identifiable {
    
    let id = UUID()
    let pendingTx: PendingTransaction
    var pushAction: (() -> Void)? = nil
    
    var address: String {
        pendingTx.destination
    }
    
    var titlePrefixLocalized: String {
        switch pendingTx.direction {
        case .outgoing:
            return "wallet_pending_tx_sending".localized
        case .incoming:
            return "wallet_pending_tx_receiving".localized
        }
    }
    
    var titleFormat: String {
        switch pendingTx.direction {
        case .outgoing:
            return "wallet_pending_tx_sending_address_format".localized
        case .incoming:
            return "wallet_pending_tx_receiving_address_format".localized
        }
    }
    
    var text: String {
        if address == "unknown" {
            return "wallet_balance_tx_in_progress".localized
        } else {
            return titlePrefixLocalized + pendingTx.transferAmount + String(format: titleFormat, AddressFormatter(address: address).truncated())
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 8.0) {
                if address != "unknown" {
                    Image(self.pendingTx.direction == .incoming ?  "arrow.down" :
                            "arrow.right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color.tangemTapGrayDark6)
                        .frame(width: 12.0, height: 12.0)
                }
                Text(text)
                    .font(Font.system(size: 13.0, weight: .medium, design: .default))
                    .foregroundColor(Color.tangemTapGrayDark6)
                    .lineLimit(1)
                Spacer()
                if pendingTx.canBePushed {
                    RoundedRectButton(action: {
                        pushAction?()
                    }, title: "common_push".localized)
                }
            }
            .padding(.horizontal, 20.0)
            .padding(.vertical, 11.0)
        }
        .background(Color.white)
        .cornerRadius(6.0)
    }
}

struct PendingTxView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.tangemTapBgGray
            VStack {
                PendingTxView(pendingTx: PendingTransaction(destination: "sadfasdfasdfsadf", transferAmount: "0.2 BTC", canBePushed: false, direction: .incoming))
                PendingTxView(pendingTx: PendingTransaction(destination: "sadfasdfasdfsadf", transferAmount: "0.2 BTC", canBePushed: false, direction: .outgoing))
                PendingTxView(pendingTx: PendingTransaction(destination: "sadfasdfasdfsadf", transferAmount: "0.2 BTC", canBePushed: true, direction: .outgoing))
            }
            
        }
    }
}
