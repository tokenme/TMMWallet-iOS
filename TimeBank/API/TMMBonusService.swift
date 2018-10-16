//
//  TMMBonusService.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/16.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Moya
import SwiftyUserDefaults
import Hydra

enum TMMBonusService {
    case dailyStatus()
    case dailyCommit(deviceId: String)
}

// MARK: - TargetType Protocol Implementation
extension TMMBonusService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/bonus")! }
    var path: String {
        switch self {
        case .dailyStatus():
            return "/daily/status"
        case .dailyCommit(_):
            return "/daily/commit"
        }
    }
    var method: Moya.Method {
        switch self {
        case .dailyCommit(_):
            return .post
        case .dailyStatus():
            return .get
        }
    }
    
    var task: Task {
        switch self {
        case .dailyStatus():
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
        case let .dailyCommit(deviceId):
            return .requestParameters(parameters: ["idfa": deviceId, "platform": APIPlatform.iOS.rawValue], encoding: JSONEncoding.default)
        }
    }
    
    var sampleData: Data {
        switch self {
        case .dailyStatus(), .dailyCommit(_):
            return "{}".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}


extension TMMBonusService {
    
    static func getDailyStatus(provider: MoyaProvider<TMMBonusService>) -> Promise<APIDailyBonusStatus> {
        return Promise<APIDailyBonusStatus> (in: .background, { resolve, reject, _ in
            provider.request(
                .dailyStatus()
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let resp = try response.mapObject(APIDailyBonusStatus.self)
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
    
    static func commitDailyBonus(deviceId: String, provider: MoyaProvider<TMMBonusService>) -> Promise<APIDailyBonusStatus> {
        return Promise<APIDailyBonusStatus> (in: .background, { resolve, reject, _ in
            provider.request(
                .dailyCommit(deviceId: deviceId)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let resp = try response.mapObject(APIDailyBonusStatus.self)
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
}
