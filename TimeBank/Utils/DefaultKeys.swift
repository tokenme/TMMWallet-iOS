//
//  DefaultKeys.swift
//  ucoin
//
//  Created by Syd on 2018/6/5.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import SwiftyUserDefaults

enum Currency: String {
    case USD = "USD"
    case CNY = "CNY"
    case EUR = "EUR"
    case JPY = "JPY"
    case KRW = "KRW"
}
extension DefaultsKeys {
    static let accessToken = DefaultsKey<DefaultsAccessToken?>("accessToken")
    static let user = DefaultsKey<DefaultsUser?>("user")
    static let currency = DefaultsKey<String?>("currency")
    static let lastDailyBonus = DefaultsKey<Date?>("lastDailyBonus")
    static let lastDailyInviteSummary = DefaultsKey<Date?>("lastDailyInviteSummary")
    static let userAgent = DefaultsKey<String?>("UserAgent")
}

final class DefaultsAccessToken: Codable, DefaultsSerializable {
    var token: String!
    var expire: Date!
    
    enum CodingKeys: String, CodingKey {
        case token
        case expire
    }
    
    required init(token: String, expire: Date) {
        self.token = token
        self.expire = expire
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.token = try container.decode(String.self, forKey: .token)
        self.expire = try container.decode(Date.self, forKey: .expire)
    }
}

final class DefaultsUser: Codable, DefaultsSerializable {
    var id: UInt64!
    var countryCode: UInt!
    var mobile: String!
    var showName: String!
    var avatar: String!
    var wallet: String!
    var canPay: UInt8!
    var inviteCode: String = ""
    var inviterCode: String = ""
    var passwd: String = ""
    var exchangeEnabled: Bool = false
    var level: UInt8 = 0
    var levelName: String = "普通"
    var levelEnname: String = "normal"
    var openId: String = ""
    var wxBinded: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case countryCode
        case mobile
        case showName
        case avatar
        case wallet
        case canPay
        case inviteCode
        case inviterCode
        case exchangeEnabled
        case level
        case levelName
        case levelEnname
        case openId
        case wxBinded
    }
    
    required init(id: UInt64, countryCode: UInt, mobile: String, showName: String, avatar: String, wallet: String, canPay: UInt8, inviteCode: String, inviterCode: String, exchangeEnabled: Bool, level: UInt8, levelName: String, levelEnname: String, openId: String, wxBinded: Bool) {
        self.id = id
        self.countryCode = countryCode
        self.mobile = mobile
        self.showName = showName
        self.avatar = avatar
        self.wallet = wallet
        self.canPay = canPay
        self.inviteCode = inviteCode
        self.inviterCode = inviterCode
        self.exchangeEnabled = exchangeEnabled
        self.level = level
        self.levelName = levelName
        self.levelEnname = levelEnname
        self.openId = openId
        self.wxBinded = wxBinded
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UInt64.self, forKey: .id)
        self.countryCode = try container.decode(UInt.self, forKey: .countryCode)
        self.mobile = try container.decode(String.self, forKey: .mobile)
        self.showName = try container.decode(String.self, forKey: .showName)
        self.avatar = try container.decode(String.self, forKey: .avatar)
        self.wallet = try container.decode(String.self, forKey: .wallet)
        self.canPay = try container.decode(UInt8.self, forKey: .canPay)
        self.inviteCode = try container.decode(String.self, forKey: .inviteCode)
        self.inviterCode = try container.decode(String.self, forKey: .inviterCode)
        self.exchangeEnabled = try container.decode(Bool.self, forKey: .exchangeEnabled)
        self.level = try container.decode(UInt8.self, forKey: .level)
        self.levelName = try container.decode(String.self, forKey: .levelName)
        self.levelEnname = try container.decode(String.self, forKey: .levelEnname)
        self.avatar = try container.decode(String.self, forKey: .avatar)
        self.openId = try container.decode(String.self, forKey: .openId)
        self.wxBinded = try container.decode(Bool.self, forKey: .wxBinded)
    }
    
}
