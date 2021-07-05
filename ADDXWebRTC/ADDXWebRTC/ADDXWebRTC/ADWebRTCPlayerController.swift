//
//  ADWebRTCPlayerController.swift
//  ADAutoView
//
//  Created by kzhi on 2020/7/20.
//

import Foundation
import WebRTC

struct ADDXQueueTask {
    var cmd: ADDXRTCPlayerCmdState
    var data: DataChannelRequestModel?
    var finishBlock: ((_ result:ADDXWebRTCRRequestResult) -> Void)?
}

public class ADWebRTCPlayerController: ADDXPlayerProtocol {
    
    // 非主队列
    let queue = DispatchQueue(label: "addx.webrtc.player." + UUID().uuidString, attributes: .init(rawValue:0))
    
    var taskQueue: [ADDXQueueTask] = []
    
    weak public var `protocol`: ADDXPlayerCallBackDelegate?
    
    var playerContent: ADDXWebRTCPlayer?
    
    public var renderView: UIView? {
        return self.playerContent?.renderView
    }
    
    public var videoSize: CGSize?
    
    public var byteRate: Double {
        return playerContent?.byteRate ?? 0
    }
    
    public static func instance() -> ADDXPlayerProtocol {
        return ADWebRTCPlayerController()
    }
    
    private var videoPauseTimerOut: TimeInterval = 30

    /// 对话音量
    public var audioEnable: Bool = false {
        didSet {
            if audioEnable {
                self.playerContent?.unmuteAudio()
                Log.vLog(level: .warning, "speakerOn 外放")
            } else {
                self.playerContent?.muteAudio()
                Log.vLog(level: .warning, "speakerOff 静音")
            }
        }
    }
    
    /// 播放音量
    public var speakEnable: Bool = false {
        didSet {
            if speakEnable {
                self.playerContent?.speakerOn()
                Log.vLog(level: .warning, "unmuteAudio 录音")
            }else{
                self.playerContent?.speakerOff()
                Log.vLog(level: .warning, "muteAudio 禁止录音")
            }
        }
    }
    
    public var playerState: ADWebRTCPlayerControllerState = .ready {
        didSet {
             Log.vLog(level: .warning, "addxVideo StateChange playerState: \(playerState) ")
//            if self.playerState == oldValue {
//                return
//            }
            // 直播连接成功后，通向业务层
            if playerState == .playing {
                Log.vLog(level: .notice, "addxVideo StateChange playerState playing 💚💚💚 step15")
            }
            // 业务层state状态改变
            self.protocol?.addxVideoStateChange(sender: self, state: self.playerState)

        }
    }
    
    private var canSendCmd: Bool = false
    
