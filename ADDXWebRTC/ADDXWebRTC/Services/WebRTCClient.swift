//
//  WebRTCClient.swift
//  WebRTC
//
//  Created by Stasel on 20/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import Foundation
import WebRTC
import CoreAudio

protocol WebRTCClientDelegate: class {
    func webRTCClient(_ client: WebRTCClient, localSpeakVoiceData voiceData: Array<NSNumber>)
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate)
    func webRTCClient(_ client: WebRTCClient, didChangeIceConnectionState state: RTCIceConnectionState)
    func webRTCClient(_ client: WebRTCClient, didChangePeerConnectionState state: RTCPeerConnectionState)
    func webRTCClient(_ client: WebRTCClient, didChangeDataChannelStatea state:RTCDataChannelState)
    func webRTCClient(_ client: WebRTCClient, didReceiveDataChannelData data: Data, isBinary: Bool)
    func webRTCClient(_ client: WebRTCClient, didAddStream stream: RTCMediaStream)
}

final class WebRTCClient: NSObject {
    
    // The `RTCPeerConnectionFactory` is in charge of creating new RTCPeerConnection instances.
    // A new RTCPeerConnection should be created every new call, but the factory is shared.
    //    private static let videoEncoderFactory: RTCDefaultVideoEncoderFactory = {
    //        return RTCDefaultVideoEncoderFactory()
    //    }()
    //    private static let videoDecoderFactory: RTCDefaultVideoDecoderFactory = {
    //        return RTCDefaultVideoDecoderFactory()
    //    }()
    //    private static let factory: RTCPeerConnectionFactory = {
    //        RTCInitializeSSL()
    //        let videoEncoderFactory = WebRTCClient.videoEncoderFactory
    //        let videoDecoderFactory = WebRTCClient.videoDecoderFactory
    //        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    //    }()
    private static func iniitializeSSL(){
        RTCInitializeSSL()
    }
    private static func cleanSSL(){
        RTCCleanupSSL()
    }
    weak var delegate: WebRTCClientDelegate?
    private let videoEncoderFactory: RTCDefaultVideoEncoderFactory
    private let videoDecoderFactory: RTCDefaultVideoDecoderFactory
    private let peerConnectionFactory: RTCPeerConnectionFactory
    private let peerConnection: RTCPeerConnection
    private let rtcAudioSession =  RTCAudioSession.sharedInstance()
    private let audioQueue = DispatchQueue(label: "audio")
    private let dataChannelQueue = DispatchQueue(label: "dataChannel")
    private let rtcdelegateProcessQueue = DispatchQueue(label: "rtcdelegateProcessQueue")
    
