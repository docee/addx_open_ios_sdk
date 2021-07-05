//
//  addxWebRTCPlayer.swift
//  WebRTC-Demo
//
//  Created by Hao Shen on 5/26/20.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import Foundation
import UIKit
import WebRTC


public enum ADDXWebRTCPlayerIceConnectState {
    case new
    case checking
    case connected
    case completed
    case failed
    case disconnected
    case closed
    case count
}

public enum ADDXWebRTCPlayerPeerConnectState {
    case new
    case connecting
    case connected
    case disconnected
    case failed
    case closed
}

public enum ADDXWebRTCPlayerState {
    case ready
    case connecting
    case connected
    case disConnected
    case failed
    case timeOut
    case cancelled
}

public enum ADDXWebRTCPlayerDataChannelState {
    case connecting
    case open
    case closing
    case closed
}

public enum ADDXWebRTCPlayerVideoSharpType: String {
    case hb          //高清
    case standard    //标清
    case smooth      //流畅
    case auto        //自适应
}

public enum ADDXWebSocketDisConnectReason: UInt16 {
    case unknow = 0
    case usersLimit = 3002  //观看用户上限
    case timeout = 1001
}

public class ADDXPlayerClientRoleMode {
    public var id : String?
    public var name : String?
    public var role : String?
    public var isMaster: Bool {
        get {
            if role != nil && role! == "master" {
                return true
            }else{
                return false
            }
        }
    }
}

public protocol ADDXWebRTCPlayerDelegate: class {
    //player 连接状态改变
    func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, didChangePlayer state: ADDXWebRTCPlayerState)
    func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, didChangePlayer peerState: ADDXWebRTCPlayerPeerConnectState)
    func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, didChangePlayer iceState: ADDXWebRTCPlayerIceConnectState)
    func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, localSpeakVoiceData voiceData: Array<NSNumber>)
    
    //player 接收到新的媒体流开始播放
    func addxWebRTCPlayerDidReadyPlay(_ player: ADDXWebRTCPlayer)
    //player 视频尺寸改变回调
    func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, didChange videoSize: CGSize)
    //player 发送消息的datachannel 状态改变
    func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, didChangeDataChannelState state: ADDXWebRTCPlayerDataChannelState)
    //player 发送消息的datachannel 接受到消息
    func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, didReceiveDataChannelData data: Data, isBinary: Bool, action: String?)
    //player的信令服务器连接
    func addxWebRTCPlayerSignalClientDidConnect()
    //player的信令服务器正在连接
    func addxWebRTCPlayerSignalClientConnecting()
    //player的信令服务器断开连接
    func addxWebRTCPlayerSignalClientDidDisconnect(disconnectReason: ADDXWebSocketDisConnectReason, errorCode: Int)
    //player的信令服务器通知新的设备进入
    func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, didPeerIn newSignalClient:ADDXPlayerClientRoleMode)
    //player的信令服务器通知新的设备退出
    func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, didPeerOut newSignalClient:ADDXPlayerClientRoleMode)
    //player重连 更新webticket
    func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, updateWebRTCTicket completionCallback:@escaping (_ webRTCTicket: ADDXWebRTCTicketModel?) -> Void)
    //player第一次关键帧
    func addxWebRTCPlayerFirstKeyFrames()
    
    //发送offer
    func addxWebRTCPlayerSendOffer()
    //发送anwser
    func addxWebRTCPlayerSendAnwser()
    
    func addxWebRtcLogSendCmdAction(action: String, flag: Bool)
}

extension ADDXWebRTCPlayerDelegate {
    //发送offer
    public func addxWebRTCPlayerSendOffer() {
        
    }
    
    //发送anwser
    public func addxWebRTCPlayerSendAnwser() {
        
    }
    
    public func addxWebRtcLogSendCmdAction(action: String, flag: Bool) {
        
    }
    
    public func addxWebRTCPlayerFirstKeyFrames() {
        
    }
}

public class ADDXWebRTCRRequestResult: NSObject{
    public var returnValue: String?
    public var returnData: Data?
    public var responseData: Data?
}

public class ADDXWebRTCPlayer: NSObject {
    
    var date: TimeInterval?
    //代理对象获取状态回调的
    public weak var delegate: ADDXWebRTCPlayerDelegate?
    
    //渲染view所在的父view 外部可以获取的
    public var renderView: UIView?
    
    private var renderthumbImageView: UIImageView?
    
    private var _renderVideSize: CGSize?
    
    var renderCapture: ADDXWebRTCRenderCapture?
    
    //获取当前渲染的视频尺寸
    public var renderVideSize: CGSize {
        get {
            return _renderVideSize ?? CGSize.zero
        }
    }
    
    //基于谷歌的WebRTC实现的实时流媒体通讯，主要提供来自于摄像头的视频流播放和手机与摄像头的音频通讯
    private var webRTCClient: WebRTCClient
    //基于Starscream 实现的websocket 主要用于发送通讯信息如sdp数据包
    var signalClient: SignalingClient
    
    //用于渲染远端来的视频
    private var remoteVideoRender: RTCVideoRenderer?
    //保存当先渲染远端的音视频源
    private var currentRemoteVideoTrack: RTCVideoTrack?
    private var currentRemoteAudioTrack: RTCAudioTrack?
    //可销毁的webrtc管理实例
    private static var _sharedManagerInstance: ADDXWebRTCPlayer?
    
    private var dataChannelRequestModelMap: Dictionary<String,DataChannelRequestModel> = [:]
    
    private var tmpAudioPath: String?
    private var tmpVideoPath: String?
    private var isSendedOffer: Bool = false
    
    private var _webRTCTicketModel: ADDXWebRTCTicketModel?
    var webRTCTicketModel: ADDXWebRTCTicketModel? {
        set {
            _webRTCTicketModel = newValue
        }
        get {
            return _webRTCTicketModel
        }
    }
    //该状态是根据渲染图层是否更新了渲染帧标记是否在播放
    public var isPlaying: Bool = false
    //视频下载速率，单位字节/每秒
    public var byteRate: Double {
        get {
            self.isPlaying = self.renderCapture?.isRendering() ?? false
            self.webRTCClient.updateByteCount(){}
            return self.webRTCClient.byteRate
        }
    }
    
    public var p2pInfo: (isRealy: Bool, p2pInfo: [[String : String]]) {
        let isRelay = self.webRTCClient.isRelay
        let isP2p = self.webRTCClient.p2pInfo
        return (isRelay ,isP2p)
    }
    
    private var playerState: ADDXWebRTCPlayerState = .ready {
        didSet {
            Log.vLog(level: .warning, "playerState didSet: \(playerState)")
        }
    }
    
    private var playerIceState:ADDXWebRTCPlayerIceConnectState = .new
    private var playerPeerState:ADDXWebRTCPlayerPeerConnectState = .new
    private func checkWebRTCTicketValid(ticket:ADDXWebRTCTicketModel) -> Bool{
        //
        return ticket.modelIsVaild()
    }
    
