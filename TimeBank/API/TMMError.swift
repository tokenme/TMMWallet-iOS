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
    case featureNotAvailable = 402
    case invalidPassword = 409
    case invalidCaptchaError = 408
    case duplicateUser = 202
    case unactivatedUser = 502
    case notEnoughToken = 600
    case dailyBonusCommitted = 601
    case notEnoughPoints = 700
    case invalidMinPoints = 701
    case invalidMinToken = 702
    case notEnoughEth = 800
    case uploadImageError = 900
    case invalidInviteCodeError = 1000
    case maxBindDeviceError = 1100
    case otherBindDeviceError = 1101
    case invalidCdpVendorError = 1200
    case escapeLateError = 1300
    case escapeEarlyError = 1301
}

enum TMMAPIError: Error, CustomStringConvertible {
    case badRequest(msg: String)
    case internalError(msg: String)
    case notFound
    case unauthorized
    case featureNotAvailable
    case invalidPassword
    case invalidCaptchaError
    case duplicateUser
    case unactivatedUser
    case notEnoughToken
    case dailyBonusCommitted
    case notEnoughPoints
    case invalidMinPoints
    case invalidMinToken
    case notEnoughEth
    case uploadImageError
    case invalidInviteCodeError
    case maxBindDeviceError
    case otherBindDeviceError
    case invalidCdpVendorError
    case escapeLateError
    case escapeEarlyError
    case unknown(msg: String)
    case ignore
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .badRequest(let msg): return msg
        case .internalError(let msg): return msg
        case .notFound: return I18n.notFoundError.description
        case .unauthorized: return I18n.unauthorizedError.description
        case .featureNotAvailable: return I18n.featureNotAvailableError.description
        case .invalidPassword: return I18n.invalidPasswordError.description
        case .duplicateUser: return I18n.duplicateUserError.description
        case .unactivatedUser: return I18n.inactivatedUserError.description
        case .invalidCaptchaError: return I18n.invalidCaptchaError.description
        case .notEnoughToken: return I18n.notEnoughTokenError.description
        case .dailyBonusCommitted: return I18n.dailyBonusCommittedError.description
        case .notEnoughPoints: return I18n.notEnoughPointsError.description
        case .invalidMinPoints: return I18n.invalidMinPointsError.description
        case .invalidMinToken: return I18n.invalidMinTMMError.description
        case .notEnoughEth: return I18n.notEnoughETHError.description
        case .uploadImageError: return I18n.uploadImageError.description
        case .invalidInviteCodeError: return I18n.invalidInviteCodeError.description
        case .maxBindDeviceError: return I18n.maxBindDeviceError.description
        case .otherBindDeviceError: return I18n.otherBindDeviceError.description
        case .invalidCdpVendorError: return I18n.invalidCdpVendorError.description
        case .escapeLateError: return I18n.escapeLateError.description
        case .escapeEarlyError: return I18n.escapeEarlyError.description
        case .unknown(let msg): return msg
        case .ignore: return "ignore"
        }
    }
    
    public var localizedDescription: String {
        return self.description
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
            case .featureNotAvailable:
                return TMMAPIError.featureNotAvailable
            case .invalidPassword:
                return TMMAPIError.invalidPassword
            case .duplicateUser:
                return TMMAPIError.duplicateUser
            case .unactivatedUser:
                return TMMAPIError.unactivatedUser
            case .invalidCaptchaError:
                return TMMAPIError.invalidCaptchaError
            case .notEnoughToken:
                return TMMAPIError.notEnoughToken
            case .dailyBonusCommitted:
                return TMMAPIError.dailyBonusCommitted
            case .notEnoughPoints:
                return TMMAPIError.notEnoughPoints
            case .invalidMinPoints:
                return TMMAPIError.invalidMinPoints
            case .invalidMinToken:
                return TMMAPIError.invalidMinToken
            case .uploadImageError:
                return TMMAPIError.uploadImageError
            case .notEnoughEth:
                return TMMAPIError.notEnoughEth
            case .invalidInviteCodeError:
                return TMMAPIError.invalidInviteCodeError
            case .maxBindDeviceError:
                return TMMAPIError.maxBindDeviceError
            case .otherBindDeviceError:
                return TMMAPIError.otherBindDeviceError
            case .invalidCdpVendorError:
                return TMMAPIError.invalidCdpVendorError
            case .escapeLateError:
                return TMMAPIError.escapeLateError
            case .escapeEarlyError:
                return TMMAPIError.escapeEarlyError
            }
        }
        return TMMAPIError.unknown(msg: msg)
    }
}
