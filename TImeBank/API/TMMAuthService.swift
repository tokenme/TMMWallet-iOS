//
//  TMMAuthService.swift
//  ucoin
//
//  Created by Syd on 2018/6/1.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Moya
import SwiftyUserDefaults
import Hydra

enum TMMAuthService {
    case sendCode(country: UInt, mobile: String)
    case login(country: UInt, mobile: String, password: String)
}

// MARK: - TargetType Protocol Implementation
extension TMMAuthService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/auth")! }
    var path: String {
        switch self {
        case .sendCode(_, _):
            return "/send"
        case .login(_, _, _):
            return "/login"
        }
    }
    var method: Moya.Method {
        switch self {
        case .sendCode, .login:
            return .post
        }
    }
    var task: Task {
        switch self {
        case let .sendCode(country, mobile):
            return .requestParameters(parameters: ["country": country, "mobile": mobile], encoding: JSONEncoding.default)
        case .login(let country, let mobile, let password):
            return .requestParameters(parameters: ["country_code": country, "mobile": mobile, "password": password], encoding: JSONEncoding.default)
        }
    }
    var sampleData: Data {
        switch self {
        case .sendCode(_, _):
            return "ok".utf8Encoded
        case .login(_, _, _):
            return "{'token':'xxx', 'expire': 'xxxxxx'}".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}


extension TMMAuthService {
    
    static func doLogin(country: UInt, mobile: String, password: String, provider: MoyaProvider<TMMAuthService>) -> Promise<APIAccessToken> {
        return Promise<APIAccessToken> (in: .background, { resolve, reject, _ in
            provider.request(
                .login(country: country, mobile: mobile, password: password)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let token = try response.mapObject(APIAccessToken.self)
                        if let errorCode = token.code {
                            reject(TMMAPIError.error(code: errorCode, msg: token.message ?? I18n.unknownError.description))
                        } else {
                            Defaults[.accessToken] = DefaultsAccessToken.init(token: token.token!, expire: token.expire!)
                            Defaults.synchronize()
                            resolve(token)
                        }
                    } catch {
                        reject(TMMAPIError.error(code: response.statusCode, msg: response.description))
                    }
                case let .failure(error):
                    reject(TMMAPIError.error(code: 0, msg: error.errorDescription ?? I18n.unknownError.description))
                }
            }
        })
    }
}
