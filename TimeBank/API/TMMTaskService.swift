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
    case shares(idfa: String, page: UInt, pageSize: UInt, mineOnly: Bool)
    case apps(idfa: String, page: UInt, pageSize: UInt, mineOnly: Bool)
    case install(idfa: String, bundleId: String, taskId: UInt64, status: Int8)
    case appsCheck(idfa: String)
    case records(page: UInt, pageSize: UInt)
    case shareAdd(link: String, title: String, summary: String, image: String, points: NSDecimalNumber, bonus: NSDecimalNumber, maxViewers: UInt)
    case appAdd(name: String, bundleId: String, points: NSDecimalNumber, bonus: NSDecimalNumber)
    case shareUpdate(id: UInt64, link: String, title: String, summary: String, image: String, points: NSDecimalNumber, bonus: NSDecimalNumber, maxViewers: UInt, onlineStatus: APITaskOnlineStatus)
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
        case .shares(_, _, _, _):
            return "/shares"
        case .apps(_, _, _, _):
            return "/apps"
        case .install(_, _, _, _):
            return "/app/install"
        case .appsCheck(_):
            return "/apps/check"
        case .records(_, _):
            return "/records"
        case .shareAdd(_, _, _, _, _, _, _):
            return "/share/add"
        case .shareUpdate(_, _, _, _, _, _, _, _, _):
            return "/share/update"
        case .appAdd(_, _, _, _):
            return "/app/add"
        }
    }
    var method: Moya.Method {
        switch self {
        case .shares, .apps, .appsCheck, .records:
            return .get
        case .install, .shareAdd, .appAdd, .shareUpdate:
            return .post
        }
    }
    var task: Task {
        switch self {
        case let .shares(idfa, page, pageSize, mineOnly):
            return .requestParameters(parameters: ["idfa": idfa, "platform": APIPlatform.iOS.rawValue, "page": page, "page_size": pageSize, "mine_only": mineOnly], encoding: URLEncoding.default)
        case let .apps(idfa, page, pageSize, mineOnly):
            return .requestParameters(parameters: ["idfa": idfa, "platform": APIPlatform.iOS.rawValue, "page": page, "page_size": pageSize, "mine_only": mineOnly], encoding: URLEncoding.default)
        case let .install(idfa, bundleId, taskId, status):
            return .requestParameters(parameters: ["idfa": idfa, "platform": APIPlatform.iOS.rawValue, "bundle_id": bundleId, "task_id": taskId, "status": status], encoding: JSONEncoding.default)
        case let .appsCheck(idfa):
            return .requestParameters(parameters: ["idfa": idfa, "platform": APIPlatform.iOS.rawValue], encoding: URLEncoding.default)
        case let .records(page, pageSize):
            return .requestParameters(parameters: ["page": page, "page_size": pageSize], encoding: URLEncoding.default)
        case let .shareAdd(link, title, summary, image, points, bonus, maxViewers):
            let params: [String:Any] = ["link": link, "title": title, "summary": summary, "image": image, "points": points, "bonus": bonus, "max_viewers": maxViewers]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case let .shareUpdate(id, link, title, summary, image, points, bonus, maxViewers, onlineStatus):
            var params: [String:Any] = ["id": id]
            if !link.isEmpty {
                params["link"] = link
            }
            if !title.isEmpty {
                params["title"] = title
            }
            if !summary.isEmpty {
                params["summary"] = summary
            }
            if !image.isEmpty {
                params["image"] = image
            }
            if points > 0 {
                params["points"] = points
            }
            if bonus > 0 {
                params["bonus"] = bonus
            }
            if maxViewers > 0 {
                params["max_viewers"] = maxViewers
            }
            if onlineStatus != .unknown {
                params["online_status"] = onlineStatus.rawValue
            }
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case let .appAdd(name, bundleId, points, bonus):
            let params: [String:Any] = ["platform": APIPlatform.iOS.rawValue, "name": name, "bundle_id": bundleId, "points": points, "bonus": bonus]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        }
    }
    var sampleData: Data {
        switch self {
        case .shares(_, _, _, _), .apps(_, _, _, _), .appsCheck(_), .records(_, _):
            return "[]".utf8Encoded
        case .install(_, _, _, _), .shareAdd(_, _, _, _, _, _, _), .shareUpdate(_, _, _, _, _, _, _, _, _), .appAdd(_, _, _, _):
            return "{}".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}


extension TMMTaskService {
    
    static func getShares(idfa: String, page: UInt, pageSize: UInt, mineOnly: Bool, provider: MoyaProvider<TMMTaskService>) -> Promise<[APIShareTask]> {
        return Promise<[APIShareTask]> (in: .background, { resolve, reject, _ in
            provider.request(
                .shares(idfa: idfa, page: page, pageSize: pageSize, mineOnly: mineOnly)
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
    
    static func getApps(idfa: String, page: UInt, pageSize: UInt, mineOnly: Bool, provider: MoyaProvider<TMMTaskService>) -> Promise<[APIAppTask]> {
        return Promise<[APIAppTask]> (in: .background, { resolve, reject, _ in
            provider.request(
                .apps(idfa: idfa, page: page, pageSize: pageSize, mineOnly: mineOnly)
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
    
    static func getRecords(page: UInt, pageSize: UInt, provider: MoyaProvider<TMMTaskService>) -> Promise<[APITaskRecord]> {
        return Promise<[APITaskRecord]> (in: .background, { resolve, reject, _ in
            provider.request(
                .records(page: page, pageSize: pageSize)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let records: [APITaskRecord] = try response.mapArray(APITaskRecord.self)
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
    
    static func addShareTask(link: String, title: String, summary: String, image: String, points: NSDecimalNumber, bonus: NSDecimalNumber, maxViewers: UInt, provider: MoyaProvider<TMMTaskService>) -> Promise<APIShareTask> {
        return Promise<APIShareTask> (in: .background, { resolve, reject, _ in
            provider.request(
                .shareAdd(link: link, title: title, summary: summary, image: image, points: points, bonus: bonus, maxViewers: maxViewers)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let task = try response.mapObject(APIShareTask.self)
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
    
    static func updateShareTask(id: UInt64, link: String, title: String, summary: String, image: String, points: NSDecimalNumber, bonus: NSDecimalNumber, maxViewers: UInt, onlineStatus: APITaskOnlineStatus, provider: MoyaProvider<TMMTaskService>) -> Promise<APIShareTask> {
        return Promise<APIShareTask> (in: .background, { resolve, reject, _ in
            provider.request(
                .shareUpdate(id: id, link: link, title: title, summary: summary, image: image, points: points, bonus: bonus, maxViewers: maxViewers, onlineStatus: onlineStatus)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let task = try response.mapObject(APIShareTask.self)
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
    
    static func addAppTask(name: String, bundleId: String, points: NSDecimalNumber, bonus: NSDecimalNumber, provider: MoyaProvider<TMMTaskService>) -> Promise<APIAppTask> {
        return Promise<APIAppTask> (in: .background, { resolve, reject, _ in
            provider.request(
                .appAdd(name: name, bundleId: bundleId, points: points, bonus: bonus)
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
}
