//
//  SignalClient.swift
//  WebRTC
//
//  Created by Stasel on 20/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import Foundation
import WebRTC

//观看用户上限code码 详情描述查看 http://192.168.31.7:8090/pages/viewpage.action?pageId=24577790
let users_limit_code = 3002
enum MessageTypeEnum: String {
    case PEER_IN = "PEER_IN"
    case PEER_OUT = "PEER_OUT"
    case SDP_OFFER = "SDP_OFFER"
    case SDP_ANSWER = "SDP_ANSWER"
    case ICE_CANDIDATE = "ICE_CANDIDATE"
}
struct ClientRoleMode: Codable {
    var id : String?
    var name : String?
    var role : String?
}
protocol SignalClientDelegate: class {
    func signalClientConnecting(_ signalClient: SignalingClient)
    func signalClientDidConnect(_ signalClient: SignalingClient)
    func signalClientDidDisconnect(_ signalClient: SignalingClient, code: UInt16)
    func signalClientCancelled(_ signalClient: SignalingClient)
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription)
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate)
    func signalPeerIn(recipientClientId: String, role:ClientRoleMode)
    func signalPeerOut(recipientClientId: String, role:ClientRoleMode)
    func signalSdpOffer(recipientClientId: String)
    func signalSdpAnswer(payload: String)
    func signalIceCandidate(payload: String)
}

final class SignalingClient: NSObject {
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let webSocket: WebSocketProvider
    private var pingTimer: Timer?
    weak var delegate: SignalClientDelegate?
    private let socketDelegateProcessQueue = DispatchQueue(label: "socketDelegateProcessQueue")
    private var videoPauseTimerOut : Double = Double.infinity
    var isPauseTimerOut : Bool = false
    init(webSocket: WebSocketProvider) {
        self.webSocket = webSocket
        Log.vLog(level: .notice, "webSocket init")
    }
    
    func connect() {
        Log.vLog(level: .notice, "webSocket connect start")
        self.webSocket.delegate = self
        self.webSocket.connect()
        self.delegate?.signalClientConnecting(self)
    }
    
    func disConnect() {
        Log.vLog(level: .warning, "webSocket disConnect")
        //self.stopSendPingAction()
        self.webSocket.delegate = nil
        self.webSocket.disConnect()
        stopPing()
    }

    func send(string: String)  {
        Log.vLog(level: .notice, "webSocket send: \(string)")
        self.webSocket.send(string: string)
    }
    
    func sendString(str: String)  {
        Log.vLog(level: .notice, "webSocket sendString: \(str)")
        self.webSocket.send(string: str)
    }
    
    /// 视频暂停后，设置超时时长
    /// - Parameter time: 超时时间
    func setVideoPauseTimerOut(time: TimeInterval) {
        Log.vLog(level: .warning, "setVideoPauseTimerOut time: \(time)")
        videoPauseTimerOut = time
        if time == Double.infinity {
            isPauseTimerOut = false
        } else {
            isPauseTimerOut = true
        }
    }
    
    func startSendPingAction(time: TimeInterval) {
        self.startPing(time: time)
        videoPauseTimerOut = Double.infinity
        isPauseTimerOut = false
        Log.vLog(level: .notice, "startSendPingAction func \(self)")
    }
    
    func stopSendPingAction() {
        Log.vLog(level: .warning, "stopSendPingAction func \(self)")
        
        self.stopPing()
    }
    
    private func getClientRoleModel(dictStr: String) -> ClientRoleMode {
        Log.vLog(level: .warning, "getClientRoleModel func dictStr: \(dictStr)")
        let dict = dictStr.base64Decoding().toDictionary()
        var role = ClientRoleMode()
        role.id = dict["id"] as? String
        role.name = dict["name"] as? String
        role.role = dict["role"] as? String
        return role
    }
    
