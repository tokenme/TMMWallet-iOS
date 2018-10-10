//
//  ReCaptchaViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/10.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import WebKit

protocol ReCaptchaDelegate: class {
    func didSolve(response: String)
}

class ReCaptchaViewController: UIViewController {
    public weak var delegate: ReCaptchaDelegate?
    
    private let spinner: UIActivityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
    
    private var webView: WKWebView!
    private let imageURL = ""
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController.add(self, name: "captchaReceived")
        
        self.webView = WKWebView(frame: .zero, configuration: webConfiguration)
        self.webView.navigationDelegate = self
        self.webView.scrollView.bounces = false
        self.webView.isMultipleTouchEnabled = true
        self.webView.contentMode = .scaleToFill
        self.webView.contentScaleFactor = 15.0
        self.webView.scrollView.isScrollEnabled = false
        self.webView.uiDelegate = self
        view = webView
        
        spinner.color = .darkGray
        spinner.center = CGPoint(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)
        view.addSubview(spinner)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        loadPage()
    }
    
    func fetchForToken() {
        self.webView.evaluateJavaScript("document.getElementById('g-recaptcha-response').value;") {[weak self] (any,error) -> Void in
            guard let weakSelf = self else { return }
            let response = any as! String
            weakSelf.delegate?.didSolve(response: response)
            weakSelf.dismiss(animated: true, completion: nil)
        }
    }
    
    private func loadPage() {
        spinner.startAnimating()
        spinner.isHidden = false
        self.webView.loadHTMLString("<html><meta name=\"viewport\" content=\"width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no\" />\r\n<head>\r\n<style>\r\nform {\r\n  text-align: center;\r\n}\r\nbody {\r\n  text-align: center;\r\n\r\n  \r\n}\r\n\r\nh1 {\r\n  text-align: center;\r\n}\r\nh3 {\r\n  text-align: center;\r\n}\r\ndiv-captcha {\r\n      text-align: center;\r\n}\r\n    .g-recaptcha {\r\n        display: inline-block;\r\n    }\r\n</style>\r\n\r\n<meta name=\"referrer\" content=\"never\"> <script type='text/javascript' src='https://recaptcha.net/recaptcha/api.js'></script><script>function sub() { window.webkit.messageHandlers.captchaReceived.postMessage(document.getElementById('g-recaptcha-response').value); }</script></head> <body bgcolor=\"#ffffff\"oncontextmenu=\"return false\"><div id=\"div-captcha\"><br><img width=\"50%\" src=\"\(imageURL)\"/><br><br><div style=\"opacity: 0.9\" class=\"g-recaptcha\" data-sitekey=\"\(TMMConfigs.ReCaptcha.siteKey)\" data-callback=\"sub\"></div></div><br>\r\n\r\n</body></html>", baseURL: URL(string: TMMConfigs.ReCaptcha.domain))
    }
}

extension ReCaptchaViewController: WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        spinner.isHidden = true
        spinner.stopAnimating()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.fetchForToken()
    }
}
