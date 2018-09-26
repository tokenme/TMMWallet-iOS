//
//  QRCodeResult.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/26.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation

struct QRCodeResult {
    let wallet: String
    var contractAddress: String?
    var decimals: Int8?
    
    init(_ wallet: String) {
        self.wallet = wallet
    }
    
    mutating func setContractAddress(_ addr: String) {
        contractAddress = addr
    }
    
    mutating func setDecimals(_ decimals: Int8) {
        self.decimals = decimals
    }
}
