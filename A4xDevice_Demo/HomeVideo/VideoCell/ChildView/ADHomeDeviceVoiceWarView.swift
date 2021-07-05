//
//  ADHomeDeviceVoiceWarView.swift
//  AddxAi
//
//  Created by kzhi on 2020/9/2.
//  Copyright © 2020 addx.ai. All rights reserved.
//

import Foundation
import UIKit
import A4xBaseSDK

class ADHomeDeviceVoiceWarView : UIView {
    
    private var recoredTimer : Timer?
    var maxLines : Int = 30
    var lineWidth : CGFloat = 1.5
    var pointLocation : [Float]? = Array(repeating: 0.1, count: 50) {
        didSet {
            A4xLog("ADHomeDeviceVoiceWarView -> \(self) \(pointLocation?.count ?? 0)")
        }
    }
    let horPadding : CGFloat = 16.auto()
    let centerSpace : CGFloat = 0.auto()
    
    deinit {
        A4xLog("ADLiveAudioGraphicsView deinit")
    }
    
    override var isHidden: Bool {
        didSet {
            self.recoredTimer?.fireDate = isHidden ? Date.distantFuture : Date()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
        pointLocation?.removeAll()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func free(){
        self.recoredTimer?.invalidate()
    }
    
    func load(){
        self.recoredTimer = Timer(timeInterval: 1.0 / 15.0 , target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
        RunLoop.current.add(self.recoredTimer!, forMode: .common)
//        self.recoredTimer?.fireDate = Date.distantFuture
    }
    
    @objc
    private func updateProgress(){
        self.setNeedsDisplay()
    }
    
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        A4xLog("ADHomeDeviceVoiceWarView -> draw \(self) \(pointLocation?.count ?? 0)")

        guard self.pointLocation?.count ?? 0 > 0 else {
            return
        }
        
        let pointPath = UIBezierPath()
        pointPath.lineWidth = CGFloat(lineWidth)
        pointPath.lineCapStyle = .round
        
        let between : CGFloat = 3//((self.width  - centerSpace) / 2 - CGFloat(maxLines ) * lineWidth) / CGFloat(maxLines - 1)
        let height = (rect.height - CGFloat(lineWidth * 2)) * 0.8
        let color = UIColor.white
        color.set()
        let centerY = rect.height / 2
        
        for index in 0..<min(self.pointLocation!.count, maxLines) {
            let value = self.pointLocation![index]
            let absValue = fabsf(value)
            let itemHeight = max(CGFloat(min(absValue, 1)) * height, lineWidth)
            let rect = CGRect(x: (between + lineWidth) * index.toCGFloat , y: centerY - itemHeight / 2.0 , width: lineWidth, height: itemHeight)
            if rect.minX > horPadding && self.bounds.width - rect.maxX > horPadding {
                let path = UIBezierPath(roundedRect: rect, cornerRadius: lineWidth / 2 )
                pointPath.append(path)
            }
        }
        
//        for index in (0..<min(self.pointLocation!.count, maxLines)).reversed() {
//            let value = self.pointLocation![index]
//            let absValue = fabsf(value)
//            let itemHeight = max(CGFloat(min(absValue, 1)) * height, lineWidth)
//            let rect = CGRect(x: self.width - (between + lineWidth) * index.toCGFloat - lineWidth , y: centerY - itemHeight / 2.0 , width: lineWidth, height: itemHeight)
//            if self.bounds.width - rect.maxX > horPadding {
//                let path = UIBezierPath(roundedRect: rect, cornerRadius: lineWidth / 2 )
//                pointPath.append(path)
//            }
//        }
        
        pointPath.stroke()
        color.set() // 设置线条颜色
    }
}