    private func startPing(time: TimeInterval) {
        DispatchQueue.main.async {
            self.pingTimer?.invalidate()
            self.pingTimer = nil
            self.pingTimer = Timer(timeInterval: time, target: self, selector: #selector(self.sendPingData), userInfo: nil, repeats: true)
            RunLoop.current.add(self.pingTimer!, forMode: .common)
            self.pingTimer?.fire()
        }
    }
    
    private func stopPing() {
        Log.vLog(level: .warning, "stopPing func set pingTimer to nil")
        DispatchQueue.main.async {
            self.pingTimer?.invalidate()
            self.pingTimer = nil
        }
    }
    
    @objc private func sendPingData() {
        let str = ""
        let data = str.data(using: .utf8)
        Log.vLog(level: .info, "sendPingData func for send ping data 💚❤️ step4-1")
        videoPauseTimerOut -= self.pingTimer?.timeInterval ?? 2
        debugPrint("-----------> sendPingData videoPauseTimerOut: \(videoPauseTimerOut)")
        if videoPauseTimerOut < 10 { //  10 是自定义的，目的是上报倒计时
            Log.vLog(level: .warning, "sendPingData func videoPauseTimerOut: \(videoPauseTimerOut)")
        }
        
        if videoPauseTimerOut < 0 {
            Log.vLog(level: .error, "sendPingData func videoPauseTimerOut < 0 超时主动断开 - 超时时间由后端ticket下发")
            self.delegate?.signalClientCancelled(self)
            self.webSocket.disConnect()
            self.webSocket.delegate = nil
            self.stopPing()
        } else {
            self.webSocket.sendPingData(data: data!) {}
        }
    }
}


extension SignalingClient: WebSocketProviderDelegate {
    func webSocketCancelled(_ webSocket: WebSocketProvider) {
        Log.vLog(level: .error, "-----------------> webSocketDidConnect func ❤️")
    }
    
    func webSocket(_ webSocket: WebSocketProvider, didReceiveData text: String) {
        self.socketDelegateProcessQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            let dic = text.toDictionary()
            
            let messageType     = (dic["messageType"] as? String) ?? ""
            let messagePayload  = (dic["messagePayload"] as? String) ?? ""
            let senderClientId  = (dic["senderClientId"] as? String) ?? ""
            
            Log.vLog(level: .notice, "receive senderClientId: \(senderClientId) messageType: \(messageType)")
            
            switch MessageTypeEnum(rawValue: messageType ) {
            case .PEER_IN:
                Log.vLog(level: .warning, "PEER_IN 💚❤️ step5")
                let payload = messagePayload
                let role = self.getClientRoleModel(dictStr: payload)
                self.delegate?.signalPeerIn(recipientClientId: senderClientId, role: role)
                break
            case .PEER_OUT:
                Log.vLog(level: .warning, "PEER_OUT❤️")
                let payload = messagePayload
                let role = self.getClientRoleModel(dictStr: payload)
                self.delegate?.signalPeerOut(recipientClientId: senderClientId, role: role)
                break
            case .SDP_OFFER:
                Log.vLog(level: .warning, "SDP_OFFER💚")
                self.delegate?.signalSdpOffer(recipientClientId: senderClientId)
                break
            case .SDP_ANSWER:
                Log.vLog(level: .warning, "SDP_ANSWER 💚❤️ step7")
                self.delegate?.signalSdpAnswer(payload: messagePayload)
                break
            case .ICE_CANDIDATE:
                Log.vLog(level: .warning, "ICE_CANDIDATE 💚❤️ step9")
                self.delegate?.signalIceCandidate(payload: messagePayload)
                break
            default: break
                
            }
        }
    }
    
    func webSocketDidConnect(_ webSocket: WebSocketProvider) {
        Log.vLog(level: .info, "-----------------> webSocketDidConnect func")
        self.socketDelegateProcessQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.delegate?.signalClientDidConnect(self)
        }
    }
    
    func webSocketDidDisconnect(_ webSocket: WebSocketProvider, code: UInt16) {
        Log.vLog(level: .warning, "-----------------> webSocketDidDisconnect func code: \(code) ")
        self.socketDelegateProcessQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            Log.vLog(level: .error, "-----------------> webSocketDidDisconnect func code: \(code) ")
            self.delegate?.signalClientDidDisconnect(self, code: code)
            return
        }
        
        if code == users_limit_code || isPauseTimerOut {
            //达到连接上限
            //debugPrint("-----------------> 达到连接上限")
            Log.vLog(level: .error, "-----------------> webSocketDidDisconnect func 达到连接上限 或 暂停超时 code: \(code) ")
            return
        }
        
        // try to reconnect every two seconds
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
            Log.vLog(level: .error, "Trying to reconnect to signaling server...")
            guard (self?.delegate) != nil else{
                return
            }
            
            guard (self?.webSocket.delegate) != nil else {
                return
            }
            self?.webSocket.connect()
        }
    }
    
    func webSocket(_ webSocket: WebSocketProvider, didReceiveData data: Data) {
        let newStr = String(data: data, encoding: String.Encoding.utf8)
        Log.vLog(level: .info, "webSocket didReceiveData: \(newStr!) ❤️💚 step4-2")
    }
}

