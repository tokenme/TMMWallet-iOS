//
//  APIMinETH.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/15.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIMinETH: APIResponse {
    var minETH: NSDecimalNumber = 0
    
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
        minETH <- (map["min_eth"], decimalTransform)
    }
}
