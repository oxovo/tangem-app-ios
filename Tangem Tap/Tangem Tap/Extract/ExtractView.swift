//
//  ExtractView.swift
//  Tangem Tap
//
//  Created by Alexander Osokin on 18.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ExtractView: View {
    @EnvironmentObject var tangemSdkModel: TangemSdkModel
    
    let model = ExtractViewModel()
    
    var body: some View {
        Text("Extract")
    }
}

struct ExtractView_Previews: PreviewProvider {
    static var previews: some View {
        ExtractView()
    }
}