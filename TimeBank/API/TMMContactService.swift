//
//  TMMContactService.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/4.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Moya
import SwiftyUserDefaults
import Hydra

enum TMMContactService {
    case list()
}

// MARK: - TargetType Protocol Implementation
extension TMMContactService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/contact")! }
    var path: String {
        switch self {
        case .list():
            return "/list"
        }
    }
    var method: Moya.Method {
        switch self {
        case .list:
            return .get
        }
    }
    var task: Task {
        switch self {
        case .list():
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
        }
    }
    var sampleData: Data {
        switch self {
        case .list():
            return "[]".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}


extension TMMContactService {
    
    static func getContacts(provider: MoyaProvider<TMMContactService>) -> Promise<[APIContact]> {
        return Promise<[APIContact]> (in: .background, { resolve, reject, _ in
            provider.request(
                .list()
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let contacts: [APIContact] = try response.mapArray(APIContact.self)
                        resolve(contacts)
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
