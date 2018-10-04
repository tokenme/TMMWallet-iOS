//
//  FeedbackTableViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/3.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import CoreTelephony
import SwiftyUserDefaults
import Moya
import Hydra
import Kingfisher
import Presentr
import TMMSDK
import PhotoSolution
import SKWebAPI

class FeedbackTableViewController: UITableViewController {
    
    private var userInfo: APIUser? {
        get {
            if let userInfo: DefaultsUser = Defaults[.user] {
                if CheckValidAccessToken() {
                    return APIUser.init(user: userInfo)
                }
                return nil
            }
            return nil
        }
    }
    
    private let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    private let photoSolution = PhotoSolution()
    
    @IBOutlet private weak var descTextView: UITextView!
    @IBOutlet private weak var imageButton: UIButton!
    
    private var submitButton: TransitionButton = TransitionButton(type: .custom)
    
    private var selectedImage: UIImage?
    private var isSubmitting: Bool = false
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = true
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            navigationController.navigationBar.isTranslucent = false
            navigationController.navigationBar.setBackgroundImage(UIImage(color: UIColor(white: 0.98, alpha: 1)), for: .default)
            navigationController.navigationBar.shadowImage = UIImage(color: UIColor(white: 0.91, alpha: 1), size: CGSize(width: 0.5, height: 0.5))
            navigationItem.title = I18n.feedback.description
        }
        descTextView.becomeFirstResponder()
        setupTableView()
        
        setupPhotoSolution()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = false
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            navigationController.navigationBar.isTranslucent = false
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    static func instantiate() -> FeedbackTableViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FeedbackTableViewController") as! FeedbackTableViewController
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func setupTableView() {
        //self.tableView.separatorStyle = .none
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 55.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: CGFloat.leastNormalMagnitude))
        submitButton.setTitle(I18n.submit.description, for: .normal)
        submitButton.backgroundColor = UIColor.primaryBlue
        submitButton.disabledBackgroundColor = UIColor.lightGray
        submitButton.spinnerColor = UIColor.white
        submitButton.tintColor = UIColor.white
        submitButton.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 40)
        
        submitButton.addTarget(self, action: #selector(submit), for: .touchUpInside)
        tableView.tableFooterView = submitButton
    }
    
    private func setupPhotoSolution() {
        photoSolution.delegate = self
    }
    
    @IBAction private func selectImage() {
        self.present(photoSolution.getPhotoPicker(maxPhotos: 1), animated: true, completion: nil)
    }
}

extension FeedbackTableViewController {
    @objc func submit() {
        self.descTextView.resignFirstResponder()
        if isSubmitting {
            return
        }
        
        let carrier: String = CTTelephonyNetworkInfo().subscriberCellularProvider?.carrierName ?? ""
        
        guard let appName: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String,
            let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let build: String = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String,
            let language: String = NSLocale.current.languageCode
            else {
                return
        }
        
        let country: String = NSLocale.current.regionCode ?? ""
        
        let comment: String = self.descTextView.text ?? ""
        let border: String = "------------------------"
        var post: String = ""
        var attachements: [String: String] = [
            "APP": appName,
            "VERSION": version,
            "BUILD": build,
            "DEVICE": UIDevice.current.name,
            "MODEL": UIDevice.current.model,
            "OS": UIDevice.current.systemName,
            "OS VERSION": UIDevice.current.systemVersion,
            "LANG": language,
            "COUNTRY": country,
            "CARRIER": carrier,
            ]
        if let options = FeedbackSlack.shared?.options {
            attachements.merge(options, uniquingKeysWith: {key1,key2  in
                return key1
            })
        }
        if let _ = self.selectedImage {
            var posts: [[String]] = [
                ["New feedback from userID: \(userInfo?.id ?? 0)"],
                [comment],
                [border]
            ]
            for (key, val) in attachements {
                posts += [[key, val]]
            }
            
            post = posts.map { (post: [String]) -> String in
                post.joined(separator: ": ")
                }.joined(separator: "\n")
        } else {
            post = comment
        }
        
        self.postSlack(post, attachements)
    }
    
    fileprivate func postSlack(_ comment: String, _ attachements: [String: String]) {
        guard let slack: FeedbackSlack = FeedbackSlack.shared,
            let appName: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            else {
                return
        }
        
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.current
        dateFormatter.timeZone = NSTimeZone.local
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        let date: String = dateFormatter.string(from: Date())
        
        isSubmitting = true
        submitButton.startAnimation()
        guard let image: UIImage = self.selectedImage,
            let data: Data = image.pngData() else {
                var fields: [AttachmentField] = []
                for (key, val) in attachements {
                    let field = AttachmentField(title: key, value: val, short: true)
                    fields.append(field)
                }
                let attachement: Attachment = Attachment(fallback: "New feedback from userID: \(userInfo?.id ?? 0)", title: "New feedback from userID: \(userInfo?.id ?? 0)", callbackID: nil, type: nil, colorHex: nil, pretext: nil, authorName: "+\(userInfo?.countryCode ?? 0)-\(userInfo?.mobile ?? "")", authorLink: nil, authorIcon: "\(userInfo?.avatar ?? "")", titleLink: nil, text: comment, fields: fields, actions: nil, imageURL: nil, thumbURL: nil, footer: nil, footerIcon: nil, ts: nil, markdownFields: nil)
                slack.bot.sendMessage(channel: slack.slackChannel, text: comment, username: nil, asUser: false, parse: nil, linkNames: nil, attachments: [attachement], unfurlLinks: nil, unfurlMedia: nil, iconURL: nil, iconEmoji: nil, success: {[weak self] (ts: String?, channel: String?) in
                    guard let weakSelf = self else { return }
                    DispatchQueue.main.async {
                        weakSelf.submitButton.stopAnimation(animationStyle: .normal, completion: {
                            weakSelf.isSubmitting = false
                            weakSelf.navigationController?.popViewController(animated: true)
                        })
                    }
                }) {[weak self] (error: SlackError) in
                    guard let weakSelf = self else { return }
                    DispatchQueue.main.async {
                        UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: error.localizedDescription, closeBtn: I18n.close.description)
                        weakSelf.submitButton.stopAnimation(animationStyle: .shake, completion: {
                            weakSelf.isSubmitting = false
                        })
                    }
                }
            return
        }
        slack.bot.uploadFile(
            file: data,
            filename: "\(Date().timeIntervalSince1970).png",
            filetype: "image/png",
            title: "\(appName) feedback \(date)",
            initialComment: comment,
            channels: [slack.slackChannel],
            success: { [weak self] _ in
                guard let weakSelf = self else { return }
                DispatchQueue.main.async {
                    weakSelf.submitButton.stopAnimation(animationStyle: .normal, completion: {
                        weakSelf.isSubmitting = false
                        weakSelf.navigationController?.popViewController(animated: true)
                    })
                }
            }) { [weak self] (error: SlackError) in
                guard let weakSelf = self else { return }
                DispatchQueue.main.async {
                    UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: error.localizedDescription, closeBtn: I18n.close.description)
                    weakSelf.submitButton.stopAnimation(animationStyle: .shake, completion: {
                        weakSelf.isSubmitting = false
                    })
                }
        }
    }
}

extension FeedbackTableViewController: PhotoSolutionDelegate{
    func returnImages(_ images: [UIImage]) {
        self.selectedImage = images[0].kf.scaled(to: 0.75)
        let img = images[0].kf.resize(to: CGSize(width: 63, height: 63))
        imageButton.setImage(img, for: .normal)
    }
    
    func pickerCancel() {
        // when user cancel
    }
}

