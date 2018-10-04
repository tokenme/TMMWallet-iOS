//
//  FeedbackSlack.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/3.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation
import SKWebAPI

class FeedbackSlack: NSObject {
    public let bot: WebAPI
    public let slackToken: String
    public let slackChannel: String
    public var options: [String:String]?
    fileprivate init(slackToken: String, slackChannel: String) {
        self.slackToken = slackToken
        self.slackChannel = slackChannel
        self.bot = WebAPI(token: slackToken)
        super.init()
    }
    
    public static var shared: FeedbackSlack?
    
    public static func setup(_ slackToken: String, slackChannel: String) -> FeedbackSlack? {
        if let feedback: FeedbackSlack = shared {
            return feedback
        }
        
        shared = FeedbackSlack(slackToken: slackToken, slackChannel: slackChannel)
        return shared
    }
}
