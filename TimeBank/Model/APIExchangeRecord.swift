//
//  APIExchangeRecord.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/17.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

enum APIExchangeTxStatus: UInt8 {
    case pending = 2
    case success = 1
    case failed = 0
}

public class APIExchangeRecord: APIResponse {
    var tx: String?
    var status: APIExchangeTxStatus = .pending
    var tmm: NSDecimalNumber = 0
    var points: NSDecimalNumber = 0
    var direction: APIExchangeDirection = .TMMIn
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
        status <- map["status"]
        tmm <- (map["tmm"], decimalTransform)
        points <- (map["points"], decimalTransform)
        direction <- map["direction"]
        insertedAt <- (map["inserted_at"], dateTimeTransform)
    }
}
