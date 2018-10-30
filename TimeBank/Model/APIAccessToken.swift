//
//  APIAccessToken.swift
//  ucoin
//
//  Created by Syd on 2018/6/5.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIAccessToken: APIResponse {
    var token: String?
    var expire: Date?
    
    // MARK: JSON
    required public init?(map: Map) {
        super.init(map: map)
    }
    
    // Mappable
    override public func mapping(map: Map) {
        super.mapping(map: map)
        token <- map["token"]
        expire <- (map["expire"], dateTimeTransform)
    }
}

public class APIAuthKey: Codable {
    var passwd: String = ""
    var ts: Int64 = 0
    
    enum CodingKeys: String, CodingKey {
        case passwd = "passwd"
        case ts = "ts"
    }
    
    required init(passwd: String, ts: Int64) {
        self.passwd = passwd
        self.ts = ts
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.passwd = try container.decode(String.self, forKey: .passwd)
        self.ts = try container.decode(Int64.self, forKey: .ts)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(passwd, forKey: .passwd)
        try container.encode(ts, forKey: .ts)
    }
}
