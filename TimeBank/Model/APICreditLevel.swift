//
//  APICreditLevel.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/26.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APICreditLevel: APIResponse {
    var id: UInt8 = 0
    var name: String = ""
    var enname: String = ""
    var desc: String = ""
    var endesc: String = ""
    var invites: UInt = 0
    
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
        enname <- map["enname"]
        desc <- map["desc"]
        endesc <- map["endesc"]
        invites <- map["invites"]
    }
    
    public func showName(_ full: Bool = false) -> String {
        if let language: String = NSLocale.current.languageCode {
            if language.hasPrefix("zh") {
                return full ? "\(name)\(I18n.member.description)" : name
            } else {
                return full ? "\(enname) \(I18n.member.description)" : enname
            }
        }
        return "normal"
    }
    
    public func showDesc() -> String {
        if let language: String = NSLocale.current.languageCode {
            if language.hasPrefix("zh") {
                return desc
            } else {
                return endesc
            }
        }
        return ""
    }
    
    public func color() -> UIColor {
        switch id {
        case 1: return UIColor.lightGray
        case 2: return UIColor.pinky
        case 3: return  UIColor.purple
        case 4: return UIColor.black
        default:
            return UIColor(white: 0.96, alpha: 1)
        }
    }
}
