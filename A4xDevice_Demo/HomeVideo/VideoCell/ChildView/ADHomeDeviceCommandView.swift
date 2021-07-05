//
//  ADHomeDeviceCommandView.swift
//  AddxAi
//
//  Created by kzhi on 2020/12/30.
//  Copyright © 2020 addx.ai. All rights reserved.
//

import Foundation
import yoga
import SystemConfiguration.CaptiveNetwork
import AudioToolbox
import A4xBaseSDK

enum ADHomeDeviceSpeakEnum {
    case down
    case up
    case tap
}

protocol ADHomeDeviceCommandViewProtocol : class {
    func deviceCommandSpeak(type : ADHomeDeviceSpeakEnum)
    func deviceCommandRotate() -> Bool
}

class ADHomeDeviceSpeakButton : UIView ,UIGestureRecognizerDelegate {
   
    var touchAction : ((ADHomeDeviceSpeakEnum)->Void)?
    var defaultIconColor : UIColor = ADTheme.C6
    
    var selectImage : UIImage?
    var nameTitle : String? {
        didSet {
            self.titleLable.text = nameTitle
        }
    }
    
    var generator : UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: UIImpactFeedbackGenerator.FeedbackStyle.light)

    private lazy var iconImageView : UIButton = {
        let tem: UIButton = UIButton()
        tem.setImage(R.image.home_video_speak(), for: .normal)
        tem.backgroundColor = ADTheme.C6
        tem.isUserInteractionEnabled = false
        tem.cornerRadius = 34.auto()
        tem.clipsToBounds = true
        self.addSubview(tem)
        tem.snp.makeConstraints { make in
            make.centerX.equalTo(self.snp.centerX)
            make.top.equalTo(0)
            make.width.equalTo(68.auto())
            make.height.equalTo(68.auto())
        }
        return tem;
    }()

    private lazy var titleLable : UILabel = {
        let tem: UILabel = UILabel()
        tem.text = "video"
        tem.font = ADTheme.B2
        tem.numberOfLines = 0
        tem.textAlignment = .center
        tem.textColor = UIColor.black
        self.addSubview(tem)

        tem.snp.makeConstraints { make in
            make.top.equalTo(self.iconImageView.snp.bottom).offset(6)
            make.width.equalTo(self.snp.width)
            make.centerX.equalTo(self.snp.centerX)
        }
        return tem;
    }()


    convenience init(){
        self.init(frame: CGRect.zero)
    }

    override var frame: CGRect {
        didSet {
            self.titleLable.text = R.string.localizable.hold_speak()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.titleLable.isHidden = false
        self.iconImageView.isHidden = false
        self.backgroundColor = UIColor.clear
        
        self.titleLable.text = R.string.localizable.hold_speak()
        
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
            self.iconImageView.backgroundColor = ADTheme.C5
            self.titleLable.text = R.string.localizable.release_stop()
            
            touchAction?(.down)
            generator.prepare()
            generator.impactOccurred()
        case .failed:
            fallthrough
        case .cancelled:
            fallthrough
        case .ended:
            touchAction?(.up)
            self.iconImageView.backgroundColor = defaultIconColor
            self.titleLable.text = R.string.localizable.hold_speak()
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

class ADHomeDeviceCommandView : UIView {
    weak var `protocol` : ADHomeDeviceCommandViewProtocol? = nil
   
    var videoStyle      : ADVideoCellType = .default

    weak var dragTapProtocol : AddxCircleControlProtocol? = nil {
        didSet {
            self.drawTapView.protocol = dragTapProtocol
        }
    }
    
//    weak var rockerProtocol : ADRockerViewProtocol? = nil {
//        didSet {
//            self.dragView.protocol = rockerProtocol
//        }
//    }
    
    func updateView() {
        switch videoStyle {
        case .default:
            fallthrough
        case .split:
            fallthrough
        case .options_more:
            fallthrough
        case .locations:
            fallthrough
        case .locations_edit:
            self.isHidden = true
        case .playControl:
            if self.protocol?.deviceCommandRotate() ?? false {
                self.isHidden = false
                self.drawTapView.isHidden = false
                self.speakBtn.isHidden = false
                self.drawTapView.frame = CGRect(x: (self.width - 145.auto()) / 2, y: 0, width: 145.auto(), height: 145.auto())
                self.speakBtn.frame = CGRect(x: self.drawTapView.maxX + 25.auto(), y: 38.auto(), width: 68.auto(), height: 106.auto())
            }else {
                self.isHidden = false
                self.drawTapView.isHidden = true
                self.speakBtn.isHidden = false
                self.speakBtn.frame = CGRect(x: (self.width - 68.auto()) / 2, y: 38.auto(), width: 68.auto(), height: 106.auto())
            }
        }
    }
    
    private lazy
    var speakBtn : ADHomeDeviceSpeakButton = {
        let temp = ADHomeDeviceSpeakButton()
        self.addSubview(temp)
        temp.touchAction = {[weak self]type in
            A4xLog("ADHomeDeviceSpeakButton \(type)")
            self?.protocol?.deviceCommandSpeak(type: type)
        }
        return temp
    }()
    
    
    
    
//    private lazy
//    var dragView : ADRockerView = {
//        let temp = ADRockerView()
//        self.addSubview(temp)
//        return temp
//    }()
    
    private lazy
    var drawTapView : AddxCircleControl = {
        let temp = AddxCircleControl()
        temp.visableColors = [UIColor.hex(0xEBEBEB) , UIColor.hex(0xFAFAFA)]
        temp.lineColor = UIColor.hex(0xDEDEDE)
        self.addSubview(temp)
        return temp
    }()
}


