//
//  ADLIveVideoViewController.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/3/14.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import Accelerate
import ADDXWebRTC
import LFLiveKit
import UIKit
import ADVideoMessageManager
import A4xBaseSDK
import A4xWebRTCSDK

enum LiveVideoStateType {
    case none
    case loading
    case playing
    case aiRuning
    case paused
    case done
    case error(String)
}


extension LiveVideoStateType: Equatable {
    static func == (lhs: LiveVideoStateType, rhs: LiveVideoStateType) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none): return true
        case (.loading, .loading): return true
        case (.playing, .playing): return true
        case (.paused, .paused): return true
        case let (.error(s1), .error(s2)) where s1 == s2: return true
        case _: return false
        }
    }
}

@objc protocol ADLiveVideoViewControllerDelegate {
    func didFinishViewController(controller: UIViewController, currentIndexPath: IndexPath)
}

class ADLiveVideoViewController: A4xBaseViewController {
    var dataSource: A4xDeviceModel?
    var presetModle: ADPresetDataModle?
    var otherHasLoad: Bool = false
    
    var shouldBackStop: Bool = false
    var topTipString: String?
    var currentIndexPath: IndexPath?
    // 是否点击了4g网络提示
    var isShow4GAlert: Bool = false
    var liveMoveTrackAlertView: UIView!
    var selectedDeviceId: String?
    
    weak var delegate: ADLiveVideoViewControllerDelegate?
    var logTool: A4xBasePlayerLog?
    
    let gifManager = A4xBaseGifManager(memoryLimit:60)
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        weak var weakSelf = self
        
        guard let data = weakSelf?.dataSource else {
            return
        }
        
        self.logTool = A4xBasePlayerLog(deviceModle: data)
        
        if A4xPlayerManager.handle.isPlaying(device: data) {
            otherHasLoad = true
        }
        A4xUserDataHandle.Handle?.addWifiChange(targer: self)
        
        videoControlView.whiteLight = false
        //        self.videoControlView.recordEnable = (dataSource?.deviceContrl?.deviceType() == .G0)
        
        videoControlView.isHidden = false
        if presetModle == nil {
            presetModle = ADPresetDataModle()
        }
        let whiteLightEnable = dataSource?.deviceContrl?.whiteLight ?? false
        
        videoControlView.supperWhitelight = whiteLightEnable
        // 横屏判断是否是分享用户
        videoControlView.canRotate = dataSource?.deviceContrl?.rotate ?? false
        videoControlView.isFollowAdmin = dataSource?.isAdmin() ?? false
        videoControlView.dataSource = dataSource
        
        if let tipSt = topTipString {
            DispatchQueue.main.a4xAfter(0.5) {
                weakSelf?.view.makeToast(tipSt, duration: 2, position: ToastPosition.top(offset: 20), title: nil, image: nil, style: ToastStyle(), completion: nil)
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(enterBackGround), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @objc
    func enterBackGround() {
        guard let data = dataSource else {
            return
        }
        if A4xPlayerManager.handle.isRecored(device: data) {
            A4xPlayerManager.handle.stopRecored(device: data)
        }
    }
    
    // MARK: - view 创建
    
    lazy var videoControlView: ADLiveVideoControlView = {
        let temp = ADLiveVideoControlView(frame: .zero, model: self.dataSource ?? A4xDeviceModel())
        temp.backgroundColor = UIColor.clear
        temp.protocol = self
        self.view.addSubview(temp)
        temp.snp.makeConstraints({ make in
            make.edges.equalTo(self.view.snp.edges)
        })
        
        return temp
    }()
    
    override public func viewWillAppear(_ animated: Bool) {
        //        super.viewWillAppear(animated)
        // 该页面显示时可以横竖屏切换
        //appDelegate.interfaceOrientations = .landscape
        A4xPlayerManager.handle.addStateProtocol(target: self)
        A4xLog("ADLiveVideoControlView viewWillAppear")
        ADVideoMessageManager.shared.config?.enable = false
        guard let data = dataSource else {
            return
        }
        A4xPlayerManager.handle.setVideoZoomEnable(device: data, enable: true)
        A4xPlayerManager.handle.play(playType: .landscape, device: data, voiceEnable: nil, shouldSpeak: true, playNumber: nil, Params: [.videoScale: A4xPlayerViewScale.aspectFit, .lookWhite: true])
    }
    
    private var pingTimer: Timer?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let data = dataSource else {
            return
        }
        let whiteLightEnable = dataSource?.deviceContrl?.whiteLight ?? false
        videoControlView.supperWhitelight = whiteLightEnable
        
        A4xPlayerManager.handle.update(device: data)
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        A4xLog("----------------> ADLiveVideoViewController viewWillDisappear")
        // 页面退出时还原强制竖屏状态
        A4xPlayerManager.handle.removeStateProtocol(target: self)
        ADVideoMessageManager.shared.config?.enable = true
        
        guard let data = dataSource else {
            return
        }
        if A4xPlayerManager.handle.isRecored(device: data) {
            A4xPlayerManager.handle.stopRecored(device: data)
        }
        weak var weakSelf = self
        DispatchQueue.main.a4xAfter(0.1) {
            A4xPlayerManager.handle.setVideoZoomEnable(device: data, enable: false)
            if weakSelf?.shouldBackStop ?? true {
                A4xPlayerManager.handle.stop(device: data, playNumber: nil, reason: A4xPlayerStopReason.changePage)
            } else {
                A4xPlayerManager.handle.updateParam(device: data, Params: [.videoScale: A4xPlayerViewScale.aspectFill])
            }
        }
    }
    
    private func showAnimail(img: UIImage, view: UIView) {
        A4xLog("A4xBasePhotoManager showAnimail")
        // 打点事件（截屏）
        let playVideoEM = A4xPlayVideoEventModel()
        playVideoEM.live_player_type = "fullscreen"
        A4xBasePhotoManager.default().save(image: img, result: { result, att in
            A4xLog("A4xBasePhotoManager save \(result) id \(att ?? "")")
            if result {
                playVideoEM.result = "true"
                ADLiveVideoAnimailView.showThumbnail(tapButton: view, image: img, tipString: R.string.localizable.save_album()) {
                }
            } else {
                playVideoEM.result = "true"
                playVideoEM.error_msg = R.string.localizable.shot_fail()
                self.view.makeToast(R.string.localizable.shot_fail())
            }
            A4xEventManager.endEvent(event:ADTickerPlayVideo.live_screenshot(eventModel: playVideoEM))
        })
    }
}

extension ADLiveVideoViewController: A4xPlayerStateChangeProtocol {
    func videoCurrentTimer(date: TimeInterval) {
        
    }
    
