//
//  ADDXWebRTCProtocol.swift
//  ADAutoView
//
//  Created by kzhi on 2020/7/20.
//

import Foundation
import UIKit

public protocol ADDXPlayerCallBackDelegate : class {
    
    /// 直播视频连接状态变更
    /// - Parameters:
    ///   - sender: 当前播放器
    ///   - state: 播放状态
    func addxVideoStateChange(sender : ADDXPlayerProtocol? , state : ADWebRTCPlayerControllerState)
    
    /// 视频录制状态
    /// - Parameters:
    ///   - sender: 当前播放器
    ///   - state: 录制状态
    func addxVideoRecordState(sender : ADDXPlayerProtocol? , state : ADDXRecordState)
    
    /// 获取播发器连接信息
    /// - Parameters:
    ///   - sender: 当前播放器
    ///   - comple: 异步返回播发器信息
    func addxVideoInfo(sender : ADDXPlayerProtocol? , comple : @escaping (ADDXWebRTCTicketModel?, _ state : ADWebRTCPlayerControllerState)->Void )
    
    /// 获取设备发送的命令
    /// - Parameters:
    ///   - sender: 当前播放器
    ///   - data: 数据内容
    ///   - isBinary: isBinary
    ///   - action: action
    func addxVideoDeviceCmd(sender : ADDXPlayerProtocol? ,data: Data, isBinary: Bool, action: String?)
    
    /// 双向语音波形图数据
    /// - Parameters:
    ///   - sender: 当前播放器
    ///   - thumbnail: 缩略图
    func addxVideoSpeakVoice(sender : ADDXPlayerProtocol? , localSpeakVoiceData voiceData: [Float])

    
    /// 视频连接日志
    /// - Parameters:
    ///   - sender: 播放器
    ///   - state: 状态
    func addxConnectLog(sender : ADDXPlayerProtocol? , state : ADDXWebRtcLogState)
}

public protocol ADDXWebRTCPlayerBaseProtocol : class {
    
    /// 视频的View
    var renderView : UIView? {
        get
    }
    
    /// 视频大小
    var videoSize : CGSize? {
        get
    }
    
    /// sd 传输速率
    var byteRate: Double {
        get
    }
    
    /// 对话音量
    var audioEnable : Bool {
        set get
    }
    
    /// 播放音量
    var speakEnable : Bool{
        set get
    }
    
    /// 播放状态
    var playerState : ADWebRTCPlayerControllerState {
        get
    }
    
    /// 开启直播
    /// - Parameter startTime: 开启时间 ，如果开启时间为空为直播
    func start(startTime : TimeInterval? , type : ADDXWebRTCPlayerVideoSharpType)
    
    /// 停止直播
    func stop()
    
    /// 暂停
    func pause(tips : String?)

    /// 获取缩率图
    func thumbnail(comple : @escaping (UIImage?)->Void)
    
    /// 开始录制视频
    func startRecord()
    
    /// 停止录制视频
    /// - Parameters:
    ///   - comple: 如果`protocol`为空调用
    func stopRecord(comple : ((ADDXRecordState) -> Void)?)
    
    
}

public protocol ADDXWebRTCPlayerCmdProtocol : class {
    
    /// 给设备发送命令
    /// - Parameters:
    ///   - cmdType: 命令类型
    ///   - returnType: 返回值类型
    ///   - comple: 异步返回
    func sendCmd<Param : Codable , Result : Codable>(cmdType : ADDXRTCPlayerCmdState , param : Param?, returnType : Result.Type , comple : @escaping (_ data : Result? , _ error : ADDXCmdError?)->Void )
    
    func reloadVideoView()
    
    func beginConnect(comple : ((Bool)->Void)? )
}

public extension ADDXPlayerCallBackDelegate {
    func addxConnectLog(sender : ADDXPlayerProtocol? , state : ADDXWebRtcLogState) {
        
    }
}

public extension ADDXPlayerProtocol {
    func sendCmd<Result : Codable>(cmdType : ADDXRTCPlayerCmdState, returnType : Result.Type , comple : @escaping (_ data : Result? , _ error : ADDXCmdError?)->Void ) {
        let str : String? = nil
        self.sendCmd(cmdType: cmdType, param: str, returnType: returnType , comple: comple)
    }

}

/// 视频播放器
public protocol ADDXPlayerProtocol: ADDXWebRTCPlayerCmdProtocol, ADDXWebRTCPlayerBaseProtocol {
    
    var `protocol` : ADDXPlayerCallBackDelegate? {
        set get
    }
    
    static func instance() -> ADDXPlayerProtocol
}

