//
//  InputTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/12/5.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable
import SnapKit

class InputTableViewCell: UITableViewCell, Reusable {
    
    public weak var delegate: InputTableViewCellDelegate?
    
    lazy private var titleLabel: UILabel = {[weak self] in
        let label = UILabel()
        label.textColor = UIColor.darkText
        label.font = UIFont.systemFont(ofSize: 17)
        self?.contentView.addSubview(label)
        label.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.top.equalToSuperview().offset(16)
            maker.bottom.equalToSuperview().offset(-16)
        }
        return label
    }()
    
    lazy private var inputField: UITextField = {[weak self] in
        let field = UITextField()
        field.adjustsFontSizeToFitWidth = true
        field.minimumFontSize = 10
        field.textColor = UIColor.darkText
        field.font = UIFont.systemFont(ofSize: 17)
        field.delegate = self
        field.textAlignment = .right
        self?.contentView.addSubview(field)
        field.snp.remakeConstraints {[weak self] (maker) -> Void in
            maker.trailing.equalToSuperview().offset(-16)
            maker.centerY.equalToSuperview()
            guard let weakSelf = self else { return }
            maker.leading.equalTo(weakSelf.titleLabel.snp.trailing).offset(16).priority(251)
        }
        return field
    }()
    
    func fill(_ title: String, placeholder: String, value: String?) {
        titleLabel.text = title
        inputField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize:15), NSAttributedString.Key.foregroundColor:UIColor.lightGray])
        if let v = value {
            inputField.text = v
        }
    }
    
    public func showKeyboard() {
        inputField.becomeFirstResponder()
    }
    
    public func hideKeyboard() {
        inputField.resignFirstResponder()
    }
}

extension InputTableViewCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let txt = textField.text ?? ""
        if !txt.isEmpty {
            self.delegate?.textUpdated(txt)
        }
        textField.resignFirstResponder()
        return true
    }
}

public protocol InputTableViewCellDelegate: NSObjectProtocol {
    func textUpdated(_ text: String)
}
