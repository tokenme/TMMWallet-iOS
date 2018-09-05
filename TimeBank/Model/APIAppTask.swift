//
//  APIAppTask.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/5.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIAppTask: APIResponse {
    var id: UInt64?
    var name: String = ""
    var platform: APIPlatform = APIPlatform.iOS
    var bundleId: String = ""
    var storeId: UInt64?
    var icon: String?
    var points: NSDecimalNumber = 0
    var pointsLeft: NSDecimalNumber = 0
    var bonus: NSDecimalNumber = 0
    var downloads: UInt = 0
    var status: Int8 = 0
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
        name <- map["name"]
        platform <- map["platform"]
        bundleId <- map["bundle_id"]
        storeId <- map["store_id"]
        icon <- map["icon"]
        points <- (map["points"], decimalTransform)
        pointsLeft <- (map["points_left"], decimalTransform)
        bonus <- (map["bonus"], decimalTransform)
        downloads <- map["downloads"]
        status <- map["status"]
        insertedAt <- (map["inserted_at"], dateTimeTransform)
        updatedAt <- (map["updated_at"], dateTimeTransform)
    }
}