    private let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
                                   kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue]    
    private var videoCapturer: RTCVideoCapturer?
    private var localVideoTrack: RTCVideoTrack?
    private var localAudioTrack: RTCAudioTrack?
    private var remoteStream   : RTCMediaStream?
    private var remoteVideoTrack: RTCVideoTrack?
    private var remoteAudioTrack: RTCAudioTrack?
    private var localDataChannel: RTCDataChannel?
    private var remoteDataChannel: RTCDataChannel?
    
    private var localDataChannelState: RTCDataChannelState?
    private var prevByteCount = 0
    public  var byteRate: Double = 0.0
    private var prevTime: CFTimeInterval = 0.0
    private var isRemoteAudioMuted: Bool = false
    
    public var deviceGroupId : String?
    
    public var p2pInfo : [[String : String]] = []
    public var isRelay : Bool = true
    
    private var _localVolume: Double = 3.0
    private var _remoteVolume: Double = 3.0
    
    @available(*, unavailable)
    override init() {
        fatalError("WebRTCClient:init is unavailable")
    }
    
    required init(iceServers: [ADDXWebRTCTicketIceServer]) {
        let config = RTCConfiguration()
        var rtcIceServers: Array<RTCIceServer> = Array.init()
        for ice in iceServers {
            let rtcIceServer = RTCIceServer.init(urlStrings: ice.url!, username: ice.username, credential: ice.credential)
            rtcIceServers.append(rtcIceServer)
        }
        config.iceServers = rtcIceServers
        
        // Unified plan is more superior than planB
        config.sdpSemantics = .unifiedPlan
        
        // gatherContinually will let WebRTC to listen to any network changes and send any new candidates to the other client
        config.continualGatheringPolicy = .gatherOnce
        config.tcpCandidatePolicy = .disabled
        config.bundlePolicy = .maxBundle
        config.keyType = .ECDSA
        config.rtcpMuxPolicy = .require
        
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil,
                                              optionalConstraints: ["DtlsSrtpKeyAgreement":kRTCMediaConstraintsValueTrue])
        //全局peerConnectionFactory 创建
        //        self.peerConnection = WebRTCClient.factory.peerConnection(with: config, constraints: constraints, delegate: nil)
        
        //局部peerConnectionFactory 创建
        WebRTCClient.iniitializeSSL()
        self.videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        self.videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        self.peerConnectionFactory = RTCPeerConnectionFactory(encoderFactory: self.videoEncoderFactory, decoderFactory: self.videoDecoderFactory)
        self.peerConnection = self.peerConnectionFactory.peerConnection(with: config, constraints: constraints, delegate: nil)
        
        super.init()
        self.createMediaSenders()
        self.peerConnection.delegate = self
        
        initAudio()
    }
    private func getPeerConnectionFactory() -> RTCPeerConnectionFactory{
        return self.peerConnectionFactory
        //        return WebRTCClient.factory
    }
    private func getVideoDecoderFactory() -> RTCDefaultVideoDecoderFactory{
        return self.videoDecoderFactory
        //        return WebRTCClient.videoDecoderFactory
    }
    private func getVideoEncoderFactory() -> RTCDefaultVideoEncoderFactory{
        return self.videoEncoderFactory
        //        return WebRTCClient.videoEncoderFactory
    }
    func startWebRTCConnect(){
        //在要业务层要启动这个链接才开启音频采集的配置 - 暂未使用
        self.configureAudioSession()
    }
    
    func startAecDump(filePath :String, maxSizeInbytes: Int64){
        self.getPeerConnectionFactory().startAecDump(withFilePath: filePath, maxSizeInBytes: maxSizeInbytes)
    }
    
    func stopAecDump(){
        self.getPeerConnectionFactory().stopAecDump()
    }
    
    // MARK: Signaling
    func offer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        let constrains = RTCMediaConstraints(mandatoryConstraints: self.mediaConstrains,
                                             optionalConstraints: nil)
        self.peerConnection.offer(for: constrains) { [weak self](sdp, error) in
            guard let sdp = sdp else {
                return
            }
            
            self?.peerConnection.setLocalDescription(sdp, completionHandler: { (error) in
                completion(sdp)
            })
        }
    }
    
    func answer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void)  {
        let constrains = RTCMediaConstraints(mandatoryConstraints: self.mediaConstrains,
                                             optionalConstraints: nil)
        self.peerConnection.answer(for: constrains) { [weak self](sdp, error) in
            guard let sdp = sdp else {
                return
            }
            
            self?.peerConnection.setLocalDescription(sdp, completionHandler: { (error) in
                completion(sdp)
            })
        }
    }
    
    func set(remoteSdp: RTCSessionDescription, completion: @escaping (Error?) -> ()) {
        self.peerConnection.setRemoteDescription(remoteSdp, completionHandler: completion)
    }
    
    func set(remoteCandidate: RTCIceCandidate) {
        self.peerConnection.add(remoteCandidate)
    }
    
    private func closeCaputre() -> Void {
        self.rtcdelegateProcessQueue.async { [weak self] in
            self?.localDataChannel?.close()
            self?.peerConnection.close()
        }
        self.peerConnection.delegate = nil
    }
    func renderRemoteVideo(to renderer: RTCVideoRenderer) {
        self.remoteVideoTrack?.add(renderer)
    }
    
    func removeRenderRemoteVideo(for renderer: RTCVideoRenderer) {
        self.remoteVideoTrack?.remove(renderer)
    }
    private func dumpAudio(prefix: String) {
        debugPrint("-----------> 直播连接成功后，音频属性设置打印")
        Log.vLog(level: .notice, "#### \(prefix) category: \(AVAudioSession.sharedInstance().category)👇")
        Log.vLog(level: .notice, "#### \(prefix) categoryOptions: \(AVAudioSession.sharedInstance().categoryOptions)")
        Log.vLog(level: .notice, "#### \(prefix) mode: \(AVAudioSession.sharedInstance().mode)")
        Log.vLog(level: .notice, "#### \(prefix) input: \(String(describing: AVAudioSession.sharedInstance().preferredInput))")
        Log.vLog(level: .notice, "#### \(prefix) inputDataSource: \(String(describing: AVAudioSession.sharedInstance().inputDataSource))")
        Log.vLog(level: .notice, "#### \(prefix) inputDataSources: \(String(describing: AVAudioSession.sharedInstance().inputDataSources))")
        Log.vLog(level: .notice, "#### \(prefix) outputDataSource: \(String(describing: AVAudioSession.sharedInstance().outputDataSource))")
        Log.vLog(level: .notice, "#### \(prefix) outputDataSources: \(String(describing: AVAudioSession.sharedInstance().outputDataSources))👆")
    }
    
    private func configMic() {
        RTCAudioSession.sharedInstance().lockForConfiguration()
        var input : AVAudioSessionPortDescription? = nil
        do {
            if let inputs = AVAudioSession.sharedInstance().availableInputs {
            for i in inputs {
                if i.portType == AVAudioSession.Port.builtInMic {
                    input = i
                    break
                }
            }
            if let dataSources = input?.dataSources {
                for dataSource in dataSources {
                    Log.vLog(level: .notice, "deviceGroupId: \(deviceGroupId ?? "") #### dataSource: \(dataSource)  location: \(String(describing: dataSource.location))")
                    if dataSource.location == AVAudioSession.Location.lower {
                        try input?.setPreferredDataSource(dataSource)
                        break
                    }
                }
            }
            //try RTCAudioSession.sharedInstance().setPreferredInput(input!)
            try AVAudioSession.sharedInstance().setPreferredInput(input)
            }
        } catch {
            Log.vLog(level: .error, "deviceGroupId: \(deviceGroupId ?? "") #### configMic error: \(error)")
        }
        RTCAudioSession.sharedInstance().unlockForConfiguration()
        dumpAudio(prefix: "configMic");
    }
    
    private func initAudio() {
        Log.vLog(level: .notice, "deviceGroupId: \(deviceGroupId ?? "") #### initAudio")
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        let config = RTCAudioSessionConfiguration.current()
        RTCAudioSession.sharedInstance().lockForConfiguration()
        
        // disable built-in AGC for all ios devices
        // up volume for iphone 6s in webrtc framework
        // so, we need't change Category/Mode for iphone 6s
        if identifier == "iPhone8,1"  && false {
            Log.vLog(level: .warning, "deviceGroupId: \(deviceGroupId ?? "") #### \(identifier) use multiRoute")
            config.category = AVAudioSession.Category.multiRoute.rawValue
            config.categoryOptions = []
            config.mode = AVAudioSession.Mode.default.rawValue
            config.inputNumberOfChannels = 1 
            config.outputNumberOfChannels = 1
        } else {
            config.category = AVAudioSession.Category.playAndRecord.rawValue
            config.categoryOptions = []
            config.mode = AVAudioSession.Mode.videoChat.rawValue
            config.inputNumberOfChannels = 1
            config.outputNumberOfChannels = 1
        }
        RTCAudioSessionConfiguration.setWebRTC(config)
        RTCAudioSession.sharedInstance().unlockForConfiguration()
        dumpAudio(prefix: "initAUdio");
    }
    
    private func configAudio(on : Bool) {
        Log.vLog(level: .notice, "deviceGroupId: \(deviceGroupId ?? "") #### configAudio: \(on)")
        /*
        do {
            if on {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
                try AVAudioSession.sharedInstance().setMode(AVAudioSession.Mode.videoChat)
                try AVAudioSession.sharedInstance().setActive(true)
            } else {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
                try AVAudioSession.sharedInstance().setMode(AVAudioSession.Mode.default)
                try AVAudioSession.sharedInstance().setActive(true)
            }
        } catch {
            Log.vLog(level: .notice, "#### configAudio error \(error)")
        }
 */
        
        dumpAudio(prefix: "configAudio")
    }
    
    private func configureAudioSession() {
        //configAudio(on: false)
    }
    
    private func createMediaSenders() {
        let streamId = "myStream-" + String(Int64(Date().timeIntervalSince1970))
        
        // Audio
        let audioTrack = self.createAudioTrack()
        self.localAudioTrack = audioTrack
        self.localAudioTrack?.source.volume = _localVolume
        self.peerConnection.add(audioTrack, streamIds: [streamId])
        
        // Video
        self.remoteVideoTrack = self.peerConnection.transceivers.first { $0.mediaType == .video }?.receiver.track as? RTCVideoTrack
        // self.remoteAudioTrack?.source.volume = 0.5
        self.remoteAudioTrack?.source.volume = _remoteVolume

        // Data
        if let dataChannel = createDataChannel() {
            dataChannel.delegate = self
            self.localDataChannelState = .closed
            self.localDataChannel = dataChannel
        }
    }
    
    private func createAudioTrack() -> RTCAudioTrack {
        let audioTarckId = "myAudioTrack-" + String(Int64(Date().timeIntervalSince1970))
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = self.getPeerConnectionFactory().audioSource(with: audioConstrains)
        let audioTrack = self.getPeerConnectionFactory().audioTrack(with: audioSource, trackId: audioTarckId)
        return audioTrack
    }
    
    
    // MARK: Data Channels
    private func createDataChannel() -> RTCDataChannel? {
        let config = RTCDataChannelConfiguration()
        guard let dataChannel = self.peerConnection.dataChannel(forLabel: "WebRTCData", configuration: config) else {
            Log.vLog(level: .error, "deviceGroupId: \(deviceGroupId ?? "") Warning: Couldn't create data channel.")
            return nil
        }
        return dataChannel
    }
    
    func sendData(_ data: Data, isBinary: Bool) -> Bool{
        self.dataChannelQueue.async {
            //如果当前状态不是打开则说明还不能放信息
            if self.localDataChannel == nil {
                return
            }
            if self.localDataChannelState != .open {
                return 
            }
            let buffer = RTCDataBuffer(data: data, isBinary: isBinary)
            self.localDataChannel?.sendData(buffer)
        }
        return true
    }
    
    func closePeerConnection() {
        self.peerConnection.close()
    }
    
    public func updateByteCount(comple : @escaping ()->Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                return
            }
            self.peerConnection.stats(for: self.remoteVideoTrack, statsOutputLevel: .standard) { [weak self] (reports) in
                reports.forEach { (report) in
                    for info in report.values{
                        if (info.key as String).elementsEqual("bytesReceived") {
                            let byteCount = Int(info.value)
                            self?.updateByteCount(byteCount: byteCount)
                        }
                    }
                }
            }
            var beginLoad : Bool = false
            self.peerConnection.stats(for: nil, statsOutputLevel: .standard) { [weak self] (reports) in
                
                var tempP2PInfo : [[String : String]] = []
                
                var remoteCandidateType : String? = nil
                var localCandidateType : String? = nil
                reports.forEach { (report) in
                    if report.type == "googCandidatePair" {
                        if !beginLoad {
                            beginLoad = true
                        }
                        let isConnection : Bool = Bool(report.values["googActiveConnection"] ?? "false") ?? false
                        if isConnection {
                            remoteCandidateType = report.values["googRemoteCandidateType"]
                            localCandidateType = report.values["googLocalCandidateType"]
                        }
                    }
                    if beginLoad {
                        tempP2PInfo.append(report.values)
                    }
                }
                if localCandidateType == "relay" || remoteCandidateType == "relay" {
                    self?.isRelay = true
                } else {
                    self?.isRelay = false
                }
                self?.p2pInfo = tempP2PInfo
                comple()
            }
        }
    }
        
    private func updateByteCount(byteCount: Int?){
        if byteCount == nil{
            return
        }
        let currentTime = CACurrentMediaTime();
        if (byteCount! > self.prevByteCount){
            self.byteRate = Double((byteCount! - self.prevByteCount)) / (currentTime - self.prevTime);//大B
        }else{
            self.byteRate = 0.0
        }
        self.prevByteCount = byteCount!;
        self.prevTime = currentTime;
        
    }
}

