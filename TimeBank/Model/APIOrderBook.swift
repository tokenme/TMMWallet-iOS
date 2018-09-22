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

public class APIOrderBook: APIResponse {
    var side: APIOrderBookProcessType!
    var quantity: NSDecimalNumber = 0
    var price: NSDecimalNumber = 0
    var dealQuantity: NSDecimalNumber = 0
    var dealETH: NSDecimalNumber = 0
    
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
        side <- map["side"]
        quantity <- (map["quantity"], decimalTransform)
        price <- (map["price"], decimalTransform)
        dealQuantity <- (map["deal_quantity"], decimalTransform)
        dealETH <- (map["deal_eth"], decimalTransform)
    }
}
