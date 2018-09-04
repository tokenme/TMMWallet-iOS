//
//  DefaultKeys.swift
//  ucoin
//
//  Created by Syd on 2018/6/5.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import SwiftyUserDefaults

extension DefaultsKeys {
    static let accessToken = DefaultsKey<DefaultsAccessToken?>("accessToken")
    static let user = DefaultsKey<DefaultsUser?>("user")
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
    
    enum CodingKeys: String, CodingKey {
        case id
        case countryCode
        case mobile
        case showName
        case avatar
        case wallet
        case canPay
    }
    
    required init(id: UInt64, countryCode: UInt, mobile: String, showName: String, avatar: String, wallet: String, canPay: UInt8) {
        self.id = id
        self.countryCode = countryCode
        self.mobile = mobile
        self.showName = showName
        self.avatar = avatar
        self.wallet = wallet
        self.canPay = canPay
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
    }
    
}