// MARK:- Audio control
extension WebRTCClient {
    func startRtcEventLogWithFilePath(filePath: String){
        //        do {
        //            try FileManager.default.removeItem(atPath: filePath)
        //        } catch  {
        //            Log.vLog(level: .notice, "删除文件失败  \(filePath)")
        //        }
        //        self.peerConnection.startRtcEventLog(withFilePath: filePath, maxSizeInBytes: -1)
    }
    func stopRtcEventLog(){
        //        self.peerConnection.stopRtcEventLog()
    }
    
    
    func startRecordAudio(filePath:String) -> Bool{
        do {
            try FileManager.default.removeItem(atPath: filePath)
        } catch  {
            Log.vLog(level: .error, "startRecordAudio func 删除文件失败: \(filePath)")
        }
        if self.remoteAudioTrack == nil {
            return false
        }
        var res = false
        do {
            res = ((try self.remoteAudioTrack?.source.startAudioRecord(withFilePath: filePath)) != nil)
        } catch  {
            Log.vLog(level: .error, "startRecordAudio func create wav encoder fail")
        }
        if res {
            Log.vLog(level: .notice, "startRecordAudio func 开始录音")
        }
        return res
    }
    func stopRecordAudio(_ completionCallback:((_ firstFrameTime: UInt32, _ audioPath: String) -> Void)? = nil){
        if self.remoteAudioTrack == nil {
            return
        }
        self.remoteAudioTrack!.source.stopAudioRecordFinish { (firstFrameTime, audioPath) in
            completionCallback?(firstFrameTime,audioPath)
        }
        Log.vLog(level: .warning, "stopRecordAudio func 停止录音")
    }
    
