//
//  NewVideoViewController.swift
//  WebRTC-Demo
//
//  Created by Hao Shen on 5/26/20.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import Foundation
import UIKit


enum ADDXWebRTCVideoSharpType {
    case type480p
    case type720p
    case type1080p
}

class ADDXWebRTCVideoVC: UIViewController {
    
    var settingBtnClickedBlock: (() -> ())?
    private var wbeRTCPlayer:ADDXWebRTCPlayer?
    private var dataChannelInput: DataChannelInputView?
    private var leaveingRoom: Bool = false
    private var muteBtn: UIButton?
    private var speakBtn: UIButton?
    private var videoSharpBtn: UIButton?
    
    var _groupId: String = ""
    var _roleId: String  = ""
    var _clientId: String = ""
    var _recipientClientId: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.leaveingRoom = false
        self.view.backgroundColor = UIColor.black
        //for test
        let ticket = ADDXWebRTCConfig.sharedInstance().ticket
        ticket.groupId  = _groupId
        ticket.role = _roleId
        ticket.clientId = _clientId
        ticket.recipientClientId = _recipientClientId
        
        self.wbeRTCPlayer = ADDXWebRTCPlayer.player(webRTCTicket: ticket)
        if self.wbeRTCPlayer != nil {
            self.wbeRTCPlayer?.delegate = self
            let remoteRenderer = self.wbeRTCPlayer?.renderView
            remoteRenderer?.frame = CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
            self.view.addSubview(remoteRenderer!)
            self.view.sendSubviewToBack(remoteRenderer!)
            
            //加载页面控件
            self.loadSubViews()
            self.wbeRTCPlayer?.startConnect()
        }else{
            let alertController = UIAlertController(title: "提示", message: "配置ice 错误！", preferredStyle: UIAlertController.Style.alert)
            
            alertController.addAction(UIAlertAction(title: "确认", style:UIAlertAction.Style.default
                , handler: { (action: UIAlertAction) in
                    self.navigationController?.popViewController(animated: true)
            }))
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //        self.wbeRTCPlayer?.renderView.frame = CGRect.init(x: 0, y: 0, width: Int(arc4random())%100+100, height: Int(arc4random())%100+100)
    }
    func loadSubViews(){
        //返回按钮
        let backbtn = UIButton.init(type: .custom)
        let backImage = UIImage.init(named: "icon_back_write")
        if backImage != nil {
            backbtn.setImage(UIImage.init(named: "icon_back_write"), for: .normal)
        }else{
            backbtn.setTitle("<", for: .normal)
        }
        
        backbtn.addTarget(self, action: #selector(back), for: UIControl.Event.touchUpInside)
        backbtn.frame = CGRect.init(x: 12, y: 20, width: 40, height: 40)
        self.view.addSubview(backbtn)
        
        //保存图片按钮
        let btn = UIButton.init(type: .custom)
        let savePictureImage = UIImage.init(named: "video_live_screen_shot")
        if savePictureImage != nil {
            btn.setImage(savePictureImage, for: .normal)
            btn.frame = CGRect.init(x: 12, y: self.view.frame.size.height/2.0 + 30, width: 40, height: 40)
        }else{
            btn.setTitle("保存图片", for: .normal)
            btn.titleLabel?.adjustsFontSizeToFitWidth = true
            btn.frame = CGRect.init(x: 12, y: self.view.frame.size.height/2.0 + 30, width: 60, height: 40)
        }
        btn.addTarget(self, action: #selector(captureImage), for: UIControl.Event.touchUpInside)
        self.view.addSubview(btn)
        
        //录制按钮
        let btn1 = UIButton.init(type: .custom)
        let saveVideoimage = UIImage.init(named: "live_video_record_normail")
        if saveVideoimage != nil {
            btn1.setImage(saveVideoimage, for: .normal)
            btn1.frame = CGRect.init(x: 12, y: self.view.frame.size.height/2.0 - 30, width: 40, height: 40)
        }else{
            btn1.setTitle("开始录制", for: .normal)
            btn1.titleLabel?.adjustsFontSizeToFitWidth = true
            btn1.frame = CGRect.init(x: 12, y: self.view.frame.size.height/2.0 - 30, width: 60, height: 40)
        }
        btn1.addTarget(self, action: #selector(captureVideo), for: UIControl.Event.touchUpInside)
        self.view.addSubview(btn1)
        
        //静音按钮
        let muteBtn = UIButton.init(type: .custom)
        let muteBtnimage = UIImage.init(named: "video_live_volume")
        if muteBtnimage != nil {
            muteBtn.setImage(muteBtnimage, for: .normal)
        }else{
            muteBtn.setTitle("外放", for: .normal)
            muteBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        }
        muteBtn.frame = CGRect.init(x: 12, y: self.view.frame.size.height - 60, width: 40, height: 40)
        muteBtn.addTarget(self, action: #selector(muteBtnClicked), for: UIControl.Event.touchUpInside)
        self.view.addSubview(muteBtn)
        self.muteBtn = muteBtn
        
        //铃声按钮
        let warnimgBtn = UIButton.init(type: .custom)
        let warnimgBtnimage = UIImage.init(named: "video_live_warning")
        if warnimgBtnimage != nil {
            warnimgBtn.setImage(warnimgBtnimage, for: .normal)
        }else{
            warnimgBtn.setTitle("警告", for: .normal)
            warnimgBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        }
        warnimgBtn.frame = CGRect.init(x: 100, y: self.view.frame.size.height - 60, width: 40, height: 40)
        warnimgBtn.addTarget(self, action: #selector(warningBtnClicked), for: UIControl.Event.touchUpInside)
        self.view.addSubview(warnimgBtn)
        
        
        //说话按钮
        let speakBtn = UIButton.init(type: .custom)
        let speakBtnimage = UIImage.init(named: "video_live_speak")
        if speakBtnimage != nil {
            speakBtn.setImage(speakBtnimage, for: .normal)
        }else{
            speakBtn.setTitle("不可以说话", for: .normal)
            speakBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        }
        speakBtn.frame = CGRect.init(x: self.view.frame.size.width/2.0 - 20.0, y: self.view.frame.size.height - 60, width: 60, height: 40)
        speakBtn.addTarget(self, action: #selector(speakBtnClicked), for: UIControl.Event.touchUpInside)
        self.view.addSubview(speakBtn)
        self.speakBtn = speakBtn
        self.speakBtn?.isSelected = false
        self.speakBtnClicked(sender: self.speakBtn!)
        
        //设置按钮
        let settingBtn = UIButton.init(type: .custom)
        let settingBtnimage = UIImage.init(named: "live_video_setting")
        if settingBtnimage != nil {
            settingBtn.setImage(settingBtnimage, for: .normal)
        }else{
            settingBtn.setTitle("设置", for: .normal)
            settingBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        }
        settingBtn.frame = CGRect.init(x: self.view.frame.size.width - 60.0, y: 20, width: 40, height: 40)
        settingBtn.addTarget(self, action: #selector(settingBtnClicked), for: UIControl.Event.touchUpInside)
        self.view.addSubview(settingBtn)
        
        //设置按钮
        let connectBtn = UIButton.init(type: .custom)
        connectBtn.setTitle("连接", for: .normal)
        connectBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        connectBtn.frame = CGRect.init(x: 60.0, y: 80, width: 100, height: 40)
        connectBtn.addTarget(self, action: #selector(connectBtnClicked), for: UIControl.Event.touchUpInside)
        self.view.addSubview(connectBtn)
        
        let disconnectBtn = UIButton.init(type: .custom)
        disconnectBtn.setTitle("断开连接", for: .normal)
        disconnectBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        disconnectBtn.frame = CGRect.init(x: self.view.frame.size.width - 160.0, y: 80, width: 100, height: 40)
        disconnectBtn.addTarget(self, action: #selector(disconnectBtnClicked), for: UIControl.Event.touchUpInside)
        self.view.addSubview(disconnectBtn)
        
        //设置按钮
        let videoSharpBtn = UIButton.init(type: .custom)
        let videoSharpBtnimage = UIImage.init(named: self.videoSharpImageName(type: .type480p))
        if videoSharpBtnimage != nil {
            videoSharpBtn.setImage(videoSharpBtnimage, for: .normal)
        }else{
            videoSharpBtn.setTitle("标清", for: .normal)
            videoSharpBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        }
        videoSharpBtn.frame = CGRect.init(x: self.view.frame.size.width - 100, y: self.view.frame.size.height - 60, width: 80, height: 40)
        videoSharpBtn.addTarget(self, action: #selector(videoSharpBtnClicked), for: UIControl.Event.touchUpInside)
        self.view.addSubview(videoSharpBtn)
        self.videoSharpBtn = videoSharpBtn
        
        //添加data channel 输入文本的textview
        let textView = DataChannelInputView.init(frame: CGRect.init(x:self.view.frame.size.width/2.0 , y:self.view.frame.size.height - 300.0, width:self.view.frame.size.width/2.0 , height:200.0))
        self.view.addSubview(textView)
        self.dataChannelInput = textView;
        self.dataChannelInput!.updateSendedMessage(message: "建立连接中......", sucess: true,receive:false)
        self.dataChannelInput!.sendTextBlock = { message in
            if message.count > 0 {
                let data = message.data(using: .utf8)
                let sucess = self.wbeRTCPlayer?.dataChannelSendData(data: data!,isBinary:false)
                var result = "(成功)"
                if sucess! {
                    result = "(成功)"
                    debugPrint("发送消息: \(message) 成功")
                }else{
                    result = "(失败)f"
                    debugPrint("发送消息: \(message) 失败")
                }
                self.dataChannelInput?.updateSendedMessage(message: "发送消息："+message+result, sucess: sucess!,receive:false)
            }
        }
        let tgr = UITapGestureRecognizer.init(target: self, action: #selector(touchTGRClicked))
        self.view.addGestureRecognizer(tgr)
    }
    @objc func touchTGRClicked(tgr:UITapGestureRecognizer){
        self.view.endEditing(true)
    }
    @objc func connectBtnClicked(sender: UIButton) -> Void {
        self.wbeRTCPlayer?.startConnect()
    }
    @objc func disconnectBtnClicked(sender: UIButton) -> Void {
        self.wbeRTCPlayer?.stopConnect()
    }
    
    @objc func back(sender: UIButton) -> Void {
        debugPrint("退出页面")
        self.leaveingRoom = true
        self.wbeRTCPlayer?.stopConnect()
        self.navigationController?.popViewController(animated: true)
    }
    @objc func warningBtnClicked(sender: UIButton) -> Void {
        
    }
    @objc func settingBtnClicked(sender: UIButton) -> Void {
        self.settingBtnClickedBlock?()
    }
    @objc func videoSharpBtnClicked(sender: UIButton) -> Void {
        
    }
    func videoSharpImageName(type: ADDXWebRTCVideoSharpType) -> String{
        switch type {
        case .type480p:
            // 480
            return "live_video_sharp_480p"
        case .type720p:
            // 720
            return "live_video_sharp_720p"
        case .type1080p:
            // 1080
            return "live_video_sharp_1080p"
        }
    }
    @objc func speakBtnClicked(sender: UIButton) -> Void {
        //将静音按钮恢复
        if sender.isSelected {
            self.wbeRTCPlayer!.speakerOff()
            self.speakBtn?.setTitle("不可以说话", for: .normal)
            self.speakBtn?.isSelected = false
        }else{
            self.wbeRTCPlayer!.speakerOn()
            self.speakBtn?.setTitle("可以说话", for: .normal)
            self.speakBtn?.isSelected = true
        }
    }
    
    @objc func muteBtnClicked(sender: UIButton) -> Void {
        if !sender.isSelected {
            let muteBtnimage = UIImage.init(named: "video_live_volume_mute")
            if muteBtnimage != nil {
                sender.setImage(muteBtnimage, for: .normal)
            }else{
                sender.setTitle("静音", for: .normal)
                sender.titleLabel?.adjustsFontSizeToFitWidth = true
            }
            sender.isSelected = true
            //静音
            if self.wbeRTCPlayer != nil{
                self.wbeRTCPlayer!.muteAudio()
            }
        }else{
            //外放
            sender.isSelected = false
            let unmuteBtnimage = UIImage.init(named: "video_live_volume")
            if unmuteBtnimage != nil {
                sender.setImage(unmuteBtnimage, for: .normal)
            }else{
                sender.setTitle("外放", for: .normal)
                sender.titleLabel?.adjustsFontSizeToFitWidth = true
            }
            if self.wbeRTCPlayer != nil{
                self.wbeRTCPlayer!.unmuteAudio()
            }
        }
    }
    @objc func captureVideo(sender: UIButton) -> Void {
        if self.wbeRTCPlayer != nil {
            if !sender.isSelected {
                let sucess = self.wbeRTCPlayer!.startCaptureVideo()
                if sucess{
                    let saveVideoimage = UIImage.init(named: "live_video_record_selected")
                    if saveVideoimage != nil {
                        sender.setImage(saveVideoimage, for: .normal)
                        sender.frame = CGRect.init(x: 12, y: self.view.frame.size.height/2.0 - 30, width: 40, height: 40)
                    }else{
                        sender.setTitle("停止录制", for: .normal)
                        sender.titleLabel?.adjustsFontSizeToFitWidth = true
                        sender.frame = CGRect.init(x: 12, y: self.view.frame.size.height/2.0 - 30, width: 60, height: 40)
                    }
                    sender.isSelected = true
                }
            }else{
                sender.isEnabled = false
                sender.isSelected = false
                self.wbeRTCPlayer?.stopCaptureVideo({ (sucess, url) in
                    DispatchQueue.main.async {
                        sender.setTitle("开始录制", for: .normal)
                        sender.isEnabled = true
                        self.saveVideoUrl(string: url!.path)
                    }
                })
            }
        }
    }
    
    @objc func captureImage(sender: UIButton) -> Void {
        debugPrint("点击截屏按钮")
        self.wbeRTCPlayer?.captureImage({ (image:UIImage) in
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "提示", message: "保存图片完成！", preferredStyle: UIAlertController.Style.alert)
                
                alertController.addAction(UIAlertAction(title: "确认", style:UIAlertAction.Style.default
                    , handler: { (action: UIAlertAction) in
                }))
                self.present(alertController, animated: true, completion: nil)
            }
        })
    }
    
    func saveVideoUrl(string:String) {
        if string != ""{
            if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(string){
                UISaveVideoAtPathToSavedPhotosAlbum(string, self, #selector(self.video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }
    ///将下载的网络视频保存到相册
    @objc func video(videoPath: String, didFinishSavingWithError error: NSError, contextInfo info: AnyObject) {
        
        if error.code != 0{
            print("保存失败")
            print(error)
        }else{
            print("保存成功")
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.dataChannelInput?.frame = CGRect.init(x:self.view.frame.size.width/2.0 , y:self.view.frame.size.height - 300.0, width:self.view.frame.size.width/2.0 , height:200.0)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.leaveingRoom {
            self.wbeRTCPlayer?.delegate = nil
            self.wbeRTCPlayer = nil
            
        }
    }
    private func embedView(_ view: UIView, into containerView: UIView) {
        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        containerView.layoutIfNeeded()
    }
    
    func leaveRoom() -> Void {
        if self.leaveingRoom {
            return
        }
        self.leaveingRoom = true
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "警告", message: "当前连接中断，需要退出房间！", preferredStyle: UIAlertController.Style.alert)
            
            alertController.addAction(UIAlertAction(title: "确认", style:UIAlertAction.Style.default
                , handler: { (action: UIAlertAction) in
                    self.navigationController?.popViewController(animated: true)
            }))
            alertController.addAction(UIAlertAction(title: "取消", style:UIAlertAction.Style.cancel
                , handler: { (action: UIAlertAction) in
            }))
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
}

extension ADDXWebRTCVideoVC:ADDXWebRTCPlayerDelegate{
    func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, didChangePlayer state: ADDXWebRTCPlayerState) {
        switch state {
        case .ready:
            break
        case .connecting:
            break
        case .connected:
            break
        case .disConnected:
            self.leaveRoom()
            break
        }
    }
    
    func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, didChangePlayer peerState: ADDXWebRTCPlayerPeerConnectState) {
        switch peerState {
        case .new:
            break
        case .connecting:
            self.dataChannelInput!.updateSendedMessage(message: "peer建立连接中......", sucess: true,receive:false)
            break
        case .connected:
            self.dataChannelInput!.updateSendedMessage(message: "peer连接成功.......", sucess: true,receive:false)
            break
        case .disconnected:
            self.dataChannelInput!.updateSendedMessage(message: "peer连接断开......", sucess: true,receive:false)
            break
        case .failed:
            self.dataChannelInput!.updateSendedMessage(message: "peer连接失败......", sucess: true,receive:false)
            break
        case .closed:
            self.dataChannelInput!.updateSendedMessage(message: "peer连接关闭......", sucess: true,receive:false)
            break
        
        }
    }
    
    func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, didChangePlayer iceState: ADDXWebRTCPlayerIceConnectState) {
        switch iceState {
        case .new:
            break
        case .checking:
            self.dataChannelInput!.updateSendedMessage(message: "ice checking中......", sucess: true,receive:false)
            break
        case .connected:
            self.dataChannelInput!.updateSendedMessage(message: "ice连接成功.......", sucess: true,receive:false)
            break
        case .disconnected:
            self.dataChannelInput!.updateSendedMessage(message: "ice连接断开......", sucess: true,receive:false)
            break
        case .failed:
            self.dataChannelInput!.updateSendedMessage(message: "ice连接失败......", sucess: true,receive:false)
            break
        case .closed:
            self.dataChannelInput!.updateSendedMessage(message: "ice连接关闭......", sucess: true,receive:false)
            break
        case .completed:
            self.dataChannelInput!.updateSendedMessage(message: "ice连接完成......", sucess: true,receive:false)
            break
        case .count:
            self.dataChannelInput!.updateSendedMessage(message: "ice count......", sucess: true,receive:false)
            break
        
        }
    }
    
    func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, didChange videoSize: CGSize) {
        print("addxWebRTCPlayerDiddidChange  \(videoSize)")
        
    }
    
    func addxWebRTCPlayerDidReadyPlay(_ player: ADDXWebRTCPlayer) {
        print("addxWebRTCPlayerDidReadyPlay")
    }
    
    func addxWebRTCPlayer(_ manager: ADDXWebRTCPlayer, didReceiveDataChannelData data: Data, isBinary: Bool) {
        if data.count > 0 {
            let mesage = String(data: data, encoding: .utf8)
            self.dataChannelInput?.updateSendedMessage(message: "收到消息：" + mesage!, sucess: true,receive:true)
        }
    }
    
    func addxWebRTCPlayer(_ manager: ADDXWebRTCPlayer, didChangeDataChannelStatea state: ADDXWebRTCPlayerDataChannelState) {
        switch state {
        case .connecting:
            self.dataChannelInput?.updateSendedMessage(message: "建立连接中......", sucess: true,receive:false)
            break
        case .open:
            self.dataChannelInput?.updateSendedMessage(message: "连接已打开", sucess: true,receive:false)
            
            break
        case .closing:
            self.dataChannelInput?.updateSendedMessage(message: "关闭连接中......", sucess: true,receive:false)
            break
        case .closed:
            self.dataChannelInput?.updateSendedMessage(message: "关闭连接中", sucess: true,receive:false)
            break            
        }
    }
    
    func addxWebRTCPlayerSignalClientDidConnect() {
        
    }
    func addxWebRTCPlayerSignalClientDidDisconnect() {
        
    }
}
