//
//  SessionDescription.swift
//  WebRTC-Demo
//
//  Created by Stasel on 20/02/2019.
//  Copyright © 2019 Stasel. All rights reserved.
//

import Foundation
import WebRTC


/// This struct is a swift wrapper over `RTCSessionDescription` for easy encode and decode
class SessionDescription: NSObject {
    let sdp: RTCSessionDescription
    let recipientClientId: String
    init(from sdp: RTCSessionDescription,recipientClientId: String) {
        self.sdp = sdp
        self.recipientClientId = recipientClientId
    }
    
    func offerJsonData() -> Data {
        let sdpdic:[String : String] = [
            "sdp":self.sdp.sdp,
            "type":"offer"
        ]
        
        let sdpdicData = try! JSONSerialization.data(withJSONObject: sdpdic,options: [])
        var sdpJson: String = String(data: sdpdicData,encoding:String.Encoding.utf8) ?? ""
        sdpJson = sdpJson.components(separatedBy: "\\/").joined(separator: "/")
        Log.vLog(level: .notice, "SDP_OFFER sdpJson:\(sdpJson)")
        let data:[String: String] = [
            "action": "SDP_OFFER",
            "messagePayload": sdpJson.base64Encoding(),
            "recipientClientId": self.recipientClientId
        ]
        let encoder = JSONEncoder()
        let json = try! encoder.encode(data)
        return json
    }
    
    func answerJsonData() -> Data {
        let sdpdic:[String : String] = [
            "sdp":self.sdp.sdp,
            "type":"answer"
        ]
        Log.vLog(level: .notice, "SDP_ANSWER sdpTypeStr: \(String(sdp.type.rawValue))")
        let sdpdicData = try! JSONSerialization.data(withJSONObject: sdpdic,options: [])
        var sdpJson: String = String(data: sdpdicData,encoding:String.Encoding.utf8) ?? ""
        sdpJson = sdpJson.components(separatedBy: "\\/").joined(separator: "/")
        Log.vLog(level: .notice, "SDP_ANSWER sdpJson: \(sdpJson)")
        let data:[String: String] = [
            "action": "SDP_ANSWER",
            "messagePayload": sdpJson.base64Encoding(),
            "recipientClientId": self.recipientClientId
        ]
            
        let encoder = JSONEncoder()
        let json = try! encoder.encode(data)
        return json
    }
}
