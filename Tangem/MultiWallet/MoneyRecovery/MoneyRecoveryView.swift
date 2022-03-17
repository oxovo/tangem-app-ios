//
//  MoneyRecoveryView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 16.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk

struct MoneyRecoveryView: View {
    @ObservedObject var viewModel: MoneyRecoveryViewModel
    
    var body: some View {
        VStack {
            switch viewModel.state {
            case .checking:
                Text("Checking")
            case .found(let amount):
                Text("Found \(amount.description)")
                
                Button {
                    viewModel.send()
                } label: {
                    Text("Send")
                }
            case .nothing:
                Text("Nothing found")
            }
            
            Color.clear.frame(width: 0.5, height: 0.5)
                .sheet(isPresented: $viewModel.showSendView) {
                    SendView(viewModel: viewModel.assembly.makeSendViewModel(with: Amount(with: .rsk, value: 1), blockchain: .rsk, card: viewModel.card))
                }
        }
        .onAppear(perform: viewModel.didAppear)
    }
}
/* 
struct MoneyRecoveryView_Previews: PreviewProvider {
    static var previews: some View {
        MoneyRecoveryView()
    }
}
 */