    func startAecdump(filePath:String, maxSize: Int64){
        self.getPeerConnectionFactory().startAecDump(withFilePath: filePath, maxSizeInBytes: -1)
    }
    
    func stopAecdump(){
        self.getPeerConnectionFactory().stopAecDump()
    }
    
    func muteRemoteAudio() {
        self.audioQueue.async { [weak self] in
            if self?.remoteAudioTrack?.source != nil {
                self?.remoteAudioTrack?.source.volume = 0.0
                self?.isRemoteAudioMuted = true
            }
        }
    }
    
    func unmuteRemoteAudio() {
        self.audioQueue.async {[weak self] in
            if self?.remoteAudioTrack?.source != nil {
                //self?.remoteAudioTrack?.source.volume = 10.0
                self?.remoteAudioTrack?.source.volume = self!._remoteVolume
                self?.isRemoteAudioMuted = false
            }
        }
    }
    
    func mutelocalAudio() {
        self.setlocalAudioEnabled(false)
    }
    
    func unmutelocalAudio() {
        self.setlocalAudioEnabled(true)
    }
    
    func speakerOff() {
        configAudio(on: false)
        self.audioQueue.async { [weak self] in
            if self?.remoteAudioTrack != nil && !(self?.isRemoteAudioMuted ?? false) {
                self?.remoteAudioTrack!.source.volume = self!._remoteVolume
            }
            self?.mutelocalAudio()
        }
    }
    
