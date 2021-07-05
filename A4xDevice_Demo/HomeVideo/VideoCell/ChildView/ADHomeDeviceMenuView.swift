//
//  ADHomeDeviceMenuView.swift
//  AddxAi
//
//  Created by kzhi on 2020/12/29.
//  Copyright © 2020 addx.ai. All rights reserved.
//

import Foundation
import yoga
import A4xBaseSDK
import A4xYogaKit

class ADTestLable : UILabel {
    override var intrinsicContentSize: CGSize {
        return super.intrinsicContentSize
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return super.sizeThatFits(size)
    }
    
    var _frame: CGRect = .zero
    override var frame: CGRect {
        set {
            var resultFrame = newValue
            if newValue.width > 0 {
                let width = newValue.width
                let height = self.sizeThatFits(CGSize(width: width, height: 100 )).height
                resultFrame = CGRect(x: newValue.minX, y: newValue.minY, width: width, height: height)
            }
            
            super.frame = resultFrame
        }
        get {
           return _frame
        }
    }
    
}

enum ADHomeDeviceMenuType : Int {
    case sound      = 10000
    case alert      = 10001
    case track      = 10002
    case location   = 10003
    case light      = 10014
    case more       = 10015
    
    static func allCase() -> [ADHomeDeviceMenuType] {
        return [.sound , .alert , .track , .location ,.light]
    }
    
    static func roteCase() -> [ADHomeDeviceMenuType] {
        return [.sound , .alert , .track , .location ]
    }
    
    static func lightCase(enable : Bool) -> [ADHomeDeviceMenuType] {
        var menus : [ADHomeDeviceMenuType] = [.sound , .alert ]
        if enable {
            menus.append(.light)
        }
        return menus
    }
    
    var stringValue : String {
        switch self {
        case .sound:
            return R.string.localizable.sound()
        case .alert:
            return R.string.localizable.alert_buttom()
        case .track:
            return R.string.localizable.motion_tracking()
        case .location:
            return R.string.localizable.preset_location()
        case .light:
            return R.string.localizable.white_light()
        case .more:
            return R.string.localizable.more()
        }
    }
}

protocol ADHomeDeviceMenuViewProtocol : class {
    func deviceVoiceIsOn() -> Bool
    func deviceRotateEnable() -> Bool
    func deviceMoveIsHuman() -> Bool
    func deviceIsAdmin() -> Bool
    func deviceLightEnable() -> Bool
    func deviceLightisOn() -> Bool
    func deviceIsShowMore() -> Bool
    func deviceIsAlerting() -> Bool
    func devcieSupperAlert() -> Bool
    func deviceIsFllow() -> Bool
    func deviceShowMoreMenu()
    func deviceMenuClick(type : ADHomeDeviceMenuType , comple :@escaping (Bool)->Void)
}

class ADHomeDeviceMenuView : UIView {
    weak var `protocol` : ADHomeDeviceMenuViewProtocol?
    let gifManager = A4xBaseGifManager(memoryLimit:60)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.yoga.isEnabled = true
        self.yoga.flexDirection = .row
        self.yoga.justifyContent = .flexStart
        self.yoga.flexWrap = .wrap
        loadBaseInfo()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var isHumanFllow : Bool = false
    
    var isAlerting : Bool = false
    
    fileprivate static let maxMenuCount : Int = 4
    
