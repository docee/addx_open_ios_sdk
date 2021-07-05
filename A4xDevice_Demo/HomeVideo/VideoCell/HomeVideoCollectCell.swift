//
//  HomeVideoCollectCell.swift
//  AddxAi
//
//  Created by kzhi on 2020/12/28.
//  Copyright © 2020 addx.ai. All rights reserved.
//

import Foundation
import UIKit
import yoga
import A4xYogaKit
import A4xBaseSDK
import A4xWebRTCSDK

protocol HomeVideoCollectCellProtocol : class {
    
    /// 视频点击全屏
    ///
    /// - Parameters:
    ///   - device: 设备信息
    ///   - player: 视频播放器
    func videoControlFull(device : A4xDeviceModel?,indexPath:IndexPath?)
    
    /// 视频帮助按钮点击
    func videoHelpAction()
    
    /// 设备回看按钮点击
    ///
    /// - Parameter device: 设备信息
    func deviceRecordList(device : A4xDeviceModel?)
    
    /// 点击设备设置
    ///
    func deviceSetting(device : A4xDeviceModel?)
    
    /// 点击设备信息
    ///
    func deviceInfoSetting(device : A4xDeviceModel?, state: String?)
    
    /// 设备分享的用户
    ///
    func deviceShareUsers(device : A4xDeviceModel?)
    
    /// 点击双向对话
    ///
    func deviceLoadSpeak(device : A4xDeviceModel?  , enable : Bool) -> Bool
    
    
    func deviceCellModleUpdate(device : A4xDeviceModel?, type : ADVideoCellType , indexPath:IndexPath?)
    
    
    func deviceAlert(device : A4xDeviceModel?  , isAlerting : Bool , comple : @escaping (Bool)->Void)
    
    /// 点击设备刷新
    ///
    func deviceSettingRefresh(device : A4xDeviceModel?)
    
    /// 设备唤醒
    func deviceSleepToWakeUp(device : A4xDeviceModel?)
    
    
    func videoReportLogAction(device : A4xDeviceModel?)
}

class HomeVideoCollectCell : UICollectionViewCell {
    let videoRatio : CGFloat = 1.8
    
    var videoStyle      : ADVideoCellType = .default
    
    var indexPath       : IndexPath?
    
    var showChangeAnilmail : Bool = false {
        didSet {
            self.videoV.showChangeAnilmail = showChangeAnilmail
        }
    }
    
    weak var `protocol` : HomeVideoCollectCellProtocol?
    
    var presetListData  : [ADPresetModel]? {
        didSet {
            deviceControlV.presetListData = presetListData
        }
    }
    
    private var sycLightCompleBlock : ((Bool) -> Void)?
    var isFllow : Bool = false {
        didSet {
            deviceControlV.isFollow = isFllow
        }
    }
    
    // 是否切换成人形追踪
    var autoFollowBtnIsHumanImg: Bool = false {
        didSet {
            deviceControlV.autoFollowBtnIsHumanImg = autoFollowBtnIsHumanImg
        }
    }
    
    var autoFollowBlock : ((_ deviceId : String? , Bool , _ comple :@escaping (Bool)->Void)->Void)?
    var deviceRotateBlock : ((_ deviceId : String? , CGPoint)->Void)? {
        didSet {
            deviceControlV.deviceRotateBlock = {[weak self] point in
                self?.deviceRotateBlock?(self?.dataSource?.id , point)
            }
        }
    }
    var itemActionBlock : ((_ deviceId : String? , ADPresetModel? , HomeVideoPresetCellType , UIImage?)->Void)?
    
    // 是否用户自己设备
    var isFollowAdmin : Bool = false {
        didSet {
            deviceControlV.isFollowAdmin = isFollowAdmin
        }
    }
    
    var dataSource: A4xDeviceModel? {
        didSet {
            // 更新首页显示状态
            debugPrint("-----------> dataSource didSet to updateVideoSytle")
            updateVideoSytle()
            if dataSource != nil {
                self.logTool = A4xBasePlayerLog(deviceModle: dataSource!)
            }
        }
    }
    
    var logTool: A4xBasePlayerLog?
    
