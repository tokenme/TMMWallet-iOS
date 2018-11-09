//
//  APIGood.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/8.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIGood: APIResponse {
    var id: UInt64?
    var skuId: UInt64 = 0
    var wareId: UInt64 = 0
    var accountId: UInt64 = 0
    var oriPrice: NSDecimalNumber = 0
    var price: NSDecimalNumber = 0
    var commissionPrice: NSDecimalNumber = 0
    var commissionPoints: NSDecimalNumber = 0
    var purchaseWithdraw: NSDecimalNumber = 0
    var investPoints: NSDecimalNumber = 0
    var totalInvest: NSDecimalNumber = 0
    var totalInvestors: UInt = 0
    var investIncome: NSDecimalNumber = 0
    var name: String = ""
    var shareLink: String?
    var pic: String?
    
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
        id <- map["id"]
        name <- map["goods_name"]
        pic <- map["goods_pic"]
        shareLink <- map["share_link"]
        skuId <- map["sku_id"]
        wareId <- map["ware_id"]
        accountId <- map["account_id"]
        oriPrice <- (map["ori_price"], decimalTransform)
        price <- (map["price"], decimalTransform)
        commissionPrice <- (map["commision_price"], decimalTransform)
        commissionPoints <- (map["commission_points"], decimalTransform)
        purchaseWithdraw <- (map["purchase_withdraw"], decimalTransform)
        investPoints <- (map["invest_points"], decimalTransform)
        totalInvest <- (map["total_invest"], decimalTransform)
        totalInvestors <- map["total_investors"]
        investIncome <- (map["invest_income"], decimalTransform)
    }
}
