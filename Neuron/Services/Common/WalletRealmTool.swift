//
//  WalletRealmTool.swift
//  Neuron
//
//  Created by XiaoLu on 2018/6/19.
//  Copyright © 2018年 cryptape. All rights reserved.
//

import UIKit
import RealmSwift

struct WalletRealmTool {
    static let realm = RealmHelper.sharedInstance
    /// according to wallet address to get WalletModel
    ///
    /// - Parameter walletName: walletName
    /// - Returns: WalletModel
    static func getCreatWallet(walletAddress: String) -> WalletModel {
        var walletModel = WalletModel()
        walletModel = realm.object(ofType: WalletModel.self, forPrimaryKey: walletAddress)!
        return walletModel
    }

    /// get everything for AppModel
    ///
    /// - Returns: appmodel
    static func getCurrentAppModel() -> AppModel {
        let result = realm.objects(AppModel.self)
        return result.first ?? AppModel()
    }

    /// update currentWallet
    ///
    /// - Parameter walletName: wallet name
    static func updateAppCurrentWallet(walletAddress: String) {
        let result = realm.objects(AppModel.self)
        let appModel: AppModel = result[0]
        try! realm.write {
            appModel.currentWallet = getCreatWallet(walletAddress: walletAddress)
        }
    }

    /// Check if there is a wallet in the current app
    ///
    /// - Returns: true or false
    static func hasWallet() -> Bool {
        let result = realm.objects(AppModel.self)
        guard let appModel = result.first else {
            return false
        }

        return appModel.wallets.count > 0
    }

    /// addAppModel
    ///
    /// - Parameter appModel: appmodel instance
    static func addObject(appModel: AppModel) {
        realm.add(appModel)
    }
}