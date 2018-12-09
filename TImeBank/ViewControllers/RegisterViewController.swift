//
//  RegisterViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/3.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import PhoneNumberKit
import CountryPickerView
import Moya
import Hydra
import Presentr

fileprivate enum InHumanCheckStep {
    case sendCode
    case register
}

class RegisterViewController: UIViewController {
    
    @IBOutlet private weak var telephoneTextField: TweeAttributedTextField!
    @IBOutlet private weak var verifyCodeTextField: TweeAttributedTextField!
    @IBOutlet private weak var passwordTextfield: TweeAttributedTextField!
    @IBOutlet private weak var repasswordTextfield: TweeAttributedTextField!
    @IBOutlet private weak var countdownButton: RNCountdownButton!
    @IBOutlet private weak var registerButton: TransitionButton!
    
    private var inHumanCheckStep: InHumanCheckStep = .sendCode
    
    private let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    private var authServiceProvider = MoyaProvider<TMMAuthService>(plugins: [networkActivityPlugin, SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    private var userServiceProvider = MoyaProvider<TMMUserService>(plugins: [networkActivityPlugin, SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
    private var countryCode: String = "+86"
    private let phoneNumberKit = PhoneNumberKit()
    
    private var isRegistering = false
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupCountDownButton()
        self.setupTelephoneTextField()
        passwordTextfield.tweePlaceholder = I18n.password.description
        repasswordTextfield.tweePlaceholder = I18n.repassword.description
        verifyCodeTextField.tweePlaceholder = I18n.verifyCode.description
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MTA.trackPageViewBegin(TMMConfigs.PageName.register)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MTA.trackPageViewEnd(TMMConfigs.PageName.register)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupCountDownButton() {
        self.countdownButton.titleColorForEnable = UIColor.init(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        self.countdownButton.titleColorForDisable = UIColor.lightGray
        self.countdownButton.titleColorForCountingDisable = UIColor.lightGray
        self.countdownButton.borderColorForEnable = UIColor.white
        self.countdownButton.borderColorForDisable = UIColor.white
        self.countdownButton.isEnabled = false
        self.countdownButton.delegate = self
    }
    
    private func setupTelephoneTextField() {
        let cpv = CountryPickerView(frame: CGRect(x: 0, y: 0, width: 125, height: 20))
        cpv.setCountryByPhoneCode(self.countryCode)
        cpv.delegate = self
        cpv.dataSource = self
        self.telephoneTextField.leftView = cpv
        self.telephoneTextField.leftViewMode = .always
    }
    
    //================
    // MARK: IBActions
    //================
    @IBAction private func sendVerifyCode() {
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
            self.present(navigationController, animated: true, completion: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.inHumanCheckStep = .sendCode
            })
        }
    }
    
    private func doSendVerifyCode(afsSession: String) {
        let country = UInt(self.countryCode.trimmingCharacters(in: CharacterSet(charactersIn: "+")))
        self.authServiceProvider.request(
            .sendCode(
                afsSession: afsSession,
                country:country!,
                mobile: self.telephoneTextField.text!
            )
        ){[weak self] result in
            guard let weakSelf = self else { return }
            switch result {
            case let .success(response):
                do {
                    let resp = try response.mapObject(APIResponse.self)
                    if resp.code ?? 0 > 0 {
                        DispatchQueue.main.async {
                            UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: resp.message ?? I18n.unknownError.description, closeBtn: I18n.close.description)
                        }
                        return
                    }
                } catch {
                    DispatchQueue.main.async {
                        UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: I18n.unknownError.description, closeBtn: I18n.close.description)
                    }
                }
            case let .failure(error):
                DispatchQueue.main.async {
                    UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: error.errorDescription!, closeBtn: I18n.close.description)
                    weakSelf.countdownButton.stop()
                    weakSelf.countdownButton.showFetchAgain()
                    weakSelf.countdownButton.isEnabled = true
                }
            }
        }
        DispatchQueue.main.async {
            self.countdownButton.start()
        }
    }
    
    @IBAction private func register() {
        var valid: Bool = true
        valid = self.verifyTelephone()
        if !self.verifyVerifyCode() {
            valid = false
        }
        if !self.verifyPassword() {
            valid = false
        }
        if !verifyRepassword() {
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
            self.present(navigationController, animated: true, completion: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.inHumanCheckStep = .register
            })
        }
        /*
        if self.isRegistering {
            return
        }
        let vc = ReCaptchaViewController()
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
        */
    }
    
    private func doRegister(recaptcha: String, afsSession: String) {
        if self.isRegistering { return }
        self.isRegistering = true
        
        guard let country = UInt(self.countryCode.trimmingCharacters(in: CharacterSet(charactersIn: "+"))),
            let mobile = self.telephoneTextField.text,
            let verifyCode = self.verifyCodeTextField.text,
            let passwd = self.passwordTextfield.text,
            let repasswd = self.repasswordTextfield.text
            else { return }
        self.registerButton.startAnimation()
        MTA.trackCustomKeyValueEventBegin(TMMConfigs.EventName.register, props: ["countryCode": country])
        async({[weak self] _ in
            guard let weakSelf = self else {
                return
            }
            let _ = try ..TMMUserService.createUser(
                country: country,
                mobile: mobile,
                verifyCode: verifyCode,
                password: passwd,
                repassword: repasswd,
                captcha: recaptcha,
                afsSession: afsSession,
                provider: weakSelf.userServiceProvider)
        }).then(in: .main, {[weak self] user in
            guard let weakSelf = self else { return }
            MTA.trackCustomKeyValueEventEnd(TMMConfigs.EventName.register, props: ["countryCode": country])
            weakSelf.registerButton.stopAnimation(animationStyle: .expand, completion: {
                weakSelf.dismiss(animated: true, completion: nil)
            })
        }).catch(in: .main, {[weak self] error in
            switch error as! TMMAPIError {
            case .ignore:
                return
            default: break
            }
            guard let weakSelf = self else { return }
            weakSelf.registerButton.stopAnimation(animationStyle: .shake, completion: nil)
            UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description, viewController: weakSelf)
        }).always(in: .main, body: {[weak self]  in
            guard let weakSelf = self else { return }
            weakSelf.isRegistering = false
        })
    }
    
    @IBAction private func close() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension RegisterViewController: MSAuthProtocol {
    func verifyDidFinished(withResult code: t_verify_reuslt, error: Error!, sessionId: String!) {
        if error != nil {
            DispatchQueue.main.async {
                UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: error.localizedDescription, closeBtn: I18n.close.description)
            }
            return
        }
        self.dismiss(animated: true, completion: {[weak self] in
            guard let weakSelf = self else { return }
            if weakSelf.inHumanCheckStep == .sendCode {
                weakSelf.doSendVerifyCode(afsSession: sessionId)
            } else if weakSelf.inHumanCheckStep == .register {
                weakSelf.doRegister(recaptcha: "", afsSession: sessionId)
            }
        })
    }
}

