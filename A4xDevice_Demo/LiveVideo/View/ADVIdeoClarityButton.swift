//
//  ADVIdeoClarityButton.swift
//  AddxAi
//
//  Created by kzhi on 2019/9/12.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import A4xBaseSDK

class ADVIdeoClarityButton : UIButton {
    var title : String? {
        didSet {
            self.titleLable.text = title
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.titleLable.isHidden = false
//        self.borderView.isHidden = false

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    lazy var titleLable : UILabel = {
        let temp = UILabel()
        temp.font = ADTheme.B2
        temp.textColor = UIColor.white
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.centerY.equalTo(self.snp.centerY)
        })
        
        return temp
        
    }()
    
    lazy var borderView : UIView = {
        let temp  = UIView()
        temp.isUserInteractionEnabled = false
        temp.layer.borderWidth = 2
        temp.layer.borderColor = UIColor.white.cgColor
        temp.layer.cornerRadius = 2
        temp.backgroundColor = UIColor.clear
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.width.equalTo(self.titleLable.snp.width).offset( 6)
            make.height.equalTo(self.titleLable.snp.height).offset( 6)
            make.center.equalTo(self)

        })
        
        return temp
    }()
}
