//
//  ETHEngine.swift
//  TangemKit
//
//  Created by Gennady Berezovsky on 04.03.19.
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import web3swift
import BigInt

class ETHEngine: CardEngine {
    static let chainId: BigUInt = 1 //Mainnet
    
    unowned var card: Card
    
    private var transaction: EthereumTransaction?
    private var hashForSign: Data?
    private let operationQueue = OperationQueue()
    private var cachedFee: (min: String, normal: String, max: String)?
    
    var blockchainDisplayName: String {
        return "Ethereum"
    }
    
    var walletType: WalletType {
        return .eth
    }
    
    var walletUnits: String {
        return "ETH"
    }
    
    var qrCodePreffix: String {
        return "ethereum:"
    }
    
    public var txCount: Int = -1
    public var pendingTxCount: Int = -1
    
    var walletAddress: String = ""
    var exploreLink: String {
        return "https://etherscan.io/address/" + walletAddress
    }
    
    required init(card: Card) {
        self.card = card
        if card.isWallet {
            setupAddress()
        }
    }
    
    func setupAddress() {
        let hexPublicKey = card.walletPublicKey
        let hexPublicKeyWithoutTwoFirstLetters = String(hexPublicKey[hexPublicKey.index(hexPublicKey.startIndex, offsetBy: 2)...])
        let binaryCuttPublicKey = dataWithHexString(hex: hexPublicKeyWithoutTwoFirstLetters)
        let keccak = binaryCuttPublicKey.sha3(.keccak256)
        let hexKeccak = keccak.hexEncodedString()
        let cutHexKeccak = String(hexKeccak[hexKeccak.index(hexKeccak.startIndex, offsetBy: 24)...])
        
        walletAddress = "0x" + cutHexKeccak
        
        card.node = "mainnet.infura.io"
    }
}


extension ETHEngine: CoinProvider {
    var coinTraitCollection: CoinTrait {
           return CoinTrait.all
       }
    
    func getHashForSignature(amount: String, fee: String, includeFee: Bool, targetAddress: String) -> Data? {
        let nonceValue = BigUInt(txCount)
        
        
        guard let feeValue = Web3.Utils.parseToBigUInt(fee, units: .eth),
            let amountValue = Web3.Utils.parseToBigUInt(amount, units: .eth),
            let transaction = EthereumTransaction(amount: includeFee ? amountValue - feeValue : amountValue,
                                                  fee: feeValue,
                                                  targetAddress: targetAddress,
                                                  nonce: nonceValue),
            let hashForSign = transaction.hashForSignature(chainID: ETHEngine.chainId) else {
                return nil
        }
        
        self.transaction = transaction
        self.hashForSign = hashForSign
        return hashForSign
    }
    
    func getFee(targetAddress: String, amount: String, completion: @escaping  ((min: String, normal: String, max: String)?)->Void) {
        
        if let cachedFee = self.cachedFee {
            completion(cachedFee)
            return
        }
        
        let web = web3(provider: InfuraProvider(Networks.Mainnet)!)
        
        DispatchQueue.global().async {
            guard let gasPrice = try? web.eth.getGasPrice() else {
                completion(nil)
                return
            }
            let m = BigUInt(21000)
            let decimalCount = Int(Blockchain.ethereum.decimalCount)
            let minValue = gasPrice * m
            let min = Web3.Utils.formatToEthereumUnits(minValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
            
            let normalValue = gasPrice * BigUInt(12) / BigUInt(10) * m
            let normal = Web3.Utils.formatToEthereumUnits(normalValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
            
            let maxValue = gasPrice * BigUInt(15) / BigUInt(10) * m
            let max = Web3.Utils.formatToEthereumUnits(maxValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
            
            let fee = (min.trimZeroes(), normal.trimZeroes(), max.trimZeroes())
            completion(fee)
        }
        
    }
    
    func sendToBlockchain(signFromCard: [UInt8], completion: @escaping (Bool) -> Void) {
        
        guard let tx = getHashForSend(signFromCard: signFromCard) else {
            completion(false)
            return
        }
        let txHexString = "0x\(tx.toHexString())"
        
        let sendOperation = EthereumNetworkSendOperation(tx: txHexString) { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.txCount += 1
                //print(value)
                completion(true)
            case .failure(let error):
              //  print(error)
                completion(false)
            }
        }
        
        self.operationQueue.addOperation(sendOperation)
    }
    
    
    public func getHashForSend(signFromCard: [UInt8]) -> Data? {
        guard let hashForSign = self.hashForSign else {
            return nil
        }
        
        let publicKey = card.walletPublicKeyBytesArray
        
        guard let normalizedSignature = getNormalizedVerifyedSignature(for: signFromCard, publicKey: publicKey, hashToSign: hashForSign.bytes),
            let recoveredSignature = recoverSignature(for: normalizedSignature, hashToSign: hashForSign, publicKey: publicKey),
            let unmarshalledSignature = SECP256K1.unmarshalSignature(signatureData: recoveredSignature) else {
                return nil
        }
        
        transaction?.v = BigUInt(unmarshalledSignature.v)
        transaction?.r = BigUInt(unmarshalledSignature.r)
        transaction?.s = BigUInt(unmarshalledSignature.s)
        
        let encodedBytesToSend = transaction?.encodeForSend(chainID: ETHEngine.chainId)
        return encodedBytesToSend
    }
    
    private func recoverSignature(for normalizedSign: Data, hashToSign: Data, publicKey: [UInt8]) -> Data? {
        for v in 27..<31 {
            let testV = UInt8(v)
            let testSign = normalizedSign + Data(bytes: [testV])
            if let recoveredKey = SECP256K1.recoverPublicKey(hash: hashToSign, signature: testSign, compressed: false),
                recoveredKey.bytes == publicKey {
                return testSign
            }
        }
        return nil
    }
    
    private func getNormalizedVerifyedSignature(for sign: [UInt8], publicKey: [UInt8], hashToSign: [UInt8]) -> Data? {
        var vrfy: secp256k1_context = secp256k1_context_create(.SECP256K1_CONTEXT_VERIFY)!
        defer {secp256k1_context_destroy(&vrfy)}
        var sig = secp256k1_ecdsa_signature()
        var normalizied = secp256k1_ecdsa_signature()
        _ = secp256k1_ecdsa_signature_parse_compact(vrfy, &sig, sign)
        _ = secp256k1_ecdsa_signature_normalize(vrfy, &normalizied, sig)
        
        var pubkey = secp256k1_pubkey()
        _ = secp256k1_ec_pubkey_parse(vrfy, &pubkey, publicKey, 65)
        if !secp256k1_ecdsa_verify(vrfy, normalizied, hashToSign, pubkey) {
            return nil
        }        
        return Data(normalizied.data)
    }
    
    public var hasPendingTransactions: Bool {
        return txCount != pendingTxCount
    }
    
    func validate(address: String) -> Bool {
        guard !address.isEmpty,
            address.lowercased().starts(with: "0x"),
            address.count == 42
            else {
                return false
        }
        
        return true;
    }
}
