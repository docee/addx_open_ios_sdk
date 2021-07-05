//
//  ADLiveVideoMoreMenuView.swift
//  AddxAi
//
//  Created by addx-wjin on 2020/12/31.
//  Copyright © 2020 addx.ai. All rights reserved.
//

import UIKit
import yoga
import A4xBaseSDK

enum ADLiveDeviceMenuType : Int {
    case track      = 10011
    case alert      = 10012
    case location   = 10013
    case light      = 10014
    case setting    = 10015
    
    static func allCase() -> [ADLiveDeviceMenuType] {
        return [.track, .location,.alert ,.light ,.setting]
    }
    
    var stringValue : String {
        switch self {
        case .alert:
            return R.string.localizable.alert_buttom()
        case .track:
            return R.string.localizable.motion_tracking()
        case .location:
            return R.string.localizable.preset_location()
        case .light:
            return R.string.localizable.white_light()
        case .setting:
            return R.string.localizable.device_info()
        }
    }
    
    var noramilImage : UIImage? {
        switch self {
        case .track:
            return R.image.device_live_move_follow_disable()
        case .alert:
            return R.image.video_live_warning()
        case .location:
            return R.image.home_device_live_edit_modle()
        case .light:
            return R.image.device_light_close()
        case .setting:
            return R.image.live_video_setting()
        }
    }
    
    var selectImage : UIImage? {
        switch self {
        case .track:
            return R.image.device_live_move_fllow()
        case .alert:
            return R.image.video_live_warning()
        case .location:
            return R.image.home_device_live_edit_modle()
        case .light:
            return R.image.device_light_open()
        case .setting:
            return R.image.live_video_setting()
        }
    }
}


protocol ADLiveVideoMoreMenuViewProtocol : class {
    func deviceMenuClick(type : ADLiveDeviceMenuType , compleAction :@escaping (Bool)->Void)
}

class ADLiveVideoMoreMenuView: UIControl {
    var quitBlock: (() -> Void)?
    var rotateEnable : Bool = true{
        didSet{
            updateInfo()
        }
    }
    var isHuman : Bool = true {
        didSet{
            updateItemInfo(type: ADLiveDeviceMenuType.track)
        }
    }
    var lightEnable : Bool = true{
        didSet{
            updateItemInfo(type: ADLiveDeviceMenuType.light)
        }
    }
    var lightSupper : Bool = true {
        didSet{
            updateInfo()
        }
    }
    
    var fllowEnable :Bool = true {
        didSet {
            updateInfo()
        }
    }
    var isFllow : Bool = true{
        didSet{
            updateItemInfo(type: ADLiveDeviceMenuType.track)
        }
    }
    
    var supperAlert : Bool = true {
        didSet {
            updateInfo()
        }
    }

    weak var `protocol` : ADLiveVideoMoreMenuViewProtocol? = nil
    
