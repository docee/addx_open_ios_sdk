//
//  ADHomeDeviceControlSpeak.swift
//  AddxAi
//
//  Created by kzhi on 2020/9/2.
//  Copyright © 2020 addx.ai. All rights reserved.
//

import Foundation
import UIKit
import A4xBaseSDK

class ADHomeDeviceControlSpeak : UIView {
    var spackVoiceData : [Float]? {
        didSet {
            speakWarView.pointLocation = spackVoiceData
        }
    }
    
    var deviceSpeak : ((_ enable : Bool)->Bool)?
    var editButtonBlock : (()->Void)?
    var changeFloowAction : ((_ enable : Bool ,_ comple : @escaping (Bool)->Void)->())?
    
    var canStandBy : Bool = false {
        didSet {
        }
    }
    
    var canRotate : Bool = true {
        didSet {
            self.editBtn.isHidden = !canRotate
            self.autoFllowBtn.isHidden = !canRotate
            
        }
    }
    
    var isFloow : Bool = true {
        didSet {
            self.autoFllowBtn.isSelected = isFloow
            autoFllowBtn.isLoading = false
        }
    }
    
    var isFollowAdmin : Bool = true {
        didSet {
            self.autoFllowBtn.isHidden = !isFollowAdmin
            autoFllowBtn.isLoading = false
        }
    }
    
    // 追踪按钮是否可点击
    var autoFollowBtnIsEnabled: Bool = true {
        didSet {
            //let btnCurrentImg = self.autoFllowBtn.currentImage
            //let pressColor = btnCurrentImg?.multiplyColor(btnCurrentImg?.mostColor ?? ADTheme.C5, by: 0.9)
            //self.autoFllowBtn.setImage(UIImage.init(color: pressColor ?? ADTheme.C5), for: .disabled)
            self.autoFllowBtn.isEnabled = autoFollowBtnIsEnabled
        }
    }
    
    // 追踪按钮替换人形追踪
    var autoFollowBtnIsHumanImg: Bool = true {
        didSet {
//            if autoFollowBtnIsHumanImg {
//                autoFllowBtn.setImage(R.image.home_device_auto_fllow_default(), for: .normal)
//                autoFllowBtn.setImage(R.image.home_device_auto_fllow(), for: .selected)
//            } else {
//                autoFllowBtn.setImage(R.image.home_device_auto_move_default(), for: .normal)
//                autoFllowBtn.setImage(R.image.home_device_auto_move_fllow(), for: .selected)
//            }
//            autoFllowBtn.setImage(R.image.home_device_auto_move_default(), for: .normal)
            autoFllowBtn.setImage(R.image.home_device_auto_move_fllow(), for: .selected)
        }
    }
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.autoFllowBtn.isHidden = false
        self.editBtn.isHidden = false
        self.speakWarView.isHidden = false
        self.speakWarView.alpha = 0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var bounds: CGRect {
        didSet {
            self.updateViewFrame()
            A4xLog("ADHomeDeviceControlSpeak bounds --> \(bounds)")
        }
    }
    
    private func updateViewFrame(){
        let itemSize = CGSize(width: 40.auto(), height: 40.auto())
        self.autoFllowBtn.frame = CGRect(x: 10.auto(), y: (self.height - itemSize.height) / 2, width: itemSize.width, height: itemSize.height)
        self.editBtn.frame = CGRect(x: self.width - itemSize.width - 10.auto(), y: (self.height - itemSize.height) / 2, width: itemSize.width, height: itemSize.height)
        
        let speakSize = CGSize(width: 75.auto(), height: 55.auto())
        self.speakBtn.frame = CGRect(x: self.width / 2.0 - speakSize.width / 2.0 , y: (self.height - speakSize.height) / 2, width: speakSize.width , height: speakSize.height)
        
        let speakVHeight : CGFloat = 50
        self.speakWarView.frame = CGRect(x: 10.auto(), y: (self.height - speakVHeight) / 2, width: self.width - 20.auto(), height: speakVHeight)
    }
    
    private lazy
    var speakBtn : ADLiveSpeakImageView = {
        let temp = ADLiveSpeakImageView()
        temp.backgroundColor = UIColor.white
        self.addSubview(temp)
//        temp.setImage(R.image.home_video_speak(), for: UIControl.State.normal)
//        temp.touchAction = {[weak self] type in
//            A4xLog("ADHomeDeviceControlSpeak --> \(type)")
//            switch type {
//            case .down:
//                self?.startSpeak()
//            case .up:
//                self?.stopSpeak()
//            }
//        }
        return temp
    }()
    
