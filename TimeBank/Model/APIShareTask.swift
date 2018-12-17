//
//  APIShareTask.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/4.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation
import ObjectMapper

enum APIArticleCategory: UInt {
    case suggest = 0
    case sociaty = 1
    case finance = 2
    case funny = 3
    case entertainment = 4
    case technology = 5
    case fashion = 6
    case blockchain = 7
    case military = 8
    case sport = 9
    case history = 10
    case culture = 11
    case life = 12
    
    var description: String {
        switch self {
        case .suggest: return NSLocalizedString("SuggestCategory", comment: "SuggestCategory")
        case .sociaty: return NSLocalizedString("SociatyCategory", comment: "SociatyCategory")
        case .finance: return NSLocalizedString("FinanceCategory", comment: "FinanceCategory")
        case .funny: return NSLocalizedString("FunnyCategory", comment: "FunnyCategory")
        case .entertainment: return NSLocalizedString("EntertainmentCategory", comment: "EntertainmentCategory")
        case .technology: return NSLocalizedString("TechnologyCategory", comment: "TechnologyCategory")
        case .fashion: return NSLocalizedString("FashionCategory", comment: "FashionCategory")
        case .blockchain: return NSLocalizedString("BlockchainCategory", comment: "BlockchainCategory")
        case .military: return NSLocalizedString("MilitaryCategory", comment: "MilitaryCategory")
        case .sport: return NSLocalizedString("SportCategory", comment: "SportCategory")
        case .history: return NSLocalizedString("HistoryCategory", comment: "HistoryCategory")
        case .culture: return NSLocalizedString("CultureCategory", comment: "CultureCategory")
        case .life: return NSLocalizedString("LifeCategory", comment: "LifeCategory")
        }
    }
}

enum APITaskOnlineStatus: Int8 {
    case canceled = -2
    case stopped = -1
    case running = 1
    case unknown = 0
}

public class APIShareTask: APIResponse {
    var id: UInt64?
    var creator: UInt64?
    var title: String = ""
    var summary: String = ""
    var link: String = ""
    var shareLink: String = ""
    var videoLink: String = ""
    var isVideo: UInt8 = 0
    var isTask: Bool = false
    var image: String?
    var points: NSDecimalNumber = 0
    var pointsLeft: NSDecimalNumber = 0
    var bonus: NSDecimalNumber = 0
    var maxViewers: UInt = 0
    var viewers: UInt = 0
    var onlineStatus: APITaskOnlineStatus = .running
    var creative: APICreative?
    var insertedAt: Date?
    var updatedAt: Date?
    var showBonusHint: Bool = false
    
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
        creator <- map["creator"]
        title <- map["title"]
        summary <- map["summary"]
        link <- map["link"]
        shareLink <- map["share_link"]
        videoLink <- map["video_link"]
        isVideo <- map["is_video"]
        isTask <- map["is_task"]
        image <- map["image"]
        points <- (map["points"], decimalTransform)
        pointsLeft <- (map["points_left"], decimalTransform)
        bonus <- (map["bonus"], decimalTransform)
        maxViewers <- map["max_viewers"]
        viewers <- map["viewers"]
        onlineStatus <- map["online_status"]
        creative <- map["creative"]
        insertedAt <- (map["inserted_at"], dateTimeTransform)
        updatedAt <- (map["updated_at"], dateTimeTransform)
        showBonusHint <- map["show_bonus_hint"]
    }
}
