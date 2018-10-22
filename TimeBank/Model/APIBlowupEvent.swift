//
//  APIBlowupEvent.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/18.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation

enum APIBlowupEventType: String {
    case session = "session"
    case bid = "bid"
    case escape = "escape"
}

public class APIBlowupEvent: Codable {
    var sessionId: UInt64 = 0
    var rate: NSDecimalNumber = 0
    var value: NSDecimalNumber = 0
    var type: APIBlowupEventType? = .session
    var nick: String = ""
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case rate = "rate"
        case value = "value"
        case type = "type"
        case nick = "nick"
    }
    
    required init(sessionId: UInt64, rate: NSDecimalNumber, value: NSDecimalNumber, type: APIBlowupEventType, nick: String) {
        self.sessionId = sessionId
        self.rate = rate
        self.value = value
        self.type = type
        self.nick = nick
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sessionId = try container.decode(UInt64.self, forKey: .sessionId)
        let rate = try container.decode(String.self, forKey: .rate)
        self.rate = NSDecimalNumber(string: rate)
        let value = try container.decode(String.self, forKey: .value)
        self.value = NSDecimalNumber(string: value)
        let type = try container.decode(String.self, forKey: .type)
        self.type = APIBlowupEventType(rawValue: type)
        self.nick = try container.decode(String.self, forKey: .nick)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(rate.stringValue, forKey: .rate)
        try container.encode(value.stringValue, forKey: .value)
        try container.encode(type?.rawValue ?? "", forKey: .type)
        try container.encode(nick, forKey: .nick)
    }
}
