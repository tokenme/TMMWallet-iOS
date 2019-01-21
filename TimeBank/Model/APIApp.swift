//
//  APIApp.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/3.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIApp: APIResponse {
    var id: String?
    var submitBuild: String?
    var name: String = ""
    var version: String = ""
    var platform: APIPlatform = APIPlatform.iOS
    var schemeId: UInt64 = 0
    var bundleId: String = ""
    var storeId: UInt64?
    var icon: String?
    var ts: Int = 0
    var growthFactor: NSDecimalNumber = 0
    var buildVersion: String?
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
        submitBuild <- map["submit_build"]
        name <- map["name"]
        version <- map["version"]
        platform <- map["platform"]
        schemeId <- map["scheme_id"]
        bundleId <- map["bundle_id"]
        storeId <- map["store_id"]
        icon <- map["icon"]
        ts <- map["ts"]
        growthFactor <- (map["gf"], decimalTransform)
        buildVersion <- map["build_version"]
        lastPingAt <- (map["lastping_at"], dateTimeTransform)
        insertedAt <- (map["inserted_at"], dateTimeTransform)
        updatedAt <- (map["updated_at"], dateTimeTransform)
    }
}
