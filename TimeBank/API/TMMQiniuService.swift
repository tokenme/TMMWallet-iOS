//
//  TMMQiniuService.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/18.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation
import Moya
import Hydra

enum TMMQiniuService {
    case upToken()
}

// MARK: - TargetType Protocol Implementation
extension TMMQiniuService: TargetType, AccessTokenAuthorizable {
    
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/qiniu")! }
    var path: String {
        switch self {
        case .upToken():
            return "/uptoken"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .upToken():
            return .get
        }
    }
    var task: Task {
        switch self {
        case .upToken():
            return .requestParameters(parameters: [:], encoding: URLEncoding.queryString)
        }
    }
    
    var sampleData: Data {
        switch self {
        case .upToken():
            return "{}".utf8Encoded
        }
    }
    
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}

extension TMMQiniuService {
    
    static func getUpToken(
        provider: MoyaProvider<TMMQiniuService>) -> Promise<APIQiniu> {
        return Promise<APIQiniu> (in: .background, { resolve, reject, _ in
            provider.request(
                .upToken()
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let uptoken = try response.mapObject(APIQiniu.self)
                        if let errorCode = uptoken.code {
                            reject(TMMAPIError.error(code: errorCode, msg: uptoken.message ?? I18n.unknownError.description))
                        } else {
                            resolve(uptoken)
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
