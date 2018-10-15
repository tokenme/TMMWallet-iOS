//
//  SubmitShareTaskTableViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/17.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Moya
import Hydra
import Kingfisher
import Presentr
import TMMSDK
import PhotoSolution
import Qiniu

class SubmitShareTaskTableViewController: UITableViewController {
    
    weak public var delegate: ViewUpdateDelegate?
    
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
    
    public var task: APIShareTask?
    
    @IBOutlet private weak var urlLabel: UILabel!
    @IBOutlet private weak var urlTextField: UITextField!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var titleTextField: UITextField!
    @IBOutlet private weak var descLabel: UILabel!
    @IBOutlet private weak var descTextView: UITextView!
    @IBOutlet private weak var imageButton: UIButton!
    @IBOutlet private weak var rewardLabel: UILabel!
    @IBOutlet private weak var rewardTextField: UITextField!
    @IBOutlet private weak var timesLabel: UILabel!
    @IBOutlet private weak var timesTextField: UITextField!
    @IBOutlet private weak var totalPointsLabel: UILabel!
    @IBOutlet private weak var totalPointsTextField: UITextField!
    
    private var submitButton: TransitionButton = TransitionButton(type: .custom)
    
    private var selectedImage: UIImage?
    private var isSubmitting: Bool = false
    
    private var taskServiceProvider = MoyaProvider<TMMTaskService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    private var qiniuServiceProvider = MoyaProvider<TMMQiniuService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
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
            if self.task != nil {
                navigationItem.title = I18n.editShareTask.description
            } else {
                navigationItem.title = I18n.submitNewShareTask.description
            }
        }
        setupTableView()
        urlLabel.text = I18n.url.description
        titleLabel.text = I18n.title.description
        descLabel.text = I18n.description.description
        rewardLabel.text = I18n.rewardPerView.description
        timesLabel.text = I18n.maxRewardTimes.description
        totalPointsLabel.text = I18n.totalReward.description
        
        if let task = self.task {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 6
            formatter.groupingSeparator = "";
            formatter.numberStyle = NumberFormatter.Style.decimal
            
            urlTextField.text = task.link
            titleTextField.text = task.title
            descTextView.text = task.summary
            rewardTextField.text = formatter.string(from: task.bonus)
            timesTextField.text = "\(task.maxViewers)"
            totalPointsTextField.text = formatter.string(from: task.pointsLeft)
            if let image = task.image {
                imageButton.kf.setImage(with: URL(string: image), for: .normal, placeholder: nil, options: [KingfisherOptionsInfoItem.processor(ResizingImageProcessor(referenceSize: CGSize(width: 63, height: 63), mode: ContentMode.none))], progressBlock: nil, completionHandler: nil)
            }
        }
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
    
    static func instantiate() -> SubmitShareTaskTableViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SubmitShareTaskTableViewController") as! SubmitShareTaskTableViewController
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

