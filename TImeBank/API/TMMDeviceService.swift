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
    case bind(device: [String: Any])
    case unbind(id: String)
    case list()
    case apps(deviceId: String)
    case info(deviceId: String)
    case pushToken(idfa: String, token: String)
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
        case .unbind(_):
            return "/unbind"
        case .list():
            return "/list"
        case let .apps(deviceId):
            return "/apps/\(deviceId)"
        case let .info(deviceId):
            return "/get/\(deviceId)"
        case .pushToken(_, _):
            return "/push-token"
        }
    }
    var method: Moya.Method {
        switch self {
        case .bind, .unbind, .pushToken:
            return .post
        case .list, .apps, .info:
            return .get
        }
    }
    var task: Task {
        switch self {
        case let .bind(device):
            return .requestParameters(parameters: device, encoding: JSONEncoding.default)
        case let .unbind(id):
            return .requestParameters(parameters: ["id": id], encoding: JSONEncoding.default)
        case .list():
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
        case .apps(_):
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
        case .info(_):
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
        case let .pushToken(idfa, token):
            return .requestParameters(parameters: ["idfa": idfa, "token": token], encoding: JSONEncoding.default)
        }
    }
    var sampleData: Data {
        switch self {
        case .bind(_), .unbind(_), .pushToken(_, _):
            return "ok".utf8Encoded
        case .list(), .apps(_), .info(_):
            return "[]".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}


extension TMMDeviceService {
    
    static func bindUser(device: [String: Any], provider: MoyaProvider<TMMDeviceService>) -> Promise<APIResponse> {
        return Promise<APIResponse> (in: .background, { resolve, reject, _ in
            provider.request(
                .bind(device: device)
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
    
    static func unbindUser(id: String, provider: MoyaProvider<TMMDeviceService>) -> Promise<APIResponse> {
        return Promise<APIResponse> (in: .background, { resolve, reject, _ in
            provider.request(
                .unbind(id: id)
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
    
    static func getInfo(deviceId: String, provider: MoyaProvider<TMMDeviceService>) -> Promise<APIDevice> {
        return Promise<APIDevice> (in: .background, { resolve, reject, _ in
            provider.request(
                .info(deviceId: deviceId)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let device = try response.mapObject(APIDevice.self)
                        if let errorCode = device.code {
                            reject(TMMAPIError.error(code: errorCode, msg: device.message ?? I18n.unknownError.description))
                        } else {
                            resolve(device)
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
    
    static func savePushToken(idfa: String, token: String, provider: MoyaProvider<TMMDeviceService>) -> Promise<APIResponse> {
        return Promise<APIResponse> (in: .background, { resolve, reject, _ in
            provider.request(
                .pushToken(idfa: idfa, token: token)
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