    func speakerOn() {
        configAudio(on: true)
        self.audioQueue.async { [weak self] in
            if self?.remoteAudioTrack != nil {
                // for CG aec not very well
                self?.remoteAudioTrack!.source.volume = self!._remoteVolume
            }
            self?.unmutelocalAudio()
        }
    }
    // Fallback to the default playing device: headphones/bluetooth/ear speaker
    func audioOutputAudioPortNone(){
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            //self.configAudio(on: false)
        }
    }
    
    // Force speaker
    func audioOutputAudioPortSpeaker(){
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            //self.configAudio(on: true)
        }
    }
    
    private func setlocalAudioEnabled(_ isEnabled: Bool) {
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.localAudioTrack?.isEnabled = isEnabled
            if isEnabled {
                self.getPeerConnectionFactory().startRecordAudioiCallBack { [weak self](dataBuffer, dataSize) in
                    let numbers : Int32 = 32
                    var array:Array<NSNumber> = Array()
                    var offset = Int32(dataSize/numbers)
                    if offset <= 0{
                        offset = 1
                    }
                    
                    for i in 0...numbers {
                        if i*offset < dataSize {
                            let maxValue = Float(16384.0)
                            var w = Float(dataBuffer[Int(i*offset)])
                            if w > maxValue {
                                w = maxValue
                            }
                            let y = w / maxValue
                            array.append(NSNumber.init(value: y))
                        }
                    }
                    guard let self = self else {
                        return
                    }
                    self.delegate?.webRTCClient(self, localSpeakVoiceData: array)
                }
            }else{
                self.getPeerConnectionFactory().stopRecordAudio()
            }
        }
    }
}

