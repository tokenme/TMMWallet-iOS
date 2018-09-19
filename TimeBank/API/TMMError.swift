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
    case notEnoughPoints = 700
    case invalidMinPoints = 701
    case notEnoughEth = 800
    case uploadImageError = 900
    case invalidInviteCodeError = 1000
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
    case notEnoughPoints
    case invalidMinPoints
    case notEnoughEth
    case uploadImageError
    case invalidInviteCodeError
    case unknown(msg: String)
    case ignore
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .badRequest(let msg): return msg
        case .internalError(let msg): return msg
        case .notFound: return I18n.notFoundError.description
        case .unauthorized: return I18n.unauthorizedError.description
        case .invalidPassword: return I18n.invalidPasswordError.description
        case .duplicateUser: return I18n.duplicateUserError.description
        case .unactivatedUser: return I18n.inactivatedUserError.description
        case .notEnoughToken: return I18n.notEnoughTokenError.description
        case .notEnoughPoints: return I18n.notEnoughPointsError.description
        case .invalidMinPoints: return I18n.invalidMinPointsError.description
        case .notEnoughEth: return I18n.notEnoughETHError.description
        case .uploadImageError: return I18n.uploadImageError.description
        case .invalidInviteCodeError: return I18n.invalidInviteCodeError.description
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
            case .notEnoughPoints:
                return TMMAPIError.notEnoughPoints
            case .invalidMinPoints:
                return TMMAPIError.invalidMinPoints
            case .uploadImageError:
                return TMMAPIError.uploadImageError
            case .notEnoughEth:
                return TMMAPIError.notEnoughEth
            case .invalidInviteCodeError:
                return TMMAPIError.invalidInviteCodeError
            }
        }
        return TMMAPIError.unknown(msg: msg)
    }
}
