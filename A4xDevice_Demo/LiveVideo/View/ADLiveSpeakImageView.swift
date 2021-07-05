//
//  ADLiveSpeakImageView.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/6/25.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import A4xBaseSDK

class ADLiveSpeakImageView : UIButton ,UIGestureRecognizerDelegate {
    override var isUserInteractionEnabled: Bool {
        didSet {
            self.gestureRecognizers?.forEach({ (re) in
                re.isEnabled = false
                re.isEnabled = true
            })
        }
    }
    
    var touchAction : ((ADHomeDeviceSpeakEnum)->Void)?
    var defaultIconColor : UIColor = ADTheme.C6
    var generator : UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: UIImpactFeedbackGenerator.FeedbackStyle.light)

//    var selectImage : UIImage?
  
//    private lazy var iconImageView : UIButton = {
//        let tem: UIButton = UIButton()
//        tem.setImage(R.image.video_live_speak(), for: .normal)
//        tem.backgroundColor = ADTheme.C6
//        tem.isUserInteractionEnabled = false
//        tem.cornerRadius = 34.auto()
//        tem.clipsToBounds = true
//        self.addSubview(tem)
//        tem.snp.makeConstraints { make in
//            make.centerX.equalTo(self.snp.centerX)
//            make.top.equalTo(0)
//            make.width.equalTo(68.auto())
//            make.height.equalTo(68.auto())
//        }
//        return tem;
//    }()

    convenience init(){
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
//        self.iconImageView.isHidden = false
        self.backgroundColor = UIColor.clear
        
//        self.titleLable.text = R.string.localizable.hold_speak()
        
        let oneTap = UITapGestureRecognizer(target: self, action:#selector(oneClick(sender:)))
        self.addGestureRecognizer(oneTap)
        oneTap.numberOfTapsRequired = 1
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longTap(sender:)))
        longPress.minimumPressDuration = 0.2
        longPress.delegate = self
        self.addGestureRecognizer(longPress)

        oneTap.require(toFail:longPress )
    }
   
    @objc private
    func oneClick(sender : UITapGestureRecognizer){
        touchAction?(.tap)
        generator.prepare()
        generator.impactOccurred()
    }
    
    @objc private
    func longTap(sender : UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
//            self.iconImageView.backgroundColor = ADTheme.C5
//            self.titleLable.text = R.string.localizable.release_stop()
            touchAction?(.down)
            generator.prepare()
            generator.impactOccurred()
        case .failed:
            fallthrough
        case .cancelled:
            fallthrough
        case .ended:
            touchAction?(.up)
//            self.iconImageView.backgroundColor = defaultIconColor
//            self.titleLable.text = R.string.localizable.hold_speak()
        default:
            break
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

}