    public func sendCmd<Param, Result>(cmdType: ADDXRTCPlayerCmdState, param: Param?, returnType: Result.Type, comple: @escaping (Result?, ADDXCmdError?) -> Void) where Param: Decodable, Param: Encodable, Result: Decodable, Result: Encodable {

        self.queue.async { [weak self] in
            Log.vLog(level: .warning, "data sendcmd start cmdType: \(cmdType) 👇")
            let finishBlock: ((_ result:ADDXWebRTCRRequestResult) -> Void) = { data in
                Log.vLog(level: .notice, "data sendcmd finish cmdType: \(cmdType) ❤️")

                if let error = ADDXCmdError(errorCode: data.returnValue) {
                    DispatchQueue.main.async {
                        Log.vLog(level: .error, "data sendcmd error: \(error)")
                        comple(nil , error)
                    }
                    return
                }
                
                if let data = data.responseData {
                    let decoder = JSONDecoder()
                    let modle = try? decoder.decode(BaseResponseModel<Result>.self, from: data)
                    if self?.shouldUpdateVideoRanderView(state: cmdType) ?? false {
                        DispatchQueue.main.async {
                            self?.playerContent?.createNewRenderView()
                        }
                    }
                    comple(modle?.data, nil)
                } else {
                    Log.vLog(level: .error, "data sendcmd error: responseData error")
                    comple(nil, ADDXCmdError.unKnow)
                }
            }
            
            if case .sdPlay = cmdType {
                self?.playerContent?.signalClient.setVideoPauseTimerOut(time: Double.infinity)
                self?.playerContent?.renderCapture?.resetRender()
                self?.protocol?.addxConnectLog(sender: self, state: .start(type: "sd play"))
            }
            
            if self?.canSendCmd ?? false {
                let result = ADDXWebRTCRRequestResult()
                result.returnValue = "-10005"
                guard let modle = self?.getRequestModle(cmdType: cmdType, params: param) else {
                    Log.vLog(level: .error, "data sendcmd error: -10005")
                    finishBlock(result)
                    return
                }
                
                Log.vLog(level: .notice, "data sendcmd cmdType: \(cmdType)")
                modle.finishBlock = finishBlock
                let sendData = self?.playerContent?.dataChannelSendModelData(model: modle) ?? false
                if !sendData {
                    let result = ADDXWebRTCRRequestResult()
                    result.returnValue = "-10006"
                    Log.vLog(level: .error, "data sendcmd error: -10006")
                    finishBlock(result)
                }
            } else {
                guard let modle = self?.getRequestModle(cmdType: cmdType, params: param) else {
                    let result = ADDXWebRTCRRequestResult()
                    result.returnValue = "-10003"
                    DispatchQueue.main.async {
                        Log.vLog(level: .error, "data sendcmd error: -10003")
                        finishBlock(result)
                    }
                    return
                }

                guard let state = self?.playerState else {
                    let result = ADDXWebRTCRRequestResult()
                    result.returnValue = "-10001"
                    DispatchQueue.main.async {
                        Log.vLog(level: .error, "data sendcmd error: -10001")
                        finishBlock(result)
                    }
                    return
                }
                
                if state == .connecting || state == .connect || state == .play || state == .playing {
                    let cmdTaskType : ADDXQueueTask = ADDXQueueTask(cmd: cmdType, data: modle, finishBlock: finishBlock)
                    Log.vLog(level: .notice, "data cache cmd: \(cmdType)")
                    self?.taskQueue.append(cmdTaskType)
                } else {
                    let result = ADDXWebRTCRRequestResult()
                    result.returnValue = "-10002"
                    DispatchQueue.main.async {
                        Log.vLog(level: .error, "data sendcmd error: -10002")
                        finishBlock(result)
                    }
                }
            }
            Log.vLog(level: .warning, "data sendcmd end cmdType: \(cmdType) 👆")
        }
    }
    
    
    func shouldUpdateVideoRanderView(state : ADDXRTCPlayerCmdState) -> Bool {
        switch state {
        case .play:
            fallthrough
        case .sdPlay:
            return true
        case .pause:
            fallthrough
        case .sdPause:
            fallthrough
        case .getSdlist:
            fallthrough
        case .warning:
            fallthrough
        case .setWhiteLight:
            fallthrough
        case .getWhiteLight:
            fallthrough
        case .setVideoDetail:
            fallthrough
        case .getVideoDetail:
            fallthrough
        case .other:
            return false
        }
    }
    
    public func executeCmd() {
        
        Log.vLog(level: .notice, "executeCmd start canSendCmd: \(self.canSendCmd) taskQueue: \(self.taskQueue)")
        
        while self.canSendCmd && self.taskQueue.count > 0 {
            let taskModle = self.taskQueue.last
            if let task : ADDXQueueTask = taskModle  {
                self.taskQueue.removeLast()
                Log.vLog(level: .notice, "executeCmd begin cmd: \(task.cmd) 👇")
                
                guard let modleCmdData = task.data else {
                    Log.vLog(level: .error, "executeCmd cmd error: modleCmdData nil")
                    return
                }
                modleCmdData.finishBlock = task.finishBlock
                if modleCmdData.action == DataChannelRequestAction.startPlaySdVideo.rawValue {
                    self.playerContent?.signalClient.setVideoPauseTimerOut(time: Double.infinity)
                    self.playerContent?.renderCapture?.resetRender()
                }
                
                let isScuess = self.playerContent?.dataChannelSendModelData(model: modleCmdData) ?? false
                if !isScuess {
                    let result = ADDXWebRTCRRequestResult()
                    result.returnValue = "-10006"
                    Log.vLog(level: .error, "executeCmd cmd error: -10006")
                    task.finishBlock?(result)
                }
                Log.vLog(level: .notice, "executeCmd end cmd: \(task.cmd) 👆")
            }
        }
    }
    