    //当前peerin的设备 包含摄像头和其他用户 ，在收到peerin消息内解析的得设备 设备信息查看 ADDXPlayerClientRoleMode 模型
    public var currentPeerInClientArray:Array<ADDXPlayerClientRoleMode> = Array()
    
    //重连配置
    //每次等待20s 包含第一次连接整个超时等待40s，可以根据需求修改
    private var reconnectTimer: Timer?
    private let reconnectTime_max_count: Int = 40 //2次最多 每次20s 断开重新连接 一共40s超时等待
    private let reconnectTime_wait_count: Int = 20 //每次等待20s
    private var reconnectTime_current_count: Int = 0
    
    //实时视频录像的编码格式:h264/hevc
    private var codecName: String = "h264";
    
    public class func create(webRTCTicket: ADDXWebRTCTicketModel) -> ADDXWebRTCPlayer? {
        if !webRTCTicket.modelIsVaild() {
            return nil
        }
        
        let webSocketProvider: WebSocketProvider
        webSocketProvider = StarscreamWebSocket(url: webRTCTicket.signalingServerUrl!)
        let signalClient = SignalingClient(webSocket: webSocketProvider)
        let webRTCClient = WebRTCClient(iceServers: webRTCTicket.iceServers)
        // 创建
        let newInstance = ADDXWebRTCPlayer(signalClient: signalClient, webRTCClient: webRTCClient)
        newInstance.webRTCTicketModel = webRTCTicket
        newInstance.speakerOff()
        newInstance.muteAudio()
        return newInstance
    }
    
    public func updateP2pInfo(comple: @escaping ()->Void) {
        self.webRTCClient.updateByteCount {
            comple()
        }
    }
    
    //公开方法，建立WebRTC 的 P2P连接
    public func startConnect() {
        Log.vLog(level: .notice, "startConnect func playerState: \(self.playerState)")
        switch self.playerState {
        case .ready:
            self.connectWebRTCClient()
            
            //新建立连接需要重连判断 - 启动重连轮询逻辑（不一定就是走重连逻辑） - by wjin
            self.startReconnectDetect()
            
            break
        case .connecting:
            Log.vLog(level: .notice, "startConnect func playerState connecting")
            break
        case .connected:
            Log.vLog(level: .notice, "startConnect func playerState connected")
            break
        case .disConnected, .failed, .timeOut:
            Log.vLog(level: .error, "startConnect func playerState \(self.playerState)")
            self.connectP2P()
            
            //新建立连接需要重连判断
            self.startReconnectDetect()
            
            break
        case .cancelled: // 处理直播暂停情况，主动断开
            
            break
        }
    }
    
    private func connectP2P() {
        Log.vLog(level: .warning, "connectP2P func 重连 !modelIsVaild timeOut")
        self.disconnectWebRTCClient()
        self.createNewWebRTCClient()
        self.connectWebRTCClient()
    }
    
    //公开方法，断开WebRTC 的 P2P连接
    public func stopConnect() {
        Log.vLog(level: .warning, "stopConnect func playerState: \(self.playerState) to disConnected")
        self.signalClient.stopSendPingAction()
        self.stopReconnectDetect()
        self.disconnectWebRTCClient()
        self.playerState = .disConnected
    }
    
    public func reconnectSignalClient() {
        Log.vLog(level: .warning, "reconnectSignalClient func playerState: \(self.playerState)")
        self.signalClient.delegate = nil
        self.signalClient.disConnect()
        self.signalClient.connect()
        self.signalClient.delegate = self
    }
    
    private func connectWebRTCClient() {
        Log.vLog(level: .warning, "connectWebRTCClient func playerState: \(self.playerState) to connecting")
        self.webRTCClient.delegate = self
        self.webRTCClient.startWebRTCConnect()
        self.signalClient.delegate = self
        self.signalClient.connect()
        self.playerState = .connecting
    }
    
    func disconnectWebRTCClient() {
        Log.vLog(level: .warning, "disconnectWebRTCClient func playerState: \(self.playerState) to disConnected")
        
        self.signalClient.disConnect()
        
        if self.signalClient.delegate == nil {
            return
        }
        
        self.cleanRenderView()
        self.currentRemoteVideoTrack = nil
        self.currentRemoteAudioTrack = nil
        self.signalClient.delegate = nil
        self.webRTCClient.delegate = nil
        self.webRTCClient.closePeerConnection()
        self.playerState = .disConnected
    }
    
    private func cleanRenderView() {
        Log.vLog(level: .warning, "didAddStream clean RenderView")

        if self.currentRemoteVideoTrack == nil {
            return
        }
        
        if self.remoteVideoRender != nil {
            DispatchQueue.main.async { [weak self] in
                guard let view = self?.remoteVideoRender as? UIView else{
                    return
                }
                if view.superview != nil {
                    view.removeFromSuperview()
                }
            }
            self.webRTCClient.removeRenderRemoteVideo(for: self.remoteVideoRender!)
           
        }
        self.remoteVideoRender = nil
    }
    
    private func createNewWebRTCClient() {
        Log.vLog(level: .notice, "createNewWebRTCClient func playerState: \(self.playerState) to ready")
        let webSocketProvider: WebSocketProvider
        webSocketProvider = StarscreamWebSocket(url: _webRTCTicketModel!.signalingServerUrl!)
        let signalClient = SignalingClient(webSocket: webSocketProvider)
        let webRTCClient = WebRTCClient(iceServers: _webRTCTicketModel!.iceServers)
        self.webRTCClient = webRTCClient
        self.signalClient = signalClient
        self.playerState = .ready
        self.isSendedOffer = false
    }
    
    public func setUpdatePauseImageCompletionCallback(_ updatePauseImageCompletionCallback:((_ image: UIImage) -> Void)? = nil){
        self.updatePauseImageCompletionCallback = updatePauseImageCompletionCallback
    }
    
    //公开方法，通过dataChannel 发送播放请求
    public func playLive(type: ADDXWebRTCPlayerVideoSharpType,_ completionCallback:((_ result:ADDXWebRTCRRequestResult) -> Void)? = nil){
        if self.webRTCTicketModel == nil{
            let requestRuslut = ADDXWebRTCRRequestResult()
            requestRuslut.returnValue = "1"
            completionCallback?(requestRuslut)
            return
        }
        let model = DataChannelAppRequest.startPlayLiveRequest(ticketModel: self.webRTCTicketModel!,liveResoolutionType: type)
        model.finishBlock = completionCallback
        let isScuess = self.dataChannelSendModelData(model: model)
        if !isScuess {
            Log.vLog(level: .error, "send cmd error playLive: \(model)")
        }
        self.createNewRenderView()
    }
    