    init(frame: CGRect = .zero  , supperAlert : Bool , rotateEnable : Bool , lightSupper : Bool , fllowEnable : Bool) {
        super.init(frame: frame)
        self.quitBtn.isHidden = false
        //self.collectView.isHidden = false
        self.backgroundColor = UIColor.hex(0x1D1C1C, alpha: 0.8)
        self.addTarget(self, action: #selector(emtry), for: UIControl.Event.touchUpInside)
        self.yoga.isEnabled = true
        self.yoga.flexDirection = .row
        self.yoga.justifyContent = .flexStart
        self.yoga.paddingTop = YGValue(50)
        self.yoga.flexWrap = .wrap
        self.lightSupper = lightSupper
        self.rotateEnable = rotateEnable
        self.fllowEnable = fllowEnable
        self.supperAlert = supperAlert
        updateInfo()
    }
    
    func updateFrame(){
        self.yoga.applyLayout(preservingOrigin: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func emtry() { }
    
    private lazy var quitBtn: UIButton = {
        let temp = UIButton()
        temp.setImage(R.image.live_video_more_menu_quit(), for: .normal)
        temp.addTarget(self, action: #selector(closeButtonAction), for: .touchUpInside)
        self.addSubview(temp)
        temp.snp.makeConstraints { (make) in
            make.top.equalTo(10.auto())
            make.right.equalTo(self.snp.right).offset(-20.auto())
            make.size.equalTo(CGSize(width: 24.auto(), height: 24.auto()))
        }
        return temp
    }()
    
    @objc private func closeButtonAction() {
        self.quitBlock?()
    }
    
    func updateInfo(){
        
        var showAllCase : [ADLiveDeviceMenuType] = []
        if rotateEnable {
            if fllowEnable {
                showAllCase.append(.track)
            }
            showAllCase.append(.location)
        }
        if supperAlert {
            showAllCase.append(.alert)
        }
        if lightSupper {
            showAllCase.append(.light)
        }
        showAllCase.append(.setting)
        showAllCase.forEach { [weak self] (menu) in
            self?.loadItems(type: menu , isShow: true)
            self?.updateItemInfo(type: menu)
        }
       
        self.yoga.justifyContent = .flexStart
        self.yoga.width = YGValue(value: 100, unit: .percent)
    }
    
    func updateItemInfo(type : ADLiveDeviceMenuType){
        let itemButton = self.itemImageView(type: type)
        itemButton?.setImage(type.noramilImage, for: .normal)
        itemButton?.setImage(type.selectImage, for: .selected)
        let titleV = self.itemTitleView(type: type)
        titleV?.text = type.stringValue
        
        
        switch type {
        case .track:
//            if isHuman {
//                itemButton?.setImage(R.image.device_live_fllow_disable(), for: .normal)
//                itemButton?.setImage(R.image.device_live_fllow(), for: .selected)
//                titleV?.text = R.string.localizable.human_tracking()
//            } else {
//                itemButton?.setImage(R.image.device_live_move_follow_disable(), for: .normal)
//                itemButton?.setImage(R.image.device_live_move_fllow(), for: .selected)
//                titleV?.text = R.string.localizable.action_tracking()
//            }
            itemButton?.setImage(R.image.device_live_move_follow_disable(), for: .normal)
            itemButton?.setImage(R.image.device_live_move_fllow(), for: .selected)
            titleV?.text = R.string.localizable.motion_tracking()
            itemButton?.isSelected = isFllow
        case .location:
            break
        case .light:
            itemButton?.isSelected = lightEnable
        default:
            break
        }
        guard let itemv = itemButton as? A4xBaseLoadingButton else {
            return
        }
        itemv.isLoading = false
    }
    
    func loadItems(type : ADLiveDeviceMenuType , isShow : Bool){
        var itemGroupV : UIControl?     = self.viewWithTag(type.rawValue) as? UIControl
        var itemTitleV : UILabel?       = itemGroupV?.viewWithTag(1000) as? UILabel
        var itemImageV : UIButton?      = itemGroupV?.viewWithTag(1001) as? UIButton
       
        guard itemGroupV == nil else {
            itemGroupV?.yoga.isEnabled = isShow
            itemGroupV?.isHidden = !isShow
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
        
        itemImageV = A4xBaseLoadingButton()
//        itemImageV?.backgroundColor = UIColor.hex(0xF6F6F6)
//        itemImageV?.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        itemImageV?.tag = 1001
        itemImageV?.isUserInteractionEnabled = false
//        itemImageV?.layer.cornerRadius = 22.auto()
//        itemImageV?.clipsToBounds = true
        itemImageV?.addTarget(self, action: #selector(buttonAction(sender:)), for: .touchUpInside)
        itemImageV?.contentMode = .scaleAspectFit
        itemGroupV?.addSubview(itemImageV!)
        itemImageV?.yoga.isEnabled = true
        itemImageV?.yoga.alignSelf = .center
        itemImageV?.yoga.width = YGValue(CGFloat(44.auto()))
        itemImageV?.yoga.height = YGValue(CGFloat(44.auto()))

        itemTitleV = UILabel()
        itemTitleV?.tag = 1000
        itemTitleV?.textColor = UIColor.white
        itemTitleV?.numberOfLines = 0
        itemTitleV?.font = ADTheme.B2
        itemTitleV?.textAlignment = .center
        itemGroupV?.addSubview(itemTitleV!)
        self.addSubview(itemGroupV!)
        
        itemTitleV?.yoga.isEnabled = true
        itemTitleV?.yoga.marginTop = YGValue(CGFloat(2.auto()))
        itemGroupV?.yoga.width = YGValue(value: 50, unit: .percent)

    }
    
    @objc
    func buttonAction(sender : UIControl) {
        var checkEnum = ADLiveDeviceMenuType(rawValue: sender.tag)
        if checkEnum == nil {
            checkEnum = ADLiveDeviceMenuType(rawValue: sender.superview?.tag ?? 10) ?? .alert
        }
        guard let clickEnum = checkEnum else {
            return
        }
        
        guard let itemv = self.itemImageView(type: clickEnum) as? A4xBaseLoadingButton else {
            return
        }
        itemv.isLoading = true
        self.protocol?.deviceMenuClick(type: clickEnum, compleAction: { [weak itemv](f) in
            itemv?.isLoading = false
        })
    }
    
    func loadItemBaseInfo(type : ADLiveDeviceMenuType){
        let itemButton = self.itemImageView(type: type)
        itemButton?.setImage(type.noramilImage, for: .normal)
        itemButton?.setImage(type.selectImage, for: .selected)
        
        let infoLable = self.itemTitleView(type: type)
        infoLable?.text = type.stringValue
    }
    
    func itemImageView(type : ADLiveDeviceMenuType) -> UIButton? {
        let itemGroupV : UIControl? = self.viewWithTag(type.rawValue) as? UIControl
        let itemImageV : UIButton?  = itemGroupV?.viewWithTag(1001) as? UIButton
    
        return itemImageV
    }
    
    func itemTitleView(type : ADLiveDeviceMenuType) -> UILabel? {
        let itemGroupV : UIControl? = self.viewWithTag(type.rawValue) as? UIControl
        let itemTitleV : UILabel?   = itemGroupV?.viewWithTag(1000) as? UILabel
        return itemTitleV
    }
}
