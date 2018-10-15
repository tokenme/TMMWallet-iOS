//
//  APITransaction.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/10.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APITransaction: APIResponse {
    var receipt: String?
    var value: NSDecimalNumber = 0
    var status: Int8 = 0
    var from: String = ""
    var to: String = ""
    var gas: NSDecimalNumber = 0
    var gasPrice: NSDecimalNumber = 0
    var gasUsed: NSDecimalNumber = 0
    var cumulativeGasUsed: NSDecimalNumber = 0
    var confirmations: Int = 0
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
        receipt <- map["receipt"]
        value <- (map["value"], decimalTransform)
        status <- map["status"]
        from <- map["from"]
        to <- map["to"]
        gas <- (map["gas"], decimalTransform)
        gasPrice <- (map["gas_price"], decimalTransform)
        gasUsed <- (map["gas_used"], decimalTransform)
        cumulativeGasUsed <- (map["cumulative_gas_used"], decimalTransform)
        confirmations <- map["confirmations"]
        insertedAt <- (map["inserted_at"], dateTimeTransform)
    }
}