    public func clearCmd() {
        guard self.taskQueue.count > 0 else {
            Log.vLog(level: .warning, "clearCmd func taskQueue count == 0")
            return
        }
        Log.vLog(level: .notice, "clearCmd func start 👇")
        self.taskQueue.forEach { (task) in
            task.finishBlock?(ADDXWebRTCRRequestResult())
        }
        self.taskQueue.removeAll()
        Log.vLog(level: .notice, "clearCmd func end 👆")
    }
    
    public func reloadVideoView() {
        Log.vLog(level: .notice, "reloadVideoView")

        self.playerContent?.reCreateRenderView()
    }
    
    public func start(startTime: TimeInterval?, type: ADDXWebRTCPlayerVideoSharpType) {
        self.clearCmd()

        self.protocol?.addxConnectLog(sender: self, state: .start(type: type.rawValue))

        self.queue.async { [weak self] in
            Log.vLog(level: .notice, "start 💚💚💚 step1")
            self?.videoSize = nil

            self?.loadPlayerConnect(comple: {[weak self] (flag) in
                guard flag else {
                    Log.vLog(level: .error, "start loadPlayerConnect error")
                    self?.canSendCmd = false
                    self?.playerState = .error(error: ADDXError.connect_fail)
                    return
                }

                self?.playerContent?.signalClient.setVideoPauseTimerOut(time: Double.infinity)

                let str: String? = nil

                self?.sendCmd(cmdType: .play(sharpType: type), param: str, returnType: String.self, comple: { (data, error) in

                    guard (self?.canSendCmd ?? false) == true else { //如果其他地方断开，不进下操作
                        Log.vLog(level: .warning, "start sendCmd canSendCmd:false return")
                        return
                    }

                    guard error == nil else {
                        self?.canSendCmd = false
                        Log.vLog(level: .error, "start sendCmd connect_fail return")
                        self?.playerState = .error(error: ADDXError.connect_fail)
                        return
                    }

                    self?.playerContent?.renderCapture?.resetRender()
//                    self?.playerState = .play
//                    self?.protocol?.addxConnectLog(sender: self, state: .videoConnected(recordVideo: false, p2pinfo: self?.playerContent?.p2pInfo))

                })
            })

            Log.vLog(level: .notice, "start func end❤️❤️❤️")
        }
    }
    
    public func stop() {
        Log.vLog(level: .warning, "ADWebRTCPlayerController stop func ❤️❤️❤️" )
        self.stopRecord(comple: nil)
        self.stopConnect()
        self.canSendCmd = false
        // 此处有sd卡回看的bug
        self.playerState = .ready
        self.clearCmd()
        self.protocol?.addxConnectLog(sender: self, state: .videoStop)
        self.queue.async { [weak self] in
            self?.playerContent = nil
        }
    }
    
    public func pause(tips : String?) {
        Log.vLog(level: .notice, "pause func start👇 💚❤️ step16")
        
        if self.playerState == .pause || self.playerState == .ready || self.playerState == .disConnect {
            Log.vLog(level: .error, "pause func playerState: \(self.playerState)")
            return
        }
        
        if case .error = self.playerState {
            Log.vLog(level: .error, "pause func playerState error: \(self.playerState)")
            return
        }
        
        self.clearCmd()
        
        let str: String? = nil
        playerContent?.signalClient.setVideoPauseTimerOut(time: videoPauseTimerOut)
        
        // 直播状态变更
        self.playerState = .pause
        
        // 向设备发送变更命令
        self.sendCmd(cmdType: .pause, param: str, returnType: String.self, comple: { [weak self ](data, error) in
            guard self?.isConnected() ?? false == true else { //如果其他地方断开，不进下操作
                Log.vLog(level: .error, "pause func sendCmd isConnected: \(self?.isConnected() ?? false)")
                return
            }
            
            guard error == nil else {
                Log.vLog(level: .error, "pause func sendCmd error no nil: \(error ?? .unKnow)")
                self?.playerState = .error(error: ADDXError.device_unkown)
                return
            }
            
            self?.protocol?.addxConnectLog(sender: self, state: .videoPause(reasion: tips))
            // 直播状态变更 ? 又赋值一次？ - 改为当前状态不是 pause 则再次赋值 by wjin v3.1
            if (self?.playerState ?? .ready) == .pause {
                
            } else {
                self?.playerState = .pause
            }
        })
        
        Log.vLog(level: .notice, "pause func end👆")
    }
    
