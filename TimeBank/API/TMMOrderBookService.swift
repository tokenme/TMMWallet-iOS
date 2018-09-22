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
        }
    }
    var method: Moya.Method {
        switch self {
        case .orderAdd(_, _, _, _):
            return .post
        case .marketTop(_):
            return .get
        }
    }
    var task: Task {
        switch self {
        case let .orderAdd(quantity, price, side, processType):
            return .requestParameters(parameters: ["quantity": quantity, "price": price, "side": side.rawValue, "process_type": processType.rawValue], encoding: JSONEncoding.default)
        case .marketTop(_):
            return .requestParameters(parameters: [:], encoding: URLEncoding.queryString)
        }
    }
    var sampleData: Data {
        switch self {
        case .orderAdd(_, _, _, _), .marketTop(_):
            return "{}".utf8Encoded
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
}
