//
//  ADHomeEnteryView.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/2/11.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import A4xBaseSDK

//class ADAddCameraButton : UIButton {
//    override class var layerClass: AnyClass {
//        return CAGradientLayer.self
//    }
//    override init(frame: CGRect = .zero) {
//        super.init(frame: frame)
//        if let layer : CAGradientLayer = self.layer as? CAGradientLayer {
//            layer.colors = [UIColor.hex(0x04B5DD).cgColor, UIColor.hex(0x5CC7E0).cgColor]
//            layer.locations = [0, 1]
//            layer.startPoint = CGPoint(x: 1.01, y: 0.5)
//            layer.endPoint = CGPoint(x: 0.5, y: 0.5)
//        }
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}

class ADHomeEnteryView: UIView {

    override init(frame: CGRect) {
        super.init(frame : frame)
        self.iconImageV.isHidden = false
        self.nameLabelV.isHidden = false
        self.titltLabelV.isHidden = false
        self.addCameraBtn.isHidden = false
        self.backgroundColor = UIColor.white
        A4xLog("<----- ADHomeEnteryView deinit")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        A4xLog("-----> ADHomeEnteryView deinit")
    }
    
    func updateInfo(){
        self.nameLabelV.text = R.string.localizable.no_camera()
        self.titltLabelV.text = R.string.localizable.have_no_device()
        self.addCameraBtn.setTitle(R.string.localizable.add_camera_now(), for: UIControl.State.normal)

    }
    
    var addCameraBlock : (() -> Void)?{
        didSet {
            if addCameraBlock != nil {
                weak var weakSelf = self
                self.addCameraBtn.addActionHandler({ (sender) in
                    weakSelf?.addCameraBlock?()
                }, for: UIControl.Event.touchUpInside)
            }
        }
    }
    
    lazy var iconImageV: UIImageView = {
        var temp: UIImageView = UIImageView()
        temp.image = UIImage(named: "device_manager_no_device")
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.centerY.equalTo(self.snp.centerY).offset(-60.auto())
        })
        return temp;
    }();
    
    lazy var nameLabelV: UILabel = {
        var temp: UILabel = UILabel();
        temp.textAlignment = NSTextAlignment.center
        temp.font = ADTheme.B0
        temp.textColor = ADTheme.C1
        temp.text = R.string.localizable.no_camera()
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.top.equalTo(self.iconImageV.snp.bottom).offset(40.auto())
        })
        return temp;
    }();
    
    lazy var titltLabelV: UILabel = {
        var temp: UILabel = UILabel();
        temp.textAlignment = NSTextAlignment.center
        temp.font = ADTheme.B2
        temp.lineBreakMode = .byCharWrapping
        temp.numberOfLines = 0
        temp.textColor = ADTheme.C4
        temp.text = R.string.localizable.have_no_device()
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.top.equalTo(self.nameLabelV.snp.bottom).offset(5.auto())
        })
        return temp;
    }();
    
    lazy var addCameraBtn: UIButton = {
        var temp: UIButton = UIButton();
        temp.layer.borderWidth = 0 
        temp.layer.cornerRadius = 24.auto()
        temp.clipsToBounds = true
        temp.setBackgroundImage(UIImage.buttonNormallImage, for: .normal)
        temp.setBackgroundImage(UIImage.buttonPressImage, for: .highlighted)
        temp.titleLabel?.font = ADTheme.H2
        temp.setTitle(R.string.localizable.add_camera_now(), for: UIControl.State.normal)
        temp.setTitleColor(UIColor.white, for: UIControl.State.normal)
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.top.equalTo(self.titltLabelV.snp.bottom).offset(30.auto())
            make.size.equalTo(CGSize(width: 200.auto(), height: 48.auto()))
        })
        return temp;
    }();
    
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if self.addCameraBtn.frame.contains(point) {
            return true
        }
        return false
    }
}
