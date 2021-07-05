//
//  ADDisturbAlertView.swift
//  AddxAi
//
//  Created by kzhi on 2020/12/11.
//  Copyright © 2020 addx.ai. All rights reserved.
//

import Foundation
import UIKit
import Lottie
import A4xBaseSDK
import IQKeyboardManager

class ADDisturbAlertView : UIControl {
    weak var showSuperView : UIView?
    private var beginPoint : CGPoint = CGPoint.zero
    private let defaultHeight : CGFloat = 40.auto()
    private let maxWidth : CGFloat = 120.auto()
    let disturbAlertMargenTop : CGFloat = 5.auto()
    let disturbAlertMargenBottom : CGFloat = 10.auto()
    
    var hiddenActionBlock : (()->Void)?
    
    var timer : Timer?
    convenience init() {
        self.init(frame : .zero)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = ADTheme.Theme
        self.clipsToBounds = true
        self.layer.cornerRadius = defaultHeight / 2
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        A4xLog(type(of: self).description() + " deinit")
    }
    
    func free() {
        timer?.invalidate()
        timer = nil
    }
    
    func showAnimail(beginPoint : CGPoint , insetTop : CGFloat, changeSuperHeightBlock :@escaping ()->Void  , comple : ()->Void = {}) {
        if timer != nil {
            return
        }

        timer = Timer(timeInterval: 1, target: self, selector: #selector(updateShowTimes), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .common)
        timer?.fire()

        let tempV = self.showSuperView?.viewContainingController?.view

        self.beginPoint = beginPoint
        self.frame = CGRect(x: beginPoint.x - defaultHeight / 2, y: beginPoint.y - defaultHeight / 2, width: defaultHeight, height: defaultHeight)
        tempV?.addSubview(self)

        self.alpha = 0
        let animation = Animation.named("account_disable_push_animail")
        self.animailView.animation = animation
        self.timeLabel.alpha = 0
        self.animailView.play { (comple) in }
        var finalTop : CGFloat =  120
        if let showS = self.showSuperView as? UIScrollView {
            finalTop = (showS.minY + showS.contentInset.top + self.disturbAlertMargenTop)
            showS.setContentOffset(CGPoint(x: 0, y: -insetTop), animated: true)
        }
        changeSuperHeightBlock()

        UIView.animateKeyframes(withDuration: 0.8, delay: 0, options:
            UIView.KeyframeAnimationOptions.layoutSubviews, animations: { [weak self] in
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.3) {
                    self?.alpha = 1
                    self?.frame = CGRect(x: beginPoint.x - (self?.defaultHeight ?? 0) / 2, y: finalTop, width: (self?.defaultHeight ?? 0), height: (self?.defaultHeight ?? 0))
                }
                UIView.addKeyframe(withRelativeStartTime: 0.35, relativeDuration: 0.3) { [weak self] in
                    self?.frame = CGRect(x: beginPoint.x - (self?.maxWidth ?? 0) / 2, y: (self?.minY ?? 0), width: (self?.maxWidth ?? 0), height: (self?.defaultHeight ?? 0))
                }
                UIView.addKeyframe(withRelativeStartTime: 0.7, relativeDuration: 0.4) { [weak self] in
                    self?.timeLabel.alpha = 1

                }
        }) {[weak self] (f) in
            guard let self = self  else {
                return
            }
            self.removeFromSuperview()
            self.animailView.currentProgress = CGFloat(1)

            self.showSuperView?.addSubview(self)
            if let showS = self.showSuperView as? UIScrollView {
                if insetTop != showS.contentInset.top {
                    var inset = showS.contentInset
                    inset.top = insetTop
                    showS.contentInset = inset
                    showS.setContentOffset(CGPoint(x: 0, y: -insetTop), animated: false)
                }
                self.alpha = 1

                self.frame = CGRect(x: beginPoint.x - self.maxWidth / 2, y: -showS.contentInset.top + self.disturbAlertMargenTop + 10.auto(), width: self.maxWidth, height: self.defaultHeight)
            }

        }

    }
    
    func hiddenAnimail( changeSuperHeightBlock :@escaping ()->Void  ,comple : ()->Void){
        let animation = Animation.named("account_enable_push_animail")
        self.animailView.animation = animation
        
        timer?.invalidate()
        timer = nil
        
        let frame = self.convert(self.bounds, to: nil)
        self.removeFromSuperview()
        self.frame = frame
        
        
        let tempV = self.showSuperView?.viewContainingController?.view

        tempV?.addSubview(self)

        
        UIView.animate(withDuration: 0.3) {
            self.timeLabel.alpha = 0
            self.frame = CGRect(x: self.beginPoint.x - self.defaultHeight / 2, y: self.minY, width: self.defaultHeight, height: self.defaultHeight)
        } completion: { [weak self] (f) in
            self?.animailView.play { (comple) in
                UIView.animate(withDuration: 0.3) { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.alpha = 0
                    self.frame = CGRect(x: self.beginPoint.x - self.defaultHeight / 2, y: self.beginPoint.y - self.defaultHeight / 2, width: self.defaultHeight, height: self.defaultHeight)
                    changeSuperHeightBlock()
                } completion: { (f) in
                    self?.removeFromSuperview()
                }
            }
        }
    }
    
    @objc
    func updateShowTimes() {
        if let (times , isEnd) = A4xUserDataHandle.Handle?.disturbModle?.currentTime() {
            self.timeLabel.text = times
            if isEnd {
                self.hiddenActionBlock?()
            }
        }else {
            self.timeLabel.text = "00:00:00"
            self.hiddenActionBlock?()
        }
        
    }
 
    
    lazy var animailView : AnimationView = {
        let temp = AnimationView()
        temp.isUserInteractionEnabled = false
        temp.contentMode = .scaleAspectFit
        self.addSubview(temp)
        temp.frame = CGRect(x: (defaultHeight - 24.auto()) / 2, y: (defaultHeight - 24.auto()) / 2, width: 24.auto(), height: 24.auto())

        return temp
    }()
    
    lazy var timeLabel : UILabel = {
        let temp = UILabel()
        temp.numberOfLines = 0
        temp.font = UIFont.systemFont(ofSize: 16.auto())
        temp.textColor = UIColor.white
        temp.alpha = 0
        temp.text = "01:59:59"
        self.addSubview(temp)
        temp.frame = CGRect(x: animailView.maxX + 6.auto(), y: 0, width: maxWidth - animailView.maxX, height: defaultHeight)

        return temp
    }()
}
