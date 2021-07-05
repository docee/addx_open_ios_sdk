//
//  Config.swift
//  WebRTC-Demo
//
//  Created by Stasel on 30/01/2019.
//  Copyright © 2019 Stasel. All rights reserved.
//

import Foundation


class ADDXWebRTCConfig: NSObject {
    
    let ticket:ADDXWebRTCTicketModel
    private static var _sharedInstance: ADDXWebRTCConfig?
    
    
    class func sharedInstance() -> ADDXWebRTCConfig {
        guard let instance = _sharedInstance else {
            _sharedInstance = ADDXWebRTCConfig()
            return _sharedInstance!
        }
        return instance
    }
    
    override init() {
        self.ticket = ADDXWebRTCTicketModel()
        super.init()
        self.initlizeTicket1()
    }
    
    func initlizeTicket1(){
        self.ticket.groupId = "group001"
        self.ticket.role = "viewer"
        self.ticket.clientId = "viewer003";
        self.ticket.recipientClientId = "master008"
        self.ticket.signalServerHost = "wss://signal-test.addx.live"
        let ice = ADDXWebRTCTicketIceServer()
        ice.username = "1678509235:Test"
        ice.url = ["turn:47.107.151.138:5349"]
        ice.credential = "N4swu70zg3SHdZGg3oVcGerYdGQ="
        self.ticket.iceServers = [ice]
    }
    
    func initlizeTicket2(){
        self.ticket.groupId = "group001"
        self.ticket.role = "viewer"
        self.ticket.clientId = "viewer003";
        self.ticket.recipientClientId = "master008"
        self.ticket.signalServerHost = "wss://signal-test.addx.live"
        let ice = ADDXWebRTCTicketIceServer()
        ice.username = "test"
        ice.url = ["stun:118.89.227.65:3478", "turn:118.89.227.65:3478"]
        ice.credential = "123456"
        self.ticket.iceServers = [ice]
    }

}