    //公开方法，通过dataChannel 发送暂停请求
    public func pauseLive(_ completionCallback:((_ result:ADDXWebRTCRRequestResult) -> Void)? = nil){
        //暂停前截取一帧图，回调是抓取到一帧图就回调，时间很短，不是生成完图片才回调
        self.generateLastFrameImage()
        if self.webRTCTicketModel == nil{
            let requestRuslut = ADDXWebRTCRRequestResult()
            requestRuslut.returnValue = "1"
            completionCallback?(requestRuslut)
            return
        }
        let model = DataChannelAppRequest.stopPlayLiveRequest(ticketModel: self.webRTCTicketModel!)
        model.finishBlock = completionCallback
        let _ = self.dataChannelSendModelData(model: model)
        self.stopReconnectDetect()
    }
    
    public func playSdVideo(startTime: Int64,_ completionCallback:((_ result:ADDXWebRTCRRequestResult) -> Void)? = nil){
        Log.vLog(level: .notice, "playSdVideo \(startTime)")
        if self.webRTCTicketModel == nil{
            let requestRuslut = ADDXWebRTCRRequestResult()
            requestRuslut.returnValue = "1"
            completionCallback?(requestRuslut)
            return
        }
        Log.vLog(level: .notice, "playSdVideo dd \(startTime)")
        let model = DataChannelAppRequest.startPlaySdVideoRequest(ticketModel: self.webRTCTicketModel!,startTime: startTime)
        model.finishBlock = completionCallback
        let _ = self.dataChannelSendModelData(model: model)
        self.createNewRenderView()
    }
    
    //公开方法，通过dataChannel 发送暂停请求
    public func pauseSdVideo(_ completionCallback:((_ result:ADDXWebRTCRRequestResult) -> Void)? = nil){
        guard let webrtcModle = self.webRTCTicketModel else {
            let requestRuslut = ADDXWebRTCRRequestResult()
            requestRuslut.returnValue = "1"
            completionCallback?(requestRuslut)
            return
        }
        let model = DataChannelAppRequest.stopPlaySdVideoRequest(ticketModel: webrtcModle)
        model.finishBlock = completionCallback
        let _ = self.dataChannelSendModelData(model: model)
        self.stopReconnectDetect()
    }
    
    //公开方法，通过dataChannel 发送获取sd列表
    public func getSdVideoList(startTime: Int64,stopTime: Int64,_ completionCallback:((_ result:ADDXWebRTCRRequestResult) -> Void)? = nil){
        if self.webRTCTicketModel == nil{
            let requestRuslut = ADDXWebRTCRRequestResult()
            requestRuslut.returnValue = "1"
            completionCallback?(requestRuslut)
            return
        }
        let model = DataChannelAppRequest.getSdVideoListRequest(ticketModel: self.webRTCTicketModel!,startTime: startTime, stopTime: stopTime)
        model.finishBlock = completionCallback
        let _ = self.dataChannelSendModelData(model: model)
    }
    
    //公开方法，通过dataChannel 发送警告请求
    public func warning(_ completionCallback:((_ result:ADDXWebRTCRRequestResult) -> Void)? = nil){
        if self.webRTCTicketModel == nil{
            let requestRuslut = ADDXWebRTCRRequestResult()
            requestRuslut.returnValue = "1"
            completionCallback?(requestRuslut)
            return
        }
        let model = DataChannelAppRequest.triggerAlarmRequest(ticketModel: self.webRTCTicketModel!)
        model.finishBlock = completionCallback
        let _ = self.dataChannelSendModelData(model: model)
    }
    
    //公开方法，通过dataChannel 发送白灯光请求
    public func whiteLight(enable: Bool,_ completionCallback:((_ result:ADDXWebRTCRRequestResult) -> Void)? = nil){
        if self.webRTCTicketModel == nil{
            let requestRuslut = ADDXWebRTCRRequestResult()
            requestRuslut.returnValue = "1"
            completionCallback?(requestRuslut)
            return
        }
        let model = DataChannelAppRequest.setWhiteLightRequest(ticketModel: self.webRTCTicketModel!,enable:enable)
        model.finishBlock = completionCallback
        let _ = self.dataChannelSendModelData(model: model)
    }
    //公开方法，通过dataChannel 修改分辨率
    public func videoDetailChange(type: ADDXWebRTCPlayerVideoSharpType,_ completionCallback:((_ result:ADDXWebRTCRRequestResult) -> Void)? = nil){
        if self.webRTCTicketModel == nil{
            let requestRuslut = ADDXWebRTCRRequestResult()
            requestRuslut.returnValue = "1"
            completionCallback?(requestRuslut)
            return
        }
        let model = DataChannelAppRequest.setLiveResolutionRequest(ticketModel: self.webRTCTicketModel!,liveResoolutionType: type)
        model.finishBlock = completionCallback
        let _ = self.dataChannelSendModelData(model: model)
    }
    //公开方法，通过dataChannel 修改分辨率
    public func getStatus(timeStamp: TimeInterval,_ completionCallback:((_ result:ADDXWebRTCRRequestResult) -> Void)? = nil){
        if self.webRTCTicketModel == nil{
            let requestRuslut = ADDXWebRTCRRequestResult()
            requestRuslut.returnValue = "1"
            completionCallback?(requestRuslut)
            return
        }
        let model = DataChannelAppRequest.getStatusRequest(ticketModel: self.webRTCTicketModel!,timeStamp: timeStamp)
        model.finishBlock = completionCallback
        let _ = self.dataChannelSendModelData(model: model)
    }
    
    //公开方法用于dataChannel发送数据
    public func  dataChannelSendData(data: Data, isBinary: Bool)-> Bool{
        return self.webRTCClient.sendData(data, isBinary: isBinary)
    }
    
    public func dataChannelSendModelData(model:DataChannelRequestModel) -> Bool{
        guard let  modelID = model.ID else {
            return false
        }
        guard let  requestData = model.requestData else {
            return false
        }
        self.dataChannelRequestModelMap.updateValue(model, forKey: modelID)
        let sucess = self.dataChannelSendData(data: requestData, isBinary: false)
        self.delegate?.addxWebRtcLogSendCmdAction(action: model.action ?? "", flag: sucess)
        Log.vLog(level: .warning, "data channel send request requestID: \(model.requestID ?? "") model.action: \(model.action!) result: \(sucess)")
        return sucess
    }
    public func captureImage(_ completionCallback:((_ imag:UIImage) -> Void)? = nil){
        if self.currentRemoteVideoTrack == nil {
            return
        }
        self.renderCapture?.startCaptureImage(completionCallback)
    }
    
