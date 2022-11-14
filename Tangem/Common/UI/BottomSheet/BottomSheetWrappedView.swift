//
//  BottomSheetWrappedView.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 18.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct BottomSheetWrappedView<Content: View>: View {
    let content: Content
    let settings: BottomSheetSettings
    let hideCallback: () -> ()

    init(content: Content,
         settings: BottomSheetSettings,
         hideCallback: @escaping () -> ()
    ) {
        self.content = content
        self.settings = settings
        self.hideCallback = hideCallback
    }

    var body: some View {
        VStack(spacing: 0) {
            if settings.swipeDownToDismissEnabled {
                SheetDragHandler()
            }
            content
            if settings.showClosedButton {
                MainButton(text: "common_close".localized, style: .secondary, action: hideCallback)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 40)
            }
            Spacer()
        }
    }
}