extension RegisterViewController: ReCaptchaDelegate {
    func didSolve(response: String) {
        self.doRegister(recaptcha: response, afsSession: "")
    }
}

extension RegisterViewController {
    fileprivate func verifyTelephone() -> Bool {
        do {
            let phone = self.countryCode + (self.telephoneTextField.text ?? "")
            _ = try phoneNumberKit.parse(phone)
            self.countdownButton.isEnabled = !self.countdownButton.isCounting
            self.verifyCodeTextField.isEnabled = true
            self.telephoneTextField.hideInfo()
            return true
        }
        catch {
            self.telephoneTextField.showInfo(I18n.invalidPhoneNumber.description)
            if (self.countdownButton.isCounting) {
                self.countdownButton.stop()
                self.countdownButton.showFetchAgain()
            }
            self.countdownButton.isEnabled = false
            self.verifyCodeTextField.isEnabled = false
        }
        return false
    }
    
    fileprivate func verifyVerifyCode() -> Bool {
        if (self.verifyCodeTextField.text == "") {
            self.verifyCodeTextField.showInfo(I18n.emptyVerifyCode.description)
            return false
        }
        return true
    }
    
    fileprivate func verifyPassword() -> Bool {
        if let passwd = self.passwordTextfield.text {
            if (passwd == "") {
                self.passwordTextfield.showInfo(I18n.emptyPassword.description)
                return false
            }
            if (passwd.count < 8 || passwd.count > 32) {
                self.passwordTextfield.showInfo(I18n.invalidPasswordLengthError.description)
                return false
            }
            return true
        }
        self.passwordTextfield.showInfo(I18n.emptyPassword.description)
        return false
    }
    
    fileprivate func verifyRepassword() -> Bool {
        if let passwd = self.repasswordTextfield.text {
            if passwd == "" {
                self.repasswordTextfield.showInfo(I18n.emptyRepassword.description)
                return false
            } else if (passwd != self.passwordTextfield.text) {
                self.repasswordTextfield.showInfo(I18n.passwordNotMatch.description)
                return false
            }
            return true
        }
        self.repasswordTextfield.showInfo(I18n.emptyRepassword.description)
        return false
    }
}

extension RegisterViewController: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.tag == 0 {
            self.telephoneTextField.hideInfo()
        } else if textField.tag == 1 {
            self.verifyCodeTextField.hideInfo()
        } else if textField.tag == 2 {
            self.passwordTextfield.hideInfo()
        } else if textField.tag == 3 {
            self.repasswordTextfield.hideInfo()
        }
    }
    
    @IBAction func textFieldDidChange(_ textField:UITextField) {
        if textField.tag == 0 {
            let _ = self.verifyTelephone()
        }
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == 0 && self.verifyTelephone() {
            self.verifyCodeTextField.becomeFirstResponder()
        } else if textField.tag == 1 && self.verifyVerifyCode() {
            self.passwordTextfield.becomeFirstResponder()
        } else if textField.tag == 2 && self.verifyPassword() {
            self.repasswordTextfield.becomeFirstResponder()
        } else if textField.tag == 3 && self.verifyRepassword() {
            textField.resignFirstResponder()
        }
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        _ = self.verifyTelephone()
        _ = self.verifyVerifyCode()
        _ = self.verifyPassword()
        _ = self.verifyRepassword()
        textField.resignFirstResponder()
        return true
    }
}

extension RegisterViewController: CountryPickerViewDelegate {
    func countryPickerView(_ countryPickerView: CountryPickerView, didSelectCountry country: Country) {
        self.countryCode = country.phoneCode
    }
}

extension RegisterViewController: CountryPickerViewDataSource {
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

extension RegisterViewController: RNCountdownButtonDelegate {
    func countdownButtonDidBeganCounting(countdownButton: RNCountdownButton) {
    }
    
    func countdownButtonDidEndCounting(countdownButton: RNCountdownButton) {
    }
    
    func countdownButton(countdownButton: RNCountdownButton, didUpdatedWith seconds: Int) {
    }
}
