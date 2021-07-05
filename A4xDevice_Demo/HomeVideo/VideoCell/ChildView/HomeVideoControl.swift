//
//  HomeVideoPlayVideo.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/2/12.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import ADDXWebRTC
import Lottie
import A4xBaseSDK
import A4xWebRTCSDK

protocol HomeVideoControlProtocol: class {
    func videoSendPlay(btnType: String)
    func videoPlayStop()
    func videoAudioEnable(enable: Bool)

    func videoFullAction()
    func videoReportLogAction()
    func videoHelpAction()
    func videoErrorAction(admin: Bool, action: A4xVideoAction)
}

class ADVideoNewView: UIImageView {
    var showChangeAnilmail: Bool = false
    
    var thumbImage: UIImage? {
        didSet {
            if (playerView == nil || (playerView?.subviews.count ?? 0) == 0 ) && showChangeAnilmail {
                let transition = CATransition()
                transition.duration = 0.4
                transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                transition.type = CATransitionType.fade
                self.layer.add(transition, forKey: "ddd")
            }
            self.image = self.thumbImage
            updateImage()
        }
    }
    
    var blueEffectEnable: Bool = true {
        didSet {
            self.weakBlueEffectView.isHidden = !blueEffectEnable
//            updateImage()
        }
    }
    
    func updateImage() {
        if self.blueEffectEnable {
            self.image = thumbImage?.blurred(radius: 15)
        } else {
            self.image = thumbImage
        }
    }
    
    weak var playerView: UIView? {
        didSet {
            if let v = self.playerView {
                v.translatesAutoresizingMaskIntoConstraints = true
                self.playerView?.frame = self.bounds
                self.playerView?.setNeedsDisplay()
                self.insertSubview(v, at: 0)
                return
            }
        }
    }
    
    override var frame: CGRect {
        didSet {
            self.playerView?.frame = self.bounds
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.playerView?.frame = self.bounds
    }
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
//        self.weakBlueEffectView.isHidden = false
        self.backgroundColor = UIColor.black
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var weakBlueEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let tempV = UIVisualEffectView(effect: blurEffect)
        tempV.backgroundColor = UIColor.clear
        tempV.alpha = 0.6
        self.addSubview(tempV)

        tempV.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left)
            make.width.equalTo(self.snp.width)
            make.height.equalTo(self.snp.height)
            make.top.equalTo(0)
        }
        return tempV
    }()
    
}

class HomeVideoControl: UIView {

    weak var delegete: HomeVideoControlProtocol?
    
    var deviceId: String?
    var isAdmin: Bool = true
    var deviceVersion: String = "1.0.0"
    var showChangeAnilmail: Bool = false {
        didSet {
            self.videoView.showChangeAnilmail = showChangeAnilmail
        }
    }
    var autoHiddenTime: TimeInterval = 3
    var isAutoHidden: Bool = false
    
    var videoStyle: ADVideoCellStyle{
        didSet {
            updateViews()
            playStatusUpdate(isChangeed: false)
        }
    }
    var videoState: A4xPlayerStateType = .finish {
        didSet {
            debugPrint("-----------> videoState didSet to playStatusUpdate")
            playStatusUpdate(isChangeed: oldValue != videoState)
        }
    }
    
    var audioEnable: Bool  = false {
        didSet {
//            self.volumeBtn?.isSelected = !audioEnable
        }
    }
    
    var tipIcon: UIImage? {
        didSet {
            self.errorView.tipIcon = tipIcon
        }
    }
    
    var deviceOnLine: Bool = true // 是否在线
    var deviceStatus: Int = 0 // 是否休眠
    var deviceDormancyMessage: String = "" // 休眠描述
    
