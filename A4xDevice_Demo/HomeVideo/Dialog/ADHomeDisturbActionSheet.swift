//
//  ADHomeDisturbActionSheet.swift
//  AddxAi
//
//  Created by kzhi on 2020/12/13.
//  Copyright © 2020 addx.ai. All rights reserved.
//

import Foundation
import SDCAlertView

enum ADDisturbActionType {
    case cancle
    case t_30min
    case t_2h
    case t_12h
    
    func intValue() -> Int {
        switch self {
        case .cancle:
            return -1
        case .t_30min:
            return 30 * 60
        case .t_2h:
            return 2 * 60 * 60
        case .t_12h:
            return 12 * 60 * 60 
        }
    }
}


extension UIViewController {
    func showDisturbActionSheet(comple :@escaping (_ type : ADDisturbActionType)->Void){
        let alert = AlertController(title: nil, message: nil ,preferredStyle: .actionSheet)
        alert.visualStyle.contentPadding = UIEdgeInsets(top: 0, left: 56, bottom: 12, right: 56)
        alert.visualStyle.backgroundColor = UIColor.white
        if #available(iOS 13.0, *) {
            alert.overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }

        
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.attributedText = self.actionSheet(string: R.string.localizable.do_not_disturb(), font: UIFont.systemFont(ofSize: 18.auto(), weight: .medium), color: UIColor.hex(0x2F3742))
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        alert.contentView.addSubview(titleLabel)
   
        
        let messageLable = UILabel()
        messageLable.numberOfLines = 0
        messageLable.attributedText = self.actionSheet(string: R.string.localizable.do_not_disturb_describ(), font: UIFont.systemFont(ofSize: 13.auto()), color: UIColor.hex(0x666666))
        messageLable.translatesAutoresizingMaskIntoConstraints = false
        alert.contentView.addSubview(messageLable)
        NSLayoutConstraint.activate([
            titleLabel.firstBaselineAnchor.constraint(equalTo: alert.contentView.topAnchor, constant: 20),
            titleLabel.widthAnchor.constraint(equalTo: alert.contentView.widthAnchor, constant: -50),
            titleLabel.centerXAnchor.constraint(equalTo: alert.contentView.centerXAnchor),

        ])
        NSLayoutConstraint.activate([
            messageLable.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            messageLable.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            messageLable.firstBaselineAnchor.constraint(equalTo: titleLabel.lastBaselineAnchor,
                                                            constant: 25),
            messageLable.widthAnchor.constraint(equalTo: alert.contentView.widthAnchor, constant: -50),

            messageLable.lastBaselineAnchor.constraint(equalTo: alert.contentView.bottomAnchor,
                                                            constant: -10),
        ])

        alert.addAction(AlertAction(attributedTitle: self.actionSheet(string: R.string.localizable.min30(), font: UIFont.systemFont(ofSize: 16.auto()), color: UIColor.hex(0x2F3742)), style: .normal, handler: { (a) in
            comple(.t_30min)
        }))
        
        alert.addAction(AlertAction(attributedTitle: self.actionSheet(string: R.string.localizable.h1(), font: UIFont.systemFont(ofSize: 16.auto()), color: UIColor.hex(0x2F3742)), style: .normal, handler: { (a) in
            comple(.t_2h)
        }))
        
        alert.addAction(AlertAction(attributedTitle: self.actionSheet(string: R.string.localizable.h12(), font: UIFont.systemFont(ofSize: 16.auto()), color: UIColor.hex(0x2F3742)), style: .normal, handler: { (a) in
            comple(.t_12h)
        }))
        alert.addAction(AlertAction(attributedTitle: self.actionSheet(string: R.string.localizable.cancel(), font: UIFont.systemFont(ofSize: 16.auto()), color: UIColor.hex(0x999999)), style: .preferred, handler: { (action) in
        }))


        alert.present()
    }
 
    private func actionSheet(string : String , font : UIFont , color : UIColor) -> NSAttributedString {
        let param = NSMutableParagraphStyle()
        param.lineSpacing = 3
        param.lineBreakMode = .byWordWrapping
        param.alignment = .center
        let attr: [NSAttributedString.Key : Any] = [.font: font,.foregroundColor: color ,.paragraphStyle : param]
        let attrString = NSMutableAttributedString(string: string)
        attrString.addAttributes(attr, range: NSRange(location: 0, length: attrString.length))
        return attrString
    }
}