    func deviceEnableRotating(enable: Bool) {
        
    }
    
    func alertMessage(message: String?) {
        if message != nil {
            view.makeToast(message)
        }
    }
    
    func deviceCanRotating(state: A4xPlayerStateType, deviceID: String, enable: Bool) {
        videoControlView.canRotating = enable
    }
    
    func videoWhiteLight(enable: Bool, error: String?) {
        videoControlView.whiteLight = enable
        if error != nil {
            view.makeToast(error)
        }
    }
    
    func videoSpeed(speed: String) {
        weak var weakSelf = self
        DispatchQueue.main.async {
            weakSelf?.videoControlView.downloadSpeed = speed
        }
    }
    
    func playerSnapImage(image: UIImage?) {
        //        guard image != nil else {
        //            return
        //        }
        //        showAnimail(img: image!, view: view)
    }
    
    func playerSpackVoice(data: [Float]) {
        weak var weakSelf = self
        DispatchQueue.main.async {
            weakSelf?.videoControlView.spackVoiceData = data
        }
    }
    
    func playerDeviceId() -> String {
        return dataSource?.id ?? ""
    }
    
    private func checkShow4GAlert() {
        if A4xUserDataHandle.Handle?.isShow4GNet ?? false {
            return
        }
        
        guard A4xUserDataHandle.Handle?.netConnectType == .wwan else {
            return
        }
        A4xUserDataHandle.Handle?.isShow4GNet = true
        self.view.makeToast(R.string.localizable.pay_attention_data())
        //        var config = A4xBaseAlertAnimailConfig()
        //        config.leftbtnBgColor = ADTheme.C5
        //        config.leftTitleColor = ADTheme.C1
        //        config.rightbtnBgColor = ADTheme.Theme
        //        config.rightTextColor = UIColor.white
        //
        //        let alert = A4xBaseAlertView(param: config, identifier: "show Save Alert")
        //        alert.message = R.string.localizable.wlan_enable_play()
        //        alert.rightButtonTitle = R.string.localizable.yes()
        //        alert.leftButtonTitle = R.string.localizable.no()
        //        weak var weakSelf = self
        //        alert.leftButtonBlock = {
        //            weakSelf?.isShow4GAlert = true
        //            A4xPlayerManager.handle.stopAll(troubleDevice: nil, reason: .changeModle)
        //            weakSelf?.navigationController?.popViewController(animated: true)
        //        }
        //        alert.rightButtonBlock = {
        //            A4xUserDataHandle.Handle?.isShow4GNet = true
        //        }
        //        alert.show()
    }
    
