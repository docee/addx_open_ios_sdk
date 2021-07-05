//
//  ADHomeNoWifiView.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/7/18.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import A4xBaseSDK

class ADHomeNoWifiView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.hex(0xFCDFDF)
//        self.closeButton.isHidden = false
        self.imageView.isHidden = false
        self.titleLable.isHidden = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateInfo() {
        self.titleLable.text = R.string.localizable.failed_to_get_information_and_try()
    }
    
    var colseBlock: (() -> Void)?
    
//    lazy
//    var closeButton : UIButton = {
//        let temp = UIButton()
//        self.addSubview(temp)
//        temp.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
//        temp.setImage(R.image.home_error_close(), for: .normal)
//        temp.snp.makeConstraints({ (make) in
//            make.right.equalTo(self.snp.right).offset(-10)
//            make.centerY.equalTo(self.snp.centerY)
//            make.size.equalTo(CGSize(width: 40.auto(), height: 40.auto()))
//        })
//
//        return temp
//    }()
    
    lazy var imageView: UIImageView = {
        let temp  = UIImageView()
        temp.contentMode = .center
        temp.image = R.image.no_net_warming()
        self.addSubview(temp)
        temp.snp.makeConstraints({ (make) in
            make.left.equalTo(16.auto())
            make.centerY.equalTo(self.snp.centerY)
            make.size.equalTo(CGSize(width: 24.auto(), height: 24.auto()))
        })
        return temp
    }()
    
    lazy var titleLable: UILabel = {
        let temp = UILabel()
        temp.textColor = UIColor.hex(0x645757)
        temp.font = ADTheme.B1
        temp.text = R.string.localizable.failed_to_get_information_and_try()
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.left.equalTo(imageView.snp.right).offset(15.auto())
            make.right.equalTo(self.snp.right).offset(-16.auto())
            make.centerY.equalTo(self.snp.centerY)
        })

        return temp
    }()
    
    @objc
    private func closeAction() {
        self.colseBlock?()
    }
}
