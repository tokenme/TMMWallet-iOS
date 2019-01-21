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
    case tmmWithdrawList(page: UInt, pageSize: UInt)
    case pointPrice(currency: String)
    case pointWithdraw(deviceId: String, points: NSDecimalNumber, currency: String)
    case pointWithdrawList(deviceId: String, page: UInt, pageSize: UInt)
}

// MARK: - TargetType Protocol Implementation
extension TMMRedeemService: TargetType, AccessTokenAuthorizable, SignatureTargetType {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/redeem")! }
    var path: String {
        switch self {
        case .cdps:
            return "/dycdp/list"
        case .cdpOrderAdd:
            return "/dycdp/order/add"
        case .tmmRate:
            return "/tmm/rate"
        case .tmmWithdraw:
            return "/tmm/withdraw"
        case .tmmWithdrawList:
            return "/tmm/withdraw/list"
        case .pointPrice:
            return "/point/price"
        case .pointWithdraw:
            return "/points/withdraw"
        case .pointWithdrawList:
            return "/points/withdraw/list"
        }
    }
    var method: Moya.Method {
        switch self {
        case .cdps, .tmmRate, .tmmWithdrawList, .pointPrice, .pointWithdrawList:
            return .get
        case .cdpOrderAdd, .tmmWithdraw, .pointWithdraw:
            return .post
        }
    }
    
    var params: [String: Any] {
        switch self {
        case .cdps:
            return [:]
        case let .cdpOrderAdd(offerId, deviceId):
            return ["offer_id": offerId, "device_id": deviceId]
        case let .tmmRate(currency):
            return ["currency": currency]
        case let .tmmWithdraw(tmm, currency):
            return ["tmm": tmm, "currency": currency]
        case let .tmmWithdrawList(page, pageSize):
            return ["page": page, "page_size": pageSize]
        case let .pointPrice(currency):
            return ["currency": currency]
        case let .pointWithdraw(deviceId, points, currency):
            return ["device_id": deviceId, "points": points, "currency": currency]
        case let .pointWithdrawList(deviceId, page, pageSize):
            var vars: [String: Any] = ["page": page, "page_size": pageSize]
            if deviceId != "" {
                vars["device_id"] = deviceId
            }
            return vars
        }
    }
    
    var task: Task {
        switch self {
        case .cdps:
            return .requestParameters(parameters: self.params, encoding: URLEncoding.default)
        case .cdpOrderAdd:
            return .requestParameters(parameters: self.params, encoding: JSONEncoding.default)
        case .tmmRate:
            return .requestParameters(parameters: self.params, encoding: URLEncoding.default)
        case .tmmWithdraw:
            return .requestParameters(parameters: self.params, encoding: JSONEncoding.default)
        case .tmmWithdrawList:
            return .requestParameters(parameters: self.params, encoding: URLEncoding.default)
        case .pointPrice:
            return .requestParameters(parameters: self.params, encoding: URLEncoding.default)
        case .pointWithdraw:
            return .requestParameters(parameters: self.params, encoding: JSONEncoding.default)
        case .pointWithdrawList:
            return .requestParameters(parameters: self.params, encoding: URLEncoding.default)
        }
    }
    
    var sampleData: Data {
        switch self {
        case .cdps, .tmmWithdrawList, .pointWithdrawList:
            return "[]".utf8Encoded
        case .cdpOrderAdd, .tmmRate, .tmmWithdraw, .pointPrice, .pointWithdraw:
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
                                    formatter.roundingMode = .floor
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
    
    static func getTMMWithdrawRecords(page: UInt, pageSize: UInt, provider: MoyaProvider<TMMRedeemService>) -> Promise<[APITMMWithdrawRecord]> {
        return Promise<[APITMMWithdrawRecord]> (in: .background, { resolve, reject, _ in
            provider.request(
                .tmmWithdrawList(page: page, pageSize: pageSize)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let records: [APITMMWithdrawRecord] = try response.mapArray(APITMMWithdrawRecord.self)
                        resolve(records)
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
    
    static func getPointPrice(currency: String, provider: MoyaProvider<TMMRedeemService>) -> Promise<APIExchangeRate> {
        return Promise<APIExchangeRate> (in: .background, { resolve, reject, _ in
            provider.request(
                .pointPrice(currency: currency)
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
    
    static func withdrawPoints(deviceId: String, points: NSDecimalNumber, currency: String, provider: MoyaProvider<TMMRedeemService>) -> Promise<APITMMWithdraw> {
        return Promise<APITMMWithdraw> (in: .background, { resolve, reject, _ in
            provider.request(
                .pointWithdraw(deviceId: deviceId, points: points, currency: currency)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let resp = try response.mapObject(APITMMWithdraw.self)
                        if let errorCode = resp.code {
                            if errorCode == TMMAPIResponseType.invalidMinPoints.rawValue {
                                do {
                                    let exchangeRate = try response.mapObject(APIExchangeRate.self)
                                    let formatter = NumberFormatter()
                                    formatter.maximumFractionDigits = 4
                                    formatter.groupingSeparator = "";
                                    formatter.numberStyle = NumberFormatter.Style.decimal
                                    formatter.roundingMode = .floor
                                    let minPointsStr = formatter.string(from: exchangeRate.minPoints)!
                                    let message = String(format: I18n.invalidMinPointsError.description, minPointsStr)
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
    
    static func getPointWithdrawRecords(deviceId: String, page: UInt, pageSize: UInt, provider: MoyaProvider<TMMRedeemService>) -> Promise<[APITMMWithdrawRecord]> {
        return Promise<[APITMMWithdrawRecord]> (in: .background, { resolve, reject, _ in
            provider.request(
                .pointWithdrawList(deviceId: deviceId, page: page, pageSize: pageSize)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let records: [APITMMWithdrawRecord] = try response.mapArray(APITMMWithdrawRecord.self)
                        resolve(records)
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
