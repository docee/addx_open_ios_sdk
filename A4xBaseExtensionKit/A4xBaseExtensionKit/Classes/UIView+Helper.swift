//
//  UIView+Helper.swift
//  SwiftTemplet
//
//  Created by hsf on 2018/8/14.
//  Copyright © 2018年 BN. All rights reserved.
//

import UIKit

public extension UIView{
    
    var x: CGFloat {
        get {
            return frame.origin.x
        }
        set {
            frame.origin = CGPoint(x:newValue, y:frame.origin.y)
        }
    }
    
    var y: CGFloat {
        get {
            return frame.origin.y
        }
        set {
            frame.origin = CGPoint(x:frame.origin.x, y:newValue)
        }
    }
    
    var width: CGFloat {
        get {
            return frame.width
        }
        set {
            frame.size.width = newValue
        }
    }
    
    var height: CGFloat {
        get {
            return frame.size.height
        }
        set {
            frame.size.height = newValue
        }
    }
    
    var size: CGSize  {
        get {
            return frame.size
        }
        set{
            frame.size = newValue
        }
    }
    
    var origin: CGPoint {
        get {
            return frame.origin
        }
        set {
            frame.origin = newValue
        }
    }
    
    @objc var minX: CGFloat {
        get {
            return frame.minX
        }
    }
    
    @objc var minY: CGFloat {
        get {
            return frame.minY
        }
    }
    
    @objc var midX: CGFloat {
        get {
            return frame.midX
        }
    }
    
    @objc var midY: CGFloat {
        get {
            return frame.midY
        }
    }
    
    @objc var maxX: CGFloat {
        get {
            return frame.maxX
        }
    }
    
    @objc var maxY: CGFloat {
        get {
            return frame.maxY
        }
    }
    
    @objc var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = true
        }
    }
    
    /// 截取当前屏幕
    func takeScreenshot() -> UIImage {
        var imageSize = CGSize.zero
        let screenSize = UIScreen.main.bounds.size
        let orientation = UIApplication.shared.statusBarOrientation
        if orientation.isPortrait {
            imageSize = screenSize
        } else {
            imageSize = CGSize(width: screenSize.height, height: screenSize.width)
        }
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            for window in UIApplication.shared.windows {
                context.saveGState()
                context.translateBy(x: window.center.x, y: window.center.y)
                context.concatenate(window.transform)
                context.translateBy(x: -window.bounds.size.width * window.layer.anchorPoint.x, y: -window.bounds.size.height * window.layer.anchorPoint.y)
                
                if orientation == UIInterfaceOrientation.landscapeLeft {
                    context.rotate(by: .pi / 2)
                    context.translateBy(x: 0, y: -imageSize.width)
                } else if orientation == UIInterfaceOrientation.landscapeRight {
                    context.rotate(by: -.pi / 2)
                    context.translateBy(x: -imageSize.height, y: 0)
                } else if orientation == UIInterfaceOrientation.portraitUpsideDown {
                    context.rotate(by: .pi)
                    context.translateBy(x: -imageSize.width, y: -imageSize.height)
                }
                if window.responds(to: #selector(UIView.drawHierarchy(in:afterScreenUpdates:))) {
                    window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
                } else {
                    window.layer.render(in: context)
                }
                context.restoreGState()
            }
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let image = image {
            return image
        } else {
            return UIImage()
        }
    }
    
}
