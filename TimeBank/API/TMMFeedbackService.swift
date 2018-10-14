//
//  TMMFeedbackService.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/14.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Moya
import SwiftyUserDefaults
import Hydra

enum TMMFeedbackService {
    case add(message: String, image: String?, attachements: [String: String])
    case list()
}

// MARK: - TargetType Protocol Implementation
extension TMMFeedbackService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/feedback")! }
    var path: String {
        switch self {
        case .add(_, _, _):
            return "/add"
        case .list():
            return "/list"
        }
    }
    var method: Moya.Method {
        switch self {
        case .add(_, _, _):
            return .post
        case .list():
            return .get
        }
    }
    
    var task: Task {
        switch self {
        case .list():
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
        case let .add(message, image, attachements):
            var params: [String: Any] = ["message": message]
            if image != nil {
                params["image"] = image
            }
            var fields:[String] = []
            for (title, value) in attachements {
                fields.append("\(title)\t\(value)")
            }
            params["attachements"] = fields.joined(separator: "\n")
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        }
    }
    
    var sampleData: Data {
        switch self {
        case .add(_, _, _):
            return "{}".utf8Encoded
        case .list():
            return "[]".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}


extension TMMFeedbackService {
    
    static func add(message: String, image: String?, attachements: [String: String], provider: MoyaProvider<TMMFeedbackService>) -> Promise<APIResponse> {
        return Promise<APIResponse> (in: .background, { resolve, reject, _ in
            provider.request(
                .add(message: message, image:image, attachements: attachements)
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
    
    static func getList(provider: MoyaProvider<TMMFeedbackService>) -> Promise<[APIFeedback]> {
        return Promise<[APIFeedback]> (in: .background, { resolve, reject, _ in
            provider.request(
                .list()
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let feedbacks: [APIFeedback] = try response.mapArray(APIFeedback.self)
                        resolve(feedbacks)
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
