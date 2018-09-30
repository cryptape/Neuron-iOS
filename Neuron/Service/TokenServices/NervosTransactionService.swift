//
//  NervosTransactionService.swift
//  Neuron
//
//  Created by XiaoLu on 2018/8/22.
//  Copyright © 2018年 Cryptape. All rights reserved.
//

import Foundation
import Nervos
import BigInt
//import web3swift

protocol NervosTransactionServiceProtocol {
    func prepareNervosTransactionForSending(address: String,
                                            quota: BigUInt,
                                            data: Data,
                                            value: String,
                                            chainId: BigUInt, completion: @escaping (SendNervosResult<NervosTransaction>) -> Void)

    func send(password: String, transaction: NervosTransaction, completion: @escaping (SendNervosResult<TransactionSendingResult>) -> Void)
}

class NervosTransactionServiceImp: NervosTransactionServiceProtocol {

    func prepareNervosTransactionForSending(address: String,
                                            quota: BigUInt = BigUInt(1000000),
                                            data: Data,
                                            value: String,
                                            chainId: BigUInt, completion: @escaping (SendNervosResult<NervosTransaction>) -> Void) {
        DispatchQueue.global().async {
            guard let destinationEthAddress = Address(address) else {
                DispatchQueue.main.async {
                    completion(SendNervosResult.Error(SendNervosErrors.invalidDestinationAddress))
                }
                return
            }
            guard let amount = Utils.parseToBigUInt(value, units: .eth) else {
                DispatchQueue.main.async {
                    completion(SendNervosResult.Error(SendNervosErrors.invalidAmountFormat))
                }
                return
            }
            let nonce = UUID().uuidString
            let nervos = NervosNetwork.getNervos()
            let result = nervos.appChain.blockNumber()
            DispatchQueue.main.async {
                switch result {
                case .success(let blockNumber):
                    let transaction = NervosTransaction(
                        to: destinationEthAddress,
                        nonce: nonce,
                        quota: UInt64(quota),
                        validUntilBlock: blockNumber + UInt64(88),
                        data: data,
                        value: amount,
                        chainId: UInt32(chainId),
                        version: UInt32(0)
                    )
                    completion(SendNervosResult.Success(transaction))
                case .failure(let error):
                    completion(SendNervosResult.Error(error))
                }
            }
        }
    }

    func send(password: String, transaction: NervosTransaction, completion: @escaping (SendNervosResult<TransactionSendingResult>) -> Void) {
        let nervos = NervosNetwork.getNervos()
        let walletModel = WalletRealmTool.getCurrentAppModel().currentWallet!
        var privateKey = CryptoTool.Decode_AES_ECB(strToDecode: walletModel.encryptPrivateKey, key: password)
        if privateKey.hasPrefix("0x") {
            privateKey = String(privateKey.dropFirst(2))
        }
        guard let signed = try? NervosTransactionSigner.sign(transaction: transaction, with: privateKey) else {
            completion(SendNervosResult.Error(NervosSignErrors.signTXFailed))
            return
        }
        DispatchQueue.global().async {
            let result = nervos.appChain.sendRawTransaction(signedTx: signed)
            DispatchQueue.main.async {
                switch result {
                case .success(let transaction):
                    completion(SendNervosResult.Success(transaction))
                case .failure(let error):
                    completion(SendNervosResult.Error(error))
                }
            }
        }
    }
}