    // 开始录制视频
    public func startCaptureVideo() -> Bool {
        if self.playerState != .connected {
            return false
        }
        
        self.tmpAudioPath = nil
        if self.currentRemoteVideoTrack == nil {
            return false
        }
        
        //h264 是直接将获取的流写文件再封装
        let videoPath = NSHomeDirectory() + "/Documents/webrtcTmp.mp4"
        Log.vLog(level: .notice, videoPath)
        do {
            try FileManager.default.removeItem(atPath: videoPath)
        } catch  {
            Log.vLog(level: .error, "删除目录失败 \(videoPath)")
        }
        
        guard let renderCapture = self.renderCapture else {
            Log.vLog(level: .error, "启动录制失败 renderCapture nil")
            
            return false
        }
        
        let res = renderCapture.startCaptureH264Video(path: URL.init(fileURLWithPath: NSHomeDirectory() + "/Documents/webrtcTmp." + codecName))
        if res {
            self.tmpVideoPath = videoPath
            // let file = NSHomeDirectory() + "/Documents/webrtcTmp.wav" //wav 不需要编码，性能消耗低但是占空间
            let file = NSHomeDirectory() + "/Documents/webrtcTmp.m4a"  // m4a 需要编码 性能消耗高些，但是不占用空间
            let audioRes = self.webRTCClient.startRecordAudio(filePath: file)
            if audioRes {
                self.tmpAudioPath = file
            }
        }
        return res
    }
    
    // 结束录制视频
    public func stopCaptureVideo(_ completionCallback:((_ sucess: Bool, _ fileUrl:URL?) -> Void)? = nil) {
        if self.tmpVideoPath != nil{
            guard let renderCapture = self.renderCapture else {
                Log.vLog(level: .error, "关闭录制失败 renderCapture nil")
                completionCallback?(false, nil)
                return
            }
            
            renderCapture.stopCaptureH264Video({[weak self] (firstVideoFrameTime, pathURL) in
                let videoPath = pathURL?.path ?? ""
                //停止音频
                self?.webRTCClient.stopRecordAudio { (firstAudioFrameTime, audioPath) in
                    guard let tmpAudioPath = self?.tmpAudioPath else{
                        completionCallback?(false, nil)
                        return
                    }
                    guard let tmpVideoPath = self?.tmpVideoPath else{
                        completionCallback?(false, nil)
                        return
                    }
                    guard videoPath.count > 0 else{
                        completionCallback?(false, nil)
                        return
                    }
                    
                    //h26x 转MP4
                    ADFFmpegMuxer.muxerMP4File(tmpVideoPath, withH264File: videoPath, codecName: self!.codecName)
                    //同步处理待完善
                    let audioUrl = URL.init(fileURLWithPath: tmpAudioPath)
                    let videoUrl = URL.init(fileURLWithPath: tmpVideoPath)
                    Log.vLog(level: .notice, "firstvideo: \(firstVideoFrameTime) firstAudio: \(firstAudioFrameTime)")
                    let videoFirstFrame = CMTime.init(seconds: Double(firstVideoFrameTime)/pow(10, 6), preferredTimescale: 1000)
                    let audioFirstFrame = CMTime.init(seconds: Double(firstAudioFrameTime)/pow(10, 6), preferredTimescale: 8000)
                    
                    ADDXWebRTCMediaProcess.mergeAudio(audioURL: audioUrl, audioFirstFrameTime: audioFirstFrame, moviePathUrl: videoUrl, movieFirstFrameTime: videoFirstFrame) { (sucess) in
                        Log.vLog(level: .notice, "音视频裁剪合并完成回调")
                        completionCallback?(sucess,videoUrl)
                    }
                   
                }
            })
        } else {
            completionCallback?(false, nil)
        }
    }
    
    public func startAecDump() {
        Log.vLog(level: .notice, "startAecDump func")
        if self.playerState != .connected {
            Log.vLog(level: .warning, "startAecDump func playerState != connected return")
            return
        }
        let file = NSHomeDirectory() + "/Documents/webrtc.txt"
        self.webRTCClient.startAecdump(filePath: file, maxSize: -1)
    }
    
    public func stopAecDump() {
        Log.vLog(level: .notice, "stopAecDump func")
        if self.playerState != .connected {
            Log.vLog(level: .warning, "stopAecDump func playerState != connected return")
            return
        }
        self.webRTCClient.stopAecdump()
    }
    
    public func muteAudio() {
        Log.vLog(level: .notice, "muteAudio")
        self.webRTCClient.muteRemoteAudio()
    }
    
    public func unmuteAudio() {
        Log.vLog(level: .notice, "unmuteAudio")
        self.webRTCClient.unmuteRemoteAudio()
    }
    
    // Fallback to the default playing device: headphones/bluetooth/ear speaker
    public func speakerOff() {
        Log.vLog(level: .notice, "speakerOff")
        self.webRTCClient.speakerOff()
    }
    
    // Force speaker
    public func speakerOn() {
        Log.vLog(level: .notice, "speakerOn")
        self.webRTCClient.speakerOn()
    }
    
    public func enableRemoteVideo(enable: Bool) -> Bool {
        Log.vLog(level: .notice, "enableRemoteVideo func enable: \(enable) playerState: \(self.playerState)")
        if self.playerState != .connected {
            Log.vLog(level: .warning, "enableRemoteVideo func enable: \(enable) playerState != connected return false")
            return false
        }
        
        if self.currentRemoteVideoTrack != nil && self.currentRemoteVideoTrack!.isEnabled != enable {
            self.currentRemoteVideoTrack!.isEnabled = enable
            Log.vLog(level: .warning, "enableRemoteVideo func enable: \(enable) currentRemoteVideoTrack.isEnabled != \(enable) return true")
            return true
        }
        return false
    }
    
    public func reCreateRenderView() {
        Log.vLog(level: .notice, "reCreateRenderView func didAddStream")
        //先移除 暂不创建新的，等开启直播再判断创建新的，防止残留帧影响
        DispatchQueue.main.async {
            if self.currentRemoteVideoTrack == nil {
                Log.vLog(level: .warning, "reCreateRenderView func currentRemoteVideoTrack == nil return")
                return
            }
            
            if self.remoteVideoRender != nil {
                self.webRTCClient.removeRenderRemoteVideo(for: self.remoteVideoRender!)
            }

            guard let view = self.remoteVideoRender as? UIView else {
                self.remoteVideoRender = nil
                Log.vLog(level: .warning, "reCreateRenderView func remoteVideoRender == nil return")
                return
            }
            
            if view.superview != nil {
                view.removeFromSuperview()
            }
            self.remoteVideoRender = nil
        }
    }
    
