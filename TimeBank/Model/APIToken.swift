//
//  APIToken.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/10.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIToken: APIResponse {
    var address: String?
    var name: String?
    var symbol: String?
    var balance: NSDecimalNumber = 0
    var decimals: Int8 = 0
    var icon: String?
    var price: NSDecimalNumber = 0
    var minGas: NSDecimalNumber = 0
    
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
        address <- map["address"]
        name <- map["name"]
        symbol <- map["symbol"]
        balance <- (map["balance"], decimalTransform)
        decimals <- map["decimals"]
        icon <- map["icon"]
        price <- (map["price"], decimalTransform)
        minGas <- (map["min_gas"], decimalTransform)
    }
}