    //MARK:- 生命周期
    init(frame: CGRect = CGRect.zero, videoStyle: ADVideoCellStyle = .default , delegete: HomeVideoControlProtocol) {
        self.videoStyle = videoStyle
        self.delegete = delegete
        super.init(frame: frame)
        self.videoView.isHidden = false
        self.bottomShareImageV?.isHidden = false
        self.playBtn?.isHidden = false
        self.fullVideoBtn?.isHidden = false
        self.loadingView.isHidden = true
        self.errorView.isHidden = true
        self.helpBut?.isHidden = true
        self.liveBgView.isHidden = false
        self.liveText.isHidden = false
        self.logReport.isHidden = true
//        self.volumeBtn?.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateViews() {
        if (self.videoStyle == .default) {
            self.fullVideoBtn?.snp.updateConstraints({ (make) in
                make.right.equalTo(self.snp.right).offset(-15)
                make.bottom.equalTo(self.snp.bottom).offset(-10)
            })
        } else {
            self.fullVideoBtn?.snp.updateConstraints({ (make) in
                make.right.equalTo(self.snp.right).offset(-9)
                make.bottom.equalTo(self.snp.bottom).offset(-5)
            })
        }
        
        self.errorView.snp.updateConstraints { (make) in
            make.width.equalTo(self.snp.width)
            make.height.equalTo(self.snp.height)
            make.centerX.equalTo(self.snp.centerX)
            make.centerY.equalTo(self.snp.centerY)
        }
    }
    
