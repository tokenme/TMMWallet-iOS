//
//  TMMGoodService.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/8.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Moya
import SwiftyUserDefaults
import Hydra

enum TMMGoodService {
    case list(page: UInt, pageSize: UInt)
    case item(id: UInt64)
    case invest(goodId: UInt64, idfa: String, points: NSDecimalNumber)
    case invests(goodId: UInt64, page: UInt, pageSize: UInt)
    case myInvests(page: UInt, pageSize: UInt)
    case investWithdraw(id: UInt64)
    case investSummary()
    case investRedeem(ids: [UInt64]?)
}

// MARK: - TargetType Protocol Implementation
extension TMMGoodService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/good")! }
    var path: String {
        switch self {
        case .list:
            return "/list"
        case let .item(id):
            return "/item/\(id)"
        case .invest:
            return "/invest"
        case let .invests(goodId, page, pageSize):
            return "/invests/item/\(goodId)/\(page)/\(pageSize)"
        case let .myInvests(page, pageSize):
            return "/invests/my/\(page)/\(pageSize)"
        case let .investWithdraw(id):
            return "/invest/withdraw/\(id)"
        case .investSummary:
            return "/invest/summary"
        case .investRedeem:
            return "/invest/redeem"
        }
    }
    var method: Moya.Method {
        switch self {
        case .list, .item, .invests, .myInvests, .investWithdraw, .investSummary:
            return .get
        case .invest, .investRedeem:
            return .post
        }
    }
    var task: Task {
        switch self {
        case let .list(page, pageSize):
            return .requestParameters(parameters: ["page": page, "page_size": pageSize], encoding: URLEncoding.default)
        case .item(_):
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
        case .invests(_, _, _):
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
        case let .invest(goodId, idfa, points):
            return .requestParameters(parameters: ["good_id": goodId, "points": points, "idfa": idfa], encoding: JSONEncoding.default)
        case .myInvests(_, _):
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
        case .investWithdraw(_):
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
        case .investSummary():
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
        case let .investRedeem(ids):
            var strArr: [String] = []
            if let ids = ids {
                for id in ids {
                    strArr.append("\(id)")
                }
            }
            return .requestParameters(parameters: ["ids": strArr.joined(separator: ",")], encoding: JSONEncoding.default)
        }
    }
    var sampleData: Data {
        switch self {
        case .list, .invests, .myInvests:
            return "[]".utf8Encoded
        case .item, .invest, .investWithdraw, .investSummary, .investRedeem:
            return "{}".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}


extension TMMGoodService {
    
    static func getList(page: UInt, pageSize: UInt, provider: MoyaProvider<TMMGoodService>) -> Promise<[APIGood]> {
        return Promise<[APIGood]> (in: .background, { resolve, reject, _ in
            provider.request(
                .list(page: page, pageSize: pageSize)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let goods: [APIGood] = try response.mapArray(APIGood.self)
                        resolve(goods)
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
    
    static func getInvests(goodId: UInt64, page: UInt, pageSize: UInt, provider: MoyaProvider<TMMGoodService>) -> Promise<[APIGoodInvest]> {
        return Promise<[APIGoodInvest]> (in: .background, { resolve, reject, _ in
            provider.request(
                .invests(goodId: goodId, page: page, pageSize: pageSize)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let invests: [APIGoodInvest] = try response.mapArray(APIGoodInvest.self)
                        resolve(invests)
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
    
    static func getItem(id: UInt64, provider: MoyaProvider<TMMGoodService>) -> Promise<APIGood> {
        return Promise<APIGood> (in: .background, { resolve, reject, _ in
            provider.request(
                .item(id: id)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let good = try response.mapObject(APIGood.self)
                        if let errorCode = good.code {
                            reject(TMMAPIError.error(code: errorCode, msg: good.message ?? I18n.unknownError.description))
                        } else {
                            resolve(good)
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
    
    static func investItem(goodId: UInt64, idfa: String, points: NSDecimalNumber, provider: MoyaProvider<TMMGoodService>) -> Promise<APIResponse> {
        return Promise<APIResponse> (in: .background, { resolve, reject, _ in
            provider.request(
                .invest(goodId: goodId, idfa: idfa, points: points)
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
    
    static func getMyInvests(page: UInt, pageSize: UInt, provider: MoyaProvider<TMMGoodService>) -> Promise<[APIGoodInvest]> {
        return Promise<[APIGoodInvest]> (in: .background, { resolve, reject, _ in
            provider.request(
                .myInvests(page: page, pageSize: pageSize)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let invests: [APIGoodInvest] = try response.mapArray(APIGoodInvest.self)
                        resolve(invests)
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
    
    static func withdrawInvest(id: UInt64, provider: MoyaProvider<TMMGoodService>) -> Promise<APIResponse> {
        return Promise<APIResponse> (in: .background, { resolve, reject, _ in
            provider.request(
                .investWithdraw(id: id)
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
    
    static func getInvestSummary(provider: MoyaProvider<TMMGoodService>) -> Promise<APIGoodInvestSummary> {
        return Promise<APIGoodInvestSummary> (in: .background, { resolve, reject, _ in
            provider.request(
                .investSummary()
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let summary = try response.mapObject(APIGoodInvestSummary.self)
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
    
    static func redeemInvest(ids: [UInt64]?, provider: MoyaProvider<TMMGoodService>) -> Promise<APIResponse> {
        return Promise<APIResponse> (in: .background, { resolve, reject, _ in
            provider.request(
                .investRedeem(ids: ids)
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

