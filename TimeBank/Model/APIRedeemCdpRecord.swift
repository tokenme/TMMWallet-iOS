//
//  APIRedeemCdpRecord.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/4.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIRedeemCdpRecord: APIResponse {
    var deviceId: String = ""
    var points: NSDecimalNumber = 0
    var grade: String = ""
    var insertedAt: Date?
    
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
        deviceId <- map["device_id"]
        points <- (map["points"], decimalTransform)
        grade <- map["grade"]
        insertedAt <- (map["inserted_at"], dateTimeTransform)
    }
}