    func loadBaseInfo(){
        let allCase = ADHomeDeviceMenuType.allCase()
//        allCase.append(.more)
        allCase.forEach { [weak self] (menu) in
            self?.loadItems(type: menu, totalCount: allCase.count, isShow: true)
            self?.loadItemBaseInfo(type: menu)
        }
    }
    
    
    func updateInfo(){
        let rotateEnable : Bool = self.protocol?.deviceRotateEnable() ?? false
        let lightEnable  : Bool = self.protocol?.deviceLightEnable() ?? false
        let showMore     : Bool = self.protocol?.deviceIsShowMore() ?? false
        let isAdmin      : Bool = self.protocol?.deviceIsAdmin() ?? false
        let alertSupper  : Bool = self.protocol?.devcieSupperAlert() ?? false
        var showAllCase : [ADHomeDeviceMenuType] = []
        showAllCase.append(.sound)
        if alertSupper {
            showAllCase.append(.alert)
        }
        if rotateEnable {
            if isAdmin {
                showAllCase.append(.track)
            }
            showAllCase.append(.location)
        }
        if lightEnable {
            showAllCase.append(.light)
        }
        let allCase = ADHomeDeviceMenuType.allCase()
        if showAllCase.count >= ADHomeDeviceMenuView.maxMenuCount {
            if showMore {
            }else {
                showAllCase = Array(showAllCase[0...3]) as [ADHomeDeviceMenuType]
            }
        }
        allCase.forEach { [weak self] (menu) in
            self?.loadItems(type: menu, totalCount: min(showAllCase.count, ADHomeDeviceMenuView.maxMenuCount), isShow: showAllCase.contains(menu))
            self?.updateItemInfo(type: menu)
        }
        if showAllCase.count > 3 {
            self.yoga.justifyContent = .flexStart
        }else {
            self.yoga.justifyContent = .spaceBetween
        }

        self.yoga.width = YGValue(value: 100, unit: .percent)
    }
    
    
    func loadItems(type : ADHomeDeviceMenuType , totalCount : Int , isShow : Bool){
        var itemGroupV : UIControl?     = self.viewWithTag(type.rawValue) as? UIControl
        var itemTitleV : UILabel?       = itemGroupV?.viewWithTag(1000) as? UILabel
        var itemImageV : UIButton?      = itemGroupV?.viewWithTag(1001) as? UIButton
       
        guard itemGroupV == nil else {
            itemGroupV?.yoga.isEnabled = isShow
            itemGroupV?.isHidden = !isShow
            if case .more = type {
                let barIndex = self.subviews.index(of: itemGroupV!) ?? 0
                if barIndex != 3 {
                    self.exchangeSubview(at: barIndex, withSubviewAt: 3)
                }
            }
            itemGroupV?.yoga.width = YGValue(self.bounds.width / CGFloat(ADHomeDeviceMenuView.maxMenuCount))
            guard let itemv = itemImageV as? A4xBaseLoadingButton else {
                return
            }
            itemv.isLoading = false
            return
        }
        
        itemGroupV = UIControl()
        itemGroupV?.addTarget(self, action: #selector(buttonAction(sender:)), for: .touchUpInside)
        itemGroupV?.tag = type.rawValue
        itemGroupV?.yoga.isEnabled = isShow
        itemGroupV?.isHidden = !isShow
        itemGroupV?.yoga.marginTop = YGValue(CGFloat(16.auto()))
        itemGroupV?.yoga.flexDirection = .column
        itemGroupV?.yoga.justifyContent = .flexStart

        itemImageV = A4xBaseLoadingButton()
        itemImageV?.backgroundColor = UIColor.hex(0xF6F6F6)
        itemImageV?.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        itemImageV?.tag = 1001
        itemImageV?.isUserInteractionEnabled = false
        itemImageV?.layer.cornerRadius = 22.auto()
        itemImageV?.clipsToBounds = true
        itemImageV?.addTarget(self, action: #selector(buttonAction(sender:)), for: .touchUpInside)
        itemImageV?.contentMode = .scaleAspectFit
        itemGroupV?.addSubview(itemImageV!)
        itemImageV?.yoga.isEnabled = true
        itemImageV?.yoga.alignSelf = .center
        itemImageV?.yoga.width = YGValue(CGFloat(44.auto()))
        itemImageV?.yoga.height = YGValue(CGFloat(44.auto()))

        itemTitleV = ADTestLable()
        itemTitleV?.tag = 1000
        itemTitleV?.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        itemTitleV?.textColor = ADTheme.C1
        itemTitleV?.numberOfLines = 0
        itemTitleV?.lineBreakMode = .byWordWrapping
        itemTitleV?.font = ADTheme.B2
        itemTitleV?.textAlignment = .center
        itemGroupV?.addSubview(itemTitleV!)
        if case .more = type {
            self.insertSubview(itemGroupV!, at: 3)
        }else {
            self.addSubview(itemGroupV!)
        }

        
        itemTitleV?.yoga.isEnabled = true
        itemTitleV?.yoga.flexShrink = 1
        itemTitleV?.yoga.flexGrow = 1
        itemTitleV?.yoga.marginTop = YGValue(CGFloat(9.auto()))
        itemTitleV?.yoga.width = YGValue(value: 95, unit: .percent)
    }
    
    // 竖屏直播点击声音、警铃、白光灯处理
    @objc func buttonAction(sender : UIControl) {
        var checkEnum = ADHomeDeviceMenuType(rawValue: sender.tag)
        if checkEnum == nil {
            checkEnum = ADHomeDeviceMenuType(rawValue: sender.superview?.tag ?? 10) ?? .sound
        }
        guard let clickEnum = checkEnum else {
            return
        }
        
        guard let itemv = self.itemImageView(type: clickEnum) as? A4xBaseLoadingButton else {
            return
        }
        itemv.isLoading = true
        self.protocol?.deviceMenuClick(type: clickEnum, comple: {[weak itemv , weak self] (isScuess) in
            itemv?.isLoading = false
            if isScuess {
                if case .alert = clickEnum {
                    self?.isAlerting = true
                    self?.updateItemInfo(type: .alert)
                    DispatchQueue.main.a4xAfter(5) {
                        self?.isAlerting = false
                        self?.updateItemInfo(type: .alert)
                    }
                }
            }
            
        })

    }
    
    func itemEnable(type : ADHomeDeviceMenuType) -> Bool {
        return self.itemImageView(type: type)?.isSelected ?? false
    }
    
    
    func itemImageView(type : ADHomeDeviceMenuType) -> UIButton? {
        let itemGroupV : UIControl? = self.viewWithTag(type.rawValue) as? UIControl
        let itemImageV : UIButton?  = itemGroupV?.viewWithTag(1001) as? UIButton
    
        return itemImageV
    }
    
    func itemTitleView(type : ADHomeDeviceMenuType) -> UILabel? {
        let itemGroupV : UIControl? = self.viewWithTag(type.rawValue) as? UIControl
        let itemTitleV : UILabel?   = itemGroupV?.viewWithTag(1000) as? UILabel
        return itemTitleV
    }
    
    func updateItemInfo(type : ADHomeDeviceMenuType){
        let itemButton = self.itemImageView(type: type)
        let titleV = self.itemTitleView(type: type)
        titleV?.text = type.stringValue
        switch type {
        case .sound:
            let soundEnable = self.protocol?.deviceVoiceIsOn() ?? false
            itemButton?.isSelected = soundEnable
        case .alert:
            if self.isAlerting {
                itemButton?.backgroundColor = ADTheme.E1
                self.showAlertGif(v: itemButton!)
            }else {
                gifManager.clear()
                itemButton?.backgroundColor = UIColor.hex(0xF6F6F6)
                itemButton?.setImage(R.image.home_device_alert(), for: .normal)
                if let tagview : UIImageView = itemButton?.viewWithTag(666) as? UIImageView {
                    tagview.stopAnimatingGif()
                    tagview.removeFromSuperview()
                }
            }
            break
        case .track:
//            let isHuman = self.protocol?.deviceMoveIsHuman() ?? false
//            if isHuman {
//                itemButton?.setImage(R.image.home_device_auto_fllow_default(), for: .disabled)
//                itemButton?.setImage(R.image.home_device_auto_fllow(), for: .selected)
//                titleV?.text = R.string.localizable.human_tracking()
//            } else {
//                itemButton?.setImage(R.image.home_device_auto_move_default(), for: .disabled)
//                itemButton?.setImage(R.image.home_device_auto_move_fllow(), for: .selected)
//                titleV?.text = R.string.localizable.action_tracking()
//            }
            itemButton?.setImage(R.image.home_device_auto_move_default(), for: .disabled)
            itemButton?.setImage(R.image.home_device_auto_move_fllow(), for: .selected)
            titleV?.text = R.string.localizable.motion_tracking()
    
            let isFllow = self.protocol?.deviceIsFllow() ?? false
            itemButton?.isSelected = isFllow
        case .location:
            break
        case .light:
            let lightOn = self.protocol?.deviceLightisOn() ?? false
            itemButton?.isSelected = lightOn
        case .more:
            let showMore = self.protocol?.deviceIsShowMore() ?? false
            if (showMore){
                itemButton?.transform = CGAffineTransform.init(rotationAngle: CGFloat.pi)
            }else {
                itemButton?.transform = CGAffineTransform.identity
            }
            break
        }
    }
    
    func loadItemBaseInfo(type : ADHomeDeviceMenuType){
        let itemButton = self.itemImageView(type: type)

        switch type {
        case .sound:
            itemButton?.setImage(R.image.home_device_voice_disable(), for: .normal)
            itemButton?.setImage(R.image.home_device_voice_enable(), for: .selected)
        case .alert:
            itemButton?.backgroundColor = ADTheme.E1
            itemButton?.setImage(R.image.home_device_alert(), for: .normal)
        case .track:
            itemButton?.setImage(R.image.home_device_auto_move_default(), for: .normal)
            itemButton?.setImage(R.image.home_device_auto_move_fllow(), for: .selected)
        case .location:
            itemButton?.setImage(R.image.home_device_location(), for: .disabled)
            itemButton?.setImage(R.image.home_device_location(), for: .normal)
        case .light:
            itemButton?.setImage(R.image.home_device_white_close(), for: .normal)
            itemButton?.setImage(R.image.home_device_white_open(), for: .selected)
        case .more:
            itemButton?.setImage(R.image.home_device_more(), for: .normal)
            itemButton?.setImage(R.image.home_device_more(), for: .selected)
            
        }
    }
    
    func showAlertGif(v : UIButton){
        let view = UIImageView()
        view.frame = v.imageView?.frame ?? v.bounds
        v.addSubview(view)
        view.tag = 6666
        v.setImage(nil, for: .normal)

        let gifImage = UIImage(gifName: "alert_device.gif")
        view.setGifImage(gifImage, manager: gifManager ,loopCount: 3)
    }
    
    static func height(forWidth width : CGFloat , alertSupper : Bool , rotateEnable rotate : Bool , whiteLight light : Bool , showMore more : Bool) -> CGFloat {
    
        var showAllCase : [ADHomeDeviceMenuType] = []
        showAllCase.append(.sound)
        if alertSupper {
            showAllCase.append(.alert)
        }
        if rotate {
            showAllCase.append(.track)
            showAllCase.append(.location)
        }
        if light {
            showAllCase.append(.light)
        }
        var allCase = ADHomeDeviceMenuType.allCase()
        if showAllCase.count >= maxMenuCount {
            allCase.insert(.more, at: maxMenuCount - 1)
            if more {
                showAllCase.insert(.more, at: maxMenuCount - 1)
            }else {
                showAllCase = Array(showAllCase[0...2]) as [ADHomeDeviceMenuType]
                showAllCase.append(.more)
            }
        }
        showAllCase.append(.more)
 
        let session : CGFloat = 16.auto()
        let imageHeight : CGFloat = 44.auto()
        let lableTop : CGFloat = 9.auto()
        let itemWidht : CGFloat = width / CGFloat(ADHomeDeviceMenuView.maxMenuCount)
        
        
        var height : CGFloat = 0
        var lineheight : CGFloat = 0
        for index in 0..<showAllCase.count {
            let type = showAllCase[index].stringValue
            let itemHight = type.size(maxWidth: itemWidht, font: ADTheme.B2, lineSpacing: 0, wordSpace: 0).height
            lineheight = max(itemHight, lineheight)
            if index % ADHomeDeviceMenuView.maxMenuCount == 0 && index > 0{
                if lineheight > 0 {
                    height += (lineheight + session + imageHeight + lableTop + lineheight)
                }
                lineheight = 0
            }
            
    
        }
        if lineheight != 0 {
            height += (lineheight + imageHeight + lableTop + lineheight)
        }
        return height
    }
}
