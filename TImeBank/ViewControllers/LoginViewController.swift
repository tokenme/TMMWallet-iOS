//
//  LoginViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/3.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import PhoneNumberKit
import CountryPickerView
import Moya
import SwiftyUserDefaults
import Hydra
import TMMSDK
import Presentr
import BiometricAuthentication

class LoginViewController: UIViewController {
    
    @IBOutlet private weak var telephoneTextField: TweeAttributedTextField!
    @IBOutlet private weak var passwordTextfield: TweeAttributedTextField!
    @IBOutlet private weak var loginButton: TransitionButton!
    
    weak public var delegate: LoginViewDelegate?
    
    private var countryCode: String = "+86"
    private let phoneNumberKit = PhoneNumberKit()
    
    private var isLogining = false
    private var loadingUserInfo = false
    private var bindingDevice = false
    
    private let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    private var authServiceProvider = MoyaProvider<TMMAuthService>(plugins: [networkActivityPlugin, SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    private var userServiceProvider = MoyaProvider<TMMUserService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    private var deviceServiceProvider = MoyaProvider<TMMDeviceService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let cpv = CountryPickerView(frame: CGRect(x: 0, y: 0, width: 125, height: 20))
        cpv.setCountryByPhoneCode(self.countryCode)
        cpv.delegate = self
        cpv.dataSource = self
        telephoneTextField.leftView = cpv
        telephoneTextField.leftViewMode = .always
        passwordTextfield.tweePlaceholder = I18n.password.description
        self.biometricLogin()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MTA.trackPageViewBegin(TMMConfigs.PageName.login)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MTA.trackPageViewEnd(TMMConfigs.PageName.login)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    static func instantiate() -> LoginViewController
    {
        return UIStoryboard(name: "Login", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
    }
    
    private func biometricLogin() {
        if Defaults[.user] == nil || !BioMetricAuthenticator.canAuthenticate() {
            return
        }
        guard let passwd = Defaults.string(forKey: "authKey") else {
            return }
        guard let authKeyStr = passwd.desDecrypt(withKey: TMMConfigs.TMMBeacon.secret) else { return }
        guard let jsonData = Data(base64Encoded: authKeyStr, options: Data.Base64DecodingOptions.ignoreUnknownCharacters) else {
            return }
        var authPasswd: String?
        do {
            let decoder = JSONDecoder()
            let authKey = try decoder.decode(APIAuthKey.self, from: jsonData)
            authKey.ts = Int64(Date().timeIntervalSince1970)
            let encoder = JSONEncoder()
            let encodeData = try encoder.encode(authKey)
            authPasswd = encodeData.base64EncodedString().desEncrypt(withKey: TMMConfigs.TMMBeacon.secret)
        } catch  {
            return
        }
        if authPasswd == nil { return }
        
        BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
            // authentication successful
            self.doLogin(recaptcha: TMMConfigs.TMMBeacon.key, afsSession: "", biometricAuthentication: authPasswd)
        }, failure: { [weak self] (error) in
            guard let weakSelf = self else { return }
            // do nothing on canceled
            if error == .canceledByUser || error == .canceledBySystem {
                return
            }
                
                // device does not support biometric (face id or touch id) authentication
            else if error == .biometryNotAvailable {
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: error.message(), closeBtn: I18n.close.description)
            }
                
                // show alternatives on fallback button clicked
            else if error == .fallback {
                // here we're entering username and password
                return
            }
                
                // No biometry enrolled in this device, ask user to register fingerprint or face
            else if error == .biometryNotEnrolled {
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: error.message(), closeBtn: I18n.close.description)
            }
                
                // Biometry is locked out now, because there were too many failed attempts.
                // Need to enter device passcode to unlock.
            else if error == .biometryLockedout {
                // show passcode authentication
                weakSelf.biometricPasscode()
            }
                
                // show error on authentication failed
            else {
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: error.message(), closeBtn: I18n.close.description)
            }
        })
    }
    
    private func biometricPasscode() {
        BioMetricAuthenticator.authenticateWithPasscode(reason: "", success: {[weak self] in
            // passcode authentication success
            guard let weakSelf = self else { return }
            weakSelf.biometricLogin()
        }) { [weak self] (error) in
            guard let weakSelf = self else { return }
            UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: error.message(), closeBtn: I18n.close.description)
        }
    }
    
    //================
    // MARK: IBActions
    //================
    @IBAction private func login() {
        if isLogining {
            return
        }
        var valid: Bool = true
        valid = self.verifyTelephone()
        if !self.verifyPassword() {
            valid = false
        }
        if !valid {
            return
        }
        guard let country = UInt(self.countryCode.trimmingCharacters(in: CharacterSet(charactersIn: "+")))
            else { return }
        var lang = "zh_CN"
        if country != 86 {
            lang = "en"
        }
        if let vc = MSAuthVCFactory.simapleVerify(with: MSAuthTypeSlide, language: lang, delegate: self, authCode: "0335", appKey: nil) {
            let navigationController = UINavigationController(rootViewController: vc)
            let backBtn = UIBarButtonItem(title: I18n.close.description, style: .plain, target: nil, action: nil)
            navigationController.navigationItem.leftBarButtonItem = backBtn;
            navigationController.modalTransitionStyle = UIModalTransitionStyle.coverVertical
            navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet
            navigationController.preferredContentSize  = CGSize(width: 400, height: 800)
            self.present(navigationController, animated: true, completion: nil)
        }
        
        //let vc = ReCaptchaViewController()
        //vc.delegate = self
        
    }
    
    private func doLogin(recaptcha: String, afsSession: String, biometricAuthentication: String?) {
        if isLogining {
            return
        }
        var authCountry: UInt = 0
        var authMobile: String = ""
        var authPasswd: String = ""
        if let userInfo: DefaultsUser = Defaults[.user],
            let country = userInfo.countryCode,
            let mobile = userInfo.mobile,
            let passwd = biometricAuthentication {
            authCountry = country
            authMobile = mobile
            authPasswd = passwd
        } else {
            guard let country = UInt(self.countryCode.trimmingCharacters(in: CharacterSet(charactersIn: "+"))),
                let mobile = self.telephoneTextField.text,
                let passwd = self.passwordTextfield.text
                else { return }
            authCountry = country
            authMobile = mobile
            authPasswd = passwd
        }
        
        self.isLogining = true
        MTA.trackCustomKeyValueEventBegin(TMMConfigs.EventName.login, props: ["countryCode": authCountry])
        
        self.loginButton.startAnimation()
        async({[weak self] _ in
            guard let weakSelf = self else { return }
                let _ = try ..TMMAuthService.doLogin(
                    country: authCountry,
                    mobile: authMobile,
                    password: authPasswd,
                    biometric: biometricAuthentication != nil,
                    captcha: recaptcha,
                    afsSession: afsSession,
                    provider: weakSelf.authServiceProvider)
                let _ = try ..weakSelf.getUserInfoAndBindDevice()
            
        }).then(in: .main, {[weak self] _ in
            guard let weakSelf = self else { return }
            if let userInfo: DefaultsUser = Defaults[.user] {
                if biometricAuthentication != nil {
                    Defaults.setValue(authPasswd, forKey: "authKey")
                } else {
                    let authKey = APIAuthKey(passwd: authPasswd, ts: Int64(Date().timeIntervalSince1970))
                    let encoder = JSONEncoder()
                    do {
                        let encodeData = try encoder.encode(authKey)
                        let pass = encodeData.base64EncodedString().desEncrypt(withKey: TMMConfigs.TMMBeacon.secret)
                        Defaults.setValue(pass, forKey: "authKey")
                    } catch { }
                }
                MTA.trackCustomKeyValueEventEnd(TMMConfigs.EventName.login, props: ["countryCode": userInfo.countryCode])
                Defaults.synchronize()
                let account = MTAAccountInfo.init()
                account.type = MTAAccountTypeExt.custom
                account.account = "UserId:\(userInfo.id ?? 0)"
                account.accountStatus = MTAAccountStatus.normal
                let accountPhone = MTAAccountInfo.init()
                accountPhone.type = MTAAccountTypeExt.phone
                accountPhone.account = "+\(userInfo.countryCode ?? 0)\(userInfo.mobile!)"
                accountPhone.accountStatus = MTAAccountStatus.normal
                if userInfo.openId != "" {
                    let openIdAccount = MTAAccountInfo.init()
                    openIdAccount.type = MTAAccountTypeExt.weixin
                    openIdAccount.account = userInfo.openId
                    openIdAccount.accountStatus = MTAAccountStatus.normal
                    MTA.reportAccountExt([account, accountPhone, openIdAccount])
                } else {
                    MTA.reportAccountExt([account, accountPhone])
                }
            }
            weakSelf.loginButton.stopAnimation(animationStyle: .expand, completion: {
                weakSelf.delegate?.loginSucceeded(token: nil)
                weakSelf.dismiss(animated: true, completion: nil)
            })
        }).catch(in: .main, {[weak self] error in
            guard let weakSelf = self else { return  }
            switch error as! TMMAPIError {
            case .ignore:
                weakSelf.loginButton.stopAnimation(animationStyle: .shake, completion: nil)
                return
            default: break
            }
            weakSelf.loginButton.stopAnimation(animationStyle: .shake, completion: nil)
            UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description, viewController: weakSelf)
        }).always(in: .main, body: {[weak self]  in
            guard let weakSelf = self else { return }
            weakSelf.bindingDevice = false
            weakSelf.isLogining = false
        })
    }
    
    private func getUserInfoAndBindDevice() -> Promise<Void> {
        return Promise<Void> (in: .background, {[weak self] resolve, reject, _ in
            guard let weakSelf = self else {
                reject(TMMAPIError.ignore)
                return
            }
            all(weakSelf.getUserInfo(), weakSelf.bindDevice()).then(in: .background,  {_ in resolve(())}).catch(in: .background, { error in reject(error) })
        })
    }
    
    private func getUserInfo() -> Promise<Void> {
        return Promise<Void> (in: .background, {[weak self] resolve, reject, _ in
            guard let weakSelf = self else {
                reject(TMMAPIError.ignore)
                return
            }
            if weakSelf.loadingUserInfo {
                reject(TMMAPIError.ignore)
                return
            }
            weakSelf.loadingUserInfo = true
            TMMUserService.getUserInfo(
                false,
                provider: weakSelf.userServiceProvider)
                .then(in: .background, {user in
                    resolve(())
                }).catch(in: .background, { error in
                    reject(error)
                })
        })
    }
    
    private func bindDevice() -> Promise<Void> {
        return Promise<Void> (in: .background, {[weak self] resolve, reject, _ in
            guard let deviceInfo = TMMBeacon.shareInstance().deviceInfo() as? [String: Any] else {
                reject(TMMAPIError.ignore)
                return
            }
            guard let weakSelf = self else {
                reject(TMMAPIError.ignore)
                return
            }
            if weakSelf.bindingDevice {
                reject(TMMAPIError.ignore)
                return
            }
            weakSelf.bindingDevice = true
            TMMDeviceService.bindUser(
                device: deviceInfo,
                provider: weakSelf.deviceServiceProvider)
                .always(in: .background, body: {
                    resolve(())
                })
        })
    }

}

