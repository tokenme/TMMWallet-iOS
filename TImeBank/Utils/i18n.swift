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
    case success
    case alert
    case confirm
    case close
    case shareSuccess
    case more
    case unknownError
    case notFoundError
    case unauthorizedError
    case invalidPasswordError
    case duplicateUserError
    case inactivatedUserError
    case invalidCaptchaError
    case notEnoughTokenError
    case notEnoughPointsError
    case invalidMinPointsError
    case invalidMinTMMError
    case notEnoughETHError
    case uploadImageError
    case maxQuerySchemeError
    case invalidInviteCodeError
    case maxBindDeviceError
    case otherBindDeviceError
    case invalidCdpVendorError
    case exchangeNotAvailableInYourCountryError
    case featureNotAvailableError
    case dailyBonusCommittedError
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
    case refresh
    case copy
    case submit
    case sdkApps
    case miningApps
    case moreApps
    case exchangeRecords
    case install
    case installed
    case exchangeTMM
    case exchangePoint
    case changeTo
    case toTBC
    case toPoints
    case toMobileData
    case txPending
    case txSuccess
    case txFailed
    case emptyExchangeRecordsTitle
    case emptyExchangeRecordsDesc
    case emptyTransactionsTitle
    case emptyTransactionsDesc
    case bind
    case unbindDeviceExplain
    case unbind
    case confirmUnbind
    case withdraw
    case currentTMMRedeemRate
    case TMMAmount
    case TMMWithdrawAmount
    case emptyWithdrawTMM
    case withdrawSuccessMsg
    case dailyReward
    case xDay
    case dailyBonusSuccessMsg
    case pointsAmount
    case currentPointsTMMExchangeRate
    case emptyChangePoints
    case redeemCdp
    case confirmRedeemPointsCdp
    case mobileData
    case exceedChangePoints
    case pointsTMMChangeAmount
    case exchange
    case viewTransaction
    case newTransactionTitle
    case newTransactionDesc
    case earnPointsTasks
    case publishedByMe
    case appTasks
    case shareTasks
    case earn
    case minusPoints
    case maxBonus
    case points
    case shareTaskRewardDesc
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
    case submitTask
    case submitNewAppTask
    case submitNewShareTask
    case submitAppTaskNotAvailable
    case editAppTask
    case editShareTask
    case url
    case title
    case description
    case rewardPerView
    case maxRewardTimes
    case totalReward
    case appName
    case rewardPerInstall
    case edit
    case stop
    case start
    case confirmStartTask
    case confirmStopTask
    case confirmCancelTask
    case viewers
    case bonusPoint
    case pointsLeft
    case account
    case signout
    case myInviteCode
    case inviteCode
    case inviteCodePlaceholder
    case inviteRecords
    case telegramGroup
    case currency
    case wechatGroup
    case feedback
    case currentVersion
    case copyInviteCode
    case inviteUsers
    case inviteIncome
    case bindWechatAccount
    case binded
    case notbinded
    case buy
    case sell
    case amount
    case price
    case buyOrder
    case sellOrder
    case buyOrders
    case sellOrders
    case orderAddSuccess
    case confirmOrder
    case emptyQuantity
    case emptyPrice
    case myOrderbooks
    case dealAmount
    case dealETH
    case orderbookPending
    case orderbookCompleted
    case orderbookCanceled
    case cancel
    case confirmCancelOrder
    case emptyOrderbookTitle
    case emptyOrderbookDesc
    case volumn
    case lowPrice
    case highPrice
    case day
    case month
    case week
    case year
    
    var description : String {
        switch self {
        case .close:
            return NSLocalizedString("Close", comment: "Close")
        case .error:
            return NSLocalizedString("Error", comment: "Error")
        case .success:
            return NSLocalizedString("Success", comment: "Success")
        case .alert:
            return NSLocalizedString("Alert", comment: "Alert")
        case .confirm:
            return NSLocalizedString("Confirm", comment: "Confirm")
        case .shareSuccess:
            return NSLocalizedString("ShareSuccess", comment: "Share Success")
        case .more:
            return NSLocalizedString("More", comment: "More")
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
        case .invalidCaptchaError:
            return NSLocalizedString("InvalidCaptchaError", comment: "invalidCaptchaError")
        case .notEnoughTokenError:
            return NSLocalizedString("NotEnoughTokenError", comment: "notEnoughTokenError")
        case .notEnoughPointsError:
            return NSLocalizedString("NotEnoughPointsError", comment: "notEnoughPointsError")
        case .invalidMinPointsError:
            return NSLocalizedString("InvalidMinPointsError", comment: "invalidMinPoints")
        case .invalidMinTMMError:
            return NSLocalizedString("InvalidMinTMMError", comment: "InvalidMinTMMError")
        case .notEnoughETHError:
            return NSLocalizedString("NotEnoughETHError", comment: "notEnoughETHError")
        case .uploadImageError:
            return NSLocalizedString("UploadImageError", comment: "uploadImageError")
        case .maxQuerySchemeError:
            return NSLocalizedString("MaxQuerySchemeError", comment: "MaxQuerySchemeError")
        case .invalidInviteCodeError:
            return NSLocalizedString("InvalidInviteCodeError", comment: "InvalidInviteCodeError")
        case .maxBindDeviceError:
            return NSLocalizedString("MaxBindDeviceError", comment: "maxBindDeviceError")
        case .otherBindDeviceError:
            return NSLocalizedString("OtherBindDeviceError", comment: "otherBindDeviceError")
        case .invalidCdpVendorError:
            return NSLocalizedString("InvalidCdpVendorError", comment:"invalidCdpVendorError")
        case .exchangeNotAvailableInYourCountryError:
            return NSLocalizedString("ExchangeNotAvailableInYourCountryError", comment: "ExchangeNotAvailableInYourCountryError")
        case .featureNotAvailableError:
            return NSLocalizedString("FeatureNotAvailableError", comment: "featureNotAvailableError")
        case .dailyBonusCommittedError:
            return NSLocalizedString("DailyBonusCommittedError", comment: "dailyBonusCommittedError")
        case .invalidPhoneNumber:
            return NSLocalizedString("InvalidPhoneNumber", comment: "Invalid phone number")
        case .refresh:
            return NSLocalizedString("Refresh", comment: "refresh")
        case .copy:
            return NSLocalizedString("Copy", comment: "Copy")
        case .submit:
            return NSLocalizedString("Submit", comment: "Submit")
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
        case .redeemCdp:
            return NSLocalizedString("RedeemCdp", comment: "redeemCdp")
        case .confirmRedeemPointsCdp:
            return NSLocalizedString("ConfirmRedeemPointsCdp", comment: "ConfirmRedeemPointsCdp")
        case .mobileData:
            return NSLocalizedString("MobileData", comment: "MobileData")
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
        case .toTBC:
            return NSLocalizedString("ToTBC", comment: "To UC")
        case .toPoints:
            return NSLocalizedString("ToPoints", comment: "To Points")
        case .toMobileData:
            return NSLocalizedString("ToMobileData", comment: "To Mobile Data")
        case .txPending:
            return NSLocalizedString("TxPending", comment: "Pending")
        case .txSuccess:
            return NSLocalizedString("TxSuccess", comment: "Success")
        case .txFailed:
            return NSLocalizedString("TxFailed", comment: "Failed")
        case .emptyExchangeRecordsTitle:
            return NSLocalizedString("EmptyExchangeRecordsTitle", comment: "EmptyExchangeRecordsTitle")
        case .emptyExchangeRecordsDesc:
            return NSLocalizedString("EmptyExchangeRecordsDesc", comment: "EmptyExchangeRecordsDesc")
        case .emptyTransactionsTitle:
            return NSLocalizedString("EmptyTransactionsTitle", comment: "EmptyTransactionsTitle")
        case .emptyTransactionsDesc:
            return NSLocalizedString("EmptyTransactionsDesc", comment: "EmptyTransactionsDesc")
        case .bind:
            return NSLocalizedString("Bind", comment: "Bind")
        case .unbindDeviceExplain:
            return NSLocalizedString("UnbindDeviceExplain", comment: "UnbindDeviceExplain")
        case .unbind:
            return NSLocalizedString("Unbind", comment: "Unbind")
        case .confirmUnbind:
            return NSLocalizedString("ConfirmUnbind", comment: "ConfirmUnbind")
        case .withdraw:
            return NSLocalizedString("Withdraw", comment: "Withdraw")
        case .currentTMMRedeemRate:
            return NSLocalizedString("CurrentTMMRedeemRate", comment: "CurrentTMMRedeemRate")
        case .TMMAmount:
            return NSLocalizedString("TMMAmount", comment: "TMMAmount")
        case .TMMWithdrawAmount:
            return NSLocalizedString("TMMWithdrawAmount", comment: "TMMWithdrawAmount")
        case .emptyWithdrawTMM:
            return NSLocalizedString("EmptyWithdrawTMM", comment: "emptyWithdrawTMM")
        case .withdrawSuccessMsg:
            return NSLocalizedString("WithdrawSuccessMsg", comment: "WithdrawSuccessMsg")
        case .dailyReward:
            return NSLocalizedString("DailyReward", comment: "DailyReward")
        case .xDay:
            return NSLocalizedString("XDay", comment: "XDay")
        case .dailyBonusSuccessMsg:
            return NSLocalizedString("DailyBonusSuccessMsg", comment: "dailyBonusSuccessMsg")
        case .earnPointsTasks:
            return NSLocalizedString("EarnPointsTasks", comment: "EarnPointsTasks")
        case .publishedByMe:
            return NSLocalizedString("PublishedByMe", comment: "publishedByMe")
        case .appTasks:
            return NSLocalizedString("AppTasks", comment: "App Tasks")
        case .shareTasks:
            return NSLocalizedString("ShareTasks", comment: "Share Tasks")
        case .earn:
            return NSLocalizedString("Earn", comment: "Earn")
        case .minusPoints:
            return NSLocalizedString("MinusPoints", comment: "Minus Points")
        case .maxBonus:
            return NSLocalizedString("MaxBonus", comment: "Max bonus")
        case .points:
            return NSLocalizedString("Points", comment: "Points")
        case .shareTaskRewardDesc:
            return NSLocalizedString("ShareTaskRewardDesc", comment: "ShareTaskRewardDesc")
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
        case .submitTask:
            return NSLocalizedString("SubmitTask", comment: "SubmitTask")
        case .submitNewAppTask:
            return NSLocalizedString("SubmitNewAppTask", comment: "SubmitNewAppTask")
        case .submitNewShareTask:
            return NSLocalizedString("SubmitNewShareTask", comment: "SubmitNewShareTask")
        case .submitAppTaskNotAvailable:
            return NSLocalizedString("SubmitAppTaskNotAvailable", comment: "SubmitAppTaskNotAvailable")
        case .editAppTask:
            return NSLocalizedString("EditAppTask", comment: "Edit App Task")
        case .editShareTask:
            return NSLocalizedString("EditShareTask", comment: "Edit Share Task")
        case .url:
            return NSLocalizedString("URL", comment: "Link")
        case .title:
            return NSLocalizedString("Title", comment: "Title")
        case .description:
            return NSLocalizedString("Description", comment: "Description")
        case .rewardPerView:
            return NSLocalizedString("RewardPerView", comment: "rewardPerView")
        case .maxRewardTimes:
            return NSLocalizedString("MaxRewardTimes", comment: "maxRewardTimes")
        case .totalReward:
            return NSLocalizedString("TotalReward", comment: "totalReward")
        case .appName:
            return NSLocalizedString("AppName", comment: "app name")
        case .rewardPerInstall:
            return NSLocalizedString("RewardPerInstall", comment: "RewardPerInstall")
        case .edit:
            return NSLocalizedString("Edit", comment: "Edit")
        case .stop:
            return NSLocalizedString("Stop", comment: "Stop")
        case.start:
            return NSLocalizedString("Start", comment: "Start")
        case .confirmStartTask:
            return NSLocalizedString("ConfirmStartTask", comment: "ConfirmStartTask")
        case .confirmStopTask:
            return NSLocalizedString("ConfirmStopTask", comment: "ConfirmStopTask")
        case .confirmCancelTask:
            return NSLocalizedString("ConfirmCancelTask", comment: "ConfirmCancelTask")
        case .viewers:
            return NSLocalizedString("Viewers", comment: "Viewers")
        case .bonusPoint:
            return NSLocalizedString("BonusPoint", comment: "BonusPoint")
        case .pointsLeft:
            return NSLocalizedString("PointsLeft", comment: "PointsLeft")
        case .account:
            return NSLocalizedString("Account", comment: "account")
        case .signout:
            return NSLocalizedString("Signout", comment: "Sign Out")
        case .myInviteCode:
            return NSLocalizedString("MyInviteCode", comment: "My Invite Code")
        case .inviteCode:
            return NSLocalizedString("InviteCode", comment: "Invite Code")
        case .inviteCodePlaceholder:
            return NSLocalizedString("InviteCodePlaceholder", comment: "InviteCodePlaceholder")
        case .inviteRecords:
            return NSLocalizedString("InviteRecords", comment: "InviteRecords")
        case .telegramGroup:
            return NSLocalizedString("TelegramGroup", comment: "Telegram Group")
        case .currency:
            return NSLocalizedString("Currency", comment: "Currency")
        case .wechatGroup:
            return NSLocalizedString("WechatGroup", comment: "Wechat Group")
        case .feedback:
            return NSLocalizedString("Feedback", comment: "feedback")
        case .currentVersion:
            return NSLocalizedString("CurrentVersion", comment: "Current Version")
        case .copyInviteCode:
            return NSLocalizedString("CopyInviteCode", comment: "Copy Invite Code")
        case .inviteUsers:
            return NSLocalizedString("InviteUsers", comment: "Invite Users")
        case .inviteIncome:
            return NSLocalizedString("InviteIncome", comment: "Invite Income")
        case .bindWechatAccount:
            return NSLocalizedString("BindWechatAccount", comment: "Bind Wechat Account")
        case .binded:
            return NSLocalizedString("Binded", comment: "BINDED")
        case .notbinded:
            return NSLocalizedString("NotBinded", comment: "NOT BINDED")
        case .buy:
            return NSLocalizedString("Buy", comment: "Buy")
        case .sell:
            return NSLocalizedString("Sell", comment: "Sell")
        case .amount:
            return NSLocalizedString("Amount", comment: "Amount")
        case .price:
            return NSLocalizedString("Price", comment: "Price")
        case .buyOrder:
            return NSLocalizedString("BuyOrder", comment: "Buy Order")
        case .sellOrder:
            return NSLocalizedString("SellOrder", comment: "Sell Order")
        case .buyOrders:
            return NSLocalizedString("BuyOrders", comment: "Buy Orders")
        case .sellOrders:
            return NSLocalizedString("SellOrders", comment: "Sell Orders")
        case .orderAddSuccess:
            return NSLocalizedString("OrderAddSuccess", comment: "orderAddSuccess")
        case .confirmOrder:
            return NSLocalizedString("ConfirmOrder", comment: "Confirm the order?")
        case .emptyQuantity:
            return NSLocalizedString("EmptyQuantity", comment: "EmptyQuantity")
        case .emptyPrice:
            return NSLocalizedString("EmptyPrice", comment: "EmptyPrice")
        case .myOrderbooks:
            return NSLocalizedString("MyOrderbooks", comment: "My Orders")
        case .dealAmount:
            return NSLocalizedString("DealAmount", comment: "Deal UC")
        case .dealETH:
            return NSLocalizedString("DealETH", comment: "Deal ETH")
        case .orderbookPending:
            return NSLocalizedString("OrderbookPending", comment: "Matching")
        case .orderbookCompleted:
            return NSLocalizedString("OrderbookCompleted", comment: "Completed")
        case .orderbookCanceled:
            return NSLocalizedString("OrderbookCanceled", comment: "Canceled")
        case .cancel:
            return NSLocalizedString("Cancel", comment: "Cancel")
        case .confirmCancelOrder:
            return NSLocalizedString("ConfirmCancelOrder", comment: "confirmCancelOrder")
        case .emptyOrderbookTitle:
            return NSLocalizedString("EmptyOrderbookTitle", comment: "emptyOrderbookTitle")
        case .emptyOrderbookDesc:
            return NSLocalizedString("EmptyOrderbookDesc", comment: "emptyOrderbookDesc")
        case .volumn:
            return NSLocalizedString("Volumn", comment: "volumn")
        case .lowPrice:
            return NSLocalizedString("LowPrice", comment: "low price")
        case .highPrice:
            return NSLocalizedString("HighPrice", comment: "high price")
        case .day:
            return NSLocalizedString("Day", comment: "Day")
        case .week:
            return NSLocalizedString("Week", comment: "week")
        case .month:
            return NSLocalizedString("Month", comment: "month")
        case .year:
            return NSLocalizedString("Year", comment: "year")
        }
    }
}