    //MARK:- view 创建
    lazy var helpBut: UIButton? = {
        let temp = UIButton()
        temp.setImage(R.image.live_video_question(), for: UIControl.State.normal)
        temp.addTarget(self, action: #selector(helpAction(sender:)), for: .touchUpInside)
        self.addSubview(temp)
        temp.snp.makeConstraints({ (make) in
            make.left.equalTo(15)
            make.top.equalTo(20)
        })
        return temp
    }()
    
    //MARK:- view 创建
    lazy var playBtn: UIButton? = {
        let temp = UIButton()
        temp.setImage(UIImage(named: "video_play"), for: UIControl.State.normal)
        temp.setImage(UIImage(named: "video_pause"), for: UIControl.State.selected)
        temp.addTarget(self, action: #selector(playVideoAction(sender:)), for: .touchUpInside)
        self.addSubview(temp)
        temp.snp.makeConstraints({ (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.centerY.equalTo(self.snp.centerY)
            make.size.equalTo(CGSize(width: 40.auto(), height: 40.auto()))
        })
        return temp
    }()
    
    lazy var videoView: ADVideoNewView = {
        let temp = ADVideoNewView()
        temp.clipsToBounds = true
        self.addSubview(temp)
        weak var weakSelf = self
        temp.snp.makeConstraints({ (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.centerY.equalTo(self.snp.centerY)
            make.width.equalTo(self.snp.width)
            make.height.equalTo(self.snp.height)
            //make.edges.equalTo(self.snp.edges)
        })
        return temp
    }()
    
    lazy var bottomShareImageV: UIImageView? = {
        let temp = UIImageView()
        temp.image = R.image.home_play_bottom_shard_bg()
        self.addSubview(temp)
        temp.snp.makeConstraints({ (make) in
            make.bottom.equalTo(self.snp.bottom)
            make.height.equalTo(55.auto())
            make.left.equalTo(0)
            make.width.equalTo(self.snp.width)
        })
        return temp
    }()
    
    //MARK:- view 创建
    lazy var volumeBtn: UIButton? = {
        let temp = UIButton()
        temp.setImage(UIImage(named: "video_volume"), for: UIControl.State.normal)
        temp.setImage(UIImage(named: "video_volume_mute"), for: UIControl.State.selected)
        temp.addTarget(self, action: #selector(volumeVideoAction(sender:)), for: .touchUpInside)
        self.addSubview(temp)

        temp.snp.makeConstraints({ (make) in
            make.left.equalTo(15)
            make.bottom.equalTo(self.snp.bottom).offset(-10)
        })
        
        return temp
    }()
    
    //MARK:- view 创建
    lazy var loadingView: HomeVideoLoadingView = {
        let temp = HomeVideoLoadingView()
        self.addSubview(temp)
        temp.snp.makeConstraints({ (make) in
            make.centerX.equalTo(self.snp.centerX).offset(8.auto())
            make.centerY.equalTo(self.snp.centerY)
        })
        return temp
    }()
    
    lazy var errorView: HomeVideoErrorView = {
        let temp = HomeVideoErrorView()
//        temp.backgroundColor = UIColor.hex(0x000000, alpha: 0.5)
        temp.buttonClickAction = {[weak self] type in
            // 首页点击错误页按钮处理
            UserDefaults.standard.set("1", forKey: "show_error_report_\(self?.deviceId ?? "")")
            //UserDefaults.standard.set("0", forKey: "show_error_report_\()")
            debugPrint("------------> buttonClickAction type: \(type)")
            self?.errorButtonAction(type: type)
        }
        self.insertSubview(temp, aboveSubview: self.videoView)
        temp.snp.makeConstraints({ (make) in
            make.width.equalTo(self.snp.width)
            make.height.equalTo(self.snp.height)
            make.centerX.equalTo(self.snp.centerX)
            make.centerY.equalTo(self.snp.centerY)
        })
        return temp
    }()
    
    lazy var logReport: UIButton = {
        let temp = UIButton()
        temp.setImage(R.image.home_report_log(), for: UIControl.State.normal)
        temp.addTarget(self, action: #selector(reportLogAction), for: .touchUpInside)
        self.addSubview(temp)
        temp.snp.makeConstraints({ (make) in
            make.right.equalTo(self.snp.right).offset(-15)
            make.top.equalTo(self.snp.top).offset(10)
        })
        return temp
    }()
    
    lazy var liveAnimailView: AnimationView = {
        let temp = AnimationView(name: "live_play_animail")
        temp.loopMode = .loop
        self.liveBgView.addSubview(temp)
        temp.snp.makeConstraints({ (make) in
            make.width.equalTo(12.auto())
            make.height.equalTo(12.auto())
            make.left.equalTo(3.auto())
            make.centerY.equalTo(self.liveBgView)
        })
        return temp
    }()
    
    lazy var liveBgView: UIView = {
        let temp = UIView()
        temp.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        temp.cornerRadius = 11.auto()
        temp.clipsToBounds = true
        self.addSubview(temp)
        temp.snp.makeConstraints({ (make) in
            make.height.equalTo(22.auto())
            make.left.equalTo(8.auto())
            make.top.equalTo(8.auto())
        })
        return temp
    }()
    
    lazy var liveText: UILabel = {
        let temp = UILabel()
        self.liveBgView.addSubview(temp)
        temp.font = ADTheme.B3
        temp.textColor = UIColor.white
        temp.setContentHuggingPriority(UILayoutPriority.required, for: NSLayoutConstraint.Axis.horizontal)
        temp.text = R.string.localizable.live()
        let width = temp.sizeThatFits(CGSize(width: 200, height: 16))
        temp.snp.makeConstraints({ (make) in
            make.height.equalTo(22.auto())
            make.left.equalTo(self.liveAnimailView.snp.right).offset(5)
            make.centerY.equalTo(self.liveBgView)
            make.right.equalTo(self.liveBgView.snp.right).offset(-5.auto())
        })
        return temp
    }()
    
    lazy var fullVideoBtn: UIButton? = {
        let temp = UIButton()
        temp.setImage(UIImage(named: "video_full_bg"), for: UIControl.State.normal)
        temp.addTarget(self, action: #selector(fullVideoAction(sender:)), for: .touchUpInside)
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.right.equalTo(self.snp.right).offset(-15)
            make.bottom.equalTo(self.snp.bottom).offset(-10)
        })
        return temp
    }()
}

extension HomeVideoControl {
    // 竖屏直播错误点击处理
    func errorButtonAction(type: A4xVideoAction) {
        if case .video = type {
            debugPrint("------------> errorButtonAction type:\(type)")
            self.delegete?.videoSendPlay(btnType: "upgrade")
            self.playBtn?.isSelected = true
        } else {
            self.delegete?.videoErrorAction(admin: isAdmin, action: type)
        }
    }
    
    @objc private func helpAction(sender: UIButton){
        self.delegete?.videoHelpAction()
    }
    
    @objc private func playVideoAction(sender: UIButton) {
        UserDefaults.standard.set("1", forKey: "show_error_report_\(self.deviceId ?? "")")
        if !sender.isSelected {
            sender.isSelected = !sender.isSelected
            self.delegete?.videoSendPlay(btnType: "normal")
        } else {
            sender.isSelected = !sender.isSelected
            self.delegete?.videoPlayStop()
        }
    }
    
    @objc private func reportLogAction() {
        A4xLog("reportLogAction")
        self.delegete?.videoReportLogAction()
    }
    
    @objc private func fullVideoAction(sender: UIButton) {
        A4xLog("fullVideoAction")
        self.delegete?.videoFullAction()
    }
    
    @objc private func volumeVideoAction(sender: UIButton) {
        A4xLog("volumeVideoAction")
        sender.isSelected = !sender.isSelected
        self.delegete?.videoAudioEnable(enable: !sender.isSelected)
    }
}

extension HomeVideoControl {
    // 更新首页显示状态
    private func playStatusUpdate(isChangeed: Bool) {
        let videoType = self.videoState
        self.videoView.blueEffectEnable = false
        var image: UIImage? = nil
        debugPrint("-----------> HomeVideoControl playStatusUpdate func videoType: \(videoType)")
        switch videoType {
        case .none(let img):
            image = img
            playStateNone()
        case .loading(let img):
            image = img
            self.videoView.blueEffectEnable = true
            playStateLoading()
        case .playing:
            playStatePlaying(isChangeed: isChangeed)
        case .paused(let img):
            image = img
            playStatePaused()
        case .pausedp2p(let img):
            image = img
            playStatePausedp2p()
        case .finish:
            playStateDone()
        case .updating(let error, let img, let reconnect, let tipIcon):
            self.videoView.blueEffectEnable = true
            playUploadingError(error: error, reconnectTitle: reconnect, tipIcon: tipIcon)
            image = img
        case let .error(error, _, img, action, tipIcon, _):
            self.videoView.blueEffectEnable = true
            playStateError(error: error, action: action, tipIcon: tipIcon)
            image = img
        case .unuse(let img, let isFock):
            self.videoView.blueEffectEnable = true
            image = img
            playStateUnuseError(isFock: isFock)
        }
        self.videoView.thumbImage = image
    }
    
    private func playStateNone() {
        self.isAutoHidden = false
        self.loadingView.isHidden = true
        self.fullVideoBtn?.isHidden = false
        self.errorView.isHidden = true
        self.logReport.isHidden = true
        self.helpBut?.isHidden = true
        self.playBtn?.isHidden = false
        self.playBtn?.isSelected = false
        self.liveAnimailView.stop()
        self.liveBgView.isHidden = true
//        self.volumeBtn?.isHidden = true
        
        checkSleepPlan()
    }
    
    // 检测是否休眠
    private func checkSleepPlan() {
        // 正式逻辑
        if deviceOnLine && deviceStatus == 3 {
            playStateSleepPlan(sleepPlanIntro: deviceDormancyMessage)
        } else {
            self.errorView.backgroundColor = .clear
        }
        // 测试逻辑
//        if deviceOnLine && deviceStatus == 0 {
//            playStateSleepPlan(sleepPlanIntro: deviceDormancyMessage)
//        }
    }
    
    // 竖屏设备休眠状态UI
    private func playStateSleepPlan(sleepPlanIntro: String) {
        var sleepTips = sleepPlanIntro
        self.isAutoHidden = false
        self.fullVideoBtn?.isHidden = true
        self.liveAnimailView.stop()
        self.liveBgView.isHidden = true
        self.helpBut?.isHidden = true
        self.playBtn?.isHidden = true
        self.loadingView.stopAnimail()
        self.loadingView.isHidden = true
        self.logReport.isHidden = true
        self.errorView.isHidden = false
        let startColor = UIColor.colorFromHex("#06241C")
        let endColor = UIColor.colorFromHex("#020106")
        self.errorView.gradientColor(CGPoint(x:0, y:0), CGPoint(x:1, y:1), [startColor.cgColor, endColor.cgColor])
        //self.errorView.backgroundColor = UIColor.hex(0x000000, alpha: 1)
        if self.videoStyle == .default {
            self.errorView.type = .default
            self.errorView.tipIcon = R.image.home_sleep_plan()
            self.errorView.buttonItems = []
            if isAdmin { // 判断设备是否是非分享设备
                self.errorView.sleepPlanButton()
            } else {
                // 分享用户
                sleepTips += "\n\n" + R.string.localizable.admin_wakeup_camera()
            }
        } else if self.videoStyle == .split {
            // if !isAdmin {
                //sleepTips += "\n\n" + R.string.localizable.admin_wakeup_camera()
            //}
            // 四分屏
            self.errorView.type = .simple
            self.errorView.tipIcon = nil
            self.errorView.buttonItems = []
        }
        
        self.errorView.error = sleepTips.isBlank ? R.string.localizable.camera_sleep() : sleepTips
    }
    
    private func playStateLoading() {
        debugPrint("-----------> playStateLoading func")
        self.isAutoHidden = false
        self.playBtn?.isHidden = true
        
        self.loadingView.isHidden = false
//        self.fullVideoBtn?.isHidden = true
        self.errorView.isHidden = true
        self.logReport.isHidden = true
        self.helpBut?.isHidden = true
//        self.volumeBtn?.isHidden = true
        self.liveAnimailView.stop()
        self.liveBgView.isHidden = true
        self.loadingView.startAnimail()
    }
    
    private func playStatePaused(){
        self.isAutoHidden = false
        self.loadingView.isHidden = true
        self.fullVideoBtn?.isHidden = false
        self.errorView.isHidden = true
        self.logReport.isHidden = true
        self.helpBut?.isHidden = true
        self.playBtn?.isHidden = false
        self.playBtn?.isSelected = false
        self.liveAnimailView.stop()
        self.liveBgView.isHidden = true
//        self.volumeBtn?.isHidden = true
    }
    private func playStatePausedp2p(){
        self.isAutoHidden = false
        self.loadingView.isHidden = true
        self.fullVideoBtn?.isHidden = false
        self.errorView.isHidden = true
        self.logReport.isHidden = true
        self.helpBut?.isHidden = true
        self.playBtn?.isHidden = false
        self.playBtn?.isSelected = false
        self.liveAnimailView.stop()
        self.liveBgView.isHidden = true
//        self.volumeBtn?.isHidden = true
        
        // 休眠处理
        checkSleepPlan()
    }
    
    private func playStatePlaying(isChangeed: Bool) {
        self.liveText.text = R.string.localizable.live()
        self.isAutoHidden = true
        if isChangeed {
            self.playBtn?.isHidden = false
        }
//        self.volumeBtn?.isHidden = false
        self.loadingView.isHidden = true
        self.fullVideoBtn?.isHidden = false
        self.loadingView.stopAnimail()
        self.errorView.isHidden = true
        self.logReport.isHidden = true
        self.helpBut?.isHidden = true
        self.playBtn?.isSelected = true
        self.liveAnimailView.play()
        self.liveBgView.isHidden = false
        if isChangeed {
            
        }
        DispatchQueue.main.a4xAfter(self.autoHiddenTime) { [weak self] in
            self?.autoHiddenPause()
        }
    }
    
    private func playStateDone() {
        self.isAutoHidden = false
        self.loadingView.isHidden = true
        self.fullVideoBtn?.isHidden = false
        self.errorView.isHidden = true
        self.logReport.isHidden = true
        self.helpBut?.isHidden = true
//        self.volumeBtn?.isHidden = true
        self.liveAnimailView.stop()
        self.liveBgView.isHidden = true
    }
    
    private func playStateUnuseError(isFock: Bool) {
        self.isAutoHidden = false
        self.errorView.isHidden = false
        self.logReport.isHidden = true
        self.errorView.localRemoveGradientLayer()
        self.errorView.backgroundColor = .clear
        self.fullVideoBtn?.isHidden = true
        self.liveAnimailView.stop()
        self.liveBgView.isHidden = true
//        self.volumeBtn?.isHidden = true
        if isAdmin {
            self.errorView.error = R.string.localizable.forck_update(deviceVersion)
//            self.errorView.buttonItems = [HomeVideoItem(style: .theme, action: .upgrade, title: R.string.localizable.go_set())]
            if isFock {
                self.errorView.forceUpgradeButton()
            } else {
                self.errorView.upgradeButton()
            }
            self.errorView.tipIcon = R.image.device_connect_supper()
        } else {
            if !isFock {
                self.errorView.error = R.string.localizable.forck_update_share(deviceVersion)
                self.errorView.buttonItems = [HomeVideoItem(style: .line, action: .video(title:  R.string.localizable.do_not_update(), style: .line))]
            } else {
                self.errorView.error = R.string.localizable.forck_update_share(deviceVersion) + "\n\n" + R.string.localizable.unavailable_before_upgrade()
                self.errorView.buttonItems = []
            }
            self.errorView.tipIcon = R.image.device_connect_supper()
        }
        //let isDefault = self.videoStyle == .default
        self.helpBut?.isHidden = true//!isDefault
        self.playBtn?.isHidden = true
        self.loadingView.stopAnimail()
        self.loadingView.isHidden = true
        
        if videoStyle == .default {
            self.errorView.type = .default
        } else {
            self.errorView.type = .simple
        }
        
        // 固件升级 < 休眠状态
        checkSleepPlan()
      
    }
    
    private func playUploadingError(error: String, reconnectTitle: String?, tipIcon: UIImage?) {
        self.errorView.isHidden = false
        self.logReport.isHidden = true
        self.errorView.localRemoveGradientLayer()
        self.errorView.backgroundColor = .clear
        self.errorView.error = error
        self.errorView.buttonItems = nil
        //let isDefault = self.videoStyle == .default
        self.errorView.tipIcon = tipIcon
        self.helpBut?.isHidden = true//!isDefault
        self.fullVideoBtn?.isHidden = true
        self.playBtn?.isHidden = true
        self.loadingView.stopAnimail()
        self.loadingView.isHidden = true
        self.liveAnimailView.stop()
        self.liveBgView.isHidden = true
//        self.volumeBtn?.isHidden = true
        if videoStyle == .default {
            self.errorView.type = .default
        }else {
            self.errorView.type = .simple
        }
    }
    
    private func playStateError(error: String, action: A4xVideoAction?, tipIcon: UIImage?) {
        self.errorView.isHidden = false
        // 判断是否点击过播放按钮 - (拟在重新拉列表的时候会清除-暂未处理)
        if UserDefaults.standard.string(forKey: "show_error_report_\(self.deviceId ?? "")") == "1" {
            self.logReport.isHidden = false
        } else {
            self.logReport.isHidden = true
        }
        
        //UserDefaults.standard.set("1", forKey: "show_error_report_\()")
        //UserDefaults.standard.set("0", forKey: "show_error_report_\()")
        
        self.errorView.localRemoveGradientLayer()
        self.errorView.backgroundColor = .clear
        self.errorView.error = error
        if let action = action {
            var viewStyle: HomeVideoButtonStyle = .line
            if let style = action.style() {
                switch style {
                case .theme:
                    viewStyle = .theme
                case .line:
                    viewStyle = .line
                case .none:
                    viewStyle = .none
                }
            }
            self.errorView.buttonItems = [HomeVideoItem(style: viewStyle, action: action)]
        } else {
            self.errorView.buttonItems = []
        }
        //let isDefault = self.videoStyle == .default
        self.errorView.tipIcon = tipIcon
        self.helpBut?.isHidden = true//!isDefault
        self.fullVideoBtn?.isHidden = true
        self.playBtn?.isHidden = true
        self.loadingView.stopAnimail()
        self.loadingView.isHidden = true
        
        
//        self.volumeBtn?.isHidden = true
        if videoStyle == .default {
            self.errorView.type = .default
        } else {
            self.errorView.type = .simple
        }
        self.liveAnimailView.stop()
        self.liveBgView.isHidden = true
        
        // 返回休眠错误getwebrtc
        if error == R.string.localizable.camera_sleep() {
            self.playStateSleepPlan(sleepPlanIntro: error)
        }
        
        // 固件升级 < 休眠状态
        if error == R.string.localizable.updating() {
            checkSleepPlan()
        }
    }
   
    func autoHiddenPause() {
        if !isAutoHidden {
            return
        }
        
        if case .playing = self.videoState {
            self.playBtn?.isHidden = true
//            let isDefault = self.videoStyle == .default
//            self.volumeBtn?.isHidden =  !isDefault
//            self.fullVideoBtn?.isHidden = true
        }
        isAutoHidden = false
    }
    
    // 半屏直播点击屏幕处理
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if deviceStatus == 3 {//四分屏点击不处理
            return
        }
        
        let videoType = self.videoState
        switch videoType {
        case .playing:
            let isHidden = !(self.playBtn?.isHidden ?? true)
            self.playBtn?.isHidden = isHidden
            isAutoHidden = true
//            let isDefault = self.videoStyle == .default
//            self.volumeBtn?.isHidden = isHidden || !isDefault
//            self.fullVideoBtn?.isHidden = isHidden
            if !isHidden {
                DispatchQueue.main.a4xAfter(self.autoHiddenTime) { [weak self] in
                    self?.autoHiddenPause()
                }
            }
        default :
            break
        }
    }
}

