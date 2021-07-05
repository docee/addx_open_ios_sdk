//
//  ADLiveVideoAnimailView.swift
//  AddxAi
//
//  Created by kzhi on 2021/1/4.
//  Copyright © 2021 addx.ai. All rights reserved.
//

import Foundation
import UIKit
import A4xBaseSDK

class ADLiveVideoAnimailView : UIView {
    static func showThumbnail(tapButton : UIView , image : UIImage , tipString : String , comple :@escaping ()->Void ){
        guard let keyWindown : UIWindow = UIApplication.shared.keyWindow else {
            comple()
            return
        }
        
        let bgView = UIView(frame: keyWindown.bounds)
        keyWindown.addSubview(bgView)
        
        let imageView : UIImageView = UIImageView()
        imageView.image = image
        imageView.frame = CGRect(x: 5, y: 5, width: 140, height: 80)
        imageView.layer.cornerRadius = 6
        imageView.alpha = 0
        bgView.addSubview(imageView)
        
        let lable : UILabel = UILabel()
        lable.textAlignment = .center
        lable.textColor = ADTheme.C3
        lable.alpha = 0
        lable.numberOfLines = 0
        lable.font = ADTheme.B3
        lable.text = tipString
        bgView.addSubview(lable)
        let lableSize = lable.sizeThatFits(CGSize(width: 140, height: 100))
        lable.frame = CGRect(x: 5, y: imageView.maxY + 3, width: 140, height: lableSize.height)
        
        let resultFrame = CGRect(x: tapButton.maxX + 10, y: tapButton.midY - imageView.height / 2 - 10, width: imageView.width + 10, height: lable.maxY + 3)
        
        
        UIView.animate(withDuration: 0.3) {
            bgView.backgroundColor = UIColor.white
        } completion: { (f) in
            UIView.animate(withDuration: 0.3) {
                bgView.cornerRadius = 10
                bgView.frame = resultFrame
                
            } completion: { (f) in
                UIView.animate(withDuration: 1) {
                    lable.alpha = 1
                    imageView.alpha = 1
                } completion: { (f) in
                    UIView.animate(withDuration: 0.5) {
                        bgView.frame = CGRect(x: -bgView.width, y: bgView.minY, width: bgView.width, height: bgView.height)
                    } completion: { (f) in
                        bgView.removeFromSuperview()
                        comple()
                    }

                }
            }
        }
    }
}
