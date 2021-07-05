//
//  IceCandidate.swift
//  WebRTC-Demo
//
//  Created by Stasel on 20/02/2019.
//  Copyright © 2019 Stasel. All rights reserved.
//

import Foundation
import WebRTC

/// This struct is a swift wrapper over `RTCIceCandidate` for easy encode and decode
class IceCandidate: NSObject {
    let sdp: String
    let sdpMLineIndex: Int32
    let sdpMid: String?
    let recipientClientId: String
    
    init(from iceCandidate: RTCIceCandidate, recipientClientId: String) {
        self.sdp = iceCandidate.sdp
        self.sdpMLineIndex = iceCandidate.sdpMLineIndex
        self.sdpMid = iceCandidate.sdpMid
        self.recipientClientId = recipientClientId
    }
    func iceJsonData() -> Data {
        let ice:[String: String] = [
            "sdpMid":self.sdpMid!,
            "sdpMLineIndex":String(self.sdpMLineIndex),
            "candidate":String(self.sdp)
        ]
        let encoder = JSONEncoder()
        let icejson = try! encoder.encode(ice)
        
        let data:[String: String] = [
            "action": "ICE_CANDIDATE",
            "messagePayload": String(data: icejson, encoding: .utf8)!.base64Encoding(),
            "recipientClientId": self.recipientClientId
        ]
        
        let json = try! encoder.encode(data)
        return json
    }
    var rtcIceCandidate: RTCIceCandidate {
        return RTCIceCandidate(sdp: self.sdp, sdpMLineIndex: self.sdpMLineIndex, sdpMid: self.sdpMid)
    }
}
