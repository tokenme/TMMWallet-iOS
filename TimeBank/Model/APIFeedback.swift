//
//  APIFeedback.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/14.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIFeedback: APIResponse {
    var ts: String = ""
    var msg: String = ""
    var image: String?
    var replies: [APIFeedback]?
    var bot: Bool = false
    
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
        ts <- map["ts"]
        msg <- map["msg"]
        image <- map["image"]
        replies <- map["replies"]
        bot <- map["bot"]
    }
}
