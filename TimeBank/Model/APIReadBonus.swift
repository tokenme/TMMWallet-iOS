//
//  APIReadBonus.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/30.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIReadBonus: APIResponse {
    var taskId: UInt64?
    var points: NSDecimalNumber = 0
    var duration: Int64 = 0
    var ts: Int64 = 0
    
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
        taskId <- map["task_id"]
        points <- (map["points"], decimalTransform)
        duration <- map["duration"]
        ts <- map["ts"]
    }
}
