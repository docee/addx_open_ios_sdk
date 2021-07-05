//
//  ADDialogMenuItem.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/2/11.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import A4xBaseSDK

class ADDialogMenuItem: ADDialogCell {

    var dataModel :ADMenuInfoModel?{
        didSet{
            self.aNameLable.text = dataModel?.title!
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.aNameLable.isHidden = false;
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    lazy var aNameLable: UILabel = {
        var temp: UILabel = UILabel();
        temp.setContentHuggingPriority(UILayoutPriority.required, for: NSLayoutConstraint.Axis.horizontal)
        temp.font = ADTheme.H4
        temp.textColor = UIColor.black
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.left.equalTo(self.snp.left).offset(15)
            make.centerY.equalTo(self.snp.centerY)
            make.bottom.equalTo(self.snp.bottom).offset(-15)
            make.top.equalTo(self.snp.top).offset(15)
        })
        return temp;
    }();
}