    public func createNewRenderView() {
        Log.vLog(level: .notice, "createNewRenderView func didAddStream 💚❤️ step14")
        //延迟200ms创建
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            if self.currentRemoteVideoTrack == nil {
                Log.vLog(level: .warning, "createNewRenderView func currentRemoteVideoTrack == nil return")
                return
            }
            
            if self.remoteVideoRender == nil {
                let remoteRenderer = self.createWebRTCRender()
                self.remoteVideoRender = remoteRenderer
                self.webRTCClient.renderRemoteVideo(to: remoteRenderer)
                let view = remoteRenderer as? UIView
                if view != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 ) { [weak self] in
                        self?.renderView!.addSubview(view!)
                    }
                }
            }
        }
    }
    
    private func createWebRTCRender() -> RTCVideoRenderer {
        Log.vLog(level: .notice, "createWebRTCRender func")
        #if arch(arm64)
        // Using metal (arm64 only)
        let remoteRenderer = RTCMTLVideoView(frame: self.renderView!.bounds)
        remoteRenderer.videoContentMode = .scaleAspectFit
        remoteRenderer.delegate = self
        remoteRenderer.isUserInteractionEnabled = false
        #else
        // Using OpenGLES for the rest
        let remoteRenderer = RTCEAGLVideoView(frame: self.renderView!.bounds)
        remoteRenderer.delegate = self
        remoteRenderer.isUserInteractionEnabled = false
        #endif
        return remoteRenderer
    }
    
    private init(signalClient: SignalingClient, webRTCClient: WebRTCClient) {
       
        Log.vLog(level: .notice, "ADDXWebRTCPlayer init didAddStream")
        Log.vLog(level: .notice, "webRTCClient init")
        Log.vLog(level: .notice, "signalClient init")
        Log.vLog(level: .notice, "renderCapture init")
        Log.vLog(level: .notice, "renderView init")
        Log.vLog(level: .notice, "renderthumbImageView init")
        
        self.webRTCClient = webRTCClient
        self.signalClient = signalClient
        
        // 死锁操作
        //DispatchQueue.main.sync { [self] in }
        // 此处在子线程里刷新UI - 需调整
        //DispatchQueue.main.async { [self] in }
//        DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
//        }
        // 放在异步里无法二次直播
        //DispatchQueue.main.async { [self] in }
        
//        self.renderView = UIView.init()
//        self.renderthumbImageView = UIImageView.init()
//        self.renderthumbImageView?.backgroundColor = UIColor.black
        super.init()
        
        DispatchQueue.main.async { [self] in
            self.renderView = UIView.init()
            self.renderthumbImageView = UIImageView.init()
            self.renderthumbImageView?.backgroundColor = UIColor.black
            
            self.renderCapture = ADDXWebRTCRenderCapture(frame: CGRect.init(x: 0, y: 0, width: 10, height: 10))
            self.renderView!.addSubview(self.renderthumbImageView ?? UIImageView.init())
            self.renderView!.addObserver(self, forKeyPath: "frame", options: [.new,.old], context: nil)
            
            self.renderCapture?.renderFirstFrameBlock = { [weak self ] in
                debugPrint("-----------> renderFirstFrameBlock to addxWebRTCPlayerFirstKeyFrames")
                self?.delegate?.addxWebRTCPlayerFirstKeyFrames()
            }
            
        }
        
//        self.renderCapture = ADDXWebRTCRenderCapture(frame: CGRect.init(x: 0, y: 0, width: 10, height: 10))
//        self.renderView!.addSubview(self.renderthumbImageView ?? UIImageView.init())
//        self.renderView!.addObserver(self, forKeyPath: "frame", options: [.new,.old], context: nil)
//
//        self.renderCapture?.renderFirstFrameBlock = { [weak self ] in
//            debugPrint("-----------> renderFirstFrameBlock to addxWebRTCPlayerFirstKeyFrames")
//            self?.delegate?.addxWebRTCPlayerFirstKeyFrames()
//        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(headsetChangenNotify), name: AVAudioSession.routeChangeNotification, object: AVAudioSession.sharedInstance())
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: AVAudioSession.sharedInstance())
        self.muteAudio()
        self.speakerOff()
        self.webRTCClient.mutelocalAudio()
        self.renderView!.removeObserver(self, forKeyPath: "frame")
        self.stopReconnectDetect()
        self.disconnectWebRTCClient()
        Log.vLog(level: .warning, "ADDXWebRTCPlayer deinit")
        
    }
    
    @objc func headsetChangenNotify(notify:Notification) {
        let info = notify.userInfo
        
        guard let reason = info?[AVAudioSessionRouteChangeReasonKey] as? Int else{
            return
        }
        
        Log.vLog(level: .notice, "headsetChangenNotify reason: \(reason)")
        if (reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue) {
            // 拔耳机
//            self.enableSpeaker(enable: true)
            Log.vLog(level: .notice, "headsetChangenNotify 耳机监听到拔掉耳机")
        } else if (reason == AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue) {
            //插耳机
//            self.enableSpeaker(enable: false)
            Log.vLog(level: .notice, "headsetChangenNotify 耳机监听到插上耳机")
        } else {
            //其他情况
//、            self.enableSpeaker(enable: true)
//            Log.vLog(level: .notice, "headsetChangenNotify 耳机监听其他情况 " + reason)
        }
    }
    
    private func isHeadSetPlugging() -> Bool {
        let route = AVAudioSession.sharedInstance().currentRoute
        var isHeadSet = false
        route.outputs.enumerated().forEach { (index,desc) in
            if desc.portType == AVAudioSession.Port.headphones {
                isHeadSet = true
            }
        }
        return isHeadSet
    }
    
    private func enableSpeaker(enable: Bool) {
        if enable {
            Log.vLog(level: .notice, "开启外放")
            self.webRTCClient.audioOutputAudioPortSpeaker()
        } else {
            Log.vLog(level: .notice, "关闭外放")
            self.webRTCClient.audioOutputAudioPortNone()
        }
    }
    
    private func paramDataChannelResponseData(data: Data, isBinary: Bool) {
        if !isBinary {
            Log.vLog(level: .warning, "data channel receive data  \(String(data: data, encoding: .utf8) ?? " ")  date: \(Date().timeIntervalSince1970) ms")
            let (requestID,connectionID) = DataChannelCameraResponse.responseRequestID(response: data)
            if requestID != nil && connectionID != nil {
                let model = self.dataChannelRequestModelMap[requestID! + connectionID!]
                if model != nil {
                    DataChannelCameraResponse.paramResponse(response: data, model: model!)
                    if model != nil  && model!.response != nil {
                        let returnValue = model!.response!.returnValue
                        let requestRuslut = ADDXWebRTCRRequestResult()
                        requestRuslut.returnValue = "0"
                        if returnValue != nil {
                            requestRuslut.returnValue = returnValue
                        }
                        requestRuslut.responseData = model?.response?.responseData
                        requestRuslut.returnData = model?.response?.resultData
                        self.dataChannelRequestModelMap.removeValue(forKey: requestID!)
                        DispatchQueue.main.async {
                            model!.finishBlock?(requestRuslut)
                        }
                    }
                } else {
                    Log.vLog(level: .error, "发送camera当前发送响应未找到请求 \(requestID ?? "") \(connectionID ?? "")" )
                }
            } else {
                //收到camera发的主动消息
                let model = DataChannelRequestModel()
                let action = DataChannelCameraRequest.responseAction(response: data)
                if action != nil {
                    model.action = action
                    model.responseData = data
                    DataChannelAppResponse.paramResponseModel(model: model)
                    //通知上层
                    self.delegate?.addxWebRTCPlayer(self, didReceiveDataChannelData: data, isBinary: isBinary,action: model.action)
                    //发送回应
                    let _ = self.dataChannelSendModelData(model: model)
                    Log.vLog(level: .notice, "发送对camera发送的 \(action!) 命令 的回应")
                }
            }
        }
    }
    
    private func cancelRequestAfterConnectClosed() {
        guard self.reconnectTimer == nil else {
            return
        }
        
        self.dataChannelRequestModelMap.forEach { (key ,model) in
               DispatchQueue.main.async {
                let requestRuslut = ADDXWebRTCRRequestResult()
                requestRuslut.returnValue = "-10000"
                model.finishBlock?(requestRuslut)
            }
        }
        self.dataChannelRequestModelMap.removeAll()
    }
    
    private var updatePauseImageCompletionCallback: ((_ image: UIImage) -> Void)?
    private func generateLastFrameImage(_ grabImageDataFinishCallback:(() -> Void)? = nil) {
        //        self.renderCapture?.startCaptureImage({
        //            grabImageDataFinishCallback?()
        //        }, { [weak self](image) in
        //            DispatchQueue.main.async {
        //                Log.vLog(level: .notice, "updatesnapshot ")
        //                self?.updatePauseImageCompletionCallback?(image)
        //            }
        //        })
        DispatchQueue.main.async {
            UIGraphicsBeginImageContextWithOptions(self.renderView!.frame.size, false, 0)
            self.renderView!.drawHierarchy(in: self.renderView!.frame, afterScreenUpdates: true)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            Log.vLog(level: .notice, "updatesnapshot ")
            if image != nil{
                self.renderthumbImageView!.image = image
                self.updatePauseImageCompletionCallback?(image!)
            }
        }
        
    }
    
    private func copyClientInfo(client:ADDXPlayerClientRoleMode ,model: ClientRoleMode) {
        client.name = model.name
        client.id = model.id
        client.role = model.role
    }
    
    private func startSendPing() {
        let time = TimeInterval(self.webRTCTicketModel?.signalPingInterval ?? 5)
        self.signalClient.startSendPingAction(time:time)
    }
    
    private func stopSendPing() {
        self.signalClient.stopSendPingAction()
    }
}

