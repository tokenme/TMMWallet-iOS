//
//  i18n.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/3.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation

enum I18n: CustomStringConvertible {
    case error
    case close
    case unknownError
    case notFoundError
    case unauthorizedError
    case invalidPasswordError
    case duplicateUserError
    case inactivatedUserError
    case invalidPhoneNumber
    case emptyPassword
    case emptyRepassword
    case emptyVerifyCode
    case passwordNotMatch
    case suggestOptions
    case chooseCountry
    case password
    case repassword
    case verifyCode
    case sent
    case resend
    case sending
    
    var description : String {
        switch self {
        case .close:
            return NSLocalizedString("Close", comment: "Close")
        case .error:
            return NSLocalizedString("Error", comment: "Error")
        case .unknownError:
            return NSLocalizedString("UnknownError", comment: "Unknown Error")
        case .notFoundError:
            return NSLocalizedString("NotFoundError", comment: "Not Found Request")
        case .unauthorizedError:
            return NSLocalizedString("UnauthorizedError", comment: "Unauthorized")
        case .invalidPasswordError:
            return NSLocalizedString("InvalidPasswordError", comment: "Invalid Password")
        case .duplicateUserError:
            return NSLocalizedString("DuplicateUserError", comment: "User already exists!")
        case .inactivatedUserError:
            return NSLocalizedString("InactivatedUserError", comment: "User not activated")
        case .invalidPhoneNumber:
            return NSLocalizedString("InvalidPhoneNumber", comment: "Invalid phone number")
        case .emptyPassword:
            return NSLocalizedString("EmptyPassword", comment: "Password must be input")
        case .emptyRepassword:
            return NSLocalizedString("EmptyRepassword", comment: "Repassword must be input")
        case .emptyVerifyCode:
            return NSLocalizedString("EmptyVerifyCode", comment: "Verify code must be input")
        case .passwordNotMatch:
            return NSLocalizedString("PasswordNotMatch", comment: "Password not match")
        case .suggestOptions:
            return NSLocalizedString("SuggestOptions", comment: "Suggested Options")
        case .chooseCountry:
            return NSLocalizedString("ChooseCountry", comment: "Choose Country")
        case .password:
            return NSLocalizedString("Password", comment: "Password")
        case .repassword:
            return NSLocalizedString("Repassword", comment: "Repassword")
        case .verifyCode:
            return NSLocalizedString("VerifyCode", comment: "Verify code")
        case .sent:
            return NSLocalizedString("Sent", comment: "Sent")
        case .resend:
            return NSLocalizedString("Resend", comment: "Resend")
        case .sending:
            return NSLocalizedString("Sending", comment: "Sending")
        }
    }
}
