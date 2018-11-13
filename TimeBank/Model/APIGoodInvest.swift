//
//  APIGoodInvest.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/8.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

enum APIGoodInvestRedeemStatus: UInt8 {
    case unknown = 0
    case redeemed = 1
    case withdraw = 2
}

public class APIGoodInvest: APIResponse {
    var userId: UInt64?
    var goodId: UInt64?
    var avatar: String?
    var userName: String?
    var points: NSDecimalNumber = 0
    var income: NSDecimalNumber = 0
    var goodName: String?
    var goodPic: String?
    var redeemStatus: APIGoodInvestRedeemStatus = .unknown
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
        goodName <- map["good_name"]
        goodPic <- map["good_pic"]
        avatar <- map["avatar"]
        userName <- map["user_name"]
        redeemStatus <- map["redeem_status"]
        points <- (map["points"], decimalTransform)
        income <- (map["income"], decimalTransform)
        investedAt <- (map["inserted_at"], dateTimeTransform)
    }
    
    public func toGood() -> APIGood? {
        let good = APIGood()
        good?.id = self.goodId ?? 0
        good?.name = self.goodName ?? ""
        good?.pic = self.goodPic ?? ""
        return good
    }
}

public class APIGoodInvestSummary: APIResponse {
    var invest: NSDecimalNumber = 0
    var income: NSDecimalNumber = 0
    var bonus: NSDecimalNumber = 0
    
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
        invest <- (map["invest"], decimalTransform)
        income <- (map["income"], decimalTransform)
        bonus <- (map["bonus"], decimalTransform)
    }
}
