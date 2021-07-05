//
//  HomeVideoErrorView.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/3/21.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import A4xBaseSDK
import A4xWebRTCSDK


enum HomeVideoErrorType {
    case `default`
    case simple
}



enum HomeVideoButtonStyle : Int {
    case theme
    case line
    case none
}

struct HomeVideoItem {
    var style : HomeVideoButtonStyle
    var action : A4xVideoAction
    
    static func `default` (title : String) -> HomeVideoItem {
        return HomeVideoItem(style: .line, action: .video(title: title, style: .line))
    }
    
    static func upgrade(title : String) -> HomeVideoItem {
        return HomeVideoItem(style: .theme, action: .upgrade(title: title, style: .theme))
    }
}

class HomeVideoErrorButton : UIView {
    var buttonClickAction : ((_ action : A4xVideoAction)->Void)?

    
    var buttonItems : [HomeVideoItem]? {
        didSet {
            loadItems()
        }
    }
    
    private func loadItems () {
        self.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        
        guard let itemsSub = buttonItems else {
            return
        }
        
        var tempView : UIView? = nil
        let count = itemsSub.count
        for index in 0..<count {
            let item = itemsSub[index]
            let temp : UIButton = UIButton()
            temp.tag = index + 1000
            temp.layer.cornerRadius = 35/2
            temp.layer.masksToBounds = true
            temp.titleLabel?.font = ADTheme.B2
            if item.style == .theme {
                temp.setBackgroundImage(UIImage.init(color: ADTheme.Theme), for: .normal)
                temp.setTitleColor(UIColor.white , for: .normal)
                temp.setTitle(item.action.title() , for: .normal)
            } else if item.style == .none {
                temp.setTitleColor(UIColor.white , for: .normal)
                temp.setTitle(item.action.title() , for: .normal)
            } else if item.style == .line {
//                temp.setAttributedTitle(self.buttonAttributedString(item.title), for: .normal)
                temp.setTitleColor(ADTheme.Theme , for: .normal)
                temp.setTitle(item.action.title() , for: .normal)
                temp.titleLabel?.font = ADTheme.B1
            }
            temp.addTarget(self, action: #selector(buttonAction(sender:)), for: .touchUpInside)
            temp.titleLabel?.numberOfLines = 0
            temp.titleLabel?.lineBreakMode = .byWordWrapping
            
            let titleSize = temp.titleLabel?.sizeThatFits(CGSize(width: 150, height: 35))
            self.addSubview(temp)
            //temp.backgroundColor = .blue

            temp.snp.makeConstraints { (make) in
                make.centerX.equalTo(self.snp.centerX)
                
                if item.style == .none {
                    make.width.equalTo(max(190, (titleSize?.width ?? 0) + 24))
                } else {
                    make.width.equalTo(max(150, (titleSize?.width ?? 0) + 78))
                }
                make.height.equalTo(max(35, (titleSize?.height ?? 0)))
                
                if let uTemp = tempView {
                    make.top.equalTo(uTemp.snp.bottom).offset(3.auto())
                } else {
                    make.top.equalTo(0)
                }
                
                if index == count - 1 {
                    make.right.equalTo(self.snp.right)
                }
            }
            
            // loading ui
            let loadingV = UIImageView()
            loadingV.image = R.image.live_night_white_loading()
            loadingV.size = CGSize(width: 25.auto() , height: 25.auto() )
            temp.addSubview(loadingV)
            loadingV.isHidden = true
            loadingV.tag = index + 1000
            loadingV.snp.makeConstraints { (make) in
                make.size.equalTo(CGSize(width: 25.auto() , height: 25.auto()))
                make.center.equalTo(temp.snp.center)
            }
            
            tempView = temp
        }
    }
    
    
    
    private lazy var animail: CABasicAnimation = {
        let baseAnil = CABasicAnimation(keyPath: "transform.rotation")
        baseAnil.fromValue = 0
        baseAnil.toValue = Double.pi * 2
        baseAnil.duration = 1.5
        baseAnil.repeatCount = MAXFLOAT
        return baseAnil
    }()
    
    private func buttonAttributedString(_ title : String?) -> NSAttributedString? {
        guard let bTitle = title else {
            return nil
        }
        let attributes: [NSAttributedString.Key : Any] = [
            .foregroundColor: UIColor.white,
            .underlineColor: UIColor.white,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .font : ADTheme.B2
        ]
        let attrString = NSAttributedString(string: bTitle, attributes: attributes)
        return attrString
    }
    
    @objc private func buttonAction(sender : UIButton) {
        let index = sender.tag - 1000
        guard let item = self.buttonItems?.getIndex(index) else {
            return
        }
        
        // 休眠唤醒点击 loading 处理 - v2.6 废弃 - 2020.03.10
//        if case .sleepPlan = item.action {
//            let subV = sender.getSubView(name: "UIImageView")
//            if subV.count > 0 {
//                subV.forEach { (v) in
//                    if v.tag == sender.tag {
//                        v.isHidden = false
//                        v.layer.add(animail, forKey: "ddd")
//                    }
//                }
//            }
//        }
        //if item.action
        self.buttonClickAction?(item.action)
     }
}

class HomeVideoErrorView: UIView {
    
