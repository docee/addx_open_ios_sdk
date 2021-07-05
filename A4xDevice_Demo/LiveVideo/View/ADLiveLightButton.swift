//
//  ADLiveLightButton.swift
//  AddxAi
//
//  Created by kzhi on 2020/3/18.
//  Copyright © 2020 addx.ai. All rights reserved.
//

import UIKit

enum ADLiveLightEnum : Int {
    case on
    case off
    case loading
}

class ADLiveLightButton : UIButton {
    lazy var loadingImg : UIImageView = {
        let temp = UIImageView()
        temp.image = R.image.live_night_white_loading()
        temp.isUserInteractionEnabled = false
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.center.equalTo(self.snp.center)
            make.size.equalTo(CGSize(width: 32.auto(), height: 32.auto()))
        })
        return temp
    }()
    private var liveLightState : ADLiveLightEnum = .off {
        didSet {
            switch liveLightState {
            case .on:
                self.stopAnimail()
                self.loadingImg.image = R.image.device_light_open()
            case .off:
                self.stopAnimail()
                self.loadingImg.image = R.image.device_light_close()
            case .loading:
                self.loadingImg.image = R.image.live_night_white_loading()
                self.startAnimail()
            }
        }
    }
    
    var isOn : Bool = false {
        didSet {
            self.liveLightState = isOn ? .on : .off
        }
    }
    
    
    override init(frame: CGRect) {
        liveLightState = .off
        super.init(frame: frame)
        self.loadingImg.isHidden = false
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startAnimail() {
        let count = self.loadingImg.layer.animationKeys()?.count ?? 0
        
        if count > 0 {
            return
        }
        let baseAnil = CABasicAnimation(keyPath: "transform.rotation")
        baseAnil.fromValue = 0
        baseAnil.toValue = Double.pi * 2
        baseAnil.duration = 1.5
        baseAnil.repeatCount = MAXFLOAT
        self.loadingImg.layer.add(baseAnil, forKey: "rotation")
    }
    
    func stopAnimail() {
        guard self.loadingImg.layer.animationKeys()?.count ?? 0 > 0 else {
            return
        }
        self.loadingImg.layer.removeAllAnimations()
    }
    
  
    
//    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
//        if liveLightState == .loading {
//            return false
//        }
//        self.sendActions(for: UIControl.Event.touchUpInside)
//        return true
//    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if liveLightState == .loading {
            return
        }
        liveLightState = .loading
        self.sendActions(for: UIControl.Event.valueChanged)
        return
    }
    
    
}