    // 首次运动追踪弹窗
    func fristGuideAlert(_ devceid: String?, type: String) {
        if type == "move_track" {
            if UserDefaults.standard.string(forKey: "\(A4xUserDataHandle.Handle?.loginModel?.id ?? 0)_frist_move_track_alert") != "1" {
                
                UserDefaults.standard.setValue(String(1), forKey:"\(A4xUserDataHandle.Handle?.loginModel?.id ?? 0)_frist_move_track_alert")
                UserDefaults.standard.synchronize()
                
                self.selectedDeviceId = devceid
                self.fristAlertView(type: type)
            }
        }else {
            if UserDefaults.standard.string(forKey: "\(A4xUserDataHandle.Handle?.loginModel?.id ?? 0)_frist_preset_location_alert") != "1" {
                UserDefaults.standard.setValue(String(1), forKey:"\(A4xUserDataHandle.Handle?.loginModel?.id ?? 0)_frist_preset_location_alert")
                UserDefaults.standard.synchronize()
                fristAlertView(type: type)
            }
        }
    }
    
    func fristAlertView(type: String) {
        
        liveMoveTrackAlertView = UIView()
        liveMoveTrackAlertView.isUserInteractionEnabled = true
        liveMoveTrackAlertView.backgroundColor = UIColor.colorFromHex("#000000" ,alpha: 1)
        UIApplication.shared.keyWindow?.addSubview(liveMoveTrackAlertView)
        liveMoveTrackAlertView.snp.makeConstraints { (make) in
            make.edges.equalTo(UIApplication.shared.keyWindow!.snp.edges)
        }
        
        let titleIconImgView = UIImageView()
        titleIconImgView.image = type == "move_track" ? R.image.device_live_title_move_alert() : R.image.device_preset_location()
        liveMoveTrackAlertView.addSubview(titleIconImgView)
        titleIconImgView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(type == "move_track" ? 65.5.auto() : 20.auto())
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 36.auto(), height: 36.auto()))
        }
        
        let titleLbl = UILabel()
        titleLbl.textColor = .white
        titleLbl.font = UIFont.regular(17.auto())
        titleLbl.text = type == "move_track" ? R.string.localizable.motion_tracking() : R.string.localizable.preset_location()
        titleLbl.textAlignment = .center
        titleLbl.numberOfLines = 0
        liveMoveTrackAlertView.addSubview(titleLbl)
        titleLbl.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalTo(type == "move_track" ? 395.auto() : 470.5.auto())
            make.top.equalTo(titleIconImgView.snp.bottom).offset(14.auto())
        }
        
        let msgLbl = UILabel()
        msgLbl.textColor = .white
        msgLbl.font = UIFont.regular(15.auto())
        msgLbl.text = type == "move_track" ? R.string.localizable.action_tracing_open() : R.string.localizable.position_tips()
        msgLbl.textAlignment = .center
        msgLbl.numberOfLines = 0
        liveMoveTrackAlertView.addSubview(msgLbl)
        msgLbl.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalTo(type == "move_track" ? 395.auto() : UIScreen.width - 32.auto())
            make.top.equalTo(titleLbl.snp.bottom).offset(8.auto())
        }
        
        let msg2Lbl = UILabel()
//        msg2Lbl.textColor = .white
//        msg2Lbl.font = UIFont.regular(15.auto())
//        msg2Lbl.text = R.string.localizable.tracking_guide()
//        msg2Lbl.textAlignment = .center
//        msg2Lbl.numberOfLines = 0
        if type == "move_track" {
            liveMoveTrackAlertView.addSubview(msg2Lbl)
            msg2Lbl.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.width.equalTo(395.auto())
                make.top.equalTo(msgLbl.snp.bottom).offset(8.auto())
            }
            
        }
        
        let setMoveTypeLbl = UILabel()
//        setMoveTypeLbl.textColor = ADTheme.Theme
//        setMoveTypeLbl.font = UIFont.regular(14.67.auto())
//        setMoveTypeLbl.text = R.string.localizable.tracking_guide_2()
//        setMoveTypeLbl.textAlignment = .center
//        setMoveTypeLbl.numberOfLines = 0
//        setMoveTypeLbl.isUserInteractionEnabled = true
        if type == "move_track" {
            liveMoveTrackAlertView.addSubview(setMoveTypeLbl)
            setMoveTypeLbl.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.width.equalTo(395.auto())
                make.top.equalTo(msg2Lbl.snp.bottom).offset(8.auto())
            }
