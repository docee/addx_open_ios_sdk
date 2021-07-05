//
//  ADVideoMessageView.swift
//  ADVideoMessageManager
//
//  Created by kzhi on 2020/12/9.
//

import Foundation
import AutoInch
class ADVideoMessageView : UIView {
    static let messagePadding : CGFloat = 8.auto()
    static let animailDuration : TimeInterval = 0.3
    
    private var superWidth : CGFloat = 0
    
    private var messageCount = 0
    private var currentIsMoveBar : Bool = false
    private var currentIsMoveCount : Bool = false
    private var currentIsMoveCotent : Bool = false

    private var messageContentModle : ADVideoMessageModel?
    private var showContentMessage : Bool = false {
        didSet {
            if !showContentMessage  && !showCountMessage {
                lastCloseDateTimer = Date().timeIntervalSince1970
            }
        }
    }
    private var showCountMessage   : Bool = false{
        didSet {
            if !showContentMessage  && !showCountMessage {
                lastCloseDateTimer = Date().timeIntervalSince1970
            }
        }
    }
    
    private var lastCloseDateTimer : TimeInterval = 0
    
    convenience init() {
        self.init(frame : .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addGestureRecognizer(self.dragGesture)
        self.addGestureRecognizer(self.tapGestUre)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func superViewUpdate() {
        superWidth = self.superview?.frame.width ?? 0
    }
    
    func checkShowMessge() ->Bool {
        let datet = Date().timeIntervalSince1970
        if datet - lastCloseDateTimer > 2 {
            return true
        }
        return false
    }
    
    func hiddenMessage() {
        dragGesture.isEnabled = false

        UIView.animate(withDuration: 0.3) {
            self.messageContentView.moveTohidden()
            self.hiddenCountView()
        } completion: { (f) in
            self.dragGesture.isEnabled = true
            self.messageContentView.reset()

        }
    }
    
    func resetMessageCount() {
        messageCount = 0
        hiddenMessageCount()
    }
    
    func recordMessage(message : ADVideoMessageModel) {
        if !checkShowMessge() {
            return
        }
        if self.currentIsMoveBar || self.currentIsMoveCount {
            return
        }
        if !(ADVideoMessageManager.shared.config?.enable ?? false) {
            return
        }
        
        messageCount += 1
        if !self.showMessageContent(message: message){
            self.showMessageCount()
        }
    }
    
    lazy
    var dragGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.moveSmailProgress(sender:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        return panGesture
    }()
    
    lazy
    var tapGestUre : UITapGestureRecognizer =  {
        let oneTap = UITapGestureRecognizer(target: self, action:#selector(oneClick(tap:)))
        oneTap.numberOfTapsRequired = 1
        return oneTap
    }()
    
    func showMessageContent(message : ADVideoMessageModel) -> Bool{
      
        if !showContentMessage && !showCountMessage { //如果图文显示和数量显示  都不显示，来消息收展示消息
            messageContentModle = message
            showContentMessage = true //如果移除的是展示条，messageCount 应该是 > 2
            messageCountView.isHidden = true
            messageContentView.message = message
            let messageWidth = Int(superWidth - 2 * ADVideoMessageView.messagePadding)
            let height = max(100, messageContentView.sizeThatFits(CGSize(width: messageWidth, height: 400)).height)
            messageContentView.frame = CGRect(x: ADVideoMessageView.messagePadding, y: -height, width: CGFloat(messageWidth), height: height)
            var top : CGFloat = 20
            if #available(iOS 11.0, *) {
                top = self.safeAreaInsets.top
            }
            self.frame = CGRect(x: 0,  y: 0, width: superWidth , height: height + top)
            self.messageContentView.defaultMinX = top
            UIView.animate(withDuration: ADVideoMessageView.animailDuration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIView.AnimationOptions.allowAnimatedContent) { [weak self] in
                self?.messageContentView.frame = CGRect(x: ADVideoMessageView.messagePadding,  y: top, width: CGFloat(messageWidth), height: height)
            } completion: { (f) in
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.hiddenMessageCountent), object: nil)
                let time : TimeInterval = ADVideoMessageManager.shared.config?.pushShowTime ?? 5
                self.perform(#selector(self.hiddenMessageCountent), with: nil, afterDelay: time)
            }
            return true
        }
        return false
    }
    
    
    
    func showMessageCount(){
        guard messageCount > 1 else {
            return
        }
        if !showCountMessage && !showContentMessage { //如果图片和数量都不展示，不展示新的数量
            return
        }
        let messageWidth = Int(superWidth - 2 * ADVideoMessageView.messagePadding)
        let countViewHeight = self.messageCountView.sizeThatFits(CGSize(width: messageWidth, height: 1000)).height
        messageCountView.messageCount = messageCount - 1
        
        if !showCountMessage {
            showCountMessage = true
            messageCountView.isHidden = false
            messageCountView.frame = CGRect(x: self.messageContentView.frame.minX, y: self.messageContentView.frame.maxY - countViewHeight, width: messageContentView.frame.width, height: countViewHeight)
            self.frame = CGRect(x: 0,  y: 0, width: superWidth, height: self.messageContentView.frame.maxY + ADVideoMessageView.messagePadding + countViewHeight)

            UIView.animate(withDuration: ADVideoMessageView.animailDuration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIView.AnimationOptions.allowAnimatedContent) { [weak self] in
                let rect = CGRect(x: self?.messageContentView.frame.minX ?? 0,
                                  y: (self?.messageContentView.frame.maxY ?? 0) + (ADVideoMessageView.messagePadding),
                                                      width: self?.messageContentView.frame.width ?? 0,
                                                      height: countViewHeight)
                self?.messageCountView.frame = rect
            } completion: { (f) in
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.hiddenMessageCount), object: nil)
                let time : TimeInterval = ADVideoMessageManager.shared.config?.pushShowTime ?? 15
                self.perform(#selector(self.hiddenMessageCount), with: nil, afterDelay: time)
            }
        }else {
            if showCountMessage && !currentIsMoveCotent && !currentIsMoveCount{
                self.updateCountViewFrame()
            }
        }
    }
    
    
    @objc
    func hiddenMessageCount(){
        dragGesture.isEnabled = false
        UIView.animate(withDuration: 0.3) {
            self.hiddenCountView()
        } completion: { (f) in
            self.dragGesture.isEnabled = true
            self.hiddenCountView()
        }

      
    }
    
