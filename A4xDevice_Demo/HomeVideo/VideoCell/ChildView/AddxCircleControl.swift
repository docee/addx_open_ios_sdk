//
//  AddxCircleControl.swift
//  AddxAi
//
//  Created by kzhi on 2021/3/25.
//  Copyright © 2021 addx.ai. All rights reserved.
//

import Foundation
import UIKit



enum AddxDirectionType : Float {
    case left
    case top
    case right
    case bottom
    
    init?(rawValue: Float) {
        var progress = rawValue / Float.pi / 2
        progress += 0.25 //top reset to 0
        while progress < 0 {
            progress += 1
        }
        while progress > 1 {
            progress -= 1
        }
        let stemp = Float(1) / Float(8)
        
        switch progress {
        case 0..<stemp , (stemp * 7)...1:
            self = .top
        case stemp..<stemp * 3:
            self = .right
        case (stemp * 3)..<(stemp * 5):
            self = .bottom
        case (stemp * 5)..<(stemp * 7):
            self = .left
        default:
            return nil
        }
    }
    
    func getPoint() -> CGPoint {
        switch self {
        case .left:
            return CGPoint(x: -1, y: 0)
        case .top:
            return CGPoint(x: 0, y: -1)
        case .right:
            return CGPoint(x: 1, y: 0)
        case .bottom:
            return CGPoint(x: 0, y: 1)
        }
    }

}

protocol AddxCircleControlProtocol : class {
    func onCircleTapAction(point : CGPoint)
}

class AddxCircleControl : UIView {
    weak var `protocol` : AddxCircleControlProtocol?
    var selectColor : UIColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.3161922089)
    var arrowColor : UIColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
    var visableProgress : CGFloat = 0.6
    var triangleProgress : CGFloat = 0.72
