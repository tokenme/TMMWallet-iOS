//
//  APITMMWithdrawRecord.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/23.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APITMMWithdrawRecord: APIResponse {
    var tx: String = ""
    var txStatus: APIExchangeTxStatus = .pending
    var withdrawStatus: APIExchangeTxStatus = .pending
    var tmm: NSDecimalNumber = 0
    var cash: NSDecimalNumber = 0
    var insertedAt: Date?
    
    // MARK: JSON
    required public init?(map: Map) {
        super.init(map: map)
    }
    
    convenience init?() {
        self.init(map: Map.init(mappingType: MappingType.fromJSON, JSON: [:]))
    }
    
    // Mappable
    override public func mapping(map: Map) {
        super.mapping(map: map)
        tx <- map["tx"]
        tmm <- (map["tmm"], decimalTransform)
        cash <- (map["cash"], decimalTransform)
        txStatus <- map["tx_status"]
        withdrawStatus <- map["withdraw_status"]
        insertedAt <- (map["inserted_at"], dateTimeTransform)
    }
}
