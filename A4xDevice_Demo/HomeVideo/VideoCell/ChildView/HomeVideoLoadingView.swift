//
//  HomeVideoLoadingView.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/3/21.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import A4xBaseSDK

class HomeVideoLoadingView: UIView {

    var isLoading : Bool = false
    
    lazy var loadingTipLab : UILabel = {
        let temp = UILabel()
        temp.text = R.string.localizable.connecting()
        temp.font = ADTheme.B2
        temp.textColor = UIColor.white
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.left.equalTo(self.loadingImg.snp.right).offset(5)
            make.centerY.equalTo(self.loadingImg.snp.centerY)
            make.right.equalTo(self.snp.right)
        })
        return temp
    }()
    
    lazy var loadingImg : UIImageView = {
        let temp = UIImageView()
        temp.image = R.image.home_video_loading()
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.top.equalTo(0)
            make.left.equalTo(0)
            make.size.equalTo(CGSize(width: 25.auto(), height: 25.auto()))
        })
        return temp
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        addObserver()
        self.loadingImg.isHidden = false
        self.loadingTipLab.isHidden = false
    }
    
    deinit {
        self.removeObserver()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startAnimail() {
        let count = self.loadingImg.layer.animationKeys()?.count ?? 0
        
        if count > 0 {
            return
        }
        isLoading = true
        self.loadingTipLab.text = R.string.localizable.connecting()
        let baseAnil = CABasicAnimation(keyPath: "transform.rotation")
        baseAnil.fromValue = 0
        baseAnil.toValue = Double.pi * 2
        baseAnil.duration = 1.5
        baseAnil.repeatCount = MAXFLOAT
        self.loadingImg.layer.add(baseAnil, forKey: "rotation")
        
        
    }
    
    func stopAnimail() {
        isLoading = false

        guard self.loadingImg.layer.animationKeys()?.count ?? 0 > 0 else {
            return
        }
        self.loadingImg.layer.removeAllAnimations()
    }
    
    private func addObserver(){
        NotificationCenter.default.addObserver(self, selector: #selector(beginAction(sender:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    private func removeObserver(){
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc
    private func beginAction(sender : UIButton){
        if isLoading {
            self.startAnimail()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 100.auto(), height: 25.auto())
    }
}