    public func thumbnail(comple : @escaping (UIImage?)->Void) {
        DispatchQueue.global().async { [weak self] in
            guard let player = self?.playerContent else {
                DispatchQueue.main.async {
                    comple(nil)
                }
                return
            }
            player.captureImage { (img) in
                DispatchQueue.main.async {
                    comple(img)
                }
            }
        }
    }
    
    // 开始录制视频
    public func startRecord() {
        DispatchQueue.global().async { [weak self] in
            guard let player = self?.playerContent else {
                DispatchQueue.main.async { [weak self] in
                    self?.protocol?.addxVideoRecordState(sender: self, state: ADDXRecordState.error(state: ADDXRecordErrorState.start_noplayer))
                }
                return
            }
            // 开始录制
            let result = player.startCaptureVideo()
            DispatchQueue.main.async { [weak self] in
                if result {
                    self?.protocol?.addxVideoRecordState(sender: self, state: ADDXRecordState.start)
                } else {
                    self?.protocol?.addxVideoRecordState(sender: self, state: ADDXRecordState.error(state: ADDXRecordErrorState.start_error))
                }
            }
        }
       
    }
    
    // 结束录制视频
    public func stopRecord(comple: ((ADDXRecordState) -> Void)?) {
        DispatchQueue.global().async { [weak self] in
            guard let player = self?.playerContent else {
                DispatchQueue.main.async { [weak self] in
                    let state = ADDXRecordState.error(state: ADDXRecordErrorState.end_player_release)
                    if self?.protocol != nil {
                        self?.protocol?.addxVideoRecordState(sender: self, state: state)
                    }else {
                        comple?(state)
                    }
                }
                return
            }
            // 结束录制
            player.stopCaptureVideo { (flag, url) in
                DispatchQueue.main.async { [weak self] in
                    if flag {
                        self?.protocol != nil ? self?.protocol?.addxVideoRecordState(sender: self, state: .end(filePath: url)) : comple?(.end(filePath: url))
                    }else {
                        self?.protocol != nil ? self?.protocol?.addxVideoRecordState(sender: self, state: .error(state: .end_error)) : comple?(.error(state: .end_error))
                    }
                }
            }
        }
    }
    
    private func loadPlayerConnect(comple: ((Bool)->Void)? = nil) {
        Log.vLog(level: .notice, "loadPlayerConnect func start")
        
        self.queue.async { [weak self] in
            
            guard self?.canSendCmd ?? false == false else {
                Log.vLog(level: .warning, "loadPlayerConnect func canSendCmd: true, return")
                comple?(true)
                return
            }
            
            if case .connecting = self?.playerState {
                Log.vLog(level: .warning, "loadPlayerConnect func playerState: connecting, return")
                comple?(true)
                return
            }
            
            self?.playerState = .connecting
            self?.playerContent?.disconnectWebRTCClient()
            
            self?.protocol?.addxConnectLog(sender: self, state: .startTicket)
            
            self?.protocol?.addxVideoInfo(sender: self, comple: { [weak self] (ticketModle, state) in
                
                if let tick = ticketModle, let player = ADDXWebRTCPlayer.create(webRTCTicket: tick) {
                    Log.vLog(level: .notice, "addxVideoInfo func webRTCTicket create success 💚❤️ step3")
                    self?.protocol?.addxConnectLog(sender: self, state: .loadTicket(ticket: tick))
                    self?.playerContent = player
                    self?.playerContent?.delegate = self
                    
                    // CG 和 CB 系列暂停时间在此初始化 - 后端下发
                    self?.videoPauseTimerOut = TimeInterval(tick.appStopLiveTimeout ?? 30)
                    
                    if case .connecting = self?.playerState {
                        self?.playerContent?.startConnect()
                    }
                    
                    comple?(true)
                } else {
                    Log.vLog(level: .error, "addxVideoInfo func error:\(state)")
                    self?.canSendCmd = false
                    // device_sleep 休眠判断需要处理：好像不准确
                    if state == .error(error: .device_sleep) {
                        self?.protocol?.addxConnectLog(sender: self, state: .loadTicketError)
                        self?.playerState = .error(error: .device_sleep)
                        comple?(false)
                        return
                    } else {
                        self?.protocol?.addxConnectLog(sender: self, state: .loadTicketError)
                        self?.playerState = .error(error: ADDXError.connect_info_error)
                        comple?(false)
                    }
                }
            })
        }
    }
    
