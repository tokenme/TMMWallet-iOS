//
//  APIMarketGraph.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/1.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIMarketGraph: APIResponse {
    var id: UInt64?
    var trades: UInt64 = 0
    var quantity: NSDecimalNumber = 0
    var price: NSDecimalNumber = 0
    var low: NSDecimalNumber = 0
    var high: NSDecimalNumber = 0
    var at: Date?
    
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
        trades <- map["trades"]
        quantity <- (map["quantity"], decimalTransform)
        price <- (map["price"], decimalTransform)
        low <- (map["low"], decimalTransform)
        high <- (map["high"], decimalTransform)
        at <- (map["at"], dateTimeTransform)
    }
}
