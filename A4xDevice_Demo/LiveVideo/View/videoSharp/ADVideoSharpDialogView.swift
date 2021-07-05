//
//  ADVideoSharpDialogView.swift
//  AddxAi
//
//  Created by kzhi on 2019/9/4.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import A4xBaseSDK
import A4xWebRTCSDK

class ADVideoSharpDialogView : UIControl {
    var selectBlock : ((A4xVideoSharpType)->Void)?
    
    override init(frame: CGRect = .zero ) {
        super.init(frame: frame)
        print("ADVideoSharpDialogView ==> init")
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        print("ADVideoSharpDialogView ==> deinit")
    }
    lazy var dialog : ADVideoSharpDialog = {
        let temp = ADVideoSharpDialog()
        self.addSubview(temp)
        return temp
    }()
    
    func hidden(animailEnd : (()->Void)?){
        UIView.animate(withDuration: 0.3, animations: {
            self.dialog.transform = .init(scaleX: 0.01, y: 0.01)
        }) { (f) in
            animailEnd?()
        }
    }
    
    func show(atTargetRect rect : CGRect , dataSource : [A4xVideoSharpType] , select : A4xVideoSharpType? ,animailEnd : (()->Void)?) {
       
        self.dialog.snp.makeConstraints { (make) in
            make.centerX.equalTo(rect.midX)
            make.bottom.equalTo(self.snp.bottom).offset(-(self.frame.size.height - rect.minY + 5))

        }
        self.dialog.selectDataBlock = selectBlock
        self.dialog.dataSouces = dataSource
        self.dialog.selectData = select
        self.layoutIfNeeded()
        
        weak var weakSelf = self
        self.dialog.transform = .init(scaleX: 0.01, y: 0.01)
        UIView.animate(withDuration: 0.3, animations: {
            //动画效果
            weakSelf?.dialog.transform = .init(scaleX: 1, y: 1)
        }) { (f) in
            animailEnd?()
        }
    }
}
