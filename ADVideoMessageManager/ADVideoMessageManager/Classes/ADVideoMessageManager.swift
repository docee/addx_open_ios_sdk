//
//  ADVideoMessageManager.swift
//  ADVideoMessageManager
//
//  Created by kzhi on 2020/12/8.
//

import Foundation
import UIKit
public enum ADVideoMessageFilterType {
    case all
    case none
    case id(id : String?)
}


public class ADVideoMessageManager {
    public var filter : ADVideoMessageFilterType?
    public static let shared = ADVideoMessageManager()
    
    public var config : ADVideoMessageConfig? {
        didSet {
            config?.enableChangeBlock = { [weak self] in
                if !(self?.config?.enable ?? false) {
                    self?.hiddenMessage()
                }
            }
        }
    }

    public weak var inView : UIView? {
        didSet {
            if messageView.superview != nil {
                messageView.removeFromSuperview()
            }
        }
    }
    
    
    /// 消息格式
    /// - Parameter dict: {
    ///  "id": 2924129,
    ///    "videoUrl": "videoURl",
    ///    "timestamp": 1607915072,
    ///    "serialNumber": "7819097212940196d6076162ef2e5d2d",
    ///    "tags": "person",
    ///    "imageUrl": "https:imageURl",
    ///    "deviceName": "Vicoo智能摄像机",
    ///    "adminName": "Jason",
    ///    "traceId" : 2222
    ///    "pushInfo": "发现有人"
    ///  }
    public func recordMessage(dict : Dictionary<String,Any>){
        if self.messageView.superview == nil {
            self.inView?.insertSubview(self.messageView, at: 100)
            self.messageView.superViewUpdate()
        }
        assert(self.inView != nil , "请设置展示的view")
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
            let decoder = JSONDecoder()
            if let modle  = try? decoder.decode(ADVideoMessageModel.self, from: data) {
                self.messageView.recordMessage(message: modle)
            }
        }
    }
    public func hiddenMessage(){
        self.messageView.hiddenMessage()
    }
    
    public func resetMessageCount() {
        self.messageView.resetMessageCount()
    }
    
    private
    lazy var messageView : ADVideoMessageView = {
        let temp = ADVideoMessageView()
        return temp
    }()
    
    
}

extension ADVideoMessageManager {
    
    
}
