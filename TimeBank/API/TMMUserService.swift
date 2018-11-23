//
//  TMMUserService.swift
//  ucoin
//
//  Created by Syd on 2018/6/5.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Moya
import SwiftyUserDefaults
import Hydra

enum TMMUserService {
    case create(country: UInt, mobile: String, verifyCode: String, password: String, repassword: String, captcha: String, afsSession: String)
    case resetPassword(country: UInt, mobile: String, verifyCode: String, password: String, repassword: String)
    case update(user: APIUser)
    case info(refresh: Bool)
    case bindWechat(unionId: String, openId: String, nick: String, avatar: String, gender: Int, accessToken: String, expires: TimeInterval)
    case inviteSummary()
}

// MARK: - TargetType Protocol Implementation
extension TMMUserService: TargetType, AccessTokenAuthorizable, SignatureTargetType {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/user")! }
    var path: String {
        switch self {
        case .create:
            return "/create"
        case .resetPassword:
            return "/reset-password"
        case .update(_):
            return "/update"
        case .bindWechat(_, _, _, _, _, _, _):
            return "/update"
        case .info(_):
            return "/info"
        case .inviteSummary():
            return "/invite/summary"
        }
    }
    var method: Moya.Method {
        switch self {
        case .create, .update, .resetPassword, .bindWechat:
            return .post
        case .info, .inviteSummary:
            return .get
        }
    }
    var params: [String: Any] {
        switch self {
        case let .create(country, mobile, verifyCode, password, repassword, captcha, afsSession):
            return ["country_code": country, "mobile": mobile, "verify_code": verifyCode, "passwd": password, "repasswd": repassword, "captcha": captcha, "afs_session": afsSession]
        case let .resetPassword(country, mobile, verifyCode, password, repassword):
            return ["country_code": country, "mobile": mobile, "verify_code": verifyCode, "passwd": password, "repasswd": repassword]
        case let .update(user):
            var params: [String:Any] = [:]
            if let nick = user.nick {
                params["nick"] = nick
            }
            if let avatar = user.avatar {
                params["avatar"] = avatar
            }
            if let paymentPasswd = user.paymentPasswd {
                params["payment_passwd"] = paymentPasswd
            }
            if let inviterCode = user.inviterCode {
                params["inviter_code"] = inviterCode
            }
            return params
        case let .bindWechat(unionId, openId, nick, avatar, gender, accessToken, expires):
            return ["wx_union_id": unionId, "wx_open_id": openId, "wx_nick": nick, "wx_avatar": avatar, "wx_gender": gender, "wx_token": accessToken, "wx_expires": Int64(expires)]
        case let .info(refresh):
            return ["refresh": refresh]
        case .inviteSummary:
            return [:]
        }
    }
    var task: Task {
        switch self {
        case .create:
            return .requestParameters(parameters: self.params, encoding: JSONEncoding.default)
        case .resetPassword:
            return .requestParameters(parameters: self.params, encoding: JSONEncoding.default)
        case .update:
            return .requestParameters(parameters: self.params, encoding: JSONEncoding.default)
        case .bindWechat:
            return .requestParameters(parameters: self.params, encoding: JSONEncoding.default)
        case .info:
            return .requestParameters(parameters: self.params, encoding: URLEncoding.queryString)
        case .inviteSummary():
            return .requestParameters(parameters: self.params, encoding: URLEncoding.queryString)
        }
    }
    var sampleData: Data {
        switch self {
        case .create:
            return "ok".utf8Encoded
        case .resetPassword:
            return "ok".utf8Encoded
        case .update(_):
            return "ok".utf8Encoded
        case .bindWechat:
            return "ok".utf8Encoded
        case .info(_), .inviteSummary():
            return "{}".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}

extension TMMUserService {
    
    static func createUser(country: UInt, mobile: String, verifyCode: String, password: String, repassword: String, captcha: String, afsSession: String, provider: MoyaProvider<TMMUserService>) -> Promise<APIResponse> {
        return Promise<APIResponse> (in: .background, { resolve, reject, _ in
            provider.request(
                .create(country: country, mobile: mobile, verifyCode: verifyCode, password: password, repassword: repassword, captcha: captcha, afsSession: afsSession)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let resp = try response.mapObject(APIResponse.self)
                        if let errorCode = resp.code {
                            reject(TMMAPIError.error(code: errorCode, msg: resp.message ?? I18n.unknownError.description))
                        } else {
                            resolve(resp)
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
    
    static func resetUserPassword(country: UInt, mobile: String, verifyCode: String, password: String, repassword: String, provider: MoyaProvider<TMMUserService>) -> Promise<APIResponse> {
        return Promise<APIResponse> (in: .background, { resolve, reject, _ in
            provider.request(
                .resetPassword(country: country, mobile: mobile, verifyCode: verifyCode, password: password, repassword: repassword)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let resp = try response.mapObject(APIResponse.self)
                        if let errorCode = resp.code {
                            reject(TMMAPIError.error(code: errorCode, msg: resp.message ?? I18n.unknownError.description))
                        } else {
                            resolve(resp)
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
    
    static func getUserInfo(_ refresh: Bool, provider: MoyaProvider<TMMUserService>) -> Promise<APIUser> {
        return Promise<APIUser> (in: .background, { resolve, reject, _ in
            provider.request(
                .info(refresh: refresh)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let userInfo = try response.mapObject(APIUser.self)
                        if let errorCode = userInfo.code {
                            reject(TMMAPIError.error(code: errorCode, msg: userInfo.message ?? I18n.unknownError.description))
                        } else {
                            Defaults[.user] = DefaultsUser.init(
                                id: userInfo.id!,
                                countryCode: userInfo.countryCode ?? 0,
                                mobile: userInfo.mobile ?? "",
                                showName: userInfo.showName ?? "",
                                avatar: userInfo.avatar ?? "",
                                wallet: userInfo.wallet ?? "",
                                canPay: userInfo.canPay ?? 0,
                                inviteCode: userInfo.inviteCode ?? "",
                                inviterCode: userInfo.inviterCode ?? "",
                                exchangeEnabled: userInfo.exchangeEnabled,
                                wxBinded: userInfo.wxBinded
                            )
                            if Defaults[.currency] == nil || Defaults[.currency]!.isEmpty {
                                switch userInfo.countryCode {
                                case 1: Defaults[.currency] = Currency.USD.rawValue
                                case 86: Defaults[.currency] = Currency.CNY.rawValue
                                case 81: Defaults[.currency] = Currency.JPY.rawValue
                                case 82: Defaults[.currency] = Currency.KRW.rawValue
                                default: Defaults[.currency] = Currency.EUR.rawValue
                                }
                            }
                            Defaults.synchronize()
                            resolve(userInfo)
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
    
    static func updateUserInfo(_ user: APIUser, provider: MoyaProvider<TMMUserService>) -> Promise<APIResponse> {
        return Promise<APIResponse> (in: .background, { resolve, reject, _ in
            provider.request(
                .update(user: user)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let resp = try response.mapObject(APIResponse.self)
                        if let errorCode = resp.code {
                            reject(TMMAPIError.error(code: errorCode, msg: resp.message ?? I18n.unknownError.description))
                        } else {
                            resolve(resp)
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
    
    static func bindWechatInfo(unionId: String, openId: String, nick: String, avatar: String, gender: Int, accessToken: String, expires: TimeInterval, provider: MoyaProvider<TMMUserService>) -> Promise<APIResponse> {
        return Promise<APIResponse> (in: .background, { resolve, reject, _ in
            provider.request(
                .bindWechat(unionId: unionId, openId: openId, nick: nick, avatar: avatar, gender: gender, accessToken: accessToken, expires: expires)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let resp = try response.mapObject(APIResponse.self)
                        if let errorCode = resp.code {
                            reject(TMMAPIError.error(code: errorCode, msg: resp.message ?? I18n.unknownError.description))
                        } else {
                            resolve(resp)
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
    
    static func getInviteSummary(provider: MoyaProvider<TMMUserService>) -> Promise<APIInviteSummary> {
        return Promise<APIInviteSummary> (in: .background, { resolve, reject, _ in
            provider.request(
                .inviteSummary()
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let summary = try response.mapObject(APIInviteSummary.self)
                        if let errorCode = summary.code {
                            reject(TMMAPIError.error(code: errorCode, msg: summary.message ?? I18n.unknownError.description))
                        } else {
                            resolve(summary)
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