    //MARK:- 生命周期
    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        
        self.contentView.backgroundColor = UIColor.white
        self.contentView.layer.cornerRadius = 11.auto()
        self.contentView.layer.masksToBounds = true
        
        self.videoBarV.isHidden = false
        self.videoV.isHidden = false
        self.deviceControlV.isHidden = true
        A4xPlayerManager.handle.addStateProtocol(target: self)
        self.speakWarView.alpha = 0
        
        self.contentView.yoga.isEnabled = true
        self.contentView.yoga.flexDirection = .column
        self.contentView.yoga.width =  YGValue(UIApplication.shared.keyWindow?.width ?? 375)
    }
    
    deinit {
        A4xLog("HomeVideoCollectCell deinit")
        //A4xPlayerManager.handle.removeStateProtocol(target: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 直播风格更新：四分屏、竖屏
    func updateVideoSytle() {
        debugPrint("-----------> updateVideoSytle func")
        let width = min(UIApplication.shared.keyWindow?.width ?? 320, UIApplication.shared.keyWindow?.height ?? 320)
        let maxWidth = min(self.width, width)
        
        self.contentView.frame = CGRect(x: 0, y: 0, width: self.width, height: self.height)
        //        self.contentView.frame = CGRect(x: 0, y: 0, width: self.width, height: self.height)
        self.contentView.yoga.width = YGValue(maxWidth)
        self.contentView.yoga.height = YGValue(self.height)
        self.deviceControlV.videoStyle = self.videoStyle
        
        // 更新首页显示状态
        debugPrint("-----------> updateVideoSytle func to updataData")
        updataData()
        
        switch videoStyle {
        case .default:
            self.loadDefalut()
        case .split:
            self.loadSplit()
        case .options_more:
            self.loadMenuStyle()
        case .locations:
            fallthrough
        case .locations_edit:
            loadMenuStyle()
        case .playControl:
            loadMenuStyle()
        }
    }
    
    private func loadMenuStyle(){
        
        let barIndex = self.contentView.subviews.index(of: self.videoBarV) ?? 0
        let videoIndex = self.contentView.subviews.index(of: self.videoV) ?? 0
        if barIndex > videoIndex {
            self.contentView.exchangeSubview(at: barIndex, withSubviewAt: videoIndex)
        }
        self.deviceControlV.isHidden = false
        self.videoBarV.yoga.height = YGValue(CGFloat(50.auto()))
        self.videoBarV.yoga.width = YGValue(value: 100, unit: YGUnit.percent)
        self.videoV.yoga.width = YGValue(value: 90, unit: YGUnit.percent)
        self.contentView.yoga.paddingLeft = YGValue(0)
        self.contentView.yoga.paddingRight = YGValue(0)
        self.deviceControlV.updateInfo()
        
        self.contentView.yoga.applyLayout(preservingOrigin: false)
        A4xLog("")
        
    }
    
    private func loadMoreMenuStyle(){
        let barIndex = self.contentView.subviews.index(of: self.videoBarV) ?? 0
        let videoIndex = self.contentView.subviews.index(of: self.videoV) ?? 0
        if barIndex > videoIndex {
            self.contentView.exchangeSubview(at: barIndex, withSubviewAt: videoIndex)
        }
        self.deviceControlV.isHidden = false
        self.videoBarV.yoga.height = YGValue(CGFloat(50.auto()))
        self.videoBarV.yoga.width = YGValue(value: 100, unit: YGUnit.percent)
        self.videoV.yoga.width = YGValue(value: 90, unit: YGUnit.percent)
        self.contentView.yoga.paddingLeft = YGValue(0)
        self.contentView.yoga.paddingRight = YGValue(0)
        self.deviceControlV.updateInfo()
        
        self.contentView.yoga.applyLayout(preservingOrigin: false)
        
    }
    
    private func loadDefalut() {
        let barIndex = self.contentView.subviews.index(of: self.videoBarV) ?? 0
        let videoIndex = self.contentView.subviews.index(of: self.videoV) ?? 0
        if barIndex > videoIndex {
            self.contentView.exchangeSubview(at: barIndex, withSubviewAt: videoIndex)
        }
        self.speakWarView.frame = CGRect(x: self.midX, y: self.videoV.maxY - 44.auto(), width: 0, height: 36.auto())
        
        self.deviceControlV.isHidden = true
        self.videoV.yoga.width = YGValue(value: 90, unit: YGUnit.percent)
        self.contentView.yoga.paddingLeft = YGValue(0)
        self.contentView.yoga.paddingRight = YGValue(0)
        self.videoBarV.yoga.height = YGValue(CGFloat(50.auto()))
        self.videoBarV.yoga.width = YGValue(value: 100, unit: YGUnit.percent)
        self.contentView.yoga.applyLayout(preservingOrigin: false)
        
        videoBarV.videoStyle = .default
        videoV.cornerRadius = 11.auto()
        videoV.videoStyle = .default
        
    }
    
    private func loadSplit(){
        let barIndex = self.contentView.subviews.index(of: self.videoBarV) ?? 0
        let videoIndex = self.contentView.subviews.index(of: self.videoV) ?? 0
        if barIndex < videoIndex {
            self.contentView.exchangeSubview(at: barIndex, withSubviewAt: videoIndex)
        }
        videoV.cornerRadius = 0
        videoBarV.videoStyle = .split
        videoV.videoStyle = .split
        
        self.deviceControlV.isHidden = true
        self.contentView.yoga.paddingLeft = YGValue(1)
        self.contentView.yoga.paddingRight = YGValue(1)
        self.videoBarV.yoga.height = YGValue(CGFloat(30.auto()))
        self.videoBarV.yoga.width = YGValue(value: 100, unit: YGUnit.percent)
        self.videoV.yoga.width = YGValue(value: 100, unit: YGUnit.percent)
        
        self.contentView.yoga.applyLayout(preservingOrigin: false)
        
    }
    
    // 更新首页显示状态
    private func updataData() {
        debugPrint("-----------> updataData func deviceStatus: \(self.dataSource?.deviceStatus ?? 1024)")
        videoBarV.dataSource = self.dataSource
        videoV.deviceOnLine = self.dataSource?.online == 1
        videoV.deviceStatus = self.dataSource?.deviceStatus ?? 0
        videoV.deviceDormancyMessage = self.dataSource?.deviceDormancyMessage ?? ""
        videoV.isAdmin = self.dataSource?.isAdmin() ?? true
        videoV.deviceId = self.dataSource?.id
        videoV.deviceVersion = self.dataSource?.newFirmwareId ?? ""
        self.deviceControlV.editEnable = self.dataSource?.isAdmin() ?? true
        
        if let datas = self.dataSource {
            if let (state, videov) = A4xPlayerManager.handle.playinfo(device: datas) {
                self.videoV.videoView.playerView = videov
                self.videoV.videoState = state
                self.deviceControlV.alpha =  A4xPlayerManager.handle.getCanRotating(device: datas) ? 1 : 0.8
                self.deviceControlV.canStandBy = self.dataSource?.deviceContrl?.standby ?? false
                self.deviceControlV.canRotate = self.dataSource?.deviceContrl?.rotate ?? false
                self.deviceControlV.lightEnable = self.dataSource?.deviceContrl?.whiteLight ?? false
                self.deviceControlV.lightisOn = A4xPlayerManager.handle.getWhiteLight(device: datas)
                self.deviceControlV.deviceVoiceOn = A4xPlayerManager.handle.audioEnable(device: datas)
                self.deviceControlV.supperAlert = self.dataSource?.deviceSupport?.deviceSupportAlarm ?? false
            } else {
                self.videoV.videoView.playerView = nil
                self.videoV.videoState = .finish
            }
        }
    }
    
    
    
    //MARK:- view 创建
    lazy var deviceControlV : HomeVideoDeviceControlView = {
        let temp = HomeVideoDeviceControlView()
        temp.protocol = self
        temp.backgroundColor = UIColor.white
        self.contentView.addSubview(temp)
        temp.yoga.isEnabled = true
        temp.yoga.width = YGValue(value: 100, unit: YGUnit.percent)
        temp.yoga.flexGrow = 1
        temp.yoga.flexShrink = 1
        return temp
    }()
    
    //MARK:- view 创建 - 竖屏
    lazy var videoV: HomeVideoControl = {
        let temp = HomeVideoControl(delegete: self)
        temp.backgroundColor = UIColor.clear
        self.contentView.addSubview(temp)
        temp.layer.cornerRadius = 11
        temp.layer.masksToBounds = true
        temp.yoga.isEnabled = true
        temp.yoga.alignSelf = .center
        temp.yoga.width = YGValue(value: 95, unit: YGUnit.percent)
        temp.yoga.aspectRatio = videoRatio
        return temp
    }()
    
    lazy var videoBarV: HomeVideoCellBar = {
        let bar : HomeVideoCellBar = HomeVideoCellBar()
        bar.protocol = self
        self.contentView.addSubview(bar)
        bar.yoga.isEnabled = true
        return bar
    }()
    
    private lazy var speakWarView: ADHomeDeviceVoiceWarView = {
        let temp = ADHomeDeviceVoiceWarView()
        temp.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        temp.layer.cornerRadius = 18.auto()
        temp.clipsToBounds = true
        self.contentView.addSubview(temp)
        return temp
    }()
    
    private func startSpeak() {
        self.contentView.bringSubviewToFront(speakWarView)
        self.speakWarView.alpha = 0
        
        self.speakWarView.frame = CGRect(x: self.midX, y: self.videoV.maxY - 40, width: 0, height: 36.auto())
        UIView.animate(withDuration: 0.2) {
            self.speakWarView.frame = CGRect(x: self.midX - 67.auto(), y: self.videoV.maxY - 44.auto(), width: 134.auto(), height: 36.auto())
            
            self.speakWarView.alpha = 1
        }
        speakWarView.load()
        //        if let result = deviceSpeak?(true) {
        //            if !result {
        //                stopSpeak()
        //            }
        //        }
    }
    
    private func stopSpeak() {
        UIView.animate(withDuration: 0.2) {
            self.speakWarView.frame = CGRect(x: self.midX, y: self.videoV.maxY - 44.auto(), width: 0, height: 36.auto())
            self.speakWarView.alpha = 0
        }
        speakWarView.free()
        //        if let _ = deviceSpeak?(false) {
        //
        //        }
    }
    
    func setCellStyle(videoStyle: ADVideoCellStyle) {
        self.videoBarV.videoStyle = videoStyle
        self.videoV.videoStyle = videoStyle
    }
}