//            setMoveTypeLbl.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pushDeviceMotionTrackingSetting)))
        }
        
        let guideImageView = UIImageView()
        let gifImage = UIImage(gifName: "device_preset_location.gif")
        guideImageView.setGifImage(gifImage, manager: gifManager ,loopCount: -1)
        if type != "move_track" {
            liveMoveTrackAlertView.addSubview(guideImageView)
            guideImageView.snp.makeConstraints { (make) in
                make.top.equalTo(msgLbl.snp.bottom).offset(13.5.auto())
                make.centerX.equalToSuperview()
                make.width.equalTo(164.auto())
                make.height.equalTo(162.auto())
            }
            guideImageView.layoutIfNeeded()
        }
        
        let doneBtn = UIButton()
        doneBtn.titleLabel?.font = ADTheme.B1
        doneBtn.titleLabel?.numberOfLines = 0
        doneBtn.titleLabel?.textAlignment = .center
        doneBtn.setTitle(R.string.localizable.ok(), for: UIControl.State.normal)
        doneBtn.setTitleColor(ADTheme.C4, for: UIControl.State.disabled)
        doneBtn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        doneBtn.setBackgroundImage(UIImage.buttonNormallImage, for: .normal)
        let image = doneBtn.currentBackgroundImage
        let pressColor = image?.multiplyColor(image?.mostColor ?? ADTheme.Theme, by: 0.9)
        doneBtn.setBackgroundImage(UIImage.init(color: pressColor ?? ADTheme.Theme), for: .highlighted)
        doneBtn.setBackgroundImage(UIImage.init(color: ADTheme.C5), for: .disabled)
        doneBtn.layer.cornerRadius = 8.auto()
        doneBtn.clipsToBounds = true
        doneBtn.isUserInteractionEnabled = true
        liveMoveTrackAlertView.addSubview(doneBtn)
        doneBtn.snp.makeConstraints { (make) in
            make.centerX.equalTo(liveMoveTrackAlertView.snp.centerX).offset(0)
            make.width.equalTo(256.auto())
            make.height.equalTo(40.auto())
            make.bottom.equalTo(liveMoveTrackAlertView.snp.bottom).offset(type == "move_track" ? -65.auto() : -20.auto())
        }
        doneBtn.addTarget(self, action: #selector(moveTrackAlertDone), for: .touchUpInside)
    }
    
    
    // 点击弹窗好的
    @objc func moveTrackAlertDone() {
        debugPrint("-------------> pushDeviceMotionTrackingSetting")
        liveMoveTrackAlertView.removeFromSuperview()
    }
    
    // 点击去设置人形追踪
    @objc private func pushDeviceMotionTrackingSetting() {
        debugPrint("-------------> pushDeviceMotionTrackingSetting")
        // 需要加loading状态，停止直播过程比较慢
        
        //        A4xPlayerManager.handle.stopAll(troubleDevice: nil, reason: A4xPlayerStopReason.changePage)
        //        // 打点事件（直播设置-四分屏）
        //        let playVideoEM = A4xPlayVideoEventModel()
        //        playVideoEM.live_player_type = "halfscreen"
        //        A4xEventManager.endEvent(event:ADTickerPlayVideo.live_camera_setting_click(eventModel: playVideoEM))
        
        liveMoveTrackAlertView.removeFromSuperview()
        
        // 待SetSDK接入
//        let vc = ADDevicesMotionTrackingViewController(deviceId: self.selectedDeviceId ?? "")
//        vc.fromVCType = .liveVC
//        navigationController?.pushViewController(vc, animated: true)
    }
    
    func playerConnectState(state: A4xPlayerStateType, videoV: UIView?, videoSize: CGSize) {
        videoControlView.videoState = state
        videoControlView.videoView = videoV
        weak var weakSelf = self
        // 点击了Wi-Fi提示后处理
        if !isShow4GAlert {
            checkShow4GAlert()
        }
        
        if state == .playing && dataSource?.deviceContrl?.rotate ?? false {
            presetModle?.featch(deviceId: dataSource?.id ?? "") { error in
                if let e = error {
                    weakSelf?.view.makeToast(e)
                }
                weakSelf?.videoControlView.presetListData = weakSelf?.presetModle?.data(deviceId: weakSelf?.dataSource?.id ?? "")
                
                // 横屏判断是否是人形追踪
                weakSelf?.videoControlView.autoFollowBtnIsHumanImg = weakSelf?.presetModle?.isFollowType(deviceId: weakSelf?.dataSource?.id ?? "") ?? false
                
                // 横屏运动追踪状态图标
                weakSelf?.videoControlView.isFllow = weakSelf?.presetModle?.isFollow(deviceId: weakSelf?.dataSource?.id ?? "") ?? false
                //debugPrint("-------> isAdmin:\(weakSelf?.dataSource?.isAdmin())")
                
            }
        }
        
        if let dateSource = dataSource {
            A4xLog("ADLiveVideoControlView playerConnectState videoV")
            videoControlView.audioEnable = A4xPlayerManager.handle.audioEnable(device: dateSource)
        }
        A4xLog("ADLiveVideoControlView playerConnectState\(state)  --  \(videoSize)")
    }
    
    func playerRecoredState(state: A4xPlayerRecordState, error errorCode: Int, videoPath: String) {
        switch state {
        case .start:
            videoControlView.recordState = .record
        case .end:
            videoControlView.recordState = .none
            if let image = self.videoFirstImage(fromVideoPath: videoPath) {
                ADLiveVideoAnimailView.showThumbnail(tapButton: self.videoControlView.recordButton, image: image, tipString: R.string.localizable.save_album()) {
                    
                }
            }
        case .startError:
            videoControlView.recordState = .none
        case .endError:
            videoControlView.recordState = .none
        }
    }
    
    func videoFirstImage(fromVideoPath path : String) -> UIImage? {
         let videoURL = URL(fileURLWithPath: path)
         let avAsset = AVAsset(url: videoURL)
         
         //生成视频截图
         let generator = AVAssetImageGenerator(asset: avAsset)
         generator.appliesPreferredTrackTransform = true
         let time = CMTimeMakeWithSeconds(0.0,preferredTimescale: 600)
         var actualTime:CMTime = CMTimeMake(value: 0,timescale: 0)
         guard let imageRef:CGImage = try? generator.copyCGImage(at: time, actualTime: &actualTime) else {
             return nil
         }
         let frameImg = UIImage(cgImage: imageRef)
         return frameImg
     }
}

