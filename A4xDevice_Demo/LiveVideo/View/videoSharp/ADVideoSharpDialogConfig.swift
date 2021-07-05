//
//  ADVideoSharpDialogConfig.swift
//  AddxAi
//
//  Created by kzhi on 2019/9/4.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import Foundation
import UIKit
import A4xBaseSDK
import A4xWebRTCSDK

extension UIView {
    func showSharpDialog(datas :  [A4xVideoSharpType] ,
                         select : A4xVideoSharpType? ,
                         comple : @escaping (A4xVideoSharpType) -> Void )
    {
        guard let keyWindown = UIApplication.shared.keyWindow else {
            print("UIApplication.shared.keyWindow nil")
            return
        }
        
        guard keyWindown.viewWithTag("sharep".hashValue) as? ADVideoSharpDialogView == nil else {
            print("UIApplication alerdy ADVideoSharpDialogView")
            return
        }
        weak var weakSelf = self
        let tem = ADVideoSharpDialogView(frame: keyWindown.bounds )
        
        weak var weakV = tem
        
        tem.selectBlock = { select in
            comple(select)
            if let w = weakV {
                weakSelf?.hiddenSharpDialog(sender: w)
            }
        }
        tem.tag = "sharep".hashValue
        tem.addTarget(self, action: #selector(hiddenSharpDialog(sender:)), for: .touchUpInside)
        keyWindown.addSubview(tem)
        tem.isUserInteractionEnabled = false
        
        let frame =  self.convert(self.bounds, to: keyWindown)
        tem.show(atTargetRect: frame, dataSource: datas, select: select ) {
            weakV?.isUserInteractionEnabled = true
        }
    }
    
    @objc
    func hiddenSharpDialog(sender : ADVideoSharpDialogView? = nil) {
        var sharpView : ADVideoSharpDialogView? = nil
        if sender != nil {
            sharpView = sender
        }else {
            guard let keyWindown = UIApplication.shared.keyWindow else {
                print("UIApplication.shared.keyWindow nil")
                return
            }
            
            guard let current = keyWindown.viewWithTag("sharep".hashValue) as? ADVideoSharpDialogView  else {
                print("UIApplication alerdy ADVideoSharpDialogView")
                return
            }
            sharpView = current
        }
        guard let shareV = sharpView else {
            return
        }
        
        weak var weakV = shareV
        shareV.isUserInteractionEnabled = false
        
        shareV.hidden() {
            weakV?.removeFromSuperview()
        }
    }
}



