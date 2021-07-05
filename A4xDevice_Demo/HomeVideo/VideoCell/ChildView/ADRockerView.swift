//
//  ADRockerView.swift
//  AddxAi
//
//  Created by kzhi on 2019/11/21.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import Foundation
import UIKit
import A4xBaseSDK
import A4xWebRTCSDK

enum ADRockerType {
    case `default`
    case light
}

protocol ADRockerViewProtocol : class {
    func beginRocker(atView view : ADRockerView)
    func moveRocker(atView view : ADRockerView , moveToPoint point : CGPoint)
    func moveEnd(atView view : ADRockerView)
    func moveEndDelay(atView view : ADRockerView)
}

class ADRockerView : UIView {
    var pockerTimer : Timer?
    var isMoveIng : Bool {
        return pockerTimer != nil
    }
    
    private var type : ADRockerType = .default
    var beganPockerBlock : (()->Void)?
    var updatePockerBlock : ((CGPoint)->Void)?
    var endPockerBlock : (()->Void)?
    var endPockerBlockAfter : (()->Void)?
    weak var `protocol` : ADRockerViewProtocol? = nil
    
    init(frame: CGRect = .zero , type : ADRockerType = .default ) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.drawView.isHidden = false
        switch type {
        case .default:
            self.layer.contents = R.image.home_rocker_drag_bg()?.cgImage
            self.drawView.image = R.image.home_rocker_drag()

        case .light:
            self.layer.contents = R.image.home_rocker_drag_light_bg()?.cgImage
            self.drawView.image = R.image.home_rocker_light_drag()
        }
        
        self.addGestureRecognizer(self.dragGesture)
        self.addGestureRecognizer(self.tapGesture)
        self.tapGesture.require(toFail: self.dragGesture)
    }
    
    override var frame: CGRect {
        didSet {
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.drawView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var
    drawView : UIImageView = {
        let temp = UIImageView()
        temp.image = R.image.home_rocker_drag()
        temp.isUserInteractionEnabled = true
        self.addSubview(temp)
        temp.frame = CGRect(x: 0, y: 0, width: 86, height: 86)
        return temp
    }()
    
    lazy
    var tapGesture : UILongPressGestureRecognizer = {
        let tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.rockerTapAction(sender:)))
        tapGesture.delegate = self
        tapGesture.minimumPressDuration = 0
        return tapGesture
    }()
    
    lazy
    var dragGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.rockerDragAction(sender:)))
        tapGesture.delegate = self

        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        return panGesture
    }()
    
    @objc private
    func rockerTapAction(sender : UILongPressGestureRecognizer) {
        switch sender.state {
        case .failed:
            fallthrough
        case .cancelled:
            fallthrough
        case .ended:
            moveDragEnd()
        default:
            break
        }
    }
    
    @objc private
    func rockerDragAction(sender : UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            // 追踪按钮不可点击处理
//            let generator = UINotificationFeedbackGenerator()
//            generator.notificationOccurred(.success)
            self.beganPockerBlock?()
            self.protocol?.beginRocker(atView: self)
            break
        case .changed:
            let tran = sender.translation(in: self)
            self.moveDragCenter(movePoint: tran)
            sender.setTranslation(CGPoint.zero, in: self)
        case .ended:
            fallthrough
        case .cancelled:
            fallthrough
        case .failed:
            fallthrough
        default:
            // 打点事件（摇杆改变）
            let playVideoEM = A4xPlayVideoEventModel()
            playVideoEM.live_player_type = UserDefaults.standard.string(forKey: "live_player_type")
            A4xEventManager.endEvent(event:ADTickerPlayVideo.live_remoteControl_rotate(eventModel: playVideoEM))
            moveDragEnd()
            self.endPockerBlock?()
            self.protocol?.moveEnd(atView: self)
            // 5秒后释放追踪按钮
            DispatchQueue.main.a4xAfter(5) {
                self.endPockerBlockAfter?()
                self.protocol?.moveEndDelay(atView: self)
            }
        }
    }
    
    private
    func moveDragCenter(movePoint : CGPoint ) {
//        print("moveDragCenter movePoint \(movePoint)")
        let toCenter = CGPoint(x: self.drawView.center.x + movePoint.x , y: self.drawView.center.y + movePoint.y)
        let vaildCenter = vailDragView(ofCenter: toCenter)
        self.drawView.center = vaildCenter

    }
    
    private
    func moveDragCenter(toPoint : CGPoint) {
//        print("moveDragCenter toPoint \(toPoint)")
        pockerTimer?.invalidate()
        pockerTimer = Timer(timeInterval: 0.4, target: self, selector: #selector(pockerTimerUpdate(sender:)), userInfo: nil, repeats: true)
        RunLoop.current.add(pockerTimer!, forMode: .common)
        let point = vailDragView(ofCenter: toPoint)
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            self.drawView.center = point
            
        }) { (f) in
            
        }
    }
    
    @objc
    private func pockerTimerUpdate(sender : Timer){
//        print("moveDragCenter pockerTimerUpdate")
        var value = pointOfCenterValue(center: self.drawView.center)
        if abs(value.x) < 0.2 {
            value.x = 0
        }
        if abs(value.y) < 0.2 {
            value.y = 0
        }
        updatePockerBlock?(value)
        self.protocol?.moveRocker(atView: self, moveToPoint: value)
    }
    
    private
    func moveDragEnd(){
//        print("moveDragCenter moveDragEnd")
        pockerTimer?.fire()

        pockerTimer?.invalidate()
        pockerTimer = nil
        let superCenter : CGPoint = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            self.drawView.center = superCenter
            
        }) { (f) in
            
        }
    }
    
    private
    func maxDragRadio() -> CGFloat {
        return max(self.frame.width / 2 - self.drawView.frame.width / 2 + 6, 1)
    }
    
    private
    func pointOfCenterValue(center dragCenter : CGPoint) -> CGPoint {
        let maxRadio = maxDragRadio()
        let superCenter : CGPoint = CGPoint(x: self.bounds.midX, y: self.bounds.midY)

        return CGPoint(x: (dragCenter.x - superCenter.x  ) / maxRadio, y: (dragCenter.y - superCenter.y) / maxRadio)
    }
    
    private
    func vailDragView(ofCenter tapCenter : CGPoint) -> CGPoint {
        let maxRadio = maxDragRadio()
        
        let superCenter : CGPoint = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        
        let cOffsetPoint : CGPoint = CGPoint(x: tapCenter.x - superCenter.x, y: superCenter.y - tapCenter.y )
        let toCenter : CGFloat = sqrt(cOffsetPoint.x * cOffsetPoint.x + cOffsetPoint.y * cOffsetPoint.y)
        if toCenter < maxRadio {
            return tapCenter
        }
        
        
        let sinangle = asin(cOffsetPoint.x/toCenter)
        let cosangle = acos(cOffsetPoint.y/toCenter)
        
        return CGPoint(x: superCenter.x + maxRadio * sin(sinangle), y:superCenter.y -  maxRadio * cos(cosangle))
    }
    
}

extension ADRockerView : UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let shouldBegin = super.gestureRecognizerShouldBegin(gestureRecognizer)
        if gestureRecognizer is UILongPressGestureRecognizer {
            let location = gestureRecognizer.location(in: self)
            moveDragCenter(toPoint: location)
        }

        return shouldBegin
    }
}