extension ADDXWebRTCPlayer {
    // 重连逻辑
    private func startReconnectDetect() {
        DispatchQueue.main.async {
            Log.vLog(level: .error, "startReconnectDetect func(开始重连检测) current_count: \(self.reconnectTime_current_count) 💚")
            if self.reconnectTimer == nil {
                self.reconnectTimer?.invalidate()
                self.reconnectTimer = nil
                self.reconnectTimer = Timer(timeInterval: TimeInterval(1), target: self, selector: #selector(self.reconnectionAction), userInfo: nil, repeats: true)
                RunLoop.current.add(self.reconnectTimer!, forMode: .common)
                self.reconnectTimer?.fire()
                self.reconnectTimer?.fireDate = Date.distantPast
            }
        }
    }
    
    private func stopReconnectDetect() {
        Log.vLog(level: .error, "stopReconnectDetect func(停止重连检测) current_count: \(self.reconnectTime_current_count) ❤️")
        if self.reconnectTimer != nil {
            self.reconnectTime_current_count = 0
            self.reconnectTimer?.fireDate = Date.distantFuture
            self.reconnectTimer?.invalidate()
            self.reconnectTimer = nil
        }
    }
    
    private func resumeReconnectDetectTimer() {
        Log.vLog(level: .warning, "resumeReconnectDetectTimer func")
        self.reconnectTimer?.fireDate = Date.distantPast
    }
    
    private func pauseReconnectDetectTimer() {
        Log.vLog(level: .warning, "pauseReconnectDetectTimer func")
        self.reconnectTimer?.fireDate = Date.distantFuture
    }
    
    @objc private func reconnectionAction() {
        DispatchQueue.main.async {
            Log.vLog(level: .warning, "reconnectionAction func(重连检查) current count: \(self.reconnectTime_current_count)")
            
            self.reconnectTime_current_count += 1
            
            if self.reconnectTime_current_count > self.reconnectTime_max_count - 1 {
                Log.vLog(level: .error, "reconnectionAction func(重连熔断，走超时处理) max count: \(self.reconnectTime_max_count)")
                self.disconnectWebRTCClient()
                self.stopReconnectDetect()
                self.playerState = .timeOut
                self.delegate?.addxWebRTCPlayer(self, didChangePlayer: self.playerState)
                return
            }
            
            debugPrint("---------> 重连检查 current_count % wait_count: \(self.reconnectTime_current_count % self.reconnectTime_wait_count) wait_count: \(self.reconnectTime_wait_count)")
            
            if self.reconnectTime_current_count % self.reconnectTime_wait_count == 0 {
                Log.vLog(level: .error, "reconnectionAction func 重连，第（\(self.reconnectTime_current_count / self.reconnectTime_wait_count)）次重新连接")
                
                self.pauseReconnectDetectTimer()
                self.playerState = .timeOut
                self.disconnectWebRTCClient()
                
                self.delegate?.addxWebRTCPlayer(self, updateWebRTCTicket: {[weak self] (ticket) in
                    guard let self = self else {
                        return
                    }
                    
                    guard let ticket = ticket else {
                        self.playerState = .timeOut
                        self.delegate?.addxWebRTCPlayer(self, didChangePlayer: self.playerState)
                        Log.vLog(level: .error, "reconnectionAction func 重连 timeOut")
                        return
                    }
                    
                    if ticket.modelIsVaild() {
                        self.webRTCTicketModel?.copyModelnfo(ticket: ticket)
                        self.resumeReconnectDetectTimer()
                        self.connectP2P()
                    } else {
                        self.playerState = .timeOut
                        self.delegate?.addxWebRTCPlayer(self, didChangePlayer: self.playerState)
                        Log.vLog(level: .error, "重连 !modelIsVaild timeOut")
                    }
                })
                
            }
        }
        
    }
}


extension ADDXWebRTCPlayer: WebRTCClientDelegate {
    
    func webRTCClient(_ client: WebRTCClient, didAddStream stream: RTCMediaStream) {
        debugPrint("-----------> didAddStream 拿到视频流")
        Log.vLog(level: .notice, "didAddStream stream.streamId:\(stream.streamId) ")
        let videoTrack = stream.videoTracks.first
        let audioTrack = stream.audioTracks.first
        if audioTrack != nil {
            self.currentRemoteAudioTrack = audioTrack
//            if self.isHeadSetPlugging() {
//                self.enableSpeaker(enable: false)
//            }else{
//                self.enableSpeaker(enable: true)
//            }
        }
        
        DispatchQueue.main.async {
            if videoTrack == nil{
                return
            }
            
            let remoteRenderer = self.createWebRTCRender()
            self.remoteVideoRender = remoteRenderer
            self.renderCapture?.resetRender()
            
            self.webRTCClient.renderRemoteVideo(to: remoteRenderer)
            self.webRTCClient.renderRemoteVideo(to: self.renderCapture!)
            let view = remoteRenderer as? UIView
            
            if view != nil {
                self.renderView!.addSubview(view!)
            }
            
            self.currentRemoteVideoTrack = videoTrack
            self.delegate?.addxWebRTCPlayerDidReadyPlay(self)
            self.renderView!.isUserInteractionEnabled = false
        }
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        self.renderthumbImageView!.frame = self.renderView!.bounds
        let view = self.remoteVideoRender as? UIView
        view?.frame = self.renderView!.bounds
    }
    
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        Log.vLog(level: .warning, "didDiscoverLocalCandidate func ice candidate")
        
