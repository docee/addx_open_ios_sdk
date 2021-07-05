//
//  HomeVideoCellBar.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/2/12.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import A4xBaseSDK

protocol HomeVideoCellBarProtocol : class {
    func recoredListAction()
    func shareUsersAction()
    func deviceSettingAction()
}

class HomeVideoCellBar: UIView {
    weak var `protocol` : HomeVideoCellBarProtocol?
    
    var videoStyle : ADVideoCellStyle{
        didSet {
            updateViews()
            updataData()
        }
    }
    
    var dataSource : A4xDeviceModel? {
        didSet {
            updataData()
        }
    }
    
    //MARK:- 生命周期
    init(frame: CGRect = CGRect.zero , videoStyle : ADVideoCellStyle = .default) {
        self.videoStyle = videoStyle
        
        super.init(frame: frame)
        
        self.nameV?.isHidden = false
        self.batterV.isHidden      = videoStyle != .default
        self.settingV?.isHidden     = videoStyle != .default
        self.membersV?.isHidden     = videoStyle != .default
        self.replayBtn?.isHidden    = videoStyle != .default
        self.updatePoint?.isHidden  = true

        self.backgroundColor = UIColor.white
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func updateViews (){
        
        self.imageV.isHidden = videoStyle != .default
        self.batterV.isHidden      = videoStyle != .default || !(dataSource?.supperBatter() ?? false)
        self.settingV?.isHidden     = videoStyle != .default
        self.membersV?.isHidden     = videoStyle != .default
        self.replayBtn?.isHidden    = videoStyle != .default
        self.nameV?.snp.updateConstraints({ (make) in
            make.width.lessThanOrEqualTo(videoStyle != .default ? 110.auto() : 130.auto())
        })
        
        self.nameV?.snp.remakeConstraints({ (make) in
            if videoStyle == .default {
                make.left.equalTo(self.imageV.snp.right).offset(7.auto())
            }else {
                make.left.equalTo(5.auto())
            }
            make.width.lessThanOrEqualTo(videoStyle != .default ? 110.auto() : 130.auto())
            make.centerY.equalTo(self.snp.centerY)
        })
    }
    //MARK:- view 创建
    func updataData() {
        self.nameV?.text = dataSource?.name
        self.batterV.isHidden = videoStyle != .default || !(dataSource?.supperBatter() ?? false)
        let userId = A4xUserDataHandle.Handle?.loginModel?.id
        self.membersV?.setImage(UIImage(named: dataSource?.adminId == userId ? "video_add_members" : "video_members" ), for: UIControl.State.normal)
        self.batterV.setBatterInfo(leavel: dataSource?.batter ?? 0, isCharging: dataSource?.charging ?? 0, isOnline: dataSource?.online ?? 0 == 1, quantityCharge: dataSource?.quantityCharge ?? false)
        
        
        if let deviceType = self.dataSource?.deviceType() {
            self.imageV.yy_setImage(with: URL(string: self.dataSource?.deviceSmailUrl ?? ""), placeholder: deviceType.smailImage())
        }
       
        var shouldUpdate = false

        if self.dataSource?.canUpdate() ?? false {
            if dataSource?.isAdmin() ?? false {
                shouldUpdate = true
            }
        }
        
        let isde = videoStyle == .default && shouldUpdate

        self.updatePoint?.isHidden = !isde
    }
    
    lazy var imageV : UIImageView = {
        let temp = UIImageView()
        temp.contentMode = .scaleAspectFit
        self.addSubview(temp)
        temp.snp.makeConstraints({ (make) in
            make.left.equalTo(15.auto())
            make.centerY.equalTo(self.snp.centerY)
            make.size.equalTo(CGSize(width: 24.auto(), height: 24.auto()))
        })
        return temp
    }()
    
    lazy var nameV : UILabel? = {
        let temp = UILabel()
        self.addSubview(temp)
        temp.contentHuggingPriority(for: NSLayoutConstraint.Axis.horizontal)
        temp.text = "Camera 1"
        temp.font = ADTheme.B2
        temp.textColor = ADTheme.C1
        
        temp.snp.makeConstraints({ (make) in
            make.top.equalTo(0)
            make.left.equalTo(self.imageV.snp.right).offset(7.auto())
            make.width.lessThanOrEqualTo(130.auto())
            make.centerY.equalTo(self.snp.centerY)
        })
        return temp
    }()
    
    lazy var batterV : A4xBaseBatteryView = {
        let temp = A4xBaseBatteryView()
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.left.equalTo(self.nameV!.snp.right).offset(5)
            make.width.equalTo(20.auto())
            make.height.equalTo(12.auto())
            make.centerY.equalTo(self.snp.centerY)
        })
        return temp
    }()
    
    
    lazy var replayBtn : UIButton? = {
        let temp = UIButton()
        temp.setImage(UIImage(named: "video_replay"), for: UIControl.State.normal)
        temp.addTarget(self, action: #selector(replayBtnAction), for: .touchUpInside)
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.right.equalTo(self.settingV!.snp.left).offset(-5.auto())

            make.centerY.equalTo(self.snp.centerY)
            make.size.equalTo(CGSize(width: 35.auto(), height: 35.auto()))
        })
        return temp
    }()
    
    lazy var membersV : UIButton? = {
        let temp = UIButton()
        temp.addTarget(self, action: #selector(membersBtnAction), for: .touchUpInside)
        self.addSubview(temp)

        temp.snp.makeConstraints({ (make) in
            make.right.equalTo(self.replayBtn!.snp.left).offset(-5.auto())

            make.centerY.equalTo(self.snp.centerY)
            make.size.equalTo(CGSize(width: 35.auto(), height: 35.auto()))
        })
        return temp
    }()
    
    lazy var updatePoint : UIView? = {
        let temp = UIView()
        temp.layer.cornerRadius = 3.auto()
        temp.isUserInteractionEnabled = false
        temp.clipsToBounds = true
        temp.backgroundColor = ADTheme.E1
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.top.equalTo(self.settingV!.snp.top).offset(4.auto())
            make.right.equalTo(self.settingV!.snp.right).offset(-5.auto())
            make.width.equalTo(6.auto())
            make.height.equalTo(6.auto())
        })
        
        return temp
    }()
    
    
    lazy var settingV : UIButton? = {
        let temp = UIButton()
        temp.addTarget(self, action: #selector(settingBtnAction), for: .touchUpInside)
        temp.setImage(UIImage(named: "video_setting"), for: UIControl.State.normal)
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.right.equalTo(self.snp.right).offset(-12.auto())
            make.centerY.equalTo(self.snp.centerY)
            make.size.equalTo(CGSize(width: 35.auto(), height: 35.auto()))
        })
        return temp
    }()
    
    @objc
    private func replayBtnAction(){
        self.protocol?.recoredListAction()
    }
    
    @objc
    private func membersBtnAction(){
        self.protocol?.shareUsersAction()
    }

    @objc
    private func settingBtnAction(){
        self.protocol?.deviceSettingAction()
    }
}
