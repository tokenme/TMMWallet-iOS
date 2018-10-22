//
//  APIBlowupEscape.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/19.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIBlowupBid: APIResponse {
    var type: APIBlowupEventType = .escape
    var sessionId: UInt64 = 0
    var value: NSDecimalNumber = 0
    var rate: NSDecimalNumber = 1
    var nick: String = ""
    
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
        type <- map["type"]
        sessionId <- map["session_id"]
        value <- (map["value"], decimalTransform)
        rate <- (map["rate"], decimalTransform)
        nick <- map["nick"]
    }
}
