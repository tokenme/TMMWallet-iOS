//
//  APIExchangeRate.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/6.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public enum APIExchangeDirection: Int8 {
    case TMMIn = 1
    case TMMOut = -1
}

public class APIExchangeRate: APIResponse {
    var rate: NSDecimalNumber = 0
    var minPoints: NSDecimalNumber = 0
    
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
        minPoints <- (map["min_points"], decimalTransform)
        rate <- (map["rate"], decimalTransform)
    }
}