extension ADLiveVideoViewController: A4xUserDataHandleWifiProtocol {
    func wifiInfoUpdate(status: ADReaStatus) {
        if A4xPlayerManager.handle.isPlaying(device: dataSource) {
            checkShow4GAlert()
        }
    }
    
    // 全屏添加预设位置
    private func addPresetAlertLocation(deviceId: String?, image: UIImage?) {
        // 打点事件（全屏添加预设位置）
        let playVideoEM = A4xPlayVideoEventModel()
        playVideoEM.live_player_type = "fullscreen"
        
        let (add, error) = presetModle?.canAdd(deviceId: deviceId) ?? (true, nil)
        if !add {
            playVideoEM.result = "\(add)"
            playVideoEM.error_msg = error
            A4xEventManager.endEvent(event:ADTickerPlayVideo.live_remoteControl_savePoint_add(eventModel: playVideoEM))
            view.makeToast(error)
            return
        }
        weak var weakSelf = self
        A4xLog("addPresetAlertLocation ")
        let alert = ADAddPresetLocationAlert(frame: CGRect.zero)
        alert.image = image
        let currKeyWindow = UIApplication.shared.keyWindow
        alert.onEditDone = { str in
            A4xLog("onEditDone onEditDone")
            currKeyWindow?.makeToastActivity(title: R.string.localizable.loading(), completion: { _ in })
            weakSelf?.presetModle?.add(deviceId: deviceId, image: image, name: str, comple: { status, tips in
                
                currKeyWindow?.hideToastActivity()
                weakSelf?.view.makeToast(tips)
                weakSelf?.videoControlView.presetListData = weakSelf?.presetModle?.data(deviceId: deviceId ?? "")
                
                playVideoEM.result = "\(status)"
                if !status {
                    playVideoEM.error_msg = tips
                }
                A4xEventManager.endEvent(event:ADTickerPlayVideo.live_remoteControl_savePoint_add(eventModel: playVideoEM))
            })
        }
        alert.show()
    }
    
    // 删除预设位置
    private func deletePresetLocaion(deviceId: String?, preset: ADPresetModel?) {
        A4xLog("deletePresetLocaion ")
        // 打点事件（全屏添加预设删除）
        let playVideoEM = A4xPlayVideoEventModel()
        playVideoEM.live_player_type = "fullscreen"
        
        weak var weakSelf = self
        presetModle?.remove(deviceId: deviceId, pointId: preset?.id ?? 0) { status, tips in
            playVideoEM.result = "\(status)"
            if status {
                weakSelf?.videoControlView.presetListData = weakSelf?.presetModle?.data(deviceId: deviceId ?? "")
            } else {
                playVideoEM.error_msg = "\(String(describing: tips))"
            }
            A4xEventManager.endEvent(event:ADTickerPlayVideo.live_remoteControl_savePoint_delete(eventModel: playVideoEM))
            weakSelf?.view.makeToast(tips)
        }
    }
    
    private func presetClickAction(deviceId: String?, preset: ADPresetModel?) {
        A4xLog("presetClickAction")
        presetModle?.send(deviceId: deviceId, preset: preset) { _ in
        }
    }
}


