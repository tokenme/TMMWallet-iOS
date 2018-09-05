//
//  TMMTaskService.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/4.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Moya
import SwiftyUserDefaults
import Hydra

enum TMMTaskService {
    case shares(idfa: String, page: UInt, pageSize: UInt)
    case apps(idfa: String, page: UInt, pageSize: UInt)
    case install(idfa: String, bundleId: String, taskId: UInt64, status: Int8)
    case appsCheck(idfa: String)
}

// MARK: - TargetType Protocol Implementation
extension TMMTaskService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/task")! }
    var path: String {
        switch self {
        case .shares(_, _, _):
            return "/shares"
        case .apps(_, _, _):
            return "/apps"
        case .install(_, _, _, _):
            return "/app/install"
        case .appsCheck(_):
            return "/apps/check"
        }
    }
    var method: Moya.Method {
        switch self {
        case .shares, .apps, .appsCheck:
            return .get
        case .install:
            return .post
        }
    }
    var task: Task {
        switch self {
        case let .shares(idfa, page, pageSize):
            return .requestParameters(parameters: ["idfa": idfa, "platform": APIPlatform.iOS.rawValue, "page": page, "page_size": pageSize], encoding: URLEncoding.default)
        case let .apps(idfa, page, pageSize):
            return .requestParameters(parameters: ["idfa": idfa, "platform": APIPlatform.iOS.rawValue, "page": page, "page_size": pageSize], encoding: URLEncoding.default)
        case let .install(idfa, bundleId, taskId, status):
            return .requestParameters(parameters: ["idfa": idfa, "platform": APIPlatform.iOS.rawValue, "bundle_id": bundleId, "task_id": taskId, "status": status], encoding: JSONEncoding.default)
        case let .appsCheck(idfa):
            return .requestParameters(parameters: ["idfa": idfa, "platform": APIPlatform.iOS.rawValue], encoding: URLEncoding.default)
        }
    }
    var sampleData: Data {
        switch self {
        case .shares(_, _, _), .apps(_, _, _), .appsCheck(_):
            return "[]".utf8Encoded
        case .install(_, _, _, _):
            return "{}".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}


extension TMMTaskService {
    
    static func getShares(idfa: String, page: UInt, pageSize: UInt, provider: MoyaProvider<TMMTaskService>) -> Promise<[APIShareTask]> {
        return Promise<[APIShareTask]> (in: .background, { resolve, reject, _ in
            provider.request(
                .shares(idfa: idfa, page: page, pageSize: pageSize)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let tasks: [APIShareTask] = try response.mapArray(APIShareTask.self)
                        resolve(tasks)
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
    
    static func getApps(idfa: String, page: UInt, pageSize: UInt, provider: MoyaProvider<TMMTaskService>) -> Promise<[APIAppTask]> {
        return Promise<[APIAppTask]> (in: .background, { resolve, reject, _ in
            provider.request(
                .apps(idfa: idfa, page: page, pageSize: pageSize)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let tasks: [APIAppTask] = try response.mapArray(APIAppTask.self)
                        resolve(tasks)
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
    
    static func appInstall(idfa: String, bundleId: String, taskId: UInt64, status: Int8, provider: MoyaProvider<TMMTaskService>) -> Promise<APIAppTask> {
        return Promise<APIAppTask> (in: .background, { resolve, reject, _ in
            provider.request(
                .install(idfa: idfa, bundleId: bundleId, taskId: taskId, status: status)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let task = try response.mapObject(APIAppTask.self)
                        if let errorCode = task.code {
                            reject(TMMAPIError.error(code: errorCode, msg: task.message ?? I18n.unknownError.description))
                        } else {
                            resolve(task)
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
    
    static func getAppsCheck(idfa: String, provider: MoyaProvider<TMMTaskService>) -> Promise<[APIAppTask]> {
        return Promise<[APIAppTask]> (in: .background, { resolve, reject, _ in
            provider.request(
                .appsCheck(idfa: idfa)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let tasks: [APIAppTask] = try response.mapArray(APIAppTask.self)
                        resolve(tasks)
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
