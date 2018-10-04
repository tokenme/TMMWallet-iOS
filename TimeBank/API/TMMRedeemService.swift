//
//  TMMRedeemService.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/4.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Moya
import SwiftyUserDefaults
import Hydra

enum TMMRedeemService {
    case cdps()
    case cdpOrderAdd(offerId: UInt64, deviceId: String)
}

// MARK: - TargetType Protocol Implementation
extension TMMRedeemService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/redeem")! }
    var path: String {
        switch self {
        case .cdps():
            return "/dycdp/list"
        case .cdpOrderAdd(_, _):
            return "/dycdp/order/add"
        }
    }
    var method: Moya.Method {
        switch self {
        case .cdps:
            return .get
        case .cdpOrderAdd(_, _):
            return .post
        }
    }
    var task: Task {
        switch self {
        case .cdps():
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
        case let .cdpOrderAdd(offerId, deviceId):
            return .requestParameters(parameters: ["offer_id": offerId, "device_id": deviceId], encoding: JSONEncoding.default)
        }
    }
    var sampleData: Data {
        switch self {
        case .cdps():
            return "[]".utf8Encoded
        case .cdpOrderAdd(_, _):
            return "{}".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}


extension TMMRedeemService {
    
    static func getCdps(provider: MoyaProvider<TMMRedeemService>) -> Promise<[APIRedeemCdp]> {
        return Promise<[APIRedeemCdp]> (in: .background, { resolve, reject, _ in
            provider.request(
                .cdps()
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let cdps: [APIRedeemCdp] = try response.mapArray(APIRedeemCdp.self)
                        resolve(cdps)
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
    
    static func addCdpOrder(offerId: UInt64, deviceId: String, provider: MoyaProvider<TMMRedeemService>) -> Promise<APIResponse> {
        return Promise<APIResponse> (in: .background, { resolve, reject, _ in
            provider.request(
                .cdpOrderAdd(offerId: offerId, deviceId: deviceId)
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
}