extension WebRTCClient: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCPeerConnectionState) {
        self.rtcdelegateProcessQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            Log.vLog(level: .notice, "deviceGroupId: \(self.deviceGroupId ?? "") peerConnection didChange PeerConnectionNewState: \(newState)")
            self.delegate?.webRTCClient(self, didChangePeerConnectionState: newState)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        Log.vLog(level: .notice, "deviceGroupId: \(deviceGroupId ?? "") peerConnection new signaling state: \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        self.rtcdelegateProcessQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.remoteStream = stream
            let videoTrack = stream.videoTracks.first
            let audioTrack = stream.audioTracks.first
            if audioTrack != nil {
                self.remoteAudioTrack = audioTrack
                self.audioOutputAudioPortSpeaker()
            }
            
            if videoTrack != nil {
                self.remoteVideoTrack = videoTrack
            }
            
            self.delegate?.webRTCClient(self, didAddStream: stream)
            
            //debug info
            Log.vLog(level: .notice, "peerConnection func deviceGroupId: \(self.deviceGroupId ?? "") didAdd stream: \(stream)  videoTrack: \(String(describing: videoTrack))  audioTrack: \(String(describing: audioTrack)) 💚❤️ step10")
            
            self.peerConnection.receivers.enumerated().forEach { (index,receiver) in
                Log.vLog(level: .notice, "peerConnection func deviceGroupId: \(self.deviceGroupId ?? "") didAdd stream receiver id: \(receiver.receiverId)  track Id: \(String(describing: receiver.track?.trackId))")
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        Log.vLog(level: .info, "deviceGroupId: \(deviceGroupId ?? "") peerConnection did remove stream")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        Log.vLog(level: .info, "deviceGroupId: \(deviceGroupId ?? "") peerConnection should negotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        self.rtcdelegateProcessQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            Log.vLog(level: .info, "deviceGroupId: \(self.deviceGroupId ?? "") peerConnection didChange RTCIceConnectionNewState: \(newState)")
            self.delegate?.webRTCClient(self, didChangeIceConnectionState: newState)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        Log.vLog(level: .info, "deviceGroupId: \(deviceGroupId ?? "") peerConnection new gathering state: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.rtcdelegateProcessQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.delegate?.webRTCClient(self, didDiscoverLocalCandidate: candidate)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        Log.vLog(level: .info, "deviceGroupId: \(deviceGroupId ?? "") peerConnection did remove candidate(s)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        Log.vLog(level: .notice, "deviceGroupId: \(deviceGroupId ?? "") peerConnection did open data channel")
        self.rtcdelegateProcessQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.remoteDataChannel = dataChannel
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didStartReceivingOn transceiver: RTCRtpTransceiver) {
        Log.vLog(level: .notice, "deviceGroupId: \(deviceGroupId ?? "") peerConnection didStartReceivingOn open data channel: \(transceiver) 💚❤️ step8")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove rtpReceiver: RTCRtpReceiver) {
        
    }
}


//data channel 功能 用于数据通讯
extension WebRTCClient: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        self.localDataChannelState = dataChannel.readyState
        self.delegate?.webRTCClient(self, didChangeDataChannelStatea: dataChannel.readyState)
        Log.vLog(level: .info, "deviceGroupId: \(deviceGroupId ?? "") dataChannel did change state: \(dataChannel.readyState)")
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        self.delegate?.webRTCClient(self, didReceiveDataChannelData: buffer.data, isBinary: buffer.isBinary)
    }
}
