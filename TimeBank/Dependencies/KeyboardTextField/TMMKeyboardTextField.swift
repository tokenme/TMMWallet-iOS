//
//  TMMKeyboardTextField.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/23.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit

class TMMKeyboardTextField : KeyboardTextField {
    
    override init(frame : CGRect) {
        super.init(frame : frame)
        self.clearTestColor()
        
        //Right Button
        self.rightButton.showsTouchWhenHighlighted = true
        self.rightButton.backgroundColor = UIColor(rgb: (252,49,89))
        self.rightButton.clipsToBounds = true
        self.rightButton.layer.cornerRadius = 18
        self.rightButton.setTitle("^0^", for: .normal)
        self.rightButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        
        //TextView
        self.textViewBackground.layer.borderColor = UIColor(rgb: (191,191,191)).cgColor
        self.textViewBackground.backgroundColor = UIColor.white
        self.textViewBackground.layer.cornerRadius = 18
        self.textViewBackground.layer.masksToBounds = true
        self.keyboardView.backgroundColor = UIColor(rgb: (238,238,238))
        self.placeholderLabel.textAlignment = .center
        self.placeholderLabel.text = "^_^"
        self.placeholderLabel.textColor = UIColor(rgb: (153,153,153))
        
        self.leftRightDistance = 15.0
        self.middleDistance = 5.0
        self.buttonMinWidth = 60
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc override func keyboardDidChangeFrame(_ notification : Notification) {
        self.isHidden = !self.isEditing
    }
    
}
