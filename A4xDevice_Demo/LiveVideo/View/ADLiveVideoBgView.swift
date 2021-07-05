//
//  ADLiveVideoBgView.swift
//  AddxAi
//
//  Created by kzhi on 2020/6/22.
//  Copyright © 2020 addx.ai. All rights reserved.
//

import Foundation
import UIKit

class ADLiveVideoBgView : UIImageView  {
    var thumbImage : UIImage? {
        didSet {
            self.image = thumbImage
        }
    }
    
    var blueEffectEnable : Bool = true {
        didSet {
            self.weakBlueEffectView.isHidden = !blueEffectEnable
        }
    }
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.weakBlueEffectView.isHidden = false
        self.backgroundColor = UIColor.black

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var weakBlueEffectView : UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let tempV = UIVisualEffectView(effect: blurEffect)
        tempV.backgroundColor = UIColor.clear
        tempV.alpha = 0.8
        self.addSubview(tempV)
        
        tempV.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left)
            make.width.equalTo(self.snp.width)
            make.height.equalTo(self.snp.height)
            make.top.equalTo(0)
        }
        return tempV;
    }()
    
}
