//
//  ADNewHomeHeaderView.swift
//  AddxAi
//
//  Created by kzhi on 2019/9/10.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import Foundation
import UIKit
import A4xBaseSDK

typealias ADNewHomeHeaderBlock = (_ show  : Bool) -> Void


class ADNewHomeHeaderView : UIView {
    private var noTipVideoPush : Bool = false
    
    var headLeftCilckBlock : ADNewHomeHeaderBlock? {
        didSet {
            weak var weakSelf = self
            self.infoView.headerShowBlock = {(result ) in
                weakSelf?.headLeftCilckBlock?(result)

            }
        }
    }
    
    var showHeadDisturb : Bool = true {
        didSet {
            self.noDisturbingView.isHidden = !showHeadDisturb
        }
    }
    
    var headDisturbClickBlock : ((_ centerPoint : CGPoint)->Void)?
    
    var headRightCilckBlock : (()->Void)?
    
    var headAddCameraCilckBlock : (()->Void)?
    
    var headerDisturbingPoint : CGPoint {
        return CGPoint(x: self.midX, y: self.noDisturbingView.midY)
    }
    
    var disturbEnable : Bool = false {
        didSet {
            UIView.animate(withDuration: 0.2) { [weak self] in
                self?.noDisturbingView.alpha = (self?.disturbEnable ?? false) ? 1 : 0
            }
        }
    }
    
    var menuImage : UIImage? {
        didSet {
            if menuImage == nil {
                self.menuView.isHidden = true
            }else {
                self.menuView.setImage(menuImage, for: UIControl.State.normal)
                self.menuView.isHidden = false
            }
        }
    }
    
    var addCameraImage : UIImage? {
        didSet {
            if menuImage == nil {
                self.addCameraView.isHidden = true
            } else {
                self.addCameraView.setImage(addCameraImage, for: UIControl.State.normal)
                self.addCameraView.isHidden = false
            }
        }
    }
    
    var title : String? {
        didSet {
            self.infoView.title = title
        }
    }
    
    var titleType : HeaderCenterType = .Arrow {
        didSet {
            self.infoView.titleType = self.titleType
        }
    }
    
    var titleInfoShow : Bool? {
        didSet {
            if let s = titleInfoShow {
                self.infoView.headerShowType = s ? .Show : .Hidden
                self.infoView.updateType(ani : false);

            }
        }
    }
    
    @objc
    func headerAddClickActin(sender : UIButton){
        self.titleInfoShow = false
        self.headLeftCilckBlock?(false)

        self.headRightCilckBlock?()
    }
    
    @objc func headerAddCameraActin(sender : UIButton){
        self.headAddCameraCilckBlock?()
    }
    
    @objc func headerDisturbingActin(sender : UIButton) {
        self.headDisturbClickBlock?(CGPoint(x: self.midX, y: sender.midY))
    }
    
    private lazy var menuView : UIButton = {
        var temp : UIButton = UIButton()
        self.addSubview(temp)
        temp.setImage(UIImage(named: "homepage_head_add"), for: UIControl.State.normal)
        temp.imageView?.contentMode = .scaleAspectFit
        temp.imageEdgeInsets = UIEdgeInsets(top: 10.auto(), left: 10.auto(), bottom: 10.auto(), right: 10.auto())
        temp.addTarget(self, action: #selector(headerAddClickActin(sender:)), for: UIControl.Event.touchUpInside)
        temp.snp.makeConstraints({ (make) in
            make.centerY.equalTo(self.infoView.snp.centerY)
            make.height.equalTo(44.auto())
            make.width.equalTo(44.auto())
            make.right.equalTo(self.addCameraView.snp.left).offset(-2.auto())
        })
        return temp
    }()
    
    lazy var addCameraView : UIButton = {
          var temp : UIButton = UIButton()
          self.addSubview(temp)
          temp.setImage(UIImage(named: "nav_add_device_right"), for: UIControl.State.normal)
          temp.imageView?.contentMode = .scaleAspectFit
          temp.imageEdgeInsets = UIEdgeInsets(top: 10.auto(), left: 10.auto(), bottom: 10.auto(), right: 10.auto())
          temp.addTarget(self, action: #selector(headerAddCameraActin(sender:)), for: UIControl.Event.touchUpInside)
          temp.snp.makeConstraints({ (make) in
              make.centerY.equalTo(self.infoView.snp.centerY)
              make.height.equalTo(44.auto())
              make.width.equalTo(44.auto())
            make.right.equalTo(self.snp.right).offset(-15.5.auto())
          })
          return temp
      }()
    
    lazy var noDisturbingView : UIButton = {
        var temp : UIButton = UIButton()
        self.addSubview(temp)
        temp.setImage(R.image.ad_disturb_icon(), for: UIControl.State.normal)
        temp.imageView?.contentMode = .scaleAspectFit
        temp.imageEdgeInsets = UIEdgeInsets(top: 10.auto(), left: 10.auto(), bottom: 10.auto(), right: 10.auto())
        temp.addTarget(self, action: #selector(headerDisturbingActin(sender:)), for: UIControl.Event.touchUpInside)
        temp.snp.makeConstraints({ (make) in
            make.centerY.equalTo(self.infoView.snp.centerY)
            make.height.equalTo(44.auto())
            make.width.equalTo(44.auto())
            make.right.equalTo(self.menuView.snp.left).offset(-2.auto())
        })
        return temp
    }()
    
    private
    lazy var infoView : ADHomeHeaderInfo = {
        var temp : ADHomeHeaderInfo = ADHomeHeaderInfo()
        temp.titleLabel.font = ADTheme.H0
        temp.alignment = .left
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.bottom.equalTo(self.snp.bottom).offset(-10)
            make.height.equalTo(44.auto())
            make.width.lessThanOrEqualTo(self.snp.width).offset(-88)
            make.left.equalTo(15.auto())
        })
        return temp
    }()
    
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.infoView.isHidden = false
        
        self.menuView.isHidden = false
        self.addCameraView.isHidden = false
        self.noDisturbingView.isHidden = false
//        //设置阴影颜色
//        self.layer.shadowColor = ADTheme.C4.cgColor
//        //设置透明度
//        self.layer.shadowOpacity = 0.2
//        //设置阴影半径
//        self.layer.shadowRadius = 5
//        //设置阴影偏移量
//        self.layer.shadowOffset = CGSize(width: 0, height: 5)
    }
    
    deinit {
        A4xLog(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
