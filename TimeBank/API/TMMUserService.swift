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
    case create(country: UInt, mobile: String, verifyCode: String, password: String, repassword: String)
    case resetPassword(country: UInt, mobile: String, verifyCode: String, password: String, repassword: String)
    case update(user: APIUser)
    case info(refresh: Bool)
    case inviteSummary()
}

// MARK: - TargetType Protocol Implementation
extension TMMUserService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/user")! }
    var path: String {
        switch self {
        case .create(_, _, _, _, _):
            return "/create"
        case .resetPassword(_, _, _, _, _):
            return "/reset-password"
        case .update(_):
            return "/update"
        case .info(_):
            return "/info"
        case .inviteSummary():
            return "/invite/summary"
        }
    }
    var method: Moya.Method {
        switch self {
        case .create, .update, .resetPassword:
            return .post
        case .info, .inviteSummary:
            return .get
        }
    }
    var task: Task {
        switch self {
        case let .create(country, mobile, verifyCode, password, repassword):
            return .requestParameters(parameters: ["country_code": country, "mobile": mobile, "verify_code": verifyCode, "passwd": password, "repasswd": repassword], encoding: JSONEncoding.default)
        case let .resetPassword(country, mobile, verifyCode, password, repassword):
            return .requestParameters(parameters: ["country_code": country, "mobile": mobile, "verify_code": verifyCode, "passwd": password, "repasswd": repassword], encoding: JSONEncoding.default)
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
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case let .info(refresh):
            return .requestParameters(parameters: ["refresh": refresh], encoding: URLEncoding.queryString)
        case .inviteSummary():
            return .requestParameters(parameters: [:], encoding: URLEncoding.queryString)
        }
    }
    var sampleData: Data {
        switch self {
        case .create(_, _, _, _, _):
            return "ok".utf8Encoded
        case .resetPassword(_, _, _, _, _):
            return "ok".utf8Encoded
        case .update(_):
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
    
    static func createUser(country: UInt, mobile: String, verifyCode: String, password: String, repassword: String, provider: MoyaProvider<TMMUserService>) -> Promise<APIResponse> {
        return Promise<APIResponse> (in: .background, { resolve, reject, _ in
            provider.request(
                .create(country: country, mobile: mobile, verifyCode: verifyCode, password: password, repassword: repassword)
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
                                inviterCode: userInfo.inviterCode ?? "")
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
