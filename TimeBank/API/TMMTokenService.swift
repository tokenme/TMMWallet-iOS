//
//  TMMTokenService.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/10.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Moya
import SwiftyUserDefaults
import Hydra

enum TMMTokenService {
    case tmmBalance()
    case assets()
}

// MARK: - TargetType Protocol Implementation
extension TMMTokenService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/token")! }
    var path: String {
        switch self {
        case .tmmBalance():
            return "/tmm/balance"
        case .assets():
            return "/assets"
        }
    }
    var method: Moya.Method {
        switch self {
        case .tmmBalance, .assets:
            return .get
        }
    }
    var task: Task {
        switch self {
        case .tmmBalance():
            return .requestParameters(parameters: [:], encoding: URLEncoding.queryString)
        case .assets():
            return .requestParameters(parameters: [:], encoding: URLEncoding.queryString)
        }
    }
    var sampleData: Data {
        switch self {
        case .tmmBalance():
            return "{}".utf8Encoded
        case .assets():
            return "[]".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}

extension TMMTokenService {
    
    static func getTMMBalance( provider: MoyaProvider<TMMTokenService>) -> Promise<APIToken> {
        return Promise<APIToken> (in: .background, { resolve, reject, _ in
            provider.request(
                .tmmBalance()
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let token = try response.mapObject(APIToken.self)
                        if let errorCode = token.code {
                            reject(TMMAPIError.error(code: errorCode, msg: token.message ?? I18n.unknownError.description))
                        } else {
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
    
    static func getAssets(provider: MoyaProvider<TMMTokenService>) -> Promise<[APIToken]> {
        return Promise<[APIToken]> (in: .background, { resolve, reject, _ in
            provider.request(
                .assets()
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let tokens: [APIToken] = try response.mapArray(APIToken.self)
                        resolve(tokens)
                    } catch {
                        do {
                            let err = try response.mapObject(APIResponse.self)
                            if let errorCode = err.code {
                                reject(TMMAPIError.error(code: errorCode, msg: err.message ?? I18n.unknownError.description))
                            } else {
                                reject(TMMAPIError.error(code: 0, msg: I18n.unknownError.description))
                            }
                        } catch {
                            if response.statusCode == 200 {
                                resolve([])
                            } else {
                                reject(TMMAPIError.error(code: response.statusCode, msg: response.description))
                            }
                        }
                    }
                case let .failure(error):
                    reject(TMMAPIError.error(code: 0, msg: error.errorDescription ?? I18n.unknownError.description))
                }
            }
        })
    }
}
