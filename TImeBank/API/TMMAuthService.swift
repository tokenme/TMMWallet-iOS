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
    case login(country: UInt, mobile: String, password: String, biometric: Bool, captcha: String, afsSession: String)
    case refresh()
}

// MARK: - TargetType Protocol Implementation
extension TMMAuthService: TargetType, AccessTokenAuthorizable, SignatureTargetType {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/auth")! }
    var path: String {
        switch self {
        case .sendCode:
            return "/send"
        case .login:
            return "/login"
        case .refresh():
            return "/refresh_token"
        }
    }
    var method: Moya.Method {
        switch self {
        case .sendCode, .login:
            return .post
        case .refresh:
            return .get
        }
    }
    var params: [String: Any] {
        switch self {
        case let .sendCode(country, mobile):
            return ["country": country, "mobile": mobile]
        case let .login(country, mobile, password, biometric, captcha, afsSession):
            return ["country_code": country, "mobile": mobile, "password": password, "biometric": biometric, "captcha": captcha, "afs_session":afsSession]
        case .refresh:
            return [:]
        }
    }
    var task: Task {
        switch self {
        case .sendCode:
            return .requestParameters(parameters: self.params, encoding: JSONEncoding.default)
        case .login:
            return .requestParameters(parameters: self.params, encoding: JSONEncoding.default)
        case .refresh:
            return .requestParameters(parameters: self.params, encoding: URLEncoding.default)
        }
    }
    var sampleData: Data {
        switch self {
        case .sendCode:
            return "ok".utf8Encoded
        case .login, .refresh():
            return "{'token':'xxx', 'expire': 'xxxxxx'}".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}


extension TMMAuthService {
    
    static func doLogin(country: UInt, mobile: String, password: String, biometric: Bool, captcha: String, afsSession: String, provider: MoyaProvider<TMMAuthService>) -> Promise<APIAccessToken> {
        return Promise<APIAccessToken> (in: .background, { resolve, reject, _ in
            provider.request(
                .login(country: country, mobile: mobile, password: password, biometric: biometric, captcha: captcha, afsSession: afsSession)
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
    
    static func refreshToken(provider: MoyaProvider<TMMAuthService>) -> Promise<APIAccessToken> {
        return Promise<APIAccessToken> (in: .background, { resolve, reject, _ in
            provider.request(
                .refresh()
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
