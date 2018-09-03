//
//  APIResponse.swift
//  ucoin
//
//  Created by Syd on 2018/6/5.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIResponse: Mappable {
    var code: Int?
    var message: String?
    
    // MARK: JSON
    required public init?(map: Map) { }
    
    // Mappable
    public func mapping(map: Map) {
        code    <- map["code"]
        message <- map["message"]
    }
}

let dateTimeTransform = TransformOf<Date, String>(fromJSON: { (value: String?) -> Date? in
    if let value = value {
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.date(from: value)
    }
    return nil
}, toJSON: { (value: Date?) -> String? in
    if let value = value {
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.string(from: value)
    }
    return nil
})

let decimalTransform = TransformOf<NSDecimalNumber, String>(fromJSON: { (value: String?) -> NSDecimalNumber? in
    if let value = value {
        return NSDecimalNumber.init(string: value)
    }
    return nil
}, toJSON: { (value: NSDecimalNumber?) -> String? in
    if let value = value {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 9
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        return formatter.string(from: value)
    }
    return nil
})
