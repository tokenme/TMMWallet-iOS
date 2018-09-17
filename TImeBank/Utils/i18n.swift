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
    case notEnoughTokenError
    case notEnoughPointsError
    case invalidMinPointsError
    case notEnoughETHError
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
    case ethWallet
    case assets
    case copyWalletAddress
    case receive
    case send
    case receiveQRCode
    case needMinGasError
    case balance
    case transferAmount
    case to
    case walletAddress
    case emptyTokenAmount
    case exceedTokenAmount
    case emptyWalletAddress
    case invalidWalletAddress
    case sdkApps
    case miningApps
    case moreApps
    case exchangeRecords
    case install
    case installed
    case exchangeTMM
    case exchangePoint
    case changeTo
    case txPending
    case txSuccess
    case txFailed
    case pointsAmount
    case currentPointsTMMExchangeRate
    case emptyChangePoints
    case exceedChangePoints
    case pointsTMMChangeAmount
    case exchange
    case viewTransaction
    case newTransactionTitle
    case newTransactionDesc
    case earnPointsTasks
    case appTasks
    case shareTasks
    case earn
    case minusPoints
    case pointsPerViewer
    case maxBonus
    case points
    case view
    case times
    case pointsPerInstall
    case appTaskSuccess
    case appTaskFailed
    case taskRecords
    case emptyTaskRecordsTitle
    case emptyTaskRecordsDesc
    case emptyAppTasksTitle
    case emptyAppTasksDesc
    case emptyShareTasksTitle
    case emptyShareTasksDesc
    
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
        case .notEnoughTokenError:
            return NSLocalizedString("NotEnoughTokenError", comment: "notEnoughTokenError")
        case .notEnoughPointsError:
            return NSLocalizedString("NotEnoughPointsError", comment: "notEnoughPointsError")
        case .invalidMinPointsError:
            return NSLocalizedString("InvalidMinPointsError", comment: "invalidMinPoints")
        case .notEnoughETHError:
            return NSLocalizedString("NotEnoughETHError", comment: "notEnoughETHError")
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
        case .ethWallet:
            return NSLocalizedString("ETHWallet", comment: "ETH Wallet")
        case .assets:
            return NSLocalizedString("Assets", comment: "Assets")
        case .copyWalletAddress:
            return NSLocalizedString("CopyWalletAddress", comment: "Copy Wallet Address")
        case .receive:
            return NSLocalizedString("Receive", comment: "Receive")
        case .send:
            return NSLocalizedString("Send", comment: "Send")
        case .receiveQRCode:
            return NSLocalizedString("ReceiveQRCode", comment: "Receive QRCode")
        case .needMinGasError:
            return NSLocalizedString("NeedMinGasError", comment: "NeedMinGasError")
        case .balance:
            return NSLocalizedString("Balance", comment: "Balance")
        case .transferAmount:
            return NSLocalizedString("TransferAmount", comment: "Transfer Amount")
        case .to:
            return NSLocalizedString("To", comment: "To")
        case .walletAddress:
            return NSLocalizedString("WalletAddress", comment: "Wallet Address")
        case .emptyTokenAmount:
            return NSLocalizedString("EmptyTokenAmount", comment: "EmptyTokenAmount")
        case .exceedTokenAmount:
            return NSLocalizedString("ExceedTokenAmount", comment: "ExceedTokenAmount")
        case .emptyWalletAddress:
            return NSLocalizedString("EmptyWalletAddress", comment: "EmptyWalletAddress")
        case .invalidWalletAddress:
            return NSLocalizedString("InvalidWalletAddress", comment: "InvalidWalletAddress")
        case .sdkApps:
            return NSLocalizedString("SDKApps", comment: "Minable Apps")
        case .miningApps:
            return NSLocalizedString("MiningApps", comment: "Mining Apps")
        case .moreApps:
            return NSLocalizedString("MoreApps", comment: "More Apps")
        case .exchangeRecords:
            return NSLocalizedString("ExchangeRecords", comment: "Exchange Records")
        case .install:
            return NSLocalizedString("Install", comment: "Install")
        case .installed:
            return NSLocalizedString("Installed", comment: "Installed")
        case .exchangeTMM:
            return NSLocalizedString("ExchangeTMM", comment: "Exchange TMM")
        case .exchangePoint:
            return NSLocalizedString("ExchangePoint", comment: "Exchange Points")
        case .pointsAmount:
            return NSLocalizedString("PointsAmount", comment: "Points Amount")
        case .currentPointsTMMExchangeRate:
            return NSLocalizedString("CurrentPointsTMMExchangeRate", comment: "CurrentPointsTMMExchangeRate")
        case .emptyChangePoints:
            return NSLocalizedString("EmptyChangePoints", comment: "Empty change points")
        case .exceedChangePoints:
            return NSLocalizedString("ExceedChangePoints", comment: "Exceeded max change points")
        case .pointsTMMChangeAmount:
            return NSLocalizedString("PointsTMMChangeAmount", comment: "PointsTMMChangeAmount")
        case .exchange:
            return NSLocalizedString("Exchange", comment: "Change")
        case .viewTransaction:
            return NSLocalizedString("ViewTransaction", comment: "View Transaction")
        case .newTransactionTitle:
            return NSLocalizedString("NewTransactionTitle", comment: "New Transaction")
        case .newTransactionDesc:
            return NSLocalizedString("NewTransactionDesc", comment: "Transaction Receipt")
        case .changeTo:
            return NSLocalizedString("ChangeTo", comment: "Change to")
        case .txPending:
            return NSLocalizedString("TxPending", comment: "Pending")
        case .txSuccess:
            return NSLocalizedString("TxSuccess", comment: "Success")
        case .txFailed:
            return NSLocalizedString("TxFailed", comment: "Failed")
        case .earnPointsTasks:
            return NSLocalizedString("EarnPointsTasks", comment: "EarnPointsTasks")
        case .appTasks:
            return NSLocalizedString("AppTasks", comment: "App Tasks")
        case .shareTasks:
            return NSLocalizedString("ShareTasks", comment: "Share Tasks")
        case .earn:
            return NSLocalizedString("Earn", comment: "Earn")
        case .minusPoints:
            return NSLocalizedString("MinusPoints", comment: "Minus Points")
        case .pointsPerViewer:
            return NSLocalizedString("PointsPerViewer", comment: "Points/Viewer")
        case .maxBonus:
            return NSLocalizedString("MaxBonus", comment: "Max bonus")
        case .points:
            return NSLocalizedString("Points", comment: "Points")
        case .view:
            return NSLocalizedString("View", comment: "View")
        case .times:
            return NSLocalizedString("Times", comment: "times")
        case .pointsPerInstall:
            return NSLocalizedString("PointsPerInstall", comment: "Points/Install")
        case .appTaskSuccess:
            return NSLocalizedString("AppTaskSuccess", comment: "appTaskSuccess")
        case .appTaskFailed:
            return NSLocalizedString("AppTaskFailed", comment: "appTaskFailed")
        case .taskRecords:
            return NSLocalizedString("TaskRecords", comment: "Task Records")
        case .emptyTaskRecordsTitle:
            return NSLocalizedString("EmptyTaskRecordsTitle", comment: "EmptyTaskRecordsTitle")
        case .emptyTaskRecordsDesc:
            return NSLocalizedString("EmptyTaskRecordsDesc", comment: "EmptyTaskRecordsDesc")
        case .emptyAppTasksTitle:
            return NSLocalizedString("EmptyAppTasksTitle", comment: "EmptyAppTasksTitle")
        case .emptyAppTasksDesc:
            return NSLocalizedString("EmptyAppTasksDesc", comment: "EmptyAppTasksDesc")
        case .emptyShareTasksTitle:
            return NSLocalizedString("EmptyShareTasksTitle", comment: "EmptyShareTasksTitle")
        case .emptyShareTasksDesc:
            return NSLocalizedString("EmptyShareTasksDesc", comment: "EmptyShareTasksDesc")
        }
    }
}