extension ADLiveVideoViewController: ADLiveVideoControlProtocol {
    func deviceSleepToWakeUp(device: A4xDeviceModel?) {
        // 开启休眠
        weak var weakSelf = self
        UIApplication.shared.keyWindow?.makeToastActivity(title: R.string.localizable.loading()) { (f) in
        }
        
        presetModle?.sleepToWakeUP(deviceId: device?.id ?? "", enable: false, comple: { (err) in
            UIApplication.shared.keyWindow?.hideToastActivity()
            if err != nil {
                weakSelf?.view.makeToast(err)
            }
            weakSelf?.videoReconnect()
        })
    }
    
    func presetLocationAction() {
        guard let devideId = dataSource?.id else {
            return
        }
        fristGuideAlert(devideId, type: "preset_location")
    }
    
    func videoFllowChange(enable: Bool, comple: @escaping (_ isScuess: Bool) -> Void) {
        guard let devideId = dataSource?.id else {
            return
        }
        weak var weakSelf = self
        presetModle?.updateMotionTrackStatus(deviceId: devideId, enable: enable, comple: { error in
            // 打点事件-
            let playVideoEM = A4xPlayVideoEventModel()
            playVideoEM.live_player_way = "fullscreen"
            playVideoEM.switch_status = "\(enable == true ? "open" : "close")"
            
            if error != nil {
                weakSelf?.view.makeToast(error)
                playVideoEM.result = "false"
                playVideoEM.error_msg = error
            }
            
            if enable && !(weakSelf?.presetModle?.isFollowType(deviceId: weakSelf?.dataSource?.id ?? "") ?? false) {
                weakSelf?.fristGuideAlert(devideId, type: "move_track")
            }
            playVideoEM.track_mode = (weakSelf?.presetModle?.isFollowType(deviceId: weakSelf?.dataSource?.id ?? "") ?? false) == true ? "people_detection" : "move_track"
            A4xEventManager.playRecordEvent(event:ADTickerPlayVideo.live_sportTrack_switch_click(eventModel: playVideoEM))
            comple(error == nil)
        })
    }
    
    func videoDisReconnect() {
        guard let dateSource = dataSource else {
            return
        }
        A4xPlayerManager.handle.stop(device: dateSource, playNumber: nil, reason: A4xPlayerStopReason.none)
    }
    
    func videoControlWhiteLight(enable: Bool) {
        guard let data = dataSource else {
            return
        }
        A4xPlayerManager.handle.setWhiteLight(device: data, enable: enable)
    }
    
    func videoZoomChange() {
        guard let data = dataSource else {
            return
        }
        A4xPlayerManager.handle.setZoomChange(device: data)
    }
    
    func resetLocationAction(type: LiveVideoPresetCellType, data: ADPresetModel?) {
        let playVideoEM = A4xPlayVideoEventModel()
        playVideoEM.live_player_type = "fullscreen"
        
        switch type {
        case .none:// 点击预设位置
            // live_remoteControl_savePoint_rotate
            playVideoEM.save_point_id = dataSource?.id
            A4xEventManager.endEvent(event:ADTickerPlayVideo.live_remoteControl_savePoint_rotate(eventModel: playVideoEM))
            presetClickAction(deviceId: dataSource?.id, preset: data)
        case .add:// 新增预设位置
            // live_remoteControl_savePoint_add
            weak var weakSelf = self
            A4xPlayerManager.handle.currentImage(device: self.dataSource ?? A4xDeviceModel()) { (img) in
                weakSelf?.addPresetAlertLocation(deviceId: self.dataSource?.id, image: img)
            }
        case .delete:// 删除预设位置
            // live_remoteControl_savePoint_delete
            deletePresetLocaion(deviceId: dataSource?.id, preset: data)
        }
    }
    
    func deviceRotate(point: CGPoint) {
        weak var weakSelf = self
        presetModle?.rotate(deviceId: playerDeviceId(), x: Float(point.x), y: Float(point.y)) { error in
            if let e = error {
                weakSelf?.view.makeToast(e)
            }
        }
    }
    
    func videoDetailChange(type: A4xVideoSharpType) {
//        dataSource?.setVideoSharp(type: type)
        A4xUserDataHandle.Handle?.updateDevice(device: dataSource)
        A4xLog("切换分辨率 \(type.rawValue)")
        A4xPlayerManager.handle.videoDetailChange(device: dataSource!, type: type) { [weak self] (flag) in
            if flag {
                self?.videoControlView.dataSource = self?.dataSource
            }
        }
    }
    
