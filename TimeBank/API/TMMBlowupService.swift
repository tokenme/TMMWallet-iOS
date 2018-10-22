//
//  TMMBlowupService.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/19.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Moya
import SwiftyUserDefaults
import Hydra

enum TMMBlowupService {
    case bid(sessionId: UInt64, points: NSDecimalNumber, idfa: String)
    case escape(sessionId: UInt64, idfa: String)
    case bids()
}

// MARK: - TargetType Protocol Implementation
extension TMMBlowupService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/blowup")! }
    var path: String {
        switch self {
        case .bid(_, _, _):
            return "/bid"
        case .escape(_, _):
            return "/escape"
        case .bids():
            return "/bids"
        }
    }
    var method: Moya.Method {
        switch self {
        case .bid(_, _, _), .escape(_, _):
            return .post
        case .bids():
            return .get
        }
    }
    
    var task: Task {
        switch self {
        case .bids():
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
        case let .bid(sessionId, points, idfa):
            return .requestParameters(parameters: ["session_id": sessionId, "points": points, "idfa": idfa], encoding: JSONEncoding.default)
        case let .escape(sessionId, idfa):
            return .requestParameters(parameters: ["session_id": sessionId, "idfa": idfa], encoding: JSONEncoding.default)
        }
    }
    
    var sampleData: Data {
        switch self {
        case .bid(_, _, _), .escape(_, _):
            return "{}".utf8Encoded
        case .bids():
            return "[]".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}


extension TMMBlowupService {
    
    static func newBid(sessionId: UInt64, points: NSDecimalNumber, idfa: String, provider: MoyaProvider<TMMBlowupService>) -> Promise<APIResponse> {
        return Promise<APIResponse> (in: .background, { resolve, reject, _ in
            provider.request(
                .bid(sessionId: sessionId, points: points, idfa: idfa)
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
    
    static func tryEscape(sessionId: UInt64, idfa: String, provider: MoyaProvider<TMMBlowupService>) -> Promise<APIBlowupBid> {
        return Promise<APIBlowupBid> (in: .background, { resolve, reject, _ in
            provider.request(
                .escape(sessionId: sessionId, idfa: idfa)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let resp = try response.mapObject(APIBlowupBid.self)
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
    
    static func getBids(provider: MoyaProvider<TMMBlowupService>) -> Promise<[APIBlowupBid]> {
        return Promise<[APIBlowupBid]> (in: .background, { resolve, reject, _ in
            provider.request(
                .bids()
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let bids: [APIBlowupBid] = try response.mapArray(APIBlowupBid.self)
                        resolve(bids)
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