//    var visableColors : [UIColor] = [#colorLiteral(red: 0.9215686275, green: 0.9215686275, blue: 0.9215686275, alpha: 1) , #colorLiteral(red: 0.9803921569, green: 0.9803921569, blue: 0.9803921569, alpha: 1)]
    var visableColors : [UIColor] = [#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.3088613014) , #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.255859375)]
    var borderColor : UIColor?
    var lineColor : UIColor?
    var fullFanArea : CGPath?
    var allFanArea : [AddxDirectionType : CGPath] = [:]
    var onCircleTapBlock : ((CGPoint)->Void)?
    var selectType : (type : AddxDirectionType,path : CGPath)?
    
    var timer : Timer?

    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.addGestureRecognizer(tapGesture)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var frame: CGRect {
        didSet {
            self.setNeedsDisplay()
            self.updateAllallFanArea()
        }
    }
    
    lazy
    var tapGesture : UILongPressGestureRecognizer = {
        let tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.circleTapAction(sender:)))
        tapGesture.delegate = self
        tapGesture.minimumPressDuration = 0
        return tapGesture
    }()
    
    
    override func draw(_ rect: CGRect) {
      
        let context = UIGraphicsGetCurrentContext()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var colorComponents : [CGFloat] = []
        visableColors.forEach({ (cgc) in
            cgc.cgColor.components?.forEach({ (com) in
                colorComponents.append(com)
            })
        })
        let colorCount = visableColors.count
        var colorLocations : [CGFloat] = []
        for i in 0..<colorCount {
            colorLocations.append((CGFloat(i)/CGFloat(colorCount)))
        }
        
        guard let gradient = CGGradient(colorSpace: colorSpace, colorComponents: colorComponents, locations: colorLocations, count: colorCount) else {
            return
        }
        
        let startPoint = CGPoint(x: self.bounds.midX , y: 0 )
        let endPoint = CGPoint(x: self.bounds.midX , y: self.bounds.maxY)
        
        let maxRadio : CGFloat = self.bounds.width / 2
        let minRadio : CGFloat = maxRadio * (1 - visableProgress )
        let radioCenter = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let radio : CGFloat = minRadio + (maxRadio - minRadio) / 2
        context?.saveGState()
        context?.setLineWidth((maxRadio - minRadio))
        context?.addArc(center: radioCenter, radius: radio, startAngle: CGFloat(0), endAngle: CGFloat.pi * 2, clockwise: true)
        context?.replacePathWithStrokedPath()
        
        self.fullFanArea = context?.path
        context?.clip()
        
        context?.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: UInt32(0)))
        context?.restoreGState()
        
        let stepAngle : Float = Float.pi * 0.5
        var currentAngle = -Float.pi * 0.75
        let trriangleRadio : CGFloat = CGFloat(triangleProgress * maxRadio)
        
        
        for _ in 0..<4 {
            if let lineColor = self.lineColor {
                context?.move(to: CGPoint(x: radioCenter.x + minRadio * CGFloat(cosf(currentAngle  )), y: radioCenter.y + minRadio * CGFloat(sinf(currentAngle))))
                context?.setStrokeColor(lineColor.cgColor)
                context?.addLine(to: CGPoint(x: radioCenter.x + maxRadio * CGFloat(cosf(currentAngle  )), y: radioCenter.y + maxRadio * CGFloat(sinf(currentAngle ))))
                context?.closePath()
                context?.strokePath()
            }
           
                        
            let triangleAngle = currentAngle + stepAngle / 2
            if let type : AddxDirectionType = AddxDirectionType(rawValue: triangleAngle) {
                let triangleCenter = CGPoint(x: radioCenter.x + trriangleRadio * CGFloat(cosf(currentAngle + stepAngle / 2 )), y: radioCenter.y + trriangleRadio * CGFloat(sinf(currentAngle + stepAngle / 2)))
                let path = self.triangleRect(type: type, center: triangleCenter)
                context?.addPath(path)
                context?.setFillColor(arrowColor.cgColor)
                context?.fillPath()
                context?.closePath()
            }
            currentAngle += stepAngle
        }
        if let borderColor = self.borderColor {
            context?.setLineWidth(0.5)
            context?.setStrokeColor(borderColor.cgColor)
            context?.addArc(center: radioCenter, radius: maxRadio - 0.25, startAngle: CGFloat(0), endAngle: CGFloat.pi * 2, clockwise: true)
            context?.strokePath()
            context?.closePath()
            context?.addArc(center: radioCenter, radius: minRadio - 0.25, startAngle: CGFloat(0), endAngle: CGFloat.pi * 2, clockwise: true)
            context?.strokePath()
            context?.closePath()
        }
        
        
        if let select = selectType {
            context?.setFillColor(selectColor.cgColor)
            context?.addPath(select.path)
            context?.fillPath()
        }
       
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setNeedsDisplay()
        self.updateAllallFanArea()

    }
    
}

extension AddxCircleControl : UIGestureRecognizerDelegate{
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: self)
        if self.fullFanArea?.contains(location) ?? false {
            return true
        }
        return false
    }

    @objc private
    func circleTapAction(sender : UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            self.startTap(point: sender.location(in: self))
        case .changed:
            break
        case .ended:
            fallthrough
        case .cancelled:
            fallthrough
        case .failed:
            endTap()
        case .possible:
            break
        @unknown default:
            break
        }
    }
    
    // 摇杆控制开始 - new
    func startTap(point : CGPoint) {
        debugPrint("---------> startTap: \(Date())")
        let type = getTapType(point: point )
        self.selectType = type
        self.setNeedsDisplay()
        timer?.invalidate()
        // 发送指令频率
        timer = Timer(timeInterval: 0.2, target: self, selector: #selector(timerUpdate(sender:)), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .common)
        timer?.fire()
    }
    
    
    func endTap(){
        debugPrint("---------> endTap: \(Date())")
        self.selectType = nil
        self.setNeedsDisplay()
        timer?.invalidate()
    }
    
    func getTapType(point : CGPoint) -> (type : AddxDirectionType,path : CGPath)?{
        var select : (type : AddxDirectionType,path : CGPath)? = nil

        allFanArea.forEach { (type , path) in
            if select == nil && path.contains(point) {
                select = (type ,path)
            }
        }
        return select
    }
    
    @objc
    private func timerUpdate(sender: Timer) {
        debugPrint("---------> TimerUpdate: \(Date())")
        if let point = self.selectType?.type.getPoint() {
            self.onCircleTapBlock?(point)
            self.protocol?.onCircleTapAction(point: point)
        }
    }
}

