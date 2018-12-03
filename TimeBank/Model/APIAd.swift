//
//  APIAd.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/12/3.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIAdgroup: APIResponse {
    var id: UInt64 = 0
    var onlineStatus: Bool = false
    var creatives: [APICreative] = []
    
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
        onlineStatus <- map["online_status"]
        creatives <- map["creatives"]
    }
}

public class APICreative: APIResponse {
    var id: UInt64 = 0
    var adgroupId: UInt64 = 0
    var onlineStatus: Bool = false
    var image: String = ""
    var link: String = ""
    var width: UInt = 0
    var height: UInt = 0
    
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
        adgroupId <- map["adgroup_id"]
        onlineStatus <- map["online_status"]
        image <- map["image"]
        link <- map["link"]
        width <- map["width"]
        height <- map["height"]
    }
}