    private var maxWidth: Float
        
    var error: String = R.string.localizable.other_errors() {
        didSet {
            self.errorMsgLbl.text = error
            updateStyle()
        }
    }
    
    var type: HomeVideoErrorType = .default {
        didSet {
            updateStyle()
        }
    }
    
    var tipIcon: UIImage? {
        didSet {
            if tipIcon != nil {
                self.imageTipV.isHidden = false
                self.imageTipV.image = tipIcon
            } else {
                self.imageTipV.isHidden = true
            }
        }
    }
    
    var buttonItems: [HomeVideoItem]? {
        didSet {
            self.detailButton.buttonItems = buttonItems
        }
    }
    
    var buttonClickAction: ((_ action : A4xVideoAction)->Void)? {
        didSet {
            self.detailButton.buttonClickAction = buttonClickAction
        }
    }
    
    func defaultButton() {
        self.buttonItems = [HomeVideoItem.default(title: R.string.localizable.reconnect())]
    }
    
    func forceUpgradeButton() {
        self.buttonItems = [HomeVideoItem(style: .theme, action: .upgrade(title: R.string.localizable.update(), style: .theme) )]
    }
    
    func upgradeButton() {
        self.buttonItems = [HomeVideoItem(style: .theme, action: .upgrade(title: R.string.localizable.update(), style: A4xVideoButtonStyle.theme)) , HomeVideoItem(style: .line, action: .video(title: R.string.localizable.do_not_update(), style: A4xVideoButtonStyle.none) )]
    }
    
    func sleepPlanButton() {
        self.buttonItems = [HomeVideoItem(style: .theme, action: .sleepPlan(title: R.string.localizable.camera_wake_up(), style: .theme) )]
    }
    
    private lazy var imageTipV: UIImageView = {
        let temp = UIImageView()
        self.addSubview(temp)
        
        temp.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.errorMsgLbl.snp.top).offset(-10)
            make.centerX.equalTo(self.snp.centerX)
            make.size.equalTo(CGSize(width: 30, height: 30))
        }
        return temp
    }()
    
    lazy var errorMsgLbl: UILabel = {
        let temp = UILabel()
        //temp.setContentHuggingPriority(UILayoutPriority.required, for: NSLayoutConstraint.Axis.vertical)
        temp.numberOfLines = 0
        temp.backgroundColor = UIColor.clear
        temp.lineBreakMode = .byWordWrapping
        temp.font = ADTheme.B2
        temp.textColor = .white
        temp.textAlignment = .center
        temp.text = self.error
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.width.equalTo(self.snp.width).offset(-20.auto())
            make.height.lessThanOrEqualTo(120.auto())
            make.centerX.equalTo(self.snp.centerX)
            make.centerY.equalTo(self.snp.centerY)//.offset(-20)
        })
        
        return temp
    } ()
    
    lazy var detailButton: HomeVideoErrorButton = {
        let temp = HomeVideoErrorButton()
        self.addSubview(temp)
        temp.snp.remakeConstraints { (make) in
            make.top.equalTo(self.errorMsgLbl.snp.bottom).offset(15.auto())
            make.centerX.equalTo(self.snp.centerX)
            make.bottom.equalTo(self.snp.bottom)
        }
        return temp
    }()
    
    
    init(frame: CGRect = .zero , maxWidth : Float = 300) {
        self.maxWidth = maxWidth
        super.init(frame: .zero)
        self.errorMsgLbl.isHidden = false
        self.detailButton.isHidden = false
        self.backgroundColor = UIColor.clear
    }
    
    private func updateStyle() {
        switch self.type {
        case .default:
            self.imageTipV.isHidden = false
            self.errorMsgLbl.snp.updateConstraints { (make) in
                if self.detailButton.buttonItems?.count ?? 0 > 0 {
                    make.centerY.equalTo(self.snp.centerY).offset(-10)
                } else {
                    make.centerY.equalTo(self.snp.centerY)//.offset(10)
                }
                make.width.equalTo(self.snp.width).offset(-30.auto())

            }
            self.errorMsgLbl.isHidden = false
            self.detailButton.isHidden = false
        case .simple:
            self.imageTipV.isHidden = true
            self.errorMsgLbl.snp.updateConstraints { (make) in
                make.centerY.equalTo(self.snp.centerY)//.offset(10)
                make.width.equalTo(self.snp.width).offset(-20.auto())
            }
            self.errorMsgLbl.isHidden = false
            self.detailButton.isHidden = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if self.type == .simple && buttonItems?.count == 1 {
            self.buttonClickAction?(.video(title: nil, style: nil))
        }
    }
}