extension AddxCircleControl {
    func updateAllallFanArea() {
        allFanArea.removeAll()
        let stepAngle : Float = Float.pi * 0.5
        var currentAngle = -Float.pi * 0.75
        let radioCenter = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let maxRadio : CGFloat = self.bounds.width / 2
        let minRadio : CGFloat = maxRadio * (1 - visableProgress)

        for _ in 0..<4 {
            let bPath = UIBezierPath()
            bPath.move(to: CGPoint(x: radioCenter.x + minRadio * CGFloat(cosf(currentAngle  )), y: radioCenter.y + minRadio * CGFloat(sinf(currentAngle))))
            bPath.addLine(to: CGPoint(x: radioCenter.x + maxRadio * CGFloat(cosf(currentAngle  )), y: radioCenter.y + maxRadio * CGFloat(sinf(currentAngle ))))
            bPath.addArc(withCenter: radioCenter, radius: maxRadio, startAngle: CGFloat(currentAngle), endAngle: CGFloat(currentAngle + stepAngle), clockwise: true)
            bPath.addLine(to: CGPoint(x: radioCenter.x + minRadio * CGFloat(cosf(currentAngle  + stepAngle )), y: radioCenter.y + minRadio * CGFloat(sinf(currentAngle + stepAngle))))
            bPath.addArc(withCenter: radioCenter, radius: minRadio, startAngle: CGFloat(currentAngle + stepAngle), endAngle: CGFloat(currentAngle), clockwise: false)
            bPath.close()
            if let type = AddxDirectionType(rawValue: currentAngle + stepAngle / 2) {
                allFanArea[type] = bPath.cgPath
            }
            currentAngle += stepAngle
        }
    }
    
    func fullFanAreaPath () -> UIBezierPath {
        let maxRadio : CGFloat = self.bounds.width / 2
        let minRadio : CGFloat = maxRadio * (1 - visableProgress )
        let radioCenter = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let radio : CGFloat = minRadio + (maxRadio - minRadio) / 2

        let path = UIBezierPath(arcCenter: radioCenter, radius: radio, startAngle: CGFloat(0), endAngle: CGFloat.pi * 2, clockwise: true)
        path.lineWidth = maxRadio - minRadio
        return path
    }
    
    func triangleRect(type : AddxDirectionType ,center : CGPoint , size : CGSize = CGSize( width: 15, height: 15) , margenTop : CGFloat = 3) -> CGPath {
        let path = UIBezierPath()
        switch type {
        case .left:
            path.move(to: CGPoint(x: center.x - size.width / 2 + margenTop, y: center.y))
            path.addLine(to:CGPoint(x: center.x + size.width / 2, y: center.y - size.height / 2))
            path.addLine(to:CGPoint(x: center.x + size.width / 2, y: center.y + size.height / 2))
        case .top:
            path.move(to:CGPoint(x: center.x , y: center.y - size.height / 2 + margenTop))
            path.addLine(to:CGPoint(x: center.x - size.width / 2, y: center.y + size.height / 2))
            path.addLine(to:CGPoint(x: center.x + size.width / 2, y: center.y + size.height / 2))
        case .right:
            path.move(to:CGPoint(x: center.x + size.width / 2 - margenTop, y: center.y))
            path.addLine(to:CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2))
            path.addLine(to:CGPoint(x: center.x - size.width / 2, y: center.y + size.height / 2))
        case .bottom:
            path.move(to:CGPoint(x: center.x , y: center.y + size.height / 2 - margenTop))
            path.addLine(to:CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2))
            path.addLine(to:CGPoint(x: center.x + size.width / 2, y: center.y - size.height / 2))
        }
        return path.cgPath
    }
}
