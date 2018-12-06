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
    var taskBonusRate: NSDecimalNumber = 100
    
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
        taskBonusRate <- map["task_bonus_rate"]
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
        case 1: return UIColor(rgb: 0xbfbfbf)
        case 2: return UIColor(rgb: 0xeec123)
        case 3: return  UIColor(rgb: 0xd49359)
        case 4: return UIColor(rgb: 0xff6757)
        default:
            return UIColor(rgb: 0x8d97b5)
        }
    }
}
