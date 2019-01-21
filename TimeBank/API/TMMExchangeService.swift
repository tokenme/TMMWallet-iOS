//
//  TMMExchangeService.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/6.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Moya
import Hydra

enum TMMExchangeService {
    case tmmRate()
    case pointsRate()
    case tmmChange(deviceId: String, points: NSDecimalNumber, direction: APIExchangeDirection)
    case records(page: UInt, pageSize: UInt, direction: APIExchangeDirection)
    case redeemCdpRecords(page: UInt, pageSize: UInt)
}

// MARK: - TargetType Protocol Implementation
extension TMMExchangeService: TargetType, AccessTokenAuthorizable, SignatureTargetType {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/exchange")! }
    var path: String {
        switch self {
        case .tmmRate():
            return "/tmm/rate"
        case .pointsRate():
            return "/points/rate"
        case .tmmChange(_, _, _):
            return "/tmm/change"
        case .records(_, _, _):
            return "/records"
        case .redeemCdpRecords(_, _):
            return "/records"
        }
    }
    var method: Moya.Method {
        switch self {
        case .tmmRate, .records(_, _, _), .redeemCdpRecords(_, _), .pointsRate:
            return .get
        case .tmmChange(_, _, _):
            return .post
        }
    }
    var params: [String: Any] {
        switch self {
        case .tmmRate:
            return [:]
        case .pointsRate:
            return [:]
        case let .tmmChange(deviceId, points, direction):
            return ["device_id": deviceId, "points": points, "direction": direction.rawValue]
        case let .records(page, pageSize, direction):
            return ["page": page, "page_size": pageSize, "direction": direction.rawValue]
        case let .redeemCdpRecords(page, pageSize):
            return ["page": page, "page_size": pageSize, "type": 1]
        }
    }
    var task: Task {
        switch self {
        case .tmmRate:
            return .requestParameters(parameters: self.params, encoding: URLEncoding.default)
        case .pointsRate:
            return .requestParameters(parameters: self.params, encoding: URLEncoding.default)
        case .tmmChange:
            return .requestParameters(parameters: self.params, encoding: JSONEncoding.default)
        case .records:
            return .requestParameters(parameters: self.params, encoding: URLEncoding.default)
        case .redeemCdpRecords:
            return .requestParameters(parameters: self.params, encoding: URLEncoding.default)
        }
    }
    var sampleData: Data {
        switch self {
        case .tmmRate(), .pointsRate(), .tmmChange(_, _, _):
            return "{}".utf8Encoded
        case .records(_, _, _), .redeemCdpRecords(_, _):
            return "[]".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}


extension TMMExchangeService {
    
    static func getTMMRate(provider: MoyaProvider<TMMExchangeService>) -> Promise<APIExchangeRate> {
        return Promise<APIExchangeRate> (in: .background, { resolve, reject, _ in
            provider.request(
                .tmmRate()
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
    
    static func getPointsRate(provider: MoyaProvider<TMMExchangeService>) -> Promise<APIExchangeRate> {
        return Promise<APIExchangeRate> (in: .background, { resolve, reject, _ in
            provider.request(
                .pointsRate()
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
    
    static func changeTMM(deviceId: String, points: NSDecimalNumber, direction: APIExchangeDirection, provider: MoyaProvider<TMMExchangeService>) -> Promise<APITransaction> {
        return Promise<APITransaction> (in: .background, { resolve, reject, _ in
            provider.request(
                .tmmChange(deviceId: deviceId, points: points, direction: direction)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let resp = try response.mapObject(APITransaction.self)
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
    
    static func getRecords(page: UInt, pageSize: UInt, direction: APIExchangeDirection, provider: MoyaProvider<TMMExchangeService>) -> Promise<[APIExchangeRecord]> {
        return Promise<[APIExchangeRecord]> (in: .background, { resolve, reject, _ in
            provider.request(
                .records(page: page, pageSize: pageSize, direction:direction)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let records: [APIExchangeRecord] = try response.mapArray(APIExchangeRecord.self)
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
    
    static func getRedeemCdpRecords(page: UInt, pageSize: UInt, provider: MoyaProvider<TMMExchangeService>) -> Promise<[APIRedeemCdpRecord]> {
        return Promise<[APIRedeemCdpRecord]> (in: .background, { resolve, reject, _ in
            provider.request(
                .redeemCdpRecords(page: page, pageSize: pageSize)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let records: [APIRedeemCdpRecord] = try response.mapArray(APIRedeemCdpRecord.self)
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
