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
    var wxBinded: Bool = false
    
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
        self.wxBinded = user.wxBinded
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
        wxBinded <- map["wx_binded"]
    }
}
