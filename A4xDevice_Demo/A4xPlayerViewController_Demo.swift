//
//  A4xPlayerViewController_Demo.swift
//  A4xBaseSDK_Demo
//
//  Created by addx-wjin on 2021/6/29.
//

import UIKit
import A4xBaseSDK
import A4xWebRTCSDK

class A4xPlayerViewController_Demo: A4xBaseViewController {
    // 设备id
    var deviceId: String?
    
    // 设备模型
    var deviceModel: A4xDeviceModel?
    
    // 控制按钮title
    var btnTitleArr = ["开始", "暂停", "重试", "全屏"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.defaultNav()
        
        // 设置UI
        self.setupUI()
        
        // 根据id获取模型
        let model = A4xUserDataHandle.Handle?.getDevice(deviceId: self.deviceId ?? "")
        self.deviceModel = model
        
        // 直播封面
        videoView.image = thumbImage(deviceID: deviceModel?.id ?? "")
        
        // 注册代理协议
        A4xPlayerManager.handle.addStateProtocol(target: self)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue,
                                  forKey: "orientation")
        
        // 停止播放 - 切换页面
        A4xPlayerManager.handle.stop(device: self.deviceModel ?? A4xDeviceModel(), playNumber: nil, reason: A4xPlayerStopReason.changePage)
        
        // 移除代理
        A4xPlayerManager.handle.removeStateProtocol(target: self)
        
        // 清空view
        self.videoView.videoView = nil
    }
    
    // 直播展示view
    lazy var videoView: A4xPlayerView_Demo = {
        let v = A4xPlayerView_Demo(frame: CGRect.zero)
        v.protocol = self
        v.backgroundColor = .black
        return v
    }()
    
    // 直播状态显示lbl
    lazy var videoStateLbl: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .red
        lbl.font = ADTheme.B2
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()
    
    // 初始化UI
    func setupUI() {
        self.view.addSubview(videoView)
        self.view.addSubview(videoStateLbl)
        
        videoView.snp.makeConstraints({ (make) in
            make.top.equalTo(self.navView!.snp.bottom)
            make.centerX.equalTo(self.view.snp.centerX)
            make.width.equalTo(self.view.snp.width)
            make.height.equalTo(self.view.snp.width).multipliedBy(9.0 / 16.0)
        })
        
        videoStateLbl.snp.makeConstraints { (make) in
            make.centerX.equalTo(videoView.snp.centerX)
            make.top.equalTo(videoView.snp.bottom).offset(120.auto())
        }
        
        let btnHeight: CGFloat = 50.auto()
        let btnWidth: CGFloat = 60.auto()
        let btnSpacing: CGFloat = 20.auto()
        let btnWidthSum: CGFloat = CGFloat(CGFloat(btnTitleArr.count) * btnWidth)
        let spacingSum: CGFloat = CGFloat(CGFloat((btnTitleArr.count  - 1)) * btnSpacing)
        let leftNum: CGFloat = (self.view.width - (btnWidthSum + spacingSum)) / 2
        
        for i in 0..<btnTitleArr.count {
            let btn = UIButton()
            btn.setTitle(btnTitleArr[i], for: .normal)
            btn.tag = i
            btn.setTitleColor(.blue, for: .normal)
            btn.setTitleColor(.red, for: .highlighted)
            btn.backgroundColor = UIColor.colorFromHex("#E7E6E5")
            btn.addAction { [weak self] (btn) in
                self?.btnClick(tag: btn.tag)
            }
            self.view.addSubview(btn)
            btn.snp.makeConstraints { (make) in
                make.top.equalTo(videoView.snp.bottom).offset(20.auto())
                make.height.equalTo(btnHeight)
                make.width.equalTo(btnWidth)
                make.left.equalTo(leftNum + CGFloat(i) * (btnWidth + btnSpacing))
            }
        }
    }
    
    // 按钮点击
    func btnClick(tag: Int) {
        switch tag {
        case 0:
            // 开始
            
            // 竖屏直播开始启动
            A4xPlayerManager.handle.play(playType: .vertical, device: self.deviceModel ?? A4xDeviceModel(), voiceEnable: false, shouldSpeak: false)
            
            // 设置直播是否可放大
            A4xPlayerManager.handle.setVideoZoomEnable(device: self.deviceModel ?? A4xDeviceModel(), enable: false)
            
            break
        case 1:
            // 暂停
            
            // 停止播放 - 点击
            A4xPlayerManager.handle.stop(device: self.deviceModel ?? A4xDeviceModel(), playNumber: nil, reason: A4xPlayerStopReason.click)
            
            break
        case 2:
            // 重试
            A4xPlayerManager.handle.play(playType: .vertical, device: self.deviceModel ?? A4xDeviceModel(), voiceEnable: false, shouldSpeak: false)
            break
        case 3:
            // 全屏
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue,
                                      forKey: "orientation")
            
            A4xPlayerManager.handle.update(device: self.deviceModel ?? A4xDeviceModel())
 
            break
        default:
            break
        }
    }
}

// 凹 - 直播控制器层回调处理
extension A4xPlayerViewController_Demo: A4xPlayerStateChangeProtocol {
    
    // 语音
    func playerSpackVoice(data: [Float]) {
        
    }
    
    // 截图
    func playerSnapImage(image: UIImage?) {
        
    }
    
    // 播放速度
    func videoSpeed(speed: String) {
        
    }
    
    // 当前时间
    func videoCurrentTimer(date: TimeInterval) {
        
    }
    
    // 白光灯
    func videoWhiteLight(enable: Bool, error: String?) {
        
    }
    
    // 可摇杆
    func deviceEnableRotating(enable: Bool) {
        
    }
    
    // 通用信息
    func alertMessage(message: String?) {
        
    }
    
    // 获取设备id，底层使用
    func playerDeviceId() -> String {
        return self.deviceModel?.id ?? ""
    }
    
    // 业务层UI处理
    func playerConnectState(state: A4xPlayerStateType, videoV: UIView?, videoSize: CGSize) {
        debugPrint("-----------> playerConnectState state: \(state) videoV: \(videoV ?? UIView()) videoSize: \(videoSize)")
        
        // 更新suvView状态
        self.videoView.videoState = state
        
        switch state {
        case .unuse(thumb: _, isFock: _):
            break
        case .none(thumb: _):
            break
        case .loading(thumb: _):
            self.view.makeToastActivity(title: "loading") { (f) in }
            break
        case .playing:
            self.view.hideToastActivity()
            self.videoView.videoView = videoV
            break
        case .paused(thumb: _):
            
            fallthrough
        case .pausedp2p(thumb: _):
            
            break
        case .updating(error: _, thumb: _, reconnect: _, tipIcon: _):
            
            break
        case .finish:
            
            break
        case .error(error: let errStr, sdError:  _, thumb: _, action: _, tipIcon:  _, code: _):
            videoStateLbl.text = errStr
            break
        }
        
    }
    
    // 录像状态
    func playerRecoredState(state: A4xPlayerRecordState, error errorCode: Int, videoPath: String) {
        
    }
}

extension A4xPlayerViewController_Demo: A4xPlayerView_DemoProtocol {
    // 重连
    func videoReconnectAction() {
        A4xPlayerManager.handle.play(playType: .vertical, device: self.deviceModel ?? A4xDeviceModel(), voiceEnable: false, shouldSpeak: false)
    }
}