extension LoginViewController: ReCaptchaDelegate {
    func didSolve(response: String) {
        self.doLogin(recaptcha: response, afsSession: "", biometricAuthentication: nil)
    }
}

extension LoginViewController {
    fileprivate func verifyTelephone() -> Bool {
        do {
            let phone = self.countryCode + (self.telephoneTextField.text ?? "")
            _ = try phoneNumberKit.parse(phone)
            return true
        }
        catch {
            guard let phone = self.telephoneTextField.text, phone != "" else { return false }
            self.telephoneTextField.showInfo(I18n.invalidPhoneNumber.description)
        }
        return false
    }
    
    fileprivate func verifyPassword() -> Bool {
        if (self.passwordTextfield.text == "") {
            self.passwordTextfield.showInfo(I18n.emptyPassword.description)
            return false
        }
        return true
    }
}

extension LoginViewController: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.tag == 0 {
            self.telephoneTextField.hideInfo()
        } else if textField.tag == 1 {
            self.passwordTextfield.hideInfo()
        }
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == 0 && self.verifyTelephone() {
            self.passwordTextfield.becomeFirstResponder()
        } else if textField.tag == 1 && self.verifyPassword() {
            textField.resignFirstResponder()
        }
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        _ = self.verifyTelephone()
        _ = self.verifyPassword()
        textField.resignFirstResponder()
        return true
    }
}

