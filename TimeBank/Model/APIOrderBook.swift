//
//  APIOrderBook.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/22.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

enum APIOrderBookSide: UInt8 {
    case ask = 1
    case bid = 2
}

enum APIOrderBookProcessType: UInt8 {
    case market = 0
    case limit = 1
}

enum APIOrderBookOnlineStatus: Int8 {
    case canceled = -1
    case pending = 0
    case completed = 1
}

public class APIOrderBook: APIResponse {
    var id: UInt64?
    var side: APIOrderBookProcessType!
    var quantity: NSDecimalNumber = 0
    var price: NSDecimalNumber = 0
    var dealQuantity: NSDecimalNumber = 0
    var dealETH: NSDecimalNumber = 0
    var onlineStatus: APIOrderBookOnlineStatus = .pending
    var insertedAt: Date?
    var updatedAt: Date?
    
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
        id <- map["trade_id"]
        side <- map["side"]
        quantity <- (map["quantity"], decimalTransform)
        price <- (map["price"], decimalTransform)
        dealQuantity <- (map["deal_quantity"], decimalTransform)
        dealETH <- (map["deal_eth"], decimalTransform)
        onlineStatus <- map["online_status"]
        insertedAt <- (map["inserted_at"], dateTimeTransform)
        updatedAt <- (map["updated_at"], dateTimeTransform)
    }
}

public class APIOrderBookRate: APIResponse {
    var changeRate: NSDecimalNumber = 0
    var price: NSDecimalNumber = 0
    
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
        changeRate <- (map["change_rate"], decimalTransform)
        price <- (map["price"], decimalTransform)
    }
}
