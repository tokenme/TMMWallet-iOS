//
//  TMMOrderBookService.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/22.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation
import Moya
import Hydra

enum TMMOrderBookService {
    case orderAdd(quantity: NSDecimalNumber, price: NSDecimalNumber, side: APIOrderBookSide, processType: APIOrderBookProcessType)
    case marketTop(side: APIOrderBookSide)
    case rate()
    case orders(page: UInt, pageSize: UInt, side: APIOrderBookSide)
    case orderCancel(id: UInt64)
    case marketGraph(hours: UInt)
}

// MARK: - TargetType Protocol Implementation
extension TMMOrderBookService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/orderbook")! }
    var path: String {
        switch self {
        case .orderAdd(_, _, _, _):
            return "/order/add"
        case let .marketTop(side):
            return "/market/top/\(side.rawValue)"
        case .rate():
            return "/rate"
        case let .orders(page, pageSize, side):
            return "/orders/\(page)/\(pageSize)/\(side.rawValue)"
        case .orderCancel(_):
            return "/order/cancel"
        case let .marketGraph(hours):
            return "/market/graph/\(hours)"
        }
    }
    var method: Moya.Method {
        switch self {
        case .orderAdd(_, _, _, _), .orderCancel(_):
            return .post
        case .marketTop(_), .rate(), .orders(_, _, _), .marketGraph(_):
            return .get
        }
    }
    var task: Task {
        switch self {
        case let .orderAdd(quantity, price, side, processType):
            return .requestParameters(parameters: ["quantity": quantity, "price": price, "side": side.rawValue, "process_type": processType.rawValue], encoding: JSONEncoding.default)
        case let .orderCancel(id):
            return .requestParameters(parameters: ["id": id], encoding: JSONEncoding.default)
        case .marketTop(_):
            return .requestParameters(parameters: [:], encoding: URLEncoding.queryString)
        case .rate():
            return .requestParameters(parameters: [:], encoding: URLEncoding.queryString)
        case .orders(_, _, _):
            return .requestParameters(parameters: [:], encoding: URLEncoding.queryString)
        case .marketGraph(_):
            return .requestParameters(parameters: [:], encoding: URLEncoding.queryString)
        }
    }
    var sampleData: Data {
        switch self {
        case .orderAdd(_, _, _, _), .rate(), .orderCancel(_):
            return "{}".utf8Encoded
        case .marketTop(_), .orders(_, _, _), .marketGraph(_):
            return "[]".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}

extension TMMOrderBookService {
    
    static func addOrder(quantity: NSDecimalNumber, price: NSDecimalNumber, side: APIOrderBookSide, processType: APIOrderBookProcessType, provider: MoyaProvider<TMMOrderBookService>) -> Promise<APIResponse> {
        return Promise<APIResponse> (in: .background, { resolve, reject, _ in
            provider.request(
                .orderAdd(quantity: quantity, price: price, side: side, processType: processType)
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
    
    static func cancelOrder(id: UInt64, provider: MoyaProvider<TMMOrderBookService>) -> Promise<APIResponse> {
        return Promise<APIResponse> (in: .background, { resolve, reject, _ in
            provider.request(
                .orderCancel(id: id)
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
    
    static func getRate(provider: MoyaProvider<TMMOrderBookService>) -> Promise<APIOrderBookRate> {
        return Promise<APIOrderBookRate> (in: .background, { resolve, reject, _ in
            provider.request(
                .rate()
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let rate = try response.mapObject(APIOrderBookRate.self)
                        if let errorCode = rate.code {
                            reject(TMMAPIError.error(code: errorCode, msg: rate.message ?? I18n.unknownError.description))
                        } else {
                            resolve(rate)
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
    
    static func getMarketTop(side: APIOrderBookSide, provider: MoyaProvider<TMMOrderBookService>) -> Promise<[APIOrderBook]> {
        return Promise<[APIOrderBook]> (in: .background, { resolve, reject, _ in
            provider.request(
                .marketTop(side: side)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let orders: [APIOrderBook] = try response.mapArray(APIOrderBook.self)
                        resolve(orders)
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
    
    static func getOrders(page: UInt, pageSize: UInt, side: APIOrderBookSide, provider: MoyaProvider<TMMOrderBookService>) -> Promise<[APIOrderBook]> {
        return Promise<[APIOrderBook]> (in: .background, { resolve, reject, _ in
            provider.request(
                .orders(page: page, pageSize: pageSize, side:side)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let orders: [APIOrderBook] = try response.mapArray(APIOrderBook.self)
                        resolve(orders)
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
    
    static func getMarketGraph(hours: UInt, provider: MoyaProvider<TMMOrderBookService>) -> Promise<[APIMarketGraph]> {
        return Promise<[APIMarketGraph]> (in: .background, { resolve, reject, _ in
            provider.request(
                .marketGraph(hours: hours)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let graph: [APIMarketGraph] = try response.mapArray(APIMarketGraph.self)
                        resolve(graph)
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
