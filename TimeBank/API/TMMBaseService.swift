//
//  TMMBaseService.swift
//  ucoin
//
//  Created by Syd on 2018/6/4.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Moya
import SwiftyUserDefaults

protocol AuthorizedTargetType: TargetType {
    var needsAuth: Bool { get }
}

struct AuthPlugin: PluginType {
    let tokenClosure: () -> String?
    
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard
            let token = tokenClosure(),
            let target = target as? AuthorizedTargetType,
            target.needsAuth
            else {
                return request
        }
        
        var request = request
        request.addValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        return request
    }
}

let networkActivityPlugin = NetworkActivityPlugin { (change, _) -> () in
    switch(change) {
    case .ended:
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    case .began:
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
    }
}

let kAPIBaseURL = "https://tmm.tokenmama.io"

let AccessTokenClosure: () -> String  = {
    if let token = Defaults[.accessToken]?.token {
        return token
    }
    return ""
}

let CheckValidAccessToken: () -> Bool = {
    if let accessToken: DefaultsAccessToken = Defaults[.accessToken] {
        if accessToken.expire.compare(Date()) == .orderedDescending {
            return true
        }
    }
    return false
}

let MaxSchemeQuery: () -> UInt64 = {
    if let dict = Bundle.main.infoDictionary {
        if let maxQuery = dict["TMMMaxSchemeQuery"] as? UInt64 {
            return maxQuery
        }
    }
    return 0
}
