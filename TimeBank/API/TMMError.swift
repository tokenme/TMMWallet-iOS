//
//  UCAPIGateway.swift
//  ucoin
//
//  Created by Syd on 2018/6/15.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

enum TMMAPIResponseType: Int {
    case badRequest = 400
    case internalError = 500
    case notFound = 404
    case unauthorized = 401
    case invalidPassword = 409
    case duplicateUser = 202
    case unactivatedUser = 502
    case notEnoughToken = 600
    case notEnoughTokenProduct = 601
    case notEnoughTokenTask = 700
    case duplicateEvidence = 701
    case tokenUnderConstruction = 800
    case productUnderConstruction = 801
}

enum TMMAPIError: Error, CustomStringConvertible {
    case badRequest(msg: String)
    case internalError(msg: String)
    case notFound
    case unauthorized
    case invalidPassword
    case duplicateUser
    case unactivatedUser
    case notEnoughToken
    case notEnoughTokenProduct
    case notEnoughTokenTask
    case duplicateEvidence
    case tokenUnderConstruction
    case productUnderConstruction
    case unknown(msg: String)
    case ignore
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .badRequest(let msg): return msg
        case .internalError(let msg): return msg
        case .notFound: return "请求不存在"
        case .unauthorized: return "用户未授权"
        case .invalidPassword: return "密码错误"
        case .duplicateUser: return "用户已经注册"
        case .unactivatedUser: return "用户未激活"
        case .notEnoughToken: return "钱包代币不足"
        case .notEnoughTokenProduct: return "已售罄"
        case .notEnoughTokenTask: return "超过参与人数上限"
        case .duplicateEvidence: return "请勿重复提交证明"
        case .tokenUnderConstruction: return "代币未创建完成，请等待"
        case .productUnderConstruction: return "代币权益未创建完成，请等待"
        case .unknown(let msg): return msg
        case .ignore: return "ignore"
        }
    }
}

extension TMMAPIError {
    static func error(code: Int, msg: String) -> TMMAPIError {
        if let errorType = TMMAPIResponseType(rawValue: code) {
            switch errorType {
            case .badRequest:
                return TMMAPIError.badRequest(msg: msg)
            case .internalError:
                return TMMAPIError.internalError(msg: msg)
            case .notFound:
                return TMMAPIError.notFound
            case .unauthorized:
                return TMMAPIError.unauthorized
            case .invalidPassword:
                return TMMAPIError.invalidPassword
            case .duplicateUser:
                return TMMAPIError.duplicateUser
            case .unactivatedUser:
                return TMMAPIError.unactivatedUser
            case .notEnoughToken:
                return TMMAPIError.notEnoughToken
            case .notEnoughTokenProduct:
                return TMMAPIError.notEnoughTokenProduct
            case .notEnoughTokenTask:
                return TMMAPIError.notEnoughTokenTask
            case .duplicateEvidence:
                return TMMAPIError.duplicateEvidence
            case .tokenUnderConstruction:
                return TMMAPIError.tokenUnderConstruction
            case .productUnderConstruction:
                return TMMAPIError.productUnderConstruction
            }
        }
        return TMMAPIError.unknown(msg: msg)
    }
}
