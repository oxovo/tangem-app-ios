//
//  TokenItem.swift
//  Tangem
//
//  Created by Alexander Osokin on 10.03.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Kingfisher
import SwiftUI

enum TokenItem: Hashable, Identifiable {
    case blockchain(BlockchainInfo)
    case token(Token)
    
    var isBlockchain: Bool { token == nil }
    
    var blockchainInfo: BlockchainInfo {
        switch self {
        case .blockchain(let blockchainInfo):
            return blockchainInfo
        default:
            return nil
        }
    }
    
    var id: Int {
        switch self {
        case .token(let token):
            return token.hashValue
        case .blockchain(let blockchainInfo):
            return blockchainInfo.hashValue
        }
    }
    
    var blockchain: Blockchain {
        switch self {
        case .token(let token):
            return token.blockchain
        case .blockchain(let blockchainInfo):
            return blockchainInfo.blockchain
        }
    }
    
    var token: Token? {
        if case let .token(token) = self {
            return token
        }
        return nil
    }
    
    var name: String {
        switch self {
        case .token(let token):
            return token.name
        case .blockchain(let blockchainInfo):
            return blockchainInfo.blockchain.displayName
        }
    }
    
    var contractName: String? {
        switch self {
        case .token(let token):
            switch token.blockchain {
            case .binance: return "BEP2"
            case .bsc: return "BEP20"
            case .ethereum: return "ERC20"
            default:
                return nil
            }
        case .blockchain:
            return "MAIN"
        }
    }
    
    var symbol: String {
        switch self {
        case .token(let token):
            return token.symbol
        case .blockchain(let blockchainInfo):
            return blockchainInfo.blockchain.currencySymbol
        }
    }
    
    var contractAddress: String? {
        switch self {
        case .token(let token):
            return token.contractAddress
        case .blockchain:
            return nil
        }
    }
    
    var amountType: Amount.AmountType {
        switch self {
        case .token(let token):
            return .token(value: token)
        case .blockchain:
            return .coin
        }
    }
    
    var iconView: TokenIconView {
        TokenIconView(token: self)
    }
    
    @ViewBuilder fileprivate var imageView: some View {
        switch self {
        case .token(let token):
            CircleImageTextView(name: token.name, color: token.color)
        case .blockchain(let blockchainInfo):
            Image(blockchainInfo.blockchain.iconNameFilled)
                .resizable()
        }
    }
    
    fileprivate var imageURL: URL? {
        switch self {
        case .blockchain(let blockchainInfo):
            return IconsUtils.getBlockchainIconUrl(blockchainInfo.blockchain).flatMap { URL(string: $0.absoluteString) }
        case .token(let token):
            return token.customIconUrl.flatMap{ URL(string: $0) }
        }
    }
}

extension TokenItem: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let token = try? container.decode(Token.self) {
            self = .token(token)
        } else if let blockchainInfo = try? container.decode(BlockchainInfo.self) {
            self = .blockchain(blockchainInfo)
        } else if let blockchain = try? container.decode(Blockchain.self) {
            // Compatibility
            self = .blockchain(BlockchainInfo(blockchain: blockchain, derivationPath: nil))
        } else if let tokenDto = try? container.decode(TokenDTO.self) {
            // Compatibility
            self = .token(Token(name: tokenDto.name,
                                symbol: tokenDto.symbol,
                                contractAddress: tokenDto.contractAddress,
                                decimalCount: tokenDto.decimalCount,
                                customIconUrl: tokenDto.customIconUrl,
                                blockchain: .ethereum(testnet: false)))
        } else {
            throw BlockchainSdkError.decodingFailed
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .blockchain(let blockchainInfo):
            try container.encode(blockchainInfo)
        case .token(let token):
            try container.encode(token)
        }
    }
}

struct TokenDTO: Decodable {
    let name: String
    let symbol: String
    let contractAddress: String
    let decimalCount: Int
    let customIcon: String?
    let customIconUrl: String?
}


struct TokenIconView: View {
    var token: TokenItem
    var size: CGSize = .init(width: 80, height: 80)
    
    var body: some View {
        if let url = token.imageURL {
        #if !CLIP
            KFImage(url)
                .placeholder { token.imageView }
                .setProcessor(DownsamplingImageProcessor(size: size))
                .cacheOriginalImage()
                .scaleFactor(UIScreen.main.scale)
                .resizable()
                .scaledToFit()
                .cornerRadius(5)
        #else
            WebImage(imagePath: url, placeholder: token.imageView.toAnyView())
        #endif
        } else {
            token.imageView
        }
    }
}