extension HomeVideoCollectCell: HomeVideoControlProtocol, HomeVideoCellBarProtocol {
    func videoAudioEnable(enable: Bool) {
        
    }
    
    // 竖屏点击直播开始
    func videoSendPlay(btnType: String) {
        guard let dataSource = self.dataSource else {
            return
        }
        
        debugPrint("------------> videoSendPlay:\( self.videoV.videoState)")
        switch self.videoV.videoState {
        case .error, .updating:
            debugPrint("------------> videoSendPlay error")
            self.logTool?.logLiveReConnectClick(error_code: "0", error_msg: self.videoV.videoState.errInfo())
            break
        case .pausedp2p, .none, .unuse:
            debugPrint("------------> videoSendPlay click")
            self.logTool?.logLiveClick(btnType: btnType)
            break
        default:
            break
        }
        
        // 直播的个数，四分屏播放四个
        let playCount = self.videoStyle == .default ? 1 : 4
        
        // 开始直播处理
        A4xPlayerManager.handle.play(playType: self.videoStyle == .default ? .vertical : .split, device: dataSource, voiceEnable: nil, shouldSpeak: true, playNumber: playCount, Params: nil)
        //延迟获取用户麦克风权限至开启语音对讲按钮按下时
        
        /*
         requestAccessForAudio { (flag) in
         A4xLog("A4xIJKPlayerViewModel requestAccessForAudio \(flag)")
         if !flag {
         A4xBaseAuthorizationViewModel.single.showRequestAlert(type: A4xBaseAuthorizationType.audio) { (f) in
         }
         }
         }
         */
        
    }
    