    private lazy
    var autoFllowBtn : A4xBaseLoadingButton = {
        let temp = A4xBaseLoadingButton()
        temp.layer.cornerRadius = 20.auto()
        temp.layer.borderColor = UIColor.hex(0xECEDEF).cgColor
        temp.layer.borderWidth = 1
        temp.setImage(R.image.home_device_auto_move_default(), for: .normal)
        temp.setImage(R.image.home_device_auto_move_fllow(), for: .selected)
        //temp.adjustsImageWhenDisabled = false
        //let btnCurrentImg = temp.currentImage
        //let pressColor = btnCurrentImg?.multiplyColor(btnCurrentImg?.mostColor ?? ADTheme.C5, by: 0.9)
        //temp.setImage(UIImage.init(color: pressColor ?? ADTheme.C5), for: .disabled)
        temp.addTarget(self, action: #selector(fllowButtonAction), for: .touchUpInside)
        self.addSubview(temp)
        return temp
    }()
    
    private lazy
    var editBtn : UIButton = {
        let temp = UIButton()
        temp.layer.cornerRadius = 20.auto()
        temp.layer.borderColor = UIColor.hex(0xECEDEF).cgColor
        temp.layer.borderWidth = 1
        temp.setImage(R.image.home_device_edit_modle(), for: .normal)
        temp.addTarget(self, action: #selector(editButtonAction), for: .touchUpInside)
        self.addSubview(temp)
        return temp
    }()
    
    private lazy
    var speakWarView : ADHomeDeviceVoiceWarView = {
        let temp = ADHomeDeviceVoiceWarView()
        temp.backgroundColor = UIColor.white
        self.insertSubview(temp, belowSubview: speakBtn)
        return temp
    }()
    
    private func startSpeak(){
        UIView.animate(withDuration: 0.2) {
            let autoframe = self.autoFllowBtn.frame
            let autoNewframe = CGRect(origin: CGPoint(x: -autoframe.width, y: autoframe.minY), size: autoframe.size)
            self.autoFllowBtn.frame = autoNewframe
            self.autoFllowBtn.alpha = 0

            let editframe = self.editBtn.frame
            let editNewframe = CGRect(origin: CGPoint(x: self.width, y: editframe.minY), size: editframe.size)
            self.editBtn.frame = editNewframe
            self.editBtn.alpha = 0
            
            self.speakWarView.alpha = 1
        }
        speakWarView.load()
        if let result = deviceSpeak?(true) {
            if !result {
                stopSpeak()
            }
        }
    }
    
    private func stopSpeak() {
        UIView.animate(withDuration: 0.2) {
            let autoframe = self.autoFllowBtn.frame
            let autoNewframe = CGRect(origin: CGPoint(x: 10.auto(), y: autoframe.minY), size: autoframe.size)
            self.autoFllowBtn.frame = autoNewframe
            self.autoFllowBtn.alpha = 1

            let editframe = self.editBtn.frame
            let editNewframe = CGRect(origin: CGPoint(x: self.width - editframe.size.width - 10.auto(), y: editframe.minY), size: editframe.size)
            self.editBtn.frame = editNewframe
            self.editBtn.alpha = 1
            
            self.speakWarView.alpha = 0
        }
        speakWarView.free()
        if let _ = deviceSpeak?(false) {
            
        }
    }
    
    @objc
    private func editButtonAction(){
        let playVideoEM = A4xPlayVideoEventModel()
        playVideoEM.live_player_type = "halfscreen"
        A4xEventManager.endEvent(event:ADTickerPlayVideo.live_remoteControl_savePoint_show(eventModel: playVideoEM))
        self.editButtonBlock?()
    }
    
    @objc
    private func fllowButtonAction(){
        let enable = !autoFllowBtn.isSelected
        debugPrint("-------------> fllowButtonAction enable:\(enable)")
        autoFllowBtn.isLoading = true
        A4xEventManager.startEvent(eventName: "live_remoteControl_sportTrack_switch_click")
        changeFloowAction?(enable) { [weak self] scuess in
            debugPrint("-------------> fllowButtonAction enable:\(enable) result:\(scuess)")

            let playVideoEM = A4xPlayVideoEventModel()
            playVideoEM.live_player_type = "halfscreen"
            playVideoEM.switch_status = "\(enable)"
            A4xEventManager.endEvent(event:ADTickerPlayVideo.live_remoteControl_sportTrack_switch_click(eventModel: playVideoEM))
            
            self?.autoFllowBtn.isLoading = false
            if scuess {
                self?.autoFllowBtn.isSelected = enable
            }
        }
    }
}
