//
//  TMMDeviceService.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/3.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Moya
import SwiftyUserDefaults
import Hydra

enum TMMDeviceService {
    case bind(idfa: String)
    case list()
    case apps(deviceId: String)
}

// MARK: - TargetType Protocol Implementation
extension TMMDeviceService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/device")! }
    var path: String {
        switch self {
        case .bind(_):
            return "/bind"
        case .list():
            return "/list"
        case let .apps(deviceId):
            return "/apps/\(deviceId)"
        }
    }
    var method: Moya.Method {
        switch self {
        case .bind:
            return .post
        case .list, .apps:
            return .get
        }
    }
    var task: Task {
        switch self {
        case let .bind(idfa):
            return .requestParameters(parameters: ["idfa": idfa], encoding: JSONEncoding.default)
        case .list():
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
        case .apps(_):
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
        }
    }
    var sampleData: Data {
        switch self {
        case .bind(_):
            return "ok".utf8Encoded
        case .list(), .apps(_):
            return "[]".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}


extension TMMDeviceService {
    
    static func bindUser(idfa: String, provider: MoyaProvider<TMMDeviceService>) -> Promise<APIResponse> {
        return Promise<APIResponse> (in: .background, { resolve, reject, _ in
            provider.request(
                .bind(idfa: idfa)
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
    
    static func getDevices(provider: MoyaProvider<TMMDeviceService>) -> Promise<[APIDevice]> {
        return Promise<[APIDevice]> (in: .background, { resolve, reject, _ in
            provider.request(
                .list()
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let devices: [APIDevice] = try response.mapArray(APIDevice.self)
                        resolve(devices)
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
    
    static func getApps(deviceId: String, provider: MoyaProvider<TMMDeviceService>) -> Promise<[APIApp]> {
        return Promise<[APIApp]> (in: .background, { resolve, reject, _ in
            provider.request(
                .apps(deviceId: deviceId)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let apps: [APIApp] = try response.mapArray(APIApp.self)
                        resolve(apps)
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