    func videoPlayStop() {
        debugPrint("-----------> videoPlayStop func")
        guard let dataSource = self.dataSource else {
            return
        }
        A4xPlayerManager.handle.stop(device: dataSource, playNumber: nil, reason: A4xPlayerStopReason.click)
    }
    
    func videoReportLogAction() {
        self.protocol?.videoReportLogAction(device: self.dataSource)
    }
    
    func videoFullAction() {
        self.videoV.videoView.playerView?.removeFromSuperview()
        self.protocol?.videoControlFull(device: self.dataSource,indexPath: self.indexPath)
    }
    
    // 首页点击错误页按钮处理（立即升级、重新连接、唤醒）
    func videoErrorAction(admin: Bool, action: A4xVideoAction) {
        A4xLog("videoErrorAction")
        if case .upgrade = action {
            if admin {
                // 主页点击立即升级处理
                self.protocol?.deviceInfoSetting(device: self.dataSource, state: "upgrade")
            } else {
                self.protocol?.deviceShareUsers(device: self.dataSource)
            }
        } else if case .sleepPlan = action {
            // 首页休眠唤醒点击
            self.protocol?.deviceSleepToWakeUp(device: self.dataSource)
        } else {
            self.protocol?.deviceSettingRefresh(device: self.dataSource)
        }
    }
    
