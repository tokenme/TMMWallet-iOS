//
//  APIRedeemCdp.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/4.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIRedeemCdp: APIResponse {
    var offerId: UInt64?
    var grade: String?
    var price: NSDecimalNumber = 0
    var points: NSDecimalNumber = 0
    
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
        offerId <- map["offer_id"]
        grade <- map["grade"]
        price <- (map["price"], decimalTransform)
        points <- (map["points"], decimalTransform)
    }
}
