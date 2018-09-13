//
//  Alert.swift
//  ucoin
//
//  Created by Syd on 2018/6/4.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import SwiftEntryKit
import Presentr
import UIKit

class UCAlert {
    static public func showAlert(_ presenter: Presentr, title: String, desc: String, closeBtn: String) {
        let alertController = Presentr.alertViewController(title: title, body: desc)
        let cancelAction = AlertAction(title: closeBtn, style: .cancel) { alert in
            //
        }
        alertController.addAction(cancelAction)
        if let vc = UIViewController.currentViewController() {
            vc.customPresentViewController(presenter, viewController: alertController, animated: true)
        }
    }
    
    static public func showAlert2(imageName: String, title: String, desc: String, closeBtn: String) {
        var attributes = EKAttributes()
        attributes = EKAttributes.centerFloat
        attributes.hapticFeedbackType = .error
        attributes.displayDuration = .infinity
        attributes.entryBackground = .color(color: .white)
        attributes.screenBackground = .color(color: .dimmedLightBackground)
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.3, radius: 8, offset: .zero))
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .absorbTouches
        attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .jolt)
        attributes.roundCorners = .all(radius: 8)
        attributes.entranceAnimation = .init(translate: .init(duration: 0.7, spring: .init(damping: 0.7, initialVelocity: 0)),
                                             scale: .init(from: 0.7, to: 1, duration: 0.4, spring: .init(damping: 1, initialVelocity: 0)))
        attributes.exitAnimation = .init(translate: .init(duration: 0.2))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.35)))
        attributes.positionConstraints.size = .init(width: .offset(value: 20), height: .intrinsic)
        attributes.positionConstraints.maxSize = .init(width: .constant(value: UIScreen.main.minEdge), height: .intrinsic)
        
        let offset = EKAttributes.PositionConstraints.KeyboardRelation.Offset(bottom: 10, screenEdgeResistance: 20)
        let keyboardRelation = EKAttributes.PositionConstraints.KeyboardRelation.bind(offset: offset)
        attributes.positionConstraints.keyboardRelation = keyboardRelation
        
        let image = EKProperty.ImageContent(imageName: imageName, size: CGSize(width: 25, height: 25), contentMode: .scaleAspectFit)
        let titleProp = EKProperty.LabelContent(text: title, style: .init(font: MainFont.medium.with(size: 24), color: UIColor.darkText, alignment: .center))
        let description = EKProperty.LabelContent(text: desc, style: .init(font: MainFont.light.with(size: 16), color: UIColor.darkSubText, alignment: .center))
        let simpleMessage = EKSimpleMessage(image: image, title: titleProp, description: description)
        
        let closeButtonLabelStyle = EKProperty.LabelStyle(font: MainFont.medium.with(size: 16), color: UIColor.darkText)
        let closeButtonLabel = EKProperty.LabelContent(text: closeBtn, style: closeButtonLabelStyle)
        let closeButton = EKProperty.ButtonContent(label: closeButtonLabel, backgroundColor: .clear, highlightedBackgroundColor:  UIColor.darkGray.withAlphaComponent(0.05)) {
            SwiftEntryKit.dismiss()
        }
        let buttonsBarContent = EKProperty.ButtonBarContent(with: closeButton, separatorColor: UIColor.lightGray, expandAnimatedly: true)
        let alertMessage = EKAlertMessage(simpleMessage: simpleMessage, buttonBarContent: buttonsBarContent)
        let contentView = EKAlertMessageView(with: alertMessage)
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }
}
