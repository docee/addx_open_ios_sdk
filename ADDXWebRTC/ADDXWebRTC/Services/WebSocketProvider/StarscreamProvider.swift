//
//  StarscreamProvider.swift
//  WebRTC-Demo
//
//  Created by Stas Seldin on 15/07/2019.
//  Copyright © 2019 Stas Seldin. All rights reserved.
//

import Foundation
import Starscream

class StarscreamWebSocket: WebSocketProvider {

    weak var delegate: WebSocketProviderDelegate?
    private let socket: WebSocket
    
    init(url: URL) {
        let request = URLRequest(url: url)
        self.socket = WebSocket(request: request)
        self.socket.delegate = self
    }
    
    func connect() {
        self.socket.connect()
    }
    
    func disConnect() {
        self.socket.forceDisconnect()
    }
    
    func send(string: String) {
        self.socket.write(string: string)
    }
    
    func sendPingData(data:Data,completion: (() -> ())?){
        self.socket.write(ping: data, completion: completion)
    }
}

extension StarscreamWebSocket: Starscream.WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            Log.vLog(level: .notice, "websocket is connected: \(headers) 💚❤️ step4")
            self.delegate?.webSocketDidConnect(self)
        case .disconnected(let reason, let code):
            Log.vLog(level: .warning, "websocket is disconnected: \(reason) with code: \(code)")
            self.delegate?.webSocketDidDisconnect(self, code: code)
        case .text(let string):
            Log.vLog(level: .notice, "Received text: \(string)")
            self.delegate?.webSocket(self, didReceiveData: string)
        case .binary(let data):
            Log.vLog(level: .notice, "Received data: \(data.count)")
            self.delegate?.webSocket(self, didReceiveData: data)
        case .ping(let data):
            if data != nil {
                Log.vLog(level: .warning, "Received ping data: \(data!.count)")
                self.delegate?.webSocket(self, didReceiveData: data!)
            }
            break
        case .pong(let data):
            if data != nil {
                Log.vLog(level: .warning, "Received pong data: \(data!.count)")
                self.delegate?.webSocket(self, didReceiveData: data!)
            }
            break
        case .viabilityChanged(let viabilityChanged):
            Log.vLog(level: .warning, "websocket is viabilityChanged: \(viabilityChanged)")
            break
        case .reconnectSuggested(let reconnectSuggested):
            Log.vLog(level: .warning, "websocket is reconnectSuggested: \(reconnectSuggested)")
            break
        case .cancelled:
            Log.vLog(level: .warning, "websocket is cancelled")
            self.delegate?.webSocketCancelled(self)
            break
        case .error(let err):
            Log.vLog(level: .error, "websocket is error: \(err.debugDescription)")
            break
        }
    }
    
    func websocketDidConnect(socket: WebSocketClient) {
        Log.vLog(level: .warning, "websocketDidConnect func")
        self.delegate?.webSocketDidConnect(self)
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        Log.vLog(level: .notice, "websocketDidDisconnect func error: \(error.debugDescription)")
        self.delegate?.webSocketDidDisconnect(self, code: 0)
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        Log.vLog(level: .notice, "websocketDidReceiveMessage text: " + text)
        self.delegate?.webSocket(self, didReceiveData: text)
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        Log.vLog(level: .notice, "websocketDidReceiveData data")
        self.delegate?.webSocket(self, didReceiveData: data)
    }
}
