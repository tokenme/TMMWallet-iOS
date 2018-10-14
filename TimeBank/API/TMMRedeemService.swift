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
    case tmmRate(currency: String)
    case tmmWithdraw(tmm: NSDecimalNumber, currency: String)
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
        case .tmmRate(_):
            return "/tmm/rate"
        case .tmmWithdraw(_, _):
            return "/tmm/withdraw"
        }
    }
    var method: Moya.Method {
        switch self {
        case .cdps, .tmmRate(_):
            return .get
        case .cdpOrderAdd(_, _), .tmmWithdraw(_, _):
            return .post
        }
    }
    
    var task: Task {
        switch self {
        case .cdps():
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
        case let .cdpOrderAdd(offerId, deviceId):
            return .requestParameters(parameters: ["offer_id": offerId, "device_id": deviceId], encoding: JSONEncoding.default)
        case let .tmmRate(currency):
            return .requestParameters(parameters: ["currency": currency], encoding: URLEncoding.default)
        case let .tmmWithdraw(tmm, currency):
            return .requestParameters(parameters: ["tmm": tmm, "currency": currency], encoding: JSONEncoding.default)
        }
    }
    
    var sampleData: Data {
        switch self {
        case .cdps():
            return "[]".utf8Encoded
        case .cdpOrderAdd(_, _), .tmmRate(_), .tmmWithdraw(_, _):
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
    
    static func getTmmRate(currency: String, provider: MoyaProvider<TMMRedeemService>) -> Promise<APIExchangeRate> {
        return Promise<APIExchangeRate> (in: .background, { resolve, reject, _ in
            provider.request(
                .tmmRate(currency: currency)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let resp = try response.mapObject(APIExchangeRate.self)
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
    
    static func withdrawTMM(tmm: NSDecimalNumber, currency: String, provider: MoyaProvider<TMMRedeemService>) -> Promise<APITMMWithdraw> {
        return Promise<APITMMWithdraw> (in: .background, { resolve, reject, _ in
            provider.request(
                .tmmWithdraw(tmm: tmm, currency: currency)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let resp = try response.mapObject(APITMMWithdraw.self)
                        if let errorCode = resp.code {
                            if errorCode == TMMAPIResponseType.invalidMinToken.rawValue {
                                do {
                                    let exchangeRate = try response.mapObject(APIExchangeRate.self)
                                    let formatter = NumberFormatter()
                                    formatter.maximumFractionDigits = 4
                                    formatter.groupingSeparator = "";
                                    formatter.numberStyle = NumberFormatter.Style.decimal
                                    let minPointsStr = formatter.string(from: exchangeRate.minPoints)!
                                    let message = String(format: I18n.invalidMinTMMError.description, minPointsStr)
                                    reject(TMMAPIError.error(code: errorCode, msg: message))
                                    return
                                } catch {
                                    reject(TMMAPIError.error(code: errorCode, msg: resp.message ?? I18n.unknownError.description))
                                }
                            }
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
