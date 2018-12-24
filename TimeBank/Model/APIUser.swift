//
//  APIUser.swift
//  ucoin
//
//  Created by Syd on 2018/6/7.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIUser: APIResponse {
    var id: UInt64?
    var countryCode: UInt?
    var mobile: String?
    var showName: String?
    var avatar: String?
    var wallet: String?
    var canPay: UInt8?
    var nick: String?
    var paymentPasswd: String?
    var inviteCode: String?
    var inviterCode: String?
    var exchangeEnabled: Bool = false
    var level: APICreditLevel?
    var wxBinded: Bool = false
    var openId: String?
    var directFriend: Bool = false
    var contribute: NSDecimalNumber = 0
    
    // MARK: JSON
    required public init?(map: Map) {
        super.init(map: map)
    }
    
    convenience init?(user: DefaultsUser) {
        self.init(map: Map.init(mappingType: MappingType.fromJSON, JSON: [:]))
        self.id = user.id
        self.countryCode = user.countryCode
        self.mobile = user.mobile
        self.showName = user.showName
        self.avatar = user.avatar
        self.wallet = user.wallet
        self.canPay = user.canPay
        self.inviteCode = user.inviteCode
        self.inviterCode = user.inviterCode
        self.exchangeEnabled = user.exchangeEnabled
        if let level = APICreditLevel() {
            level.id = user.level
            level.name = user.levelName
            level.enname = user.levelEnname
            self.level = level
        }
        self.wxBinded = user.wxBinded
        self.openId = user.openId
    }
    
    convenience init?() {
        self.init(map: Map.init(mappingType: MappingType.fromJSON, JSON: [:]))
    }
    
    // Mappable
    override public func mapping(map: Map) {
        super.mapping(map: map)
        id <- map["id"]
        countryCode <- map["country_code"]
        mobile <- map["mobile"]
        showName <- map["showname"]
        avatar <- map["avatar"]
        wallet <- map["wallet"]
        canPay <- map["can_pay"]
        inviteCode <- map["invite_code"]
        inviterCode <- map["inviter_code"]
        exchangeEnabled <- map["exchange_enabled"]
        level <- map["level"]
        wxBinded <- map["wx_binded"]
        openId <- map["open_id"]
        directFriend <- map["direct_friend"]
        contribute <- (map["contribute"], decimalTransform)
    }
}

public class APIUserBalance: APIResponse {
    var points: NSDecimalNumber = 0
    var tmm: NSDecimalNumber = 0
    var cash: NSDecimalNumber = 0
    
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
        points <- (map["points"], decimalTransform)
        tmm <- (map["tmm"], decimalTransform)
        cash <- (map["cash"], decimalTransform)
    }
}
