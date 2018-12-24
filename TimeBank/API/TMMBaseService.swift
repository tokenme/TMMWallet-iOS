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

protocol SignatureTargetType: TargetType {
    var params: [String: Any] { get }
}

struct SignaturePlugin: PluginType {
    let appKeyClosure: () -> String
    let secretClosure: () -> String
    let appBuildClosure: () -> String?
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard
            let appBuild = appBuildClosure(),
            let target = target as? SignatureTargetType
            else {
                return request
        }
        let gateway = target.baseURL.absoluteString + target.path
        let ts = Int64(Date().timeIntervalSince1970)
        let nounce = UUID().uuidString
        let appKey = appKeyClosure()
        let secret = secretClosure()
        var headers: [String:String] = ["tmm-ts": String(ts), "tmm-build": appBuild, "tmm-nounce": nounce, "tmm-platform": APIPlatform.iOS.rawValue]
        var request = request
        for (key, val) in headers {
            request.addValue(val, forHTTPHeaderField: key)
        }
        for (key, val) in target.params {
            var v = ""
            if let b = val as? Bool {
                v = b ? "1" : "0"
            } else {
                v = "\(val)"
            }
            if v == "" {
                continue
            }
            headers[key] = v
        }
        let sortedHeaders = headers.sorted {$0.0 < $1.0}
        var rawSign: String = gateway + appKey
        for (key, val) in sortedHeaders {
            rawSign += key + val
        }
        rawSign += secret
        let sign = MD5(rawSign).lowercased()
        request.addValue(sign, forHTTPHeaderField: "tmm-sign")
        request.addValue(appKey, forHTTPHeaderField: "tmm-appkey")
        #if DEBUG
        print(rawSign)
        print(sign)
        #endif
        return request
    }
}

let kAPIBaseURL = "https://tmm.tokenmama.io"

let AccessTokenClosure: () -> String = {
    if let token = Defaults[.accessToken]?.token {
        return token
    }
    return ""
}

let AppKeyClosure: () -> String = {
    return TMMConfigs.TMMBeacon.key
}

let SecretClosure: () -> String = {
    return TMMConfigs.TMMBeacon.secret
}

let AppBuildClosure: () -> String = {
    if let buildVersion = Bundle.main.infoDictionary!["CFBundleVersion"] as? String {
        return buildVersion
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

let isValidatingBuild: () -> Bool = {
    if let build = MTAConfig.getInstance()?.getCustomProperty(TMMConfigs.validatingBuildKey, default: "0") {
        #if DEBUG
        //print("Validating Build: ", build)
        #endif
        return build == AppBuildClosure()
    }
    return true
}
