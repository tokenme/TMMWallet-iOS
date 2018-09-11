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
    
    private var authServiceProvider = MoyaProvider<TMMAuthService>(plugins: [networkActivityPlugin])
    private var userServiceProvider = MoyaProvider<TMMUserService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    private var deviceServiceProvider = MoyaProvider<TMMDeviceService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
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
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    static func instantiate() -> LoginViewController
    {
        return UIStoryboard(name: "Login", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
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
        let country = UInt(self.countryCode.trimmingCharacters(in: CharacterSet(charactersIn: "+")))
        let mobile = self.telephoneTextField.text!
        let passwd = self.passwordTextfield.text!
        self.isLogining = true
        
        self.loginButton.startAnimation()
        async({[weak self] _ in
            guard let weakSelf = self else { return }
            let _ = try ..TMMAuthService.doLogin(
                country: country!,
                mobile: mobile,
                password: passwd,
                provider: weakSelf.authServiceProvider)
            let _ = try ..weakSelf.getUserInfoAndBindDevice()
        }).then(in: .main, {[weak self] _ in
            guard let weakSelf = self else { return }
            weakSelf.loginButton.stopAnimation(animationStyle: .expand, completion: {
                weakSelf.delegate?.loginSucceeded(token: nil)
                weakSelf.dismiss(animated: true, completion: nil)
                //weakSelf.navigationController?.popViewController(animated: true)
            })
        }).catch(in: .main, {[weak self] error in
            switch error as! TMMAPIError {
            case .ignore:
                return
            default: break
            }
            guard let weakSelf = self else { return  }
            weakSelf.loginButton.stopAnimation(animationStyle: .shake, completion: {})
            UCAlert.showAlert(imageName: "Error", title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
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
                idfa: TMMBeacon.shareInstance().deviceId(),
                provider: weakSelf.deviceServiceProvider)
                .then(in: .background, {user in
                    resolve(())
                }).catch(in: .background, { error in
                    reject(error)
                })
        })
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

public protocol LoginViewDelegate: NSObjectProtocol {
    func loginSucceeded(token: APIAccessToken?)
}
