//
//  ADDXErrorType.swift
//  ADAutoView
//
//  Created by kzhi on 2020/7/21.
//

import Foundation
import XCGLogger

public enum ADDXWebRtcLogState {
    case start(type : String?)
    
    case startTicket
    case startUpdateTicket
    case loadTicket(ticket : ADDXWebRTCTicketModel)
    case loadTicketError

    case socketConnect
    case socketConnected
    case socketError(error : Int)
    
    case peerIn
    case peerNew
    case peerConnecting
    case peerConnected
    case peerDisconnected
    case peerFailed
    case peerClosed
    case peerOut
    
    case offer
    case answer
    case firstFrame
    
    case iceNew
    case iceChecking
    case iceConnected
    case iceCompleted
    case iceFailed
    case iceDisconnected
    case iceClosed
    case iceCount
    
    case dataChannel
    case sendCmd(action : String? , flag : Bool)
    
    case videoConnectError(error : ADDXError?)
    case videoConnected(recordVideo : Bool , p2pinfo : (isRealy : Bool , p2pInfo : [[String : String]])?)
    case videoInterrupt // 视频连接过程中 中断
    case videoStop      // 视频正常
    case videoPause(reasion : String?)
}

public enum ADWebRTCPlayerControllerState {
    ///  默认状态
    case ready
    ///  视频连接中
    case connecting
    ///  视频连接成功
    case connect
    ///  视频播放命令已经发送
    case play
    ///  视频连接正在播放
    case playing
    ///  视频暂挺
    case pause
    ///  连接断开
    case disConnect
    ///  直播异常
    case error(error : ADDXError)


    public static func == (lhs: ADWebRTCPlayerControllerState, rhs: ADWebRTCPlayerControllerState) -> Bool {
        switch (lhs, rhs) {
        case (.ready, .ready): return true
        case (.connecting, .connecting): return true
        case (.connect, .connect): return true
        case (.playing, .playing): return true
        case (.play, .play): return true
        case (.pause, .pause): return true
        case (.disConnect, .disConnect): return true
        case (.error, .error): return true
        case _: return false
        }
    }
}

public enum ADWebRtcConnectState {
    case ticket
    case connect
    case peerin
    case answer
    case ice
    case done
    public static func == (lhs: ADWebRtcConnectState, rhs: ADWebRtcConnectState) -> Bool {
        switch (lhs, rhs) {
        case (.ticket, .ticket): return true
        case (.connect, .connect): return true
        case (.peerin, .peerin): return true
        case (.answer, .answer): return true
        case (.ice, .ice): return true
        case (.done, .done): return true
        case _: return false
        }
    }
}

public enum ADDXVideoSharpType {
    case hb          //高清
    case standard    //标清
    case smooth      //流畅
    case auto        //自适应
}

public enum ADDXError : Error {
    case connect_time_out
    case connect_fail
    case users_limit
    case connect_info_error
    case device_leave
    case device_sleep
    case device_unkown
    case video_data_error(state : ADWebRtcConnectState)
    
    public func errorMsg() -> String {
        switch self {
        case .connect_time_out:
            return "Video connection timeout"
        case .connect_fail:
            return "Video connection failed"
        case .users_limit:
            return "Maximum number of video connections"
        case .connect_info_error:
            return "User information error"
        case .device_leave:
            return "The device video connection is disconnected"
        case .device_sleep:
            return "Camera is sleeping"
        case .device_unkown:
            return "The video socket connection is broken"
        case .video_data_error:
            return "Command send exception"
        }
    }
    
    public func errorCode() -> Int {
        switch self {
        case .connect_time_out:
            return -120
        case .connect_fail:
            return -10008
        case .users_limit:
            return -120000
        case .connect_info_error:
            return -10050
        case .device_leave:
            return -10010
        case .device_sleep:
            return -2133
        case .device_unkown:
            return -10020
        case .video_data_error:
            return -10030
        }
    }

}

/// 发送命令错误码
public enum ADDXCmdError : Error {
    /// 设备无sdcard或者被拔除
    case sdNoExist
    /// 设备无录像文件
    case sDNoVideo
    /// sdcard格式不支持，需要格式化
    case sdNeedFormat
    /// 当前正在有人观看录像
    case videoLimit
    /// 未知错误
    case unKnow
    
    init?(errorCode : String?) {
        let errorInt : Int = Int(errorCode ?? "0") ?? -1
        if errorInt == 0 {
            return nil
        }
        switch errorInt {
        case 1:
            self = .sdNoExist
        case 2:
            self = .sdNoExist
        case 3:
            self = .sdNeedFormat
        case 4:
            self = .videoLimit
        default:
            self = .unKnow
        }
    }
}

public enum ADDXRecordState {
    case start
    case end(filePath : URL?)
    case error(state : ADDXRecordErrorState)
}

public enum ADDXRecordErrorState {
    case start_noplayer
    case start_error
    case end_error
    case end_player_release

}

public enum ADDXRTCPlayerCmdState  {
    case play(sharpType : ADDXWebRTCPlayerVideoSharpType)
    case sdPlay(start : TimeInterval)
    case pause
    case sdPause
    case getSdlist(start : Int64 , end : Int64)
    case warning
    case setWhiteLight(enable : Bool)
    case getWhiteLight
    case setVideoDetail(value : ADDXWebRTCPlayerVideoSharpType)
    case getVideoDetail
    case other(action : String )
}

let Log = XCGLogger.default

public extension XCGLogger {
    func vLog(level: Level , _ closure: @autoclosure () -> Any?) {
        guard let closureResult = closure() else { return }

        let logString = "\n-----------> video " + String(describing: closureResult)
        self.logln(logString, level: level, userInfo : [:])
    }
}
