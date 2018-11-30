//
//  TMMConfigs.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/8.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation
struct TMMConfigs {
    
    static let helpLink = "https://tmm.tokenmama.io/help/"
    static let downloadLink = "https://ucoin.io/app/download"
    
    struct TMMBeacon {
        static let key = "e515a8899e7a43944a68502969154e4cb87a03a3"
        static let secret = "47535bf74a8072c0b6246b4fb73508eeb12f5982"
    }
    
    struct Blowup {
        static let notifyServer = "https://tmm.tokenmama.io/blowup/notify"
    }
    
    struct ReCaptcha {
        static let siteKey = "6LdyLnQUAAAAAL9runxAoDhsDm3pEGe0KFVYeFQ7"
        static let domain = "https://tmm.tokenmama.io"
    }
    
    struct Slack {
        static let key = "xoxp-340014960567-338241194720-339563622341-94fcb61ce9353b2b0f5a86d4e99580d8"
        static let feedbackChannel = "#timebank-feedback"
    }
    
    struct Weibo {
        static let appID = "4113365511"
        static let appKey = "6e9c1c7dbb16c9725ff326db1eda289a"
        static let redirectURL = "https://tmm.tokenmama.io/callback/weibo"
        static let schemes = ["weibo"]
    }
    
    struct WeChat {
        static let appID = "wx0a039e7ca8ba313d"
        static let appKey = "93ec8a485c885fa3d69510ef9fb1c8a9"
        static let schemes = ["weixin", "wechat"]
        static let authLink = "https://ucoin.io/wechat/mapping"
    }
    
    struct QQ {
        static let appID = "1107817575"
        static let appKey = "6ipbdomufCOYAz0a"
        static let schemes = ["mqq"]
    }
    
    struct Twitter {
        static let key = "LcZ3f9eBTDRrKJFwT90jvw"
        static let secret = "ptAqjqhR19vXRFVKAdn8WU6jMQUfbPUkQ99YThCBVI "
        static let redirectURL = "https://tmm.tokenmama.io/callback/twitter"
        static let schemes = ["twitter"]
    }
    
    struct Facebook {
        static let key = "469684170205512"
        static let secret = "0c36a8165843e2184f0b182b87f4ea07"
        static let displayName = "Hello Time"
        static let schemes = ["fb"]
    }
    
    struct Telegram {
        static let botToken = "671547779:AAHr8mq1FY3JK0PJZwkHreDRcXwqm4VzI9U"
        static let domain = "tmm.tokenmama.io"
        static let schemes = ["tg"]
    }
    
    struct Line {
        static let channelId = "1613264917"
        static let channelSecret = "ca196c328a296e454e80cec08411539a"
        static let schemes = ["line"]
    }
    
    struct MTA {
        static let appKey = "IV9I18EL7INX"
    }
    
    struct XG {
        static let accessId: UInt32 = 2200315653
        static let accessKey = "I1ZKJ4D22E7R"
    }
    
    static let defaultReadSpeed: Int = 500
    
    static let defaultPointsPerTs: NSDecimalNumber = 0.1
}

enum TrackEvent: String {
    case login = "Login"
    case register = "Register"
    case pointsChangeTBC = "PointsChangeTBC"
    case TBCChangePoints = "TBCChangePoints"
    case TokenTransfer = "TokenTransfer"
    case BlowupBid = "BlowupBid"
    case BlowupEscape = "BlowupEscape"
}
