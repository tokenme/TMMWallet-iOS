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
    case shares(deviceId: String, page: UInt, pageSize: UInt)
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
        }
    }
    var method: Moya.Method {
        switch self {
        case .shares:
            return .get
        }
    }
    var task: Task {
        switch self {
        case let .shares(deviceId, page, pageSize):
            return .requestParameters(parameters: ["device_id": deviceId, "page": page, "page_size": pageSize], encoding: URLEncoding.default)
        }
    }
    var sampleData: Data {
        switch self {
        case .shares(_, _, _):
            return "[]".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}


extension TMMTaskService {
    
    static func getShares(deviceId: String, page: UInt, pageSize: UInt, provider: MoyaProvider<TMMTaskService>) -> Promise<[APIShareTask]> {
        return Promise<[APIShareTask]> (in: .background, { resolve, reject, _ in
            provider.request(
                .shares(deviceId: deviceId, page: page, pageSize: pageSize)
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
}