    func recoredListAction() { // 主页push相册 - 石虎
        let name = ((self.dataSource?.name ?? "") + ("・") + R.string.localizable.all_screen())
        self.dataSource?.name = name
        self.protocol?.deviceRecordList(device: self.dataSource)
    }
    
    func shareUsersAction() {
        self.protocol?.deviceShareUsers(device: self.dataSource)
    }
    
    func deviceSettingAction() {
        self.protocol?.deviceSetting(device: self.dataSource)
    }
    
    func videoHelpAction() {
        self.protocol?.videoHelpAction()
    }
}


extension HomeVideoCollectCell: A4xPlayerStateChangeProtocol {
    
    // 截图
    func playerSnapImage(image: UIImage?) {
        
    }
    
    // 播放速度
    func videoSpeed(speed: String) {
        
    }
    
    // 当前时间
    func videoCurrentTimer(date: TimeInterval) {
        
    }
    
    // 可摇杆
    func deviceEnableRotating(enable: Bool) {
        
    }
    
    // 通用信息
    func alertMessage(message: String?) {
        
    }
    
    func playerSpackVoice(data: [Float]) {
        self.speakWarView.pointLocation = data
    }
    
    func playerDeviceId() -> String {
        // 必须要写
        return self.dataSource?.id ?? ""
    }
    
    func playerConnectState(state: A4xPlayerStateType, videoV: UIView?, videoSize: CGSize) {
        debugPrint("-----------> HomeVideoCollectCell playerConnectState state: \(state)")
        if state == .playing {
            self.videoV.videoState = state
        }
    }
    
    func playerRecoredState(state: A4xPlayerRecordState, error errorCode: Int, videoPath: String) {
    }
    
    func videoWhiteLight(enable: Bool, error: String?) {
        sycLightCompleBlock?(error == nil)
        guard let dataSource = self.dataSource else {
            return
        }
        self.deviceControlV.lightisOn = A4xPlayerManager.handle.getWhiteLight(device: dataSource)
        
    }
}

extension HomeVideoCollectCell: HomeVideoDeviceControlViewProtocol {
    func controlLocation(clickModle modle: ADPresetModel?, clickType type: HomeVideoPresetCellType) {
        guard let device = self.dataSource else {
            return
        }
        
        if type == .add {
            A4xPlayerManager.handle.currentImage(device: device) {[weak self] (img) in
                self?.itemActionBlock?(self?.dataSource?.id, modle, type, img)
            }
        } else {
            self.itemActionBlock?(self.dataSource?.id, modle, type, nil)
        }
    }
    
    func controlType(changeToType type: ADHomeVideoPresetTypeModle) {
        switch type {
        case .none:
            self.protocol?.deviceCellModleUpdate(device: self.dataSource, type: .playControl, indexPath: self.indexPath)
        case .show:
            self.protocol?.deviceCellModleUpdate(device: self.dataSource, type: .locations, indexPath: self.indexPath)
        case .edit:
            self.protocol?.deviceCellModleUpdate(device: self.dataSource, type: .locations, indexPath: self.indexPath)
        case .delete:
            self.protocol?.deviceCellModleUpdate(device: self.dataSource, type: .locations_edit, indexPath: self.indexPath)
        }
    }
    