extension SubmitShareTaskTableViewController {
    @objc func submit() {
        if isSubmitting {
            return
        }
        guard let link = urlTextField.text else {
            UCAlert.showAlert(alertPresenter, title: I18n.error.description, desc: "missing link", closeBtn: I18n.close.description)
            return
        }
        guard let title = titleTextField.text else {
            UCAlert.showAlert(alertPresenter, title: I18n.error.description, desc: "missing title", closeBtn: I18n.close.description)
            return
        }
        guard let summary = descTextView.text else {
            UCAlert.showAlert(alertPresenter, title: I18n.error.description, desc: "missing summary", closeBtn: I18n.close.description)
            return
        }
        let points = NSDecimalNumber(string: totalPointsTextField.text)
        if points < 0 {
            UCAlert.showAlert(alertPresenter, title: I18n.error.description, desc: "missing points", closeBtn: I18n.close.description)
            return
        }
        let bonus = NSDecimalNumber(string: rewardTextField.text)
        if bonus < 0 {
            UCAlert.showAlert(alertPresenter, title: I18n.error.description, desc: "missing bonus", closeBtn: I18n.close.description)
            return
        }
        let maxViewers = UInt(timesTextField.text ?? "0") ?? 0
        if maxViewers == 0 {
            UCAlert.showAlert(alertPresenter, title: I18n.error.description, desc: "missing max viewers", closeBtn: I18n.close.description)
            return
        }
        if points < bonus * NSDecimalNumber(value: maxViewers) {
            UCAlert.showAlert(alertPresenter, title: I18n.error.description, desc: "minium points required", closeBtn: I18n.close.description)
            return
        }
        isSubmitting = true
        submitButton.startAnimation()
        if let image = self.selectedImage {
            async({[weak self] _ -> APIShareTask in
                guard let weakSelf = self else {
                    throw TMMAPIError.ignore
                }
                var upToken = try ..TMMQiniuService.getUpToken(provider: weakSelf.qiniuServiceProvider)
                guard let imageLink = upToken.link else {
                    throw TMMAPIError.uploadImageError
                }
                upToken = try ..weakSelf.uploadImage(upToken, image: image)
                var task: APIShareTask?
                if let taskId = weakSelf.task?.id {
                    task = try ..TMMTaskService.updateShareTask(
                        id: taskId,
                        link: link,
                        title: title,
                        summary: summary,
                        image: imageLink,
                        points: points,
                        bonus: bonus,
                        maxViewers: maxViewers,
                        onlineStatus: .unknown,
                        provider: weakSelf.taskServiceProvider)
                } else {
                    task = try ..TMMTaskService.addShareTask(
                        link: link,
                        title: title,
                        summary: summary,
                        image: imageLink,
                        points: points,
                        bonus: bonus,
                        maxViewers: maxViewers,
                        provider: weakSelf.taskServiceProvider)
                }
                return task!
            }).then(in: .main, {[weak self] task in
                guard let weakSelf = self else { return }
                weakSelf.submitButton.stopAnimation(animationStyle: .expand, completion: {
                    weakSelf.delegate?.shouldRefresh()
                    weakSelf.navigationController?.popViewController(animated: true)
                })
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                weakSelf.submitButton.stopAnimation(animationStyle: .shake, completion: {
                    UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
                })
            }).always(in: .main, body: { [weak self] in
                guard let weakSelf = self else { return }
                weakSelf.isSubmitting = false
            })
        }else {
            if let taskId = self.task?.id {
                TMMTaskService.updateShareTask(
                    id: taskId,
                    link: link,
                    title: title,
                    summary: summary,
                    image: "",
                    points: points,
                    bonus: bonus,
                    maxViewers: maxViewers,
                    onlineStatus: .unknown,
                    provider: self.taskServiceProvider)
                    .then(in: .main, {[weak self] task in
                        guard let weakSelf = self else { return }
                        weakSelf.submitButton.stopAnimation(animationStyle: .expand, completion: {
                            weakSelf.delegate?.shouldRefresh()
                            weakSelf.navigationController?.popViewController(animated: true)
                        })
                    }).catch(in: .main, {[weak self] error in
                        guard let weakSelf = self else { return }
                        weakSelf.submitButton.stopAnimation(animationStyle: .shake, completion: {
                            UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
                        })
                    }).always(in: .main,  body: {[weak self] in
                        guard let weakSelf = self else { return }
                        weakSelf.isSubmitting = false
                })
            } else {
                TMMTaskService.addShareTask(
                    link: link,
                    title: title,
                    summary: summary,
                    image: "",
                    points: points,
                    bonus: bonus,
                    maxViewers: maxViewers,
                    provider: self.taskServiceProvider)
                    .then(in: .main, {[weak self] task in
                        guard let weakSelf = self else { return }
                        weakSelf.submitButton.stopAnimation(animationStyle: .expand, completion: {
                            weakSelf.delegate?.shouldRefresh()
                            weakSelf.navigationController?.popViewController(animated: true)
                        })
                    }).catch(in: .main, {[weak self] error in
                        guard let weakSelf = self else { return }
                        weakSelf.submitButton.stopAnimation(animationStyle: .shake, completion: {
                            UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
                        })
                    }).always(in: .main,  body: {[weak self] in
                        guard let weakSelf = self else { return }
                        weakSelf.isSubmitting = false
                    })
            }
        }
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

extension SubmitShareTaskTableViewController: PhotoSolutionDelegate{
    func returnImages(_ images: [UIImage]) {
        self.selectedImage = images[0].kf.resize(to: CGSize(width: 500, height: 500))
        let img = images[0].kf.resize(to: CGSize(width: 63, height: 63))
        imageButton.setImage(img, for: .normal)
    }
    
    func pickerCancel() {
        // when user cancel
    }
}