    public func beginConnect(comple: ((Bool)->Void)? ) {
        Log.vLog(level: .notice, "beginConnect func")
        self.loadPlayerConnect(comple: comple)
    }
    
    func stopConnect() {
        Log.vLog(level: .warning, "stopConnect func")
        self.queue.sync { [weak self] in
            self?.playerContent?.stopConnect()
        }
        // 可能重连的时候有问题 - by wjin v3.1
        self.playerContent = nil

    }
    
    func isConnected() -> Bool {
        switch playerState {
        // 如果 socket 已经连接 ，视频连接成功，正在连接webrtc ，视频暂停 ， rtc 断开连接未断开
        case .pause , .connecting , .connect , .play  , .playing :
            return true
        case .ready ,.disConnect , .error:
            return false
        }
    }
    
}

extension ADWebRTCPlayerController {
    private func getRequestModle<Param : Codable>(cmdType : ADDXRTCPlayerCmdState , params : Param?) -> DataChannelRequestModel? {
        guard let ticketModle = self.playerContent?.webRTCTicketModel else {
            return nil
        }
        var dataModle : DataChannelRequestModel? = nil
        switch cmdType {
        case .play(sharpType : let type):
            dataModle = DataChannelAppRequest.startPlayLiveRequest(ticketModel: ticketModle,liveResoolutionType: type)
        case .pause:
            dataModle = DataChannelAppRequest.stopPlayLiveRequest(ticketModel: ticketModle)
        case .sdPlay(start: let start):
            dataModle = DataChannelAppRequest.startPlaySdVideoRequest(ticketModel: ticketModle,startTime: Int64(start))
        case .getSdlist(start: let start, end: let end):
            dataModle = DataChannelAppRequest.getSdVideoListRequest(ticketModel: ticketModle ,startTime: start, stopTime: end)
        case .warning:
            dataModle = DataChannelAppRequest.triggerAlarmRequest(ticketModel: ticketModle)
        case .setWhiteLight(enable: let enable):
            dataModle = DataChannelAppRequest.setWhiteLightRequest(ticketModel: ticketModle ,enable:enable)
        case .getWhiteLight:
            return nil
        case .setVideoDetail(value: let value):
            dataModle = DataChannelAppRequest.setLiveResolutionRequest(ticketModel: ticketModle ,liveResoolutionType: value)
        case .getVideoDetail:
            dataModle = DataChannelAppRequest.getStatusRequest(ticketModel: ticketModle ,timeStamp: Date().timeIntervalSince1970)
        case .sdPause:
            dataModle = DataChannelAppRequest.stopPlaySdVideoRequest(ticketModel: ticketModle)
        case .other(action: let action ):
            dataModle = DataChannelAppRequest.loadRequestData(ticketModel: ticketModle, action: action, param: params)
        }
        return dataModle
    }
}

extension ADWebRTCPlayerController: ADDXWebRTCPlayerDelegate {
    public func addxWebRTCPlayerFirstKeyFrames() {
        debugPrint("-----------> addxWebRTCPlayerFirstKeyFrames func self?.playerState: \(self.playerState)")
        DispatchQueue.main.async { [weak self] in
            self?.protocol?.addxConnectLog(sender: self, state: .firstFrame)
            //
            if (self?.playerState ?? .ready) == .pause || (self?.playerState ?? .ready) == .ready || (self?.playerState ?? .ready) == .disConnect {
                // || (self?.playerState ?? .ready) == .playing
                // 即使是playing，再赋值是为了改变UI,暂停再次点击播放处理
                debugPrint("-----------> addxWebRTCPlayerFirstKeyFrames func playerState set to playing")
                self?.playerState = .playing
            }
            
            // 上报log
            self?.protocol?.addxConnectLog(sender: self, state: .videoConnected(recordVideo: true, p2pinfo: self?.playerContent?.p2pInfo))
        }
    }
    
