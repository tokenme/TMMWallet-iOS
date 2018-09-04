//
//  APIDevice.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/3.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

enum APIPlatform: String {
    case iOS = "ios"
    case Android = "android"
}

public class APIDevice: APIResponse {
    var id: String?
    var name: String = ""
    var model: String = ""
    var platform: APIPlatform = APIPlatform.iOS
    var isTablet: Bool = false
    var totalTs: Int = 0
    var totalApps: UInt = 0
    var points: NSDecimalNumber = 0
    var balance: NSDecimalNumber = 0
    var growthFactor: NSDecimalNumber = 0
    var lastPingAt: Date?
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
        model <- map["model"]
        platform <- map["platform"]
        isTablet <- map["is_tablet"]
        totalTs <- map["total_ts"]
        totalApps <- map["total_apps"]
        points <- (map["points"], decimalTransform)
        balance <- (map["balance"], decimalTransform)
        growthFactor <- (map["gf"], decimalTransform)
        lastPingAt <- (map["lastping_at"], dateTimeTransform)
        insertedAt <- (map["inserted_at"], dateTimeTransform)
        updatedAt <- (map["updated_at"], dateTimeTransform)
    }
}
