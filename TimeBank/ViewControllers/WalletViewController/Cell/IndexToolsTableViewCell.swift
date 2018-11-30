//
//  IndexToolsTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/30.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable
import SnapKit

class IndexToolsTableViewCell: UITableViewCell, Reusable {
    
    weak public var delegate: IndexToolsDelegate?
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    private func toolButton(title: String, image: UIImage?) -> UIButton {
        let btn = UIButton(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 64, height: 64)))
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        btn.setTitleColor(.primaryBlue, for: .normal)
        let shareImage = image?.kf.resize(to: CGSize(width: 28, height: 28)).withRenderingMode(.alwaysTemplate)
        btn.set(image: shareImage, title: title, titlePosition: .bottom, additionalSpacing: 5, state: .normal)
        btn.tintColor = .primaryBlue
        return btn
    }
    
    lazy private var containerView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        
        let shareBtn = toolButton(title: I18n.earnByShare.description, image: UIImage(named: "ShareBtn"))
        shareBtn.addTarget(self, action: #selector(gotoShareTask), for: .touchUpInside)
        let inviteBtn = toolButton(title: I18n.earnByInvite.description, image: UIImage(named: "InviteBtn"))
        inviteBtn.addTarget(self, action: #selector(gotoInvite), for: .touchUpInside)
        let mallBtn = toolButton(title: I18n.earnByShopping.description, image: UIImage(named: "Goods"))
        mallBtn.addTarget(self, action: #selector(gotoMall), for: .touchUpInside)
        let helpBtn = toolButton(title: I18n.strategyHelp.description, image: UIImage(named: "Money"))
        helpBtn.addTarget(self, action: #selector(gotoHelp), for: .touchUpInside)
        
        let sv = UIStackView(arrangedSubviews: [shareBtn, inviteBtn, mallBtn, helpBtn])
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        
        stackView.addArrangedSubview(sv)
        contentView.addSubview(stackView)
        stackView.snp.remakeConstraints {[weak self] (maker) -> Void in
            maker.leading.top.equalToSuperview().offset(16)
            maker.trailing.bottom.equalToSuperview().offset(-16)
        }
        return stackView
    }()
    
    func show() {
        containerView.updateConstraints()
    }
    
    @objc func gotoShareTask() {
        guard let delegate = self.delegate else { return }
        delegate.gotoShareTasksView(0)
    }
    
    @objc func gotoInvite() {
        guard let delegate = self.delegate else { return }
        delegate.gotoInviteView()
    }
    
    @objc func gotoHelp() {
        guard let delegate = self.delegate else { return }
        delegate.gotoHelpView()
    }
    
    @objc func gotoMall() {
        guard let delegate = self.delegate else { return }
        delegate.gotoMallView()
    }
}

public protocol IndexToolsDelegate: NSObjectProtocol {
    func gotoShareTasksView(_ index: Int)
    func gotoInviteView()
    func gotoMallView()
    func gotoHelpView()
}