    public func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, didChangePlayer state: ADDXWebRTCPlayerState) {
        debugPrint("-----------> addxWebRTCPlayer func state: \(state)")
        DispatchQueue.main.async { [weak self] in
            switch state {
            case .ready, .connecting:
                break
            case .connected:
                self?.playerState = .connect
                self?.protocol?.addxConnectLog(sender: self, state: .peerConnected)
                break
            case .disConnected:
                self?.canSendCmd = false
                // 断开连接 - 不一定就是连接错误吧？主动断开也会调此 by wjin
                self?.protocol?.addxConnectLog(sender: self, state: .peerDisconnected)
                self?.playerState = .error(error: ADDXError.connect_fail)//.ready //.error(error: ADDXError.connect_fail)
                break
            case .failed:
                self?.canSendCmd = false
                self?.protocol?.addxConnectLog(sender: self, state: .videoConnectError(error: ADDXError.connect_fail))
                self?.playerState = .error(error: ADDXError.connect_fail)
                break
            case .timeOut:
                self?.canSendCmd = false
                self?.protocol?.addxConnectLog(sender: self, state: .videoConnectError(error: ADDXError.connect_time_out))
                self?.playerState = .error(error: ADDXError.connect_time_out)
                break
            case .cancelled:
                self?.playerState = .ready
                break
            }
        }
    }
    
    public func addxWebRTCPlayerSignalClientConnecting() {
        self.protocol?.addxConnectLog(sender: self, state: .socketConnect)
    }
    
    // peerState
    public func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, didChangePlayer peerState: ADDXWebRTCPlayerPeerConnectState) {
        switch peerState {
        case .new:
            self.protocol?.addxConnectLog(sender: self, state: .peerNew)
        case .connecting:
            self.protocol?.addxConnectLog(sender: self, state: .peerConnecting)
        case .connected:
            self.protocol?.addxConnectLog(sender: self, state: .peerConnected)
        case .disconnected:
            self.protocol?.addxConnectLog(sender: self, state: .peerDisconnected)
        case .failed:
            self.protocol?.addxConnectLog(sender: self, state: .peerFailed)
        case .closed:
            self.protocol?.addxConnectLog(sender: self, state: .peerClosed)
        }
    }
    
    // iceState
    public func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, didChangePlayer iceState: ADDXWebRTCPlayerIceConnectState) {
        switch iceState {
        case .new:
            self.protocol?.addxConnectLog(sender: self, state: .iceNew)
        case .checking:
            self.protocol?.addxConnectLog(sender: self, state: .iceChecking)
        case .connected:
            self.protocol?.addxConnectLog(sender: self, state: .iceConnected)
        case .completed:
            self.protocol?.addxConnectLog(sender: self, state: .iceCompleted)
        case .failed:
            self.protocol?.addxConnectLog(sender: self, state: .iceFailed)
        case .disconnected:
            self.protocol?.addxConnectLog(sender: self, state: .iceDisconnected)
        case .closed:
            self.protocol?.addxConnectLog(sender: self, state: .iceClosed)
        case .count:
            self.protocol?.addxConnectLog(sender: self, state: .iceCount)
        }
    }
    
    public func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, localSpeakVoiceData voiceData: Array<NSNumber>) {
        DispatchQueue.main.async { [weak self] in
            var points : [Float] = []
            voiceData.forEach { (index) in
                points.append(index.floatValue)
            }
            self?.protocol?.addxVideoSpeakVoice(sender: self, localSpeakVoiceData: points)
            
        }
        
    }
    
    public func addxWebRTCPlayerDidReadyPlay(_ player: ADDXWebRTCPlayer) {
        
    }
    
    public func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, didChange videoSize: CGSize) {
        Log.vLog(level: .alert, "videoSize: \(videoSize) playerState set to playing")
        self.videoSize = videoSize
        self.playerContent?.updateP2pInfo { [weak self] in
            self?.protocol?.addxConnectLog(sender: self, state: .videoConnected(recordVideo: false, p2pinfo: self?.playerContent?.p2pInfo))
            DispatchQueue.main.async { [weak self] in
                debugPrint("-----------> addxWebRTCPlayer didChange videoSize func playerState set to playing")
                self?.playerState = .playing
            }
        }
        
    }
    
    public func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, didChangeDataChannelState state: ADDXWebRTCPlayerDataChannelState) {
        Log.vLog(level: .notice, "didChangeDataChannelState func state: \(state)")
        if state == .open {
            canSendCmd = true
            self.protocol?.addxConnectLog(sender: self, state: .dataChannel)
            Log.vLog(level: .notice, "didChangeDataChannelState func state open and Do executeCmd 💚❤️ step13")
            self.executeCmd()
        } else if state == .closed || state == .connecting || state == .closing {
            Log.vLog(level: .warning, "didChangeDataChannelState func state open and Do executeCmd")
            self.clearCmd()
            canSendCmd = false
        }
    }
    
    public func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, didReceiveDataChannelData data: Data, isBinary: Bool, action: String?) {
        DispatchQueue.main.async { [weak self] in
            self?.protocol?.addxVideoDeviceCmd(sender: self, data: data, isBinary: isBinary, action: action)
        }
    }
    
    public func addxWebRTCPlayerSignalClientDidConnect() {
        self.protocol?.addxConnectLog(sender: self, state: .socketConnected)
    }
    
    public func addxWebRTCPlayerSignalClientDidDisconnect(disconnectReason: ADDXWebSocketDisConnectReason , errorCode : Int) {
        Log.vLog(level: .warning, "disconnect Reason: \(disconnectReason)")
        DispatchQueue.main.async { [weak self] in
            self?.canSendCmd = false
            switch disconnectReason {
            case .unknow:
                self?.protocol?.addxConnectLog(sender: self, state: .socketError(error: errorCode))
                self?.playerState = .error(error: .device_unkown)
            case .usersLimit:
                self?.protocol?.addxConnectLog(sender: self, state: .videoConnectError(error: .users_limit))
                self?.playerState = .error(error: .users_limit)
            case .timeout:
                self?.protocol?.addxConnectLog(sender: self, state: .socketError(error: errorCode))
                self?.playerState = .error(error: .connect_time_out)
            }
        }
    }
    
    public func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, didPeerIn newSignalClient: ADDXPlayerClientRoleMode) {
        self.protocol?.addxConnectLog(sender: self, state: .peerIn)
    }
    
    //发送offer
    public func addxWebRTCPlayerSendOffer() {
        self.protocol?.addxConnectLog(sender: self, state: .offer)
    }
    
    //发送anwser
    public func addxWebRTCPlayerSendAnwser() {
        self.protocol?.addxConnectLog(sender: self, state: .answer)
    }
    
    public func addxWebRtcLogSendCmdAction(action : String , flag : Bool) {
        self.protocol?.addxConnectLog(sender: self, state: .sendCmd(action: action, flag: flag))
    }
    
    public func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, didPeerOut newSignalClient: ADDXPlayerClientRoleMode) {
        self.protocol?.addxConnectLog(sender: self, state: .peerOut)
//        var videoIsInterrupt = false
        if self.playerState == .play || self.playerState == .playing {
            self.protocol?.addxConnectLog(sender: self, state: .videoInterrupt)
        } else {
            debugPrint("-----------> didPeerOut newSignalClient: didPeerOut(device_leave)")
            self.protocol?.addxConnectLog(sender: self, state: .videoConnectError(error: .device_leave))
        }
        
        self.canSendCmd = false
        DispatchQueue.main.async { [weak self] in
            debugPrint("-----------> didPeerOut newSignalClient playerState: \(self?.playerState ?? .ready) to: device_leave")
            self?.playerState = .error(error: .device_leave)
        }
        
    }
    
    // 直播重连更新updateWebRTCTicket逻辑
    public func addxWebRTCPlayer(_ player: ADDXWebRTCPlayer, updateWebRTCTicket completionCallback: @escaping (ADDXWebRTCTicketModel?) -> Void) {
        self.protocol?.addxConnectLog(sender: self, state: .startUpdateTicket)
        self.protocol?.addxVideoInfo(sender: self, comple: { [weak self] (ticketModel, state) in
            if ticketModel != nil {
                self?.protocol?.addxConnectLog(sender: self, state: .loadTicket(ticket: ticketModel!))
            } else {
                if state == .error(error: .device_sleep) {
                    self?.protocol?.addxConnectLog(sender: self, state: .loadTicketError)
                    self?.playerState = .error(error: .device_sleep)
                    completionCallback(ticketModel)
                    return
                } else {
                    self?.protocol?.addxConnectLog(sender: self, state: .loadTicketError)
                }
            }
            completionCallback(ticketModel)
        })
    }
}
