//
//  APIGoodInvest.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/8.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIGoodInvest: APIResponse {
    var userId: UInt64?
    var goodId: UInt64?
    var avatar: String?
    var userName: String?
    var points: NSDecimalNumber = 0
    var income: NSDecimalNumber = 0
    var investedAt: Date?
    
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
        userId <- map["user_id"]
        goodId <- map["good_id"]
        avatar <- map["avatar"]
        userName <- map["user_name"]
        points <- (map["points"], decimalTransform)
        income <- (map["income"], decimalTransform)
        investedAt <- (map["invested_at"], dateTimeTransform)
    }
}
