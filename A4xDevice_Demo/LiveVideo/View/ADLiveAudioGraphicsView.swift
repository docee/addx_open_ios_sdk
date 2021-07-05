//
//  ADLiveAudioView.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/6/22.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import Accelerate
import A4xBaseSDK

class ADLiveAudioGraphicsView : UIView {
    private var recoredTimer : Timer?
    var maxLines : Int = 22
    var lineWith : CGFloat = 4
    var pointLocation : [Float]?
    
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
        load()
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
        self.recoredTimer?.fireDate = Date.distantFuture
    }
    
    @objc
    private func updateProgress(){
        self.setNeedsDisplay()
    }
    
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard self.pointLocation?.count ?? 0 > 0 else {
            return
        }
        let between = (rect.width - CGFloat(lineWith * 2) - CGFloat(maxLines) * lineWith ) / CGFloat(min(self.pointLocation!.count, maxLines) - 1)
        let height = (rect.height - CGFloat(lineWith * 2)) / 1.3
        let color = ADTheme.Theme
        color.set()
        let centerY = rect.height / 2

        let pointPath = UIBezierPath()
        pointPath.lineWidth = CGFloat(lineWith)
        pointPath.lineCapStyle = .round
        
        for index in 0..<min(self.pointLocation!.count, maxLines) {
            
            let value = self.pointLocation![index]
            let absValue = fabsf(value)
            let itemHeight = max(CGFloat(min(absValue, 1)) * height, lineWith)
            
            let rect = CGRect(x: lineWith + (between + lineWith) * index.toCGFloat , y: centerY - itemHeight / 2.0 , width: lineWith, height: itemHeight)
            
            let path = UIBezierPath(roundedRect: rect, cornerRadius: lineWith / 2 )
            pointPath.append(path)
            
        }
        pointPath.stroke()
        color.set() // 设置线条颜色
    }
}