        self.signalClient.send(string:String(data: IceCandidate.init(from: candidate, recipientClientId: self.webRTCTicketModel!.recipientClientId!).iceJsonData(), encoding: .utf8)!)
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangePeerConnectionState state: RTCPeerConnectionState) {
        var playerState: ADDXWebRTCPlayerState = self.playerState
        
        Log.vLog(level: .warning, "didChangePeerConnectionState func playerState: \(playerState)")
        switch state {
        case .new:
            playerState = .ready
            self.playerPeerState = .new
            Log.vLog(level: .notice, "didChangePeerConnectionState func state new")
            break
        case .connecting:
            playerState = .connecting
            self.playerPeerState = .connecting
            Log.vLog(level: .notice, "didChangePeerConnectionState func state connecting")
            break
        case .connected:
            Log.vLog(level: .notice, "didChangePeerConnectionState func state connected 💚❤️ step11")
            playerState = .connected
            self.playerPeerState = .connected
            self.stopReconnectDetect()
            self.muteAudio()
            self.speakerOff()
            //            Log.vLog(level: .notice, "TestTime peer connected open -pper in    \(Date().timeIntervalSince1970*1000)  ms  \(Date().timeIntervalSince1970*1000 - self.date!*1000)  ms")
            break
        case .failed:
            playerState = .failed
            self.playerPeerState = .failed
            Log.vLog(level: .error, "didChangePeerConnectionState func state failed")
            break
        case .disconnected:
            playerState = .disConnected
            self.playerPeerState = .disconnected
            Log.vLog(level: .warning, "didChangePeerConnectionState func state disconnected")
            break
        case .closed:
            playerState = .disConnected
            self.playerPeerState = .closed
            Log.vLog(level: .warning, "didChangePeerConnectionState func state closed")
            break
        default:
            playerState = .disConnected
            Log.vLog(level: .warning, "didChangePeerConnectionState func state default")
            break
        }
        
        if playerState == .disConnected {
            //取消datachannel发送消息回调
            self.stopReconnectDetect()
        }
        
        if playerState != self.playerState {
            // 往业务层回调
            self.playerState = playerState
            self.delegate?.addxWebRTCPlayer(self, didChangePlayer: self.playerState)
        }
        
        // 日志上报
        self.delegate?.addxWebRTCPlayer(self, didChangePlayer: self.playerPeerState)
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeIceConnectionState state: RTCIceConnectionState) {
        var playerState:ADDXWebRTCPlayerState = self.playerState
        Log.vLog(level: .warning, "didChangeIceConnectionState func playerState: \(playerState) state: \(state)")
        switch state {
        case .new:
            playerState = .ready
            self.playerIceState = .new
            Log.vLog(level: .notice, "didChangeIceConnectionState func state new")
            break
        case .checking:
            playerState = .connecting
            self.playerIceState = .checking
            Log.vLog(level: .notice, "didChangeIceConnectionState func state checking")
            break
        case .connected:// 从打印日志来看有可能直播过程中再次发送，因此需要处理
            if self.playerState == .connected {} else {
                playerState = .connected
            }
            self.playerIceState = .connected
            // Log.vLog(level: .notice, "TestTime ice connected -peer in          \(Date().timeIntervalSince1970*1000)  ms  \(Date().timeIntervalSince1970*1000 - self.date!*1000)  ms")
            Log.vLog(level: .notice, "didChangeIceConnectionState func state connected")
            break
        case .completed: // 先调用connected，再调用completed，失败的情况会：调用completed，不调用connected
            //playerState = .connected
            self.playerIceState = .completed
            Log.vLog(level: .notice, "didChangeIceConnectionState func state completed")
            break
        case .failed:
            playerState = .failed
            self.playerIceState = .failed
            Log.vLog(level: .error, "didChangeIceConnectionState func state failed")
            break
        case .disconnected:
            playerState = .disConnected
            self.playerIceState = .disconnected
            Log.vLog(level: .error, "didChangeIceConnectionState func state disconnected")
            break
        case .closed:
            playerState = .disConnected
            self.playerIceState = .closed
            Log.vLog(level: .warning, "didChangeIceConnectionState func state closed")
            break
        case .count:
            playerState = .disConnected
            self.playerIceState = .count
            Log.vLog(level: .warning, "didChangeIceConnectionState func state count")
            break
        default:
            playerState = .disConnected
            Log.vLog(level: .warning, "didChangeIceConnectionState func state default")
            break
        }
        
        // log 上报
        self.delegate?.addxWebRTCPlayer(self, didChangePlayer: self.playerIceState)

        if self.playerState == .connected || self.reconnectTimer == nil { //ice 连接成功后断开，或者取消重连的时候状态当做最新状态 - sd卡拖动的时候调用会导致首次 connect_fail
            if case .completed = state {} else {
                if self.playerState == .connected {} else {
                    // 往业务层回调
                    self.playerState = playerState
                    self.delegate?.addxWebRTCPlayer(self, didChangePlayer: self.playerState)
                }
            }
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeDataChannelStatea state: RTCDataChannelState) {
        Log.vLog(level: .warning, "didChangeDataChannelStatea func state: \(state)")

        var icestate: ADDXWebRTCPlayerDataChannelState
        icestate = .closed
        switch state {
        case .connecting:
            icestate = .connecting
            Log.vLog(level: .notice, "didChangeDataChannelStatea func state connecting")
            break
        case .open:
            icestate = .open
            self.webRTCTicketModel?.dataChannelOpenTime = Int64(Date().timeIntervalSince1970)
            //            Log.vLog(level: .notice, "TestTime dataChannel open - peer in      \(Date().timeIntervalSince1970*1000)  ms  \(Date().timeIntervalSince1970*1000 - self.date!*1000)  ms")
            Log.vLog(level: .notice, "didChangeDataChannelStatea func state open 💚❤️ step12")
            break
        case .closing:
            icestate = .closing
            self.cancelRequestAfterConnectClosed()
            Log.vLog(level: .warning, "didChangeDataChannelStatea func state closing")
            break
        case .closed:
            icestate = .closed
            self.cancelRequestAfterConnectClosed()
            Log.vLog(level: .warning, "didChangeDataChannelStatea func state closed")
            break
        default:
            self.cancelRequestAfterConnectClosed()
            icestate = .closed
            Log.vLog(level: .warning, "didChangeDataChannelStatea func state default")
            break
            
        }
        self.delegate?.addxWebRTCPlayer(self, didChangeDataChannelState: icestate)
        
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveDataChannelData data: Data ,isBinary: Bool) {
        self.paramDataChannelResponseData(data: data, isBinary: isBinary)
    }
    
    func webRTCClient(_ client: WebRTCClient, localSpeakVoiceData voiceData: Array<NSNumber>) {
        self.delegate?.addxWebRTCPlayer(self, localSpeakVoiceData: voiceData)
    }
}

extension ADDXWebRTCPlayer: RTCVideoViewDelegate {
    