extension LoginViewController: CountryPickerViewDelegate {
    func countryPickerView(_ countryPickerView: CountryPickerView, didSelectCountry country: Country) {
        self.countryCode = country.phoneCode
    }
}

extension LoginViewController: CountryPickerViewDataSource {
    func preferredCountries(in countryPickerView: CountryPickerView) -> [Country] {
        var countries = [Country]()
        ["CN", "US", "JP"].forEach { code in
            if let country = countryPickerView.getCountryByCode(code) {
                countries.append(country)
            }
        }
        return countries
    }
    
    func sectionTitleForPreferredCountries(in countryPickerView: CountryPickerView) -> String? {
        return I18n.suggestOptions.description
    }
    
    func showOnlyPreferredSection(in countryPickerView: CountryPickerView) -> Bool {
        return false
    }
    
    func navigationTitle(in countryPickerView: CountryPickerView) -> String? {
        return I18n.chooseCountry.description
    }
    
    func searchBarPosition(in countryPickerView: CountryPickerView) -> SearchBarPosition {
        return .tableViewHeader
    }
    
    func showPhoneCodeInList(in countryPickerView: CountryPickerView) -> Bool {
        return true
    }
}

extension LoginViewController: MSAuthProtocol {
    func verifyDidFinished(withResult code: t_verify_reuslt, error: Error!, sessionId: String!) {
        if error != nil {
            DispatchQueue.main.async {
                UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: error.localizedDescription, closeBtn: I18n.close.description)
            }
            return
        }
        self.dismiss(animated: true, completion: nil)
        self.doLogin(recaptcha: "", afsSession: sessionId, biometricAuthentication: nil)
    }
}

public protocol LoginViewDelegate: NSObjectProtocol {
    func loginSucceeded(token: APIAccessToken?)
}
