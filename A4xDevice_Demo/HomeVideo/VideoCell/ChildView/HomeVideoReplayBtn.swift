//
//  HomeVideoReplayBtn.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/2/12.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import A4xBaseSDK

class HomeVideoReplayBtn: UIControl {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(white: 0.8, alpha: 1)
        self.layer.cornerRadius = 12
        self.clipsToBounds = true
        
        self.nameV?.isHidden = false
        self.imageV?.isHidden = false
    }
    
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize{
        return CGSize(width: 50, height: 24)
    }
    
    //MARK:- view 创建
    lazy var imageV : UIImageView? = {
        let temp = UIImageView()
        temp.image = UIImage(named: "video_replay")
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.left.equalTo(9)
            make.centerY.equalTo(self.snp.centerY)
        })
        return temp
    }()
    
    lazy var nameV : UILabel? = {
        let temp = UILabel()
        temp.textColor = UIColor(white: 0.6, alpha: 1)
        temp.font = ADTheme.B2
        self.addSubview(temp)
        
        temp.text = R.string.localizable.replay()
        
        temp.snp.makeConstraints({ (make) in
            make.left.equalTo(self.imageV!.snp.right).offset(4)
            make.right.equalTo(self.snp.right).offset(-9)
            make.centerY.equalTo(self.snp.centerY)
        })
        return temp
    }()

}