    @objc
    func hiddenMessageCountent(){
        dragGesture.isEnabled = false

        UIView.animate(withDuration: 0.3) {
            self.messageContentView.moveTohidden()
            self.updateCountViewFrame()
        } completion: { (f) in
            self.dragGesture.isEnabled = true
            self.messageContentView.reset()

        }
      
    }
    
    lazy var messageCountView : ADMessageCountView = {
        let temp = ADMessageCountView()
        self.addSubview(temp)
        return temp
    }()
    
    lazy var messageContentView :  ADVideoMessageContentView = {
        let temp = ADVideoMessageContentView()
        temp.messageContentHiddenBlock = { [weak self ] in
            self?.showContentMessage = false
        }
        self.addSubview(temp)
        return temp
    }()
    
    @objc private
    func oneClick(tap : UITapGestureRecognizer) {
        let point = tap.location(in: self)
        if self.messageContentView.frame.contains(point) {
            let point = tap.location(in: self.messageContentView)

            let type = self.messageContentView.locationView(ofPoint: point)
            if case .moveBar = type {
                UIView.animate(withDuration: 0.3) {
                    self.messageContentView.showBar()
                    self.updateCountViewFrame()
                }
            }else {
                ADVideoMessageManager.shared.config?.messageContentClick?(type ,messageContentModle)
                hiddenMessageCountent()
            }
         
            return
        }
        
        if self.messageCountView.frame.contains(point) {
            ADVideoMessageManager.shared.config?.messageCountClick?()
            messageCount = 0
            hiddenMessageCount()
        }
    }
    
