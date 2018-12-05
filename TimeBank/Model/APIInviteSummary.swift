//
//  APIInviteSummary.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/20.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIInviteSummary: APIResponse {
    var invites: UInt = 0
    var points: NSDecimalNumber = 0
    var friendsContribute: NSDecimalNumber = 0
    var nextLevelInvites: UInt = 0
    var users: [APIUser] = []
    
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
        invites <- map["invites"]
        nextLevelInvites <- map["next_level_invites"]
        points <- (map["points"], decimalTransform)
        friendsContribute <- (map["friends_contribute"], decimalTransform)
        users <- map["users"]
    }
}
