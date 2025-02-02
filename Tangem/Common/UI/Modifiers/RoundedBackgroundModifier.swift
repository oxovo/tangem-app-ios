//
//  RoundedBackgroundModifier.swift
//  Tangem
//
//  Created by Andrew Son on 08/11/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct RoundedBackgroundModifier: ViewModifier {
    let padding: CGFloat
    let backgroundColor: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadiusContinuous(cornerRadius)
    }
}

extension View {
    @ViewBuilder
    func roundedBackground(with color: Color, padding: CGFloat, radius: CGFloat) -> some View {
        modifier(
            RoundedBackgroundModifier(
                padding: padding,
                backgroundColor: color,
                cornerRadius: radius
            )
        )
    }
}
