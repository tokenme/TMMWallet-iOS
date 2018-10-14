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
    case assets(currency: String)
    case transactions(address: String, page: UInt, pageSize: UInt)
    case transfer(token: String, amount: NSDecimalNumber, to: String)
    case info(address: String)
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
        case .assets(_):
            return "/assets"
        case let .transactions(address, page, pageSize):
            return "/transactions/\(address)/\(page)/\(pageSize)"
        case .transfer(_, _, _):
            return "/transfer"
        case let .info(address):
            return "/info/\(address)"
        }
    }
    var method: Moya.Method {
        switch self {
        case .tmmBalance, .assets, .transactions, .info:
            return .get
        case .transfer:
            return .post
        }
    }
    var task: Task {
        switch self {
        case .tmmBalance():
            return .requestParameters(parameters: [:], encoding: URLEncoding.queryString)
        case let .assets(currency):
            return .requestParameters(parameters: ["currency": currency], encoding: URLEncoding.queryString)
        case .transactions(_, _, _):
            return .requestParameters(parameters: [:], encoding: URLEncoding.queryString)
        case let .transfer(token, amount, to):
            return .requestParameters(parameters: ["token": token, "amount": amount, "to": to], encoding: JSONEncoding.default)
        case .info(_):
            return .requestParameters(parameters: [:], encoding: URLEncoding.queryString)
        }
    }
    var sampleData: Data {
        switch self {
        case .tmmBalance(), .transfer(_, _, _), .info(_):
            return "{}".utf8Encoded
        case .assets(_), .transactions(_, _, _):
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
    
    static func getAssets(currency: String, provider: MoyaProvider<TMMTokenService>) -> Promise<[APIToken]> {
        return Promise<[APIToken]> (in: .background, { resolve, reject, _ in
            provider.request(
                .assets(currency: currency)
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
    
    static func getTransactions(address: String, page: UInt, pageSize: UInt, provider: MoyaProvider<TMMTokenService>) -> Promise<[APITransaction]> {
        return Promise<[APITransaction]> (in: .background, { resolve, reject, _ in
            provider.request(
                .transactions(address: address, page: page, pageSize: pageSize)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let txs: [APITransaction] = try response.mapArray(APITransaction.self)
                        resolve(txs)
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
    
    static func transferToken(token: String, amount: NSDecimalNumber, to: String, provider: MoyaProvider<TMMTokenService>) -> Promise<APITransaction> {
        return Promise<APITransaction> (in: .background, { resolve, reject, _ in
            provider.request(
                .transfer(token: token, amount: amount, to: to)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let resp = try response.mapObject(APITransaction.self)
                        if let errorCode = resp.code {
                            if errorCode == TMMAPIResponseType.notEnoughEth.rawValue {
                                do {
                                    let minETH = try response.mapObject(APIMinETH.self)
                                    let formatter = NumberFormatter()
                                    formatter.maximumFractionDigits = 6
                                    formatter.groupingSeparator = "";
                                    formatter.numberStyle = NumberFormatter.Style.decimal
                                    let minETHStr = formatter.string(from: minETH.minETH)!
                                    let message = String(format: I18n.notEnoughETHError.description, minETHStr)
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
    
    static func getInfo(address: String, provider: MoyaProvider<TMMTokenService>) -> Promise<APIToken> {
        return Promise<APIToken> (in: .background, { resolve, reject, _ in
            provider.request(
                .info(address: address)
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
}
