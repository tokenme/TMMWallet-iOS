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
        }
    }
    var method: Moya.Method {
        switch self {
        case .tmmBalance:
            return .get
        }
    }
    var task: Task {
        switch self {
        case .tmmBalance():
            return .requestParameters(parameters: [:], encoding: URLEncoding.queryString)
        }
    }
    var sampleData: Data {
        switch self {
        case .tmmBalance():
            return "{}".utf8Encoded
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
}