    public func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        self._renderVideSize = size
        
        Log.vLog(level: .notice, "videoView: \(videoView)  didChangeVideoSize: \(size) 💚❤️ step14-1")
        self.delegate?.addxWebRTCPlayer(self, didChange: size)
    }
}

extension ADDXWebRTCPlayer: SignalClientDelegate {
    func signalIceCandidate(payload: String) {
        Log.vLog(level: .notice, "signalIceCandidate func ICE_CANDIDATE payload: \(payload)")
        let json = payload.base64Decoding().toDictionary()
        let iceCandidate = RTCIceCandidate(sdp: json["candidate"] as! String, sdpMLineIndex: json["sdpMLineIndex"] as! Int32, sdpMid: json["sdpMid"] as? String)
        self.webRTCClient.set(remoteCandidate: iceCandidate)
    }
    
    func signalSdpAnswer(payload: String) {
        Log.vLog(level: .notice, "signalSdpAnswer func SDP_ANSWER payload: \(payload)")

        let dict = payload.base64Decoding().toDictionary()

        Log.vLog(level: .notice, "signalSdpAnswer \(dict)")
        
        //从设备端sdp中解析出当前使用的编码格式
        parseVideoCodecFromSDP(sdpStr: dict["sdp"] as! String)

        let sessionDescription = RTCSessionDescription(type: RTCSdpType.answer, sdp: dict["sdp"] as! String)
        
        self.webRTCClient.set(remoteSdp: sessionDescription) { (error) in
            Log.vLog(level: .notice, "signalSdpAnswer func SDP_ANSWER set error: \(String(describing: error))")
        }
    }
    
    func signalSdpOffer(recipientClientId: String) {
        Log.vLog(level: .notice, "signalSdpOffer func SDP_OFFER recipientClientId:\(recipientClientId)")

        webRTCClient.answer { [weak self] (sdp) in
            let json = SessionDescription.init(from: sdp, recipientClientId: recipientClientId).answerJsonData()
            Log.vLog(level: .notice, "signalSdpOffer func SDP_OFFER Do send SDP_ANSWER")
            self?.signalClient.send(string:String(data: json, encoding: .utf8)!)
            self?.delegate?.addxWebRTCPlayerSendAnwser()
        }
    }
    
    func signalPeerIn(recipientClientId: String, role: ClientRoleMode) {
        Log.vLog(level: .notice, "signalPeerIn func PEER_IN recipientClientId: \(recipientClientId)")
        if role.role == "viewer" {
            Log.vLog(level: .notice, "signalPeerIn func PEER_IN 其他成员加入")
            return
        }
        let client = ADDXPlayerClientRoleMode()
        self.copyClientInfo(client: client, model: role)
        self.delegate?.addxWebRTCPlayer(self, didPeerIn: client)
        //如果是master peerin 则发送offer
        if client.isMaster {
            //防止websocket 断开后重连收到 peer 消息
            if self.isSendedOffer {
                return
            }
            self.isSendedOffer = true
            self.delegate?.addxWebRTCPlayerSendOffer()
            webRTCClient.offer { [weak self] (sdp) in
                let json = SessionDescription.init(from: sdp, recipientClientId: recipientClientId).offerJsonData()
                Log.vLog(level: .notice, "signalPeerIn func Do send SDP_OFFER json: \(json) 💚❤️ step6")
                self?.signalClient.send(string:String(data: json, encoding: .utf8)!)
                self?.date = Date().timeIntervalSince1970
                Log.vLog(level: .notice, "signalPeerIn func TestTime PEER_IN: \((self?.date ?? 0 ) * 1000) ms")
            }
        }
    }
    
    func signalPeerOut(recipientClientId: String, role: ClientRoleMode) {
        Log.vLog(level: .error, "signalPeerOut func PEER_OUT recipientClientId: \(recipientClientId)")
        if role.role == "viewer" {
            Log.vLog(level: .error, "signalPeerOut func PEER_OUT 其他成员退出 return")
            return
        }
        let client = ADDXPlayerClientRoleMode()
        self.copyClientInfo(client: client, model: role)

        //需要取消可用操作
        self.playerState = .disConnected
        self.stopReconnectDetect()
        self.delegate?.addxWebRTCPlayer(self, didPeerOut: client)
        
    }
    
    func signalClientConnecting(_ signalClient: SignalingClient) {
        Log.vLog(level: .notice, "websocket connecting")
        self.delegate?.addxWebRTCPlayerSignalClientConnecting()
    }
    
    func signalClientDidConnect(_ signalClient: SignalingClient) {
        Log.vLog(level: .notice, "signalClientDidConnect func websocket didConnect")
        self.delegate?.addxWebRTCPlayerSignalClientDidConnect()
        //发送ping
        self.startSendPing()
    }
    
    func signalClientDidDisconnect(_ signalClient: SignalingClient, code: UInt16) {
        Log.vLog(level: .error, "websocket disconnect code: \(code)")
        //停止发送ping
        self.stopSendPing()
        
        // 初始化
        var disconnectReason = ADDXWebSocketDisConnectReason.unknow
        
        switch code {
        case ADDXWebSocketDisConnectReason.usersLimit.rawValue:
            disconnectReason = .usersLimit
            self.signalClient.stopSendPingAction()
            self.stopReconnectDetect()
        case ADDXWebSocketDisConnectReason.timeout.rawValue:
            disconnectReason = .timeout
        default:
            disconnectReason = .unknow
        }
        self.delegate?.addxWebRTCPlayerSignalClientDidDisconnect(disconnectReason: disconnectReason, errorCode: Int(code))
    }
    
    func signalClientCancelled(_ signalClient: SignalingClient) {
        Log.vLog(level: .notice, "websocket signalClientCancelled ")
        //self.playerState = .cancelled
        //self.delegate?.addxWebRTCPlayer(self, didChangePlayer: self.playerState)
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription) {
        Log.vLog(level: .notice, "websocket didReceive Remote Sdp: \(sdp)")
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate) {
        Log.vLog(level: .notice, "websocket didReceive Candidate")
    }
    
    func contains(src: String, key: String) -> Bool{
        return src.range(of: key) != nil
    }
    
    //从SDP中解析出当前使用的视频编码格式h264/h265
    func parseVideoCodecFromSDP(sdpStr: String) {
        if contains(src: sdpStr, key: "H264") {
            codecName = "h264"
        }

        if contains(src: sdpStr, key: "H265") {
            codecName = "h265"
        }

        Log.vLog(level: .notice, "parseVideoCodecFromSDP, VideoCodecName= \(codecName)")
    }
}