    func controlDeviceRotate(toPoint point: CGPoint) {
        self.deviceRotateBlock?(self.dataSource?.id, point)
    }
    
    func controlCommandSpeak(type: ADHomeDeviceSpeakEnum) {
        switch type {
        case .down:
            if let result = self.protocol?.deviceLoadSpeak(device: self.dataSource, enable: true) {
                if result {
                    self.deviceControlV.deviceVoiceOn = true
                    startSpeak()
                }
            }
            self.contentView.hideAllToasts()
        case .up:
            let _ = self.protocol?.deviceLoadSpeak(device: self.dataSource, enable: false)
            stopSpeak()
        case .tap:
            var style = ToastStyle()
            style.cornerRadius = 18
            style.messageFont = UIFont.systemFont(ofSize: 13)
            style.maxHeightPercentage = 10
            style.maxWidthPercentage = 18
            style.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            style.imageSize = CGSize(width: 18, height: 18)
            style.horizontalPadding = 12
            self.contentView.hideAllToasts()
            self.contentView.makeToast(R.string.localizable.hold_speak(), point: self.speakWarView.center, title: nil, image: R.image.speak_tip_icon(), style: style, completion: nil)
        }
    }
    
    func controlAutoFollow(autoFollow auto: Bool, comple: @escaping ((Bool) -> Void) -> Void) {
        
    }
    
    func deviceMenuAction(type: ADHomeDeviceMenuType, comple: @escaping (Bool) -> Void) {
        guard let dataSource = self.dataSource else {
            comple(true)
            return
        }
        
        guard let deviceId = dataSource.id else {
            comple(true)
            return
        }
        
        switch type {
        case .sound:
            let enable = !A4xPlayerManager.handle.audioEnable(device: dataSource)
            // 打点事件（静音）
            let playVideoEM = A4xPlayVideoEventModel()
            playVideoEM.live_player_type = "halfscreen"
            playVideoEM.switch_status = "\(enable)"
            playVideoEM.connect_device = deviceId
            A4xEventManager.endEvent(event:ADTickerPlayVideo.live_mute_switch_click(eventModel: playVideoEM))
            
            A4xPlayerManager.handle.setAudioEnable(device: dataSource, enable: enable)
            self.deviceControlV.deviceVoiceOn = A4xPlayerManager.handle.audioEnable(device: dataSource)
            
            comple(true)
        case .alert:
            self.protocol?.deviceAlert(device: dataSource, isAlerting: self.deviceControlV.isAlerting , comple: comple)
        case .track:
            let result = { [weak self](parm : Bool) -> Void in
                if parm {
                    self?.isFllow = !(self?.isFllow ?? false)
                }
                comple(parm)
            }
            self.autoFollowBlock?(deviceId ,!isFllow , result)
        case .location:
            self.protocol?.deviceCellModleUpdate(device: dataSource, type: .locations, indexPath: self.indexPath)
            comple(true)
        case .light:
            // 点击白光灯
            let isOn = A4xPlayerManager.handle.getWhiteLight(device: dataSource)
            A4xPlayerManager.handle.setWhiteLight(device: dataSource, enable: !isOn)
            sycLightCompleBlock = comple
        case .more:
            break
        }
    }
}

extension HomeVideoCollectCell {
    static func heightForDevide(type: ADVideoCellType, itemWidth: CGFloat, deviceModle: A4xDeviceModel?) -> CGFloat {
        let videoHeight : CGFloat = itemWidth / 1.8
        let normalVideoBaseHeight : CGFloat = videoHeight + 50.auto()
        switch type {
        case .default:
            return normalVideoBaseHeight
        case .split:
            return videoHeight + 30.auto()
        case .options_more:
            fallthrough
        case .locations:
            fallthrough
        case .locations_edit:
            fallthrough
        case .playControl:
            return normalVideoBaseHeight + HomeVideoDeviceControlView.height(type: type, forWidth: itemWidth , alertSupper : deviceModle?.deviceSupport?.deviceSupportAlarm ?? false , rotateEnable: deviceModle?.deviceContrl?.rotate ?? false, whiteLight: deviceModle?.deviceContrl?.whiteLight ?? false)
        }
    }
}
