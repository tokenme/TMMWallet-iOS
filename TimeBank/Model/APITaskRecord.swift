//
//  APITaskRecord.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/6.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

enum APITaskType: UInt {
    case app = 1
    case share = 2
}

public class APITaskRecord: APIResponse {
    var type: APITaskType?
    var title: String = ""
    var image: String?
    var points: NSDecimalNumber = 0
    var viewers: UInt = 0
    var updatedAt: Date?
    
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
        title <- map["title"]
        image <- map["image"]
        points <- (map["points"], decimalTransform)
        viewers <- map["viewers"]
        updatedAt <- (map["updated_at"], dateTimeTransform)
    }
}