    @objc private
    func moveSmailProgress(sender : UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            currentIsMoveBar = self.isMoveBar(sender: sender)
            currentIsMoveCount = self.isMoveCountView(sender: sender)
            currentIsMoveCotent = self.isMoveContentView(sender: sender)
        case .changed:
            let tran = sender.translation(in: self)
            if self.currentIsMoveCotent {
                messageContentView.moveBarTranform(yvalue: tran.y, isMoveBar: currentIsMoveBar)
                self.updateCountViewFrame()
            }else if currentIsMoveCount {
                self.moveCountViewFrame(move: tran.y)
            }
         
            sender.setTranslation(CGPoint.zero, in: self)
        case .ended:
            fallthrough
        case .cancelled:
            fallthrough
        case .failed:
            fallthrough
        default:
            UIView.animate(withDuration: ADVideoMessageView.animailDuration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIView.AnimationOptions.allowAnimatedContent) { [weak self] in
                guard let self = self else {
                    return
                }
                if self.currentIsMoveCotent {
                    self.messageContentView.updateBarVisable(isMoveBar: self.currentIsMoveBar)
                    self.updateCountViewFrame()
                }else if self.currentIsMoveCount  {
                    self.updateCountResultFrame()
                }
            } completion: { (f) in
                self.currentIsMoveBar = false
                self.currentIsMoveCount = false
                self.currentIsMoveCotent = false
                if !self.showContentMessage {
                    self.messageContentView.reset()
                }
            }

            
            debugPrint("move end")
        }
    }

    
    func hiddenCountView() {
        self.updateCountViewFrame()
        showCountMessage = false
    }
    
    func updateCountResultFrame() {
        if showContentMessage {
            if self.messageCountView.frame.midY < self.messageContentView.frame.maxY {
                showCountMessage = false
                messageCount = 1
            }
        }else {
            var top : CGFloat = 20
            if #available(iOS 11.0, *) {
                top = self.safeAreaInsets.top
            }
            if self.messageCountView.frame.midY < top {
                showCountMessage = false
            }
        }
        
        self.updateCountViewFrame()
    }
    
    func moveCountViewFrame(move : CGFloat) {
        var top : CGFloat = 0
        if self.showContentMessage && showCountMessage {
            top = (self.messageContentView.frame.maxY) + (ADVideoMessageView.messagePadding)
        }else {
            top = 20
            if #available(iOS 11.0, *) {
                top = self.safeAreaInsets.top
            }
            top += ADVideoMessageView.messagePadding
        }
        
        top = min(top, messageCountView.frame.minY + move)
        let rect = CGRect(x: self.messageContentView.frame.minX,
                          y: top,
                                              width: self.messageCountView.frame.width,
                                              height: messageCountView.frame.height)
        self.messageCountView.frame = rect
    }
    
    func updateCountViewFrame()  {
        if self.showContentMessage && showCountMessage {
            let rect = CGRect(x: self.messageContentView.frame.minX,
                              y: (self.messageContentView.frame.maxY) + ADVideoMessageView.messagePadding,
                                                  width: self.messageCountView.frame.width,
                                                  height: messageCountView.frame.height)
            self.messageCountView.frame = rect
            self.frame = CGRect(x: 0, y: 0, width: superWidth, height: self.messageCountView.frame.maxY)
        }else if showCountMessage{
            var top : CGFloat = 20
            if #available(iOS 11.0, *) {
                top = self.safeAreaInsets.top
            }
            let rect = CGRect(x: self.messageContentView.frame.minX,
                              y: top + ADVideoMessageView.messagePadding ,
                                                  width: self.messageCountView.frame.width,
                                                  height: messageCountView.frame.height)
            self.messageCountView.frame = rect
            self.frame = CGRect(x: 0, y: 0, width: superWidth, height: self.messageCountView.frame.maxY)
        }else if !showCountMessage {
            self.messageCountView.frame = CGRect(x: self.messageContentView.frame.minX, y: -self.messageCountView.frame.height, width: self.messageCountView.frame.width, height: self.messageCountView.frame.height)
            self.frame = CGRect(x: 0, y: 0, width: superWidth, height: self.messageContentView.frame.maxY)
        }
  
        
       
    }
    
    func isMoveBar(sender : UIPanGestureRecognizer) -> Bool {
        let conLocation = sender.location(in: messageContentView)
        let isMoveBar = messageContentView.isMoveBar(point: conLocation)
        return isMoveBar
    }
    
    func isMoveCountView(sender : UIPanGestureRecognizer) -> Bool {
        let conLocation = sender.location(in: self)
        let isMove = self.messageCountView.frame.contains(conLocation)
        return isMove
    }
    
    func isMoveContentView(sender : UIPanGestureRecognizer) -> Bool {
        let conLocation = sender.location(in: self)
        let isMove = self.messageContentView.frame.contains(conLocation)
        return isMove
    }
}
