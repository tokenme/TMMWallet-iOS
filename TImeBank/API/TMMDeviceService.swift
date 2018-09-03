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
        }
    }
    var method: Moya.Method {
        switch self {
        case .bind:
            return .post
        }
    }
    var task: Task {
        switch self {
        case let .bind(idfa):
            return .requestParameters(parameters: ["idfa": idfa], encoding: JSONEncoding.default)
        }
    }
    var sampleData: Data {
        switch self {
        case .bind(_):
            return "ok".utf8Encoded
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
}
