//
//  APIShareTask.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/4.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIShareTask: APIResponse {
    var id: UInt64?
    var creator: UInt64?
    var title: String = ""
    var summary: String = ""
    var link: String = ""
    var shareLink: String = ""
    var image: String?
    var points: NSDecimalNumber = 0
    var pointsLeft: NSDecimalNumber = 0
    var bonus: NSDecimalNumber = 0
    var maxViewers: UInt = 0
    var viewers: UInt = 0
    var insertedAt: Date?
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
        id <- map["id"]
        creator <- map["creator"]
        title <- map["title"]
        summary <- map["summary"]
        link <- map["link"]
        shareLink <- map["share_link"]
        image <- map["image"]
        points <- (map["points"], decimalTransform)
        pointsLeft <- (map["points_left"], decimalTransform)
        bonus <- (map["bonus"], decimalTransform)
        maxViewers <- map["max_viewers"]
        viewers <- map["viewers"]
        insertedAt <- (map["inserted_at"], dateTimeTransform)
        updatedAt <- (map["updated_at"], dateTimeTransform)
    }
}
