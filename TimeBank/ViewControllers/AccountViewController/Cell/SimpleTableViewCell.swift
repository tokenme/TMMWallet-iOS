//
//  SimpleTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/12/5.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable
import SnapKit

class SimpleTableViewCell: UITableViewCell, Reusable {
    
    lazy private var titleLabel: UILabel = {[weak self] in
        let label = UILabel()
        label.textColor = UIColor.darkText
        label.font = UIFont.systemFont(ofSize: 17)
        self?.contentView.addSubview(label)
        label.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.lessThanOrEqualToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(16)
            maker.bottom.equalToSuperview().offset(-16)
        }
        return label
    }()
    
    lazy private var badgeLabel: UILabel = {[weak self] in
        let label = UILabel()
        label.textColor = UIColor.lightGray
        label.font = UIFont.systemFont(ofSize: 17)
        self?.contentView.addSubview(label)
        label.snp.remakeConstraints {[weak self] (maker) -> Void in
            maker.trailing.equalToSuperview().offset(-16)
            maker.centerY.equalToSuperview()
            guard let weakSelf = self else { return }
            maker.leading.equalTo(weakSelf.titleLabel.snp.trailing).offset(16)
        }
        return label
    }()
    
    lazy private var statusLabel: UILabelPadding = {[weak self] in
        let label = UILabelPadding()
        label.textColor = UIColor.lightGray
        label.layer.cornerRadius = 5;
        label.clipsToBounds = true
        label.paddingTop = 2
        label.paddingBottom = 2
        label.paddingLeft = 4
        label.paddingRight = 4
        label.font = UIFont.systemFont(ofSize: 14)
        self?.contentView.addSubview(label)
        label.snp.remakeConstraints { (maker) -> Void in
            maker.trailing.equalToSuperview().offset(-16)
            maker.centerY.equalToSuperview()
            guard let weakSelf = self else { return }
            maker.leading.equalTo(weakSelf.titleLabel.snp.trailing).offset(16)
        }
        return label
    }()
    
    lazy private var activityIndicator: UIActivityIndicatorView = {[weak self] in
        let v = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
        v.isHidden = true
        v.hidesWhenStopped = false
        self?.contentView.addSubview(v)
        v.snp.remakeConstraints { (maker) -> Void in
            maker.trailing.equalToSuperview().offset(-16)
            maker.centerY.equalToSuperview()
        }
        return v
    }()
    
    func fill(_ title: String) {
        titleLabel.text = title
        titleLabel.textColor = UIColor.darkText
        statusLabel.snp.removeConstraints()
        statusLabel.isHidden = true
        badgeLabel.snp.removeConstraints()
        badgeLabel.isHidden = true
        titleLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.lessThanOrEqualToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(16)
            maker.bottom.equalToSuperview().offset(-16)
        }
    }
    
    func setTitleColor(_ color: UIColor) {
        titleLabel.textColor = color
    }
    
    func setBadge(_ badge: String) {
        badgeLabel.text = badge
        badgeLabel.snp.remakeConstraints {[weak self] (maker) -> Void in
            maker.trailing.equalToSuperview().offset(-16)
            maker.centerY.equalToSuperview()
            guard let weakSelf = self else { return }
            maker.leading.greaterThanOrEqualTo(weakSelf.titleLabel.snp.trailing).offset(16)
        }
        badgeLabel.isHidden = false
        statusLabel.snp.removeConstraints()
        statusLabel.isHidden = true
        
        titleLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.top.equalToSuperview().offset(16)
            maker.bottom.equalToSuperview().offset(-16)
        }
    }
    
    func setStatus(_ statusText: String, statusColor: UIColor, statusBgColor: UIColor) {
        badgeLabel.snp.removeConstraints()
        badgeLabel.isHidden = true
        statusLabel.text = statusText
        statusLabel.backgroundColor = statusBgColor
        statusLabel.textColor = statusColor
        statusLabel.snp.remakeConstraints {[weak self] (maker) -> Void in
            maker.trailing.equalToSuperview().offset(-16)
            maker.centerY.equalToSuperview()
            guard let weakSelf = self else { return }
            maker.leading.greaterThanOrEqualTo(weakSelf.titleLabel.snp.trailing).offset(16)
        }
        statusLabel.isHidden = false
        
        titleLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.top.equalToSuperview().offset(16)
            maker.bottom.equalToSuperview().offset(-16)
        }
    }
    
    func showLoader() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func hideLoader() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
}