    func videoVolumeAction(enable: Bool) {
        A4xLog("videoVolumeAction")
        guard let dateSource = dataSource else {
            return
        }
        
        // 打点事件（静音）
        let playVideoEM = A4xPlayVideoEventModel()
        playVideoEM.live_player_type = "fullscreen"
        playVideoEM.switch_status = "\(enable)"
        playVideoEM.connect_device = dataSource?.id
        A4xEventManager.endEvent(event:ADTickerPlayVideo.live_mute_switch_click(eventModel: playVideoEM))
        
        A4xPlayerManager.handle.setAudioEnable(device: dateSource, enable: enable)
    }
    
    func videoRecordVideo(start: Bool) {
        guard let dateSource = dataSource else {
            return
        }
        A4xLog("videoRecordVideo")
        //weak var weakSelf = self
        let playVideoEM = A4xPlayVideoEventModel()
        
        playVideoEM.live_player_type = "fullscreen"
        // 检测是否有录制权限 （可封装-重复代码）
        A4xBasePhotoManager.default().checkAuthor { error in
            if error == .no {
                if start {
                    A4xPlayerManager.handle.startRecored(device: dateSource)
                } else {
                    A4xPlayerManager.handle.stopRecored(device: dateSource)
                }
            } else {
                if error == .reject {
                    playVideoEM.result = "false"
                    playVideoEM.error_msg = "录制失败，录制权限被拒绝"
                    playVideoEM.stop_way = "error"
                    playVideoEM.storage_space = UIDevice.current.freeDiskSpaceInGB
                    A4xEventManager.endEvent(event:ADTickerPlayVideo.live_record_video(eventModel: playVideoEM))
                }
                // weakSelf?.view.makeToast(R.string.localizable.allow_libary())
                A4xBaseAuthorizationViewModel.single.showRequestAlert(type: A4xBaseAuthorizationType.photo) { [weak self] open in
                    if !open {
                        self?.videoControlView.recordState = .none
                    }
                }
            }
        }
    }
    
    func videoReconnect() {
        guard let dateSource = dataSource else {
            return
        }
        
        debugPrint("------------> videoSendPlay:\( self.videoControlView.videoState)")
        switch self.videoControlView.videoState {
        case .error, .updating:
            debugPrint("------------> videoSendPlay error")
            self.logTool?.logLiveReConnectClick(error_code: "0", error_msg: self.videoControlView.videoState.errInfo())
            break
        case .pausedp2p, .none:
            debugPrint("------------> videoSendPlay normal")
            self.logTool?.logLiveClick(btnType: "normal")
            break
        default:
            break
        }
        
        A4xPlayerManager.handle.stop(device: dataSource!, playNumber: nil, reason: .click)
        A4xPlayerManager.handle.play(playType: .landscape, device: dateSource, voiceEnable: nil, shouldSpeak: true, playNumber: nil, Params: [.videoScale: A4xPlayerViewScale.aspectFit, .lookWhite: true])
    }
    
