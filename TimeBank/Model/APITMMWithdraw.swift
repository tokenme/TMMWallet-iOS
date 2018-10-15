//
//  APITMMWithdraw.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/12.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APITMMWithdraw: APIResponse {
    var tmm: NSDecimalNumber = 0
    var cash: NSDecimalNumber = 0
    var currency: String = Currency.USD.rawValue
    
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
        tmm <- (map["tmm"], decimalTransform)
        cash <- (map["cash"], decimalTransform)
        currency <- map["currency"]
    }
}
