//
//  ChatView.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 14.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SupportChatView: View {
    @ObservedObject var viewModel: SupportChatViewModel

    var body: some View {
        switch viewModel.viewState {
        case .webView(let url):
            WebView(url: url)
        case .zendesk(let viewModel):
            ZendeskSupportChatView(viewModel: viewModel)
        case .none:
            EmptyView()
        }
    }
}
