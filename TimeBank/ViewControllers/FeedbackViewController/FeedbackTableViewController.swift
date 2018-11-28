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
import Photos
import AssetsPickerViewController

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
    
    private let photoSolution = AssetsPickerViewController()
    
    lazy var imageManager = {
        return PHCachingImageManager()
    }()
    
    @IBOutlet private weak var descTextView: UITextView!
    @IBOutlet private weak var imageButton: UIButton!
    
    private var submitButton: TransitionButton = TransitionButton(type: .custom)
    
    private var selectedImage: UIImage?
    private var isSubmitting: Bool = false
    
    private var feedbackServiceProvider = MoyaProvider<TMMFeedbackService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
    private var qiniuServiceProvider = MoyaProvider<TMMQiniuService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
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
            
            let myFeedbacksBarItem = UIBarButtonItem(title: I18n.myFeedbacks.description, style: .plain, target: self, action: #selector(self.showMyFeedbacks))
            navigationItem.rightBarButtonItem = myFeedbacksBarItem
            
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
        let pickerConfig = AssetsPickerConfig()
        pickerConfig.albumIsShowHiddenAlbum = true
        
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        
        pickerConfig.assetFetchOptions = [
            .smartAlbum: options,
            .album: options
        ]
        
        photoSolution.pickerConfig = pickerConfig
        
        photoSolution.pickerDelegate = self
    }
    
    @IBAction private func selectImage() {
        self.present(photoSolution, animated: true, completion: nil)
    }
    
    @objc private func showMyFeedbacks() {
        let vc = MyFeedbacksTableViewController.instantiate()
        self.navigationController?.pushViewController(vc, animated: true)
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
        let attachements: [String: String] = [
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
        
        self.postSlack(comment, attachements)
    }
    
    fileprivate func postSlack(_ comment: String, _ attachements: [String: String]) {
        isSubmitting = true
        submitButton.startAnimation()
        guard let image: UIImage = self.selectedImage else {
            self.doFeedback(
                message: comment,
                image: nil,
                attachements: attachements
            ).then(in: .main, {[weak self] task in
                guard let weakSelf = self else { return }
                weakSelf.submitButton.stopAnimation(animationStyle: .expand, completion: {
                    weakSelf.navigationController?.popViewController(animated: true)
                })
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                weakSelf.submitButton.stopAnimation(animationStyle: .shake, completion: nil)
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as? TMMAPIError)?.description ?? error.localizedDescription, closeBtn: I18n.close.description)
            }).always(in: .main, body: { [weak self] in
                guard let weakSelf = self else { return }
                weakSelf.isSubmitting = false
            })
            return
        }
            
        async({[weak self] _ in
            guard let weakSelf = self else {
                throw TMMAPIError.ignore
            }
            var upToken = try ..TMMQiniuService.getUpToken(provider: weakSelf.qiniuServiceProvider)
            guard let imageLink = upToken.link else {
                throw TMMAPIError.uploadImageError
            }
            upToken = try ..weakSelf.uploadImage(upToken, image: image)
            let _ = try ..weakSelf.doFeedback(
                    message: comment,
                    image: imageLink,
                    attachements: attachements)
        }).then(in: .main, {[weak self] task in
            guard let weakSelf = self else { return }
            weakSelf.submitButton.stopAnimation(animationStyle: .expand, completion: {
                weakSelf.navigationController?.popViewController(animated: true)
            })
        }).catch(in: .main, {[weak self] error in
            guard let weakSelf = self else { return }
            weakSelf.submitButton.stopAnimation(animationStyle: .shake, completion: nil)
            UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as? TMMAPIError)?.description ?? error.localizedDescription, closeBtn: I18n.close.description)
        }).always(in: .main, body: { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.isSubmitting = false
        })
    }
}

extension FeedbackTableViewController {
    
    private func doFeedback(message: String, image: String?, attachements:[String: String]) -> Promise<APIResponse> {
        return Promise<APIResponse>(in: .background, {[weak self] resolve, reject, _ in
            guard let weakSelf = self else {
                reject(TMMAPIError.ignore)
                return
            }
            TMMFeedbackService.add(
                message: message,
                image: image,
                attachements: attachements,
                provider: weakSelf.feedbackServiceProvider
            ).then(in: .background, { resp in
                resolve(resp)
            }).catch(in: .background, { error in
                reject(error)
            })
        })
    }
    
    private func uploadImage(_ upToken: APIQiniu, image: UIImage) -> Promise<APIQiniu> {
        return Promise<APIQiniu>(in: .background, { resolve, reject, _ in
            let imgData = image.kf.jpegRepresentation(compressionQuality: 0.6)
            let magager = QiniuManager.sharedInstance
            magager.uploader.put(
                imgData,
                key: upToken.key,
                token: upToken.upToken,
                complete: { (info: QNResponseInfo?, key: String?, resp: [AnyHashable : Any]?) -> Void in
                    if let resp = info, resp.isOK {
                        upToken.uploaded = true
                        resolve(upToken)
                        return
                    }
                    reject(TMMAPIError.uploadImageError)
            }, option: nil)
        })
    }
}

extension FeedbackTableViewController: AssetsPickerViewControllerDelegate{
    func assetsPicker(controller: AssetsPickerViewController, selected assets: [PHAsset]) {
        let asset = assets[0]
        let width = asset.pixelWidth
        let height = asset.pixelHeight
        var scaleW = width
        var scaleH = height
        if width > height {
            scaleW = 63
            scaleH = scaleW * height / width
        } else {
            scaleH = 63
            scaleW = scaleH * width / height
        }
        imageManager.requestImage(for: asset, targetSize: CGSize(width: width, height: height), contentMode: .aspectFit, options: nil) {[weak self] (image, info) in
            guard let weakSelf = self else { return }
            weakSelf.selectedImage = image?.kf.scaled(to: 0.75)
            let img = image?.kf.resize(to: CGSize(width: scaleW, height: scaleH))
            weakSelf.imageButton.contentMode = .scaleAspectFit
            weakSelf.imageButton.setImage(img, for: .normal)
        }
    }
    
    func assetsPicker(controller: AssetsPickerViewController, shouldSelect asset: PHAsset, at indexPath: IndexPath) -> Bool {
        // can limit selection count
        if controller.selectedAssets.count > 0 {
            return false
        }
        return true
    }
    
    func assetsPicker(controller: AssetsPickerViewController, shouldDeselect asset: PHAsset, at indexPath: IndexPath) -> Bool {
        return true
    }
}

