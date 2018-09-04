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
