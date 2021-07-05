//
//  ADDialogTitleItem.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/1/31.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import A4xBaseSDK
import SnapKit

class ADDialogTitleInfoItem: ADDialogCell {
    
    var selectModle : Bool = false {
        didSet {
            self.backgroundColor = selectModle ? self.selectColor : #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
    }
    
    var name : String? {
        didSet {
           self.aNameLable.text = name
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.aNameLable.isHidden = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var aNameLable: UILabel = {
        var temp: UILabel = UILabel();
        temp.font = ADTheme.B1
        temp.textColor = ADTheme.C1
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.left.equalTo(15.auto());
            make.top.equalTo(15.auto())
            make.bottom.equalTo(self.snp.bottom).offset(-15.auto())
            make.width.equalTo(self.snp.width).offset(-32.auto())
        })
        return temp;
    }();
    
}
