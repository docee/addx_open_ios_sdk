//
//  ADDXWebRTCTicketModel.swift
//  WebRTC-Demo
//
//  Created by Hao Shen on 6/18/20.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import UIKit

public class ADDXWebRTCTicketIceServer: NSObject {
   public var url                 :   Array<String>? = Array()
   public var username            :   String?
   public var credential          :   String?
}
public class ADDXWebRTCTicketModel: NSObject {
   public var recipientClientId   :   String?
   public var traceId             :   String?
   public var groupId             :   String?
   public var role                :   String?
   public var clientId            :   String?
   public var iceServers          :   Array<ADDXWebRTCTicketIceServer> = Array()
   public var signalServerHost    :   String?
   public var sign                :   String?
   public var time                :   String?
   public var name                :   String?
   public var signalPingInterval  :   Int?
   public var dataChannelOpenTime :   Int64 = Int64(Date().timeIntervalSince1970)
   private var _signalingServerUrl : URL?
    public var appStopLiveTimeout  : Int?
//   private var  maxAllocationLimit : Int?
   public var signalingServerUrl  :   URL? {
        get{
            if signalServerHost != nil && groupId != nil && role != nil  && clientId != nil {
                let timeStr = time ?? ""
                let signStr = sign ?? ""
                let nameStr = name ?? ""
                let urlStr = signalServerHost! + "/" + groupId! + "/" + role! + "/" + clientId! + "?" + "traceId=" + traceId! + "&" + "time=" + timeStr + "&" + "sign=" + signStr + "&" + "name=" + nameStr
                let encodeurlStr = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                _signalingServerUrl = URL(string: encodeurlStr ?? "")
            }
            return _signalingServerUrl
        }
    }
    public func copyModelnfo(ticket: ADDXWebRTCTicketModel){
        self.recipientClientId = ticket.recipientClientId
        
    }
    public func modelIsVaild() -> Bool {
        self.logDescriptionForConfig()
        if StringIsEmpty(value: self.groupId as AnyObject?) {
            return false
        }
        if StringIsEmpty(value: self.role as AnyObject?) {
            return false
        }
        if StringIsEmpty(value: self.clientId as AnyObject?) {
            return false
        }
        if StringIsEmpty(value: self.recipientClientId as AnyObject?) {
            return false
        }
        if StringIsEmpty(value: self.signalServerHost as AnyObject?) {
            return false
        }
        let signalingServerUrl = self.signalingServerUrl
        if signalingServerUrl == nil{
            return false
        }
        if StringIsEmpty(value: signalingServerUrl!.path as AnyObject?) {
            return false
        }
        if self.iceServers.count <= 0{
            return false
        }
        return true
    }
    private func logDescriptionForConfig(){
        Log.vLog(level: .notice, "update config start👇")
        Log.vLog(level: .notice, "groupId: \(self.groupId ?? "")")
        Log.vLog(level: .notice, "roleId: \(self.role ?? "")")
        Log.vLog(level: .notice, "clientId: \(self.clientId ?? "")")
        Log.vLog(level: .notice, "recipientClientId: \(self.recipientClientId ?? "")")
        Log.vLog(level: .notice, "signalingServerHost: \(self.signalServerHost ?? "")")
        Log.vLog(level: .notice, "signalingServerUrl: \(self.signalingServerUrl?.absoluteString ?? "")")
        Log.vLog(level: .notice, "webRTCIceServers: \(self.iceServers)")
        for ice in self.iceServers {
            Log.vLog(level: .notice, "webRTCIceServers ice url: \(ice.url ?? []) ice username:\(ice.username ?? "") ice credential: \(ice.credential ?? "")")
        }
        Log.vLog(level: .notice, "update config end👆")
    }
    private func StringIsEmpty(value: AnyObject?) -> Bool {
        //首先判断是否为nil
        if (nil == value) {
            //对象是nil，直接认为是空串
            return true
        }else{
            //然后是否可以转化为String
            if let myValue  = value as? String{
                //然后对String做判断
                return myValue == "" || myValue == "(null)" || 0 == myValue.count
            }else{
                //字符串都不是，直接认为是空串
                return true
            }
        }
    }
}
