//
//  TMMAppService.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/4.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Moya
import SwiftyUserDefaults
import Hydra

enum TMMAppService {
    case sdks(page: UInt, pageSize: UInt)
}

// MARK: - TargetType Protocol Implementation
extension TMMAppService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/app")! }
    var path: String {
        switch self {
        case let .sdks(page, pageSize):
            return "/sdks/ios/\(page)/\(pageSize)"
        }
    }
    var method: Moya.Method {
        switch self {
        case .sdks:
            return .get
        }
    }
    var task: Task {
        switch self {
        case .sdks(_, _):
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
        }
    }
    var sampleData: Data {
        switch self {
        case .sdks(_, _):
            return "[]".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}


extension TMMAppService {
    
    static func getSdks(page: UInt, pageSize: UInt, provider: MoyaProvider<TMMAppService>) -> Promise<[APIApp]> {
        return Promise<[APIApp]> (in: .background, { resolve, reject, _ in
            provider.request(
                .sdks(page: page, pageSize: pageSize)
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
