//
//  APIDailyBonusStatus.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/16.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIDailyBonusStatus: APIResponse {
    var days: Int = 0
    var points: NSDecimalNumber = 0
    
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
        days <- map["days"]
        points <- (map["points"], decimalTransform)
    }
}