    func videoBarBackAction() {
        //        navigationController?.popViewController(animated: true)
        if currentIndexPath != nil {
            //结束当前页面的直播操作
            A4xPlayerManager.handle.removeStateProtocol(target: self)
            guard let data = self.dataSource else {
                delegate?.didFinishViewController(controller: self, currentIndexPath: currentIndexPath ?? IndexPath(row: 0, section: 0))
                return
            }
            
            if A4xPlayerManager.handle.isRecored(device: data) {
                A4xPlayerManager.handle.stopRecored(device: data)
            }
            
            A4xPlayerManager.handle.setVideoZoomEnable(device: data, enable: false)
            if self.shouldBackStop {
                A4xPlayerManager.handle.stop(device: data, playNumber: nil, reason: A4xPlayerStopReason.changePage)
            } else {
                A4xPlayerManager.handle.updateParam(device: data, Params: [.videoScale : A4xPlayerViewScale.aspectFill ])
            }
            delegate?.didFinishViewController(controller: self, currentIndexPath: currentIndexPath ?? IndexPath(row: 0, section: 0))
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func videoBarSettingAction() {
        A4xLog("videoBarSettingAction")
        // 待SetSDK接入
//        let vc = ADDevicesSettingViewController()
//        vc.deviceId = dataSource?.id
//        vc.fromType = .simple
//        navigationController?.pushViewController(vc, animated: true)
//        guard let data = dataSource else {
//            return
//        }
//
//        // 打点事件（全屏设置）
//        let playVideoEM = A4xPlayVideoEventModel()
//        playVideoEM.live_player_type = "fullscreen"
//        A4xEventManager.endEvent(event:ADTickerPlayVideo.live_camera_setting_click(eventModel: playVideoEM))
//
//        A4xPlayerManager.handle.stop(device: data, playNumber: nil, reason: A4xPlayerStopReason.none)
    }
    
    func videoAlarmAction() {
        A4xLog("videoAlarmAction")
        guard let deviceId: String = dataSource?.id else {
            return
        }
        // 打点事件（警铃）
        let playVideoEM = A4xPlayVideoEventModel()
        playVideoEM.live_player_type = "fullscreen"
        weak var weakSelf = self
        self.showDeviceAlert( message: R.string.localizable.do_alarm_tips(), cancelTitle: R.string.localizable.cancel(), doneTitle: R.string.localizable.alarm_on(), image: R.image.device_send_alert(), doneAction: {
            A4xNetManager.execute(reqMoudelType: A4xNetMoudelType.Devices(.alarm(deviceId: deviceId)), resModelType: A4xNetNormaiModel.self) { result in
                switch result {
                case .success:
                    playVideoEM.result = "true"
                    weakSelf?.showAlertTip()
                    A4xEventManager.endEvent(event:ADTickerPlayVideo.live_alarm_bell(eventModel: playVideoEM))
                    A4xLog("success")
                case let .failure(code, _):
                    playVideoEM.result = "false"
                    playVideoEM.error_msg = A4xAppErrorConfig(code: code).message()
                    A4xEventManager.endEvent(event:ADTickerPlayVideo.live_alarm_bell(eventModel: playVideoEM))
                    A4xLog("failure")
                    weakSelf?.view.makeToast(A4xAppErrorConfig(code: code).message())
                }
            }
        }) {}
    }
    
    func showAlertTip(){
        var style = ToastStyle()
        style.cornerRadius = 18
        style.messageFont = UIFont.systemFont(ofSize: 13)
        style.maxHeightPercentage = 4
        style.maxWidthPercentage = 22
        style.backgroundColor = UIColor.hex(0xFF6A6A)
        style.imageSize = CGSize(width: 25, height: 25)
        style.horizontalPadding = 16
        style.verticalPadding = 10
        style.messageFont = UIFont.systemFont(ofSize: 14.auto())
        
        self.view.hideAllToasts()
        self.view.makeToast(R.string.localizable.alarm_playing() , duration: 5, point: CGPoint(x: self.view.midX, y: 60), title: nil, image: R.image.live_alert_icon(), style: style , completion: nil)
    }
    
    func videoSpeakAction(enable: Bool) -> Bool {
        
        // 打点事件（双向语音）
        let playVideoEM = A4xPlayVideoEventModel()
        playVideoEM.live_player_type = "fullscreen"
        
        guard let data = dataSource else {
            return false
        }
        
        guard A4xPlayerManager.handle.canSpeak(device: data) else {
            if enable {
                playVideoEM.result = "false"
                playVideoEM.error_msg = R.string.localizable.reject_audio()
                A4xEventManager.endEvent(event:ADTickerPlayVideo.live_voice_calls(eventModel: playVideoEM))
                //view.makeToast(R.string.localizable.reject_audio())
                A4xBaseAuthorizationViewModel.single.showRequestAlert(type: .audio) { open in
                    if !open {}
                }
            }
            return false
        }
        if enable {
            if A4xPlayerManager.handle.speakLoad(device: data) {
                A4xPlayerManager.handle.setAudioEnable(device: data, enable: true)
                videoControlView.audioEnable = true
                playVideoEM.result = "true"
                A4xEventManager.endEvent(event:ADTickerPlayVideo.live_voice_calls(eventModel: playVideoEM))
            } else {
                playVideoEM.result = "false"
                playVideoEM.error_msg = R.string.localizable.voice_talk_failed_and_retry()
                A4xEventManager.endEvent(event:ADTickerPlayVideo.live_voice_calls(eventModel: playVideoEM))
                
                view.makeToast(R.string.localizable.voice_talk_failed_and_retry())
                return false
            }
        }
        A4xPlayerManager.handle.setSpeakEnable(device: data, enable: enable)
        
        return true
    }
    
    func videoScreenSnap(view: UIView) {
        guard let dateSource = dataSource else {
            return
        }
        
        A4xBasePhotoManager.default().checkAuthor { error in
            if error == .no {
                A4xPlayerManager.handle.snapImage(device: dateSource) { [weak self] image in
                    guard let img = image else {
                        self?.view.makeToast(R.string.localizable.shot_fail())
                        return
                    }
                    self?.showAnimail(img: img, view: view)
                }
            } else {
                if error == .reject {}
                A4xBaseAuthorizationViewModel.single.showRequestAlert(type: A4xBaseAuthorizationType.photo) { open in
                    if !open {
                        //self?.videoControlView.recordState = .none
                    }
                }
            }
        }
    }
}
