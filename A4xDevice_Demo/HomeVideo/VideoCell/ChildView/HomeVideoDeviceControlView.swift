//
//  HomeVideoDeviceControlView.swift
//  AddxAi
//
//  Created by kzhi on 2019/11/21.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import Foundation
import yoga
import A4xBaseSDK

protocol HomeVideoDeviceControlViewProtocol : class {
    func controlLocation(clickModle modle : ADPresetModel? ,clickType type : HomeVideoPresetCellType)
    func controlType(changeToType type : ADHomeVideoPresetTypeModle)
    func controlDeviceRotate(toPoint point : CGPoint)
    func controlAutoFollow(autoFollow auto : Bool ,comple : @escaping ((Bool)->Void)->Void)
    func controlCommandSpeak(type : ADHomeDeviceSpeakEnum)
    func deviceMenuAction(type : ADHomeDeviceMenuType , comple: @escaping (Bool) -> Void )
}


class HomeVideoDeviceControlView : UIView {
    weak var `protocol` : HomeVideoDeviceControlViewProtocol? = nil
    var presetListData : [ADPresetModel]?{
        didSet {self.editView.presetListData = presetListData}
    }
    var autoFollowBlock : ((Bool ,_ comple: @escaping (Bool)->Void)->Void)? {
        didSet {
//            self.speakControlView.changeFloowAction = autoFollowBlock
        }
    }
    var deviceRotateBlock : ((CGPoint)->Void)?
    var deviceSpeakBlock : ((Bool)->Bool)?
    var videoStyle      : ADVideoCellType = .default {
        didSet {
            self.commentView.videoStyle = videoStyle
        }
    }

    var canStandBy : Bool = false
    
    var canRotate : Bool = true
    
    var isRotate: Bool = true
    
    var lightEnable : Bool = true
    
    var supperAlert : Bool = false{
        didSet {
            self.menuView.updateInfo()
        }
    }
    
    var deviceVoiceOn : Bool = false {
        didSet {
            self.menuView.updateInfo()
        }
    }
    
    override var frame: CGRect{
        didSet {
            A4xLog("---")
        }
    }
    
    var spackVoiceData : [Float]? {
        didSet {
//            self.speakControlView.spackVoiceData = spackVoiceData
        }
    }
    
    var editEnable : Bool = true {
        didSet {
            self.editView.editEnable = editEnable
        }
    }
    
    var isFollow : Bool = false{
        didSet {
            self.menuView.updateInfo()
        }
    }
    
    var lightisOn : Bool = false{
        didSet {
            self.menuView.updateInfo()
        }
    }
    
    var isFollowAdmin : Bool = false {
        didSet {
            self.editView.isAdmin = isFollowAdmin
//            self.speakControlView.isFollowAdmin = isFollowAdmin
            self.menuView.updateInfo()

        }
    }
    
    var isAlerting : Bool {
        return menuView.isAlerting
    }
    
    // 是否切换成人形追踪
    var autoFollowBtnIsHumanImg: Bool = false
    
    var editModle : ADHomeVideoPresetTypeModle = .none {
        didSet {
            if self.editModle == .show || self.editModle == .none {
                self.editView.isHidden = true
            }else {
                self.editView.isHidden = false
            }
            self.editView.editModle = (self.editModle == .delete)
        }
    }
    
    var follow : Bool = true {
        didSet {
//            self.speakControlView.isFloow = follow
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
//        self.speakControlView.isHidden = false
//        self.dragView.isHidden = false
//        self.editView.isHidden = true
        
        self.yoga.isEnabled = true
        self.menuView.isHidden = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateInfo() {
        switch self.videoStyle {
        case .default:
            fallthrough
        case .split:
            fallthrough
        case .options_more:
            fallthrough
        case .locations:
            self.menuView.yoga.isEnabled = false
            self.commentView.yoga.isEnabled = false
            self.menuView.isHidden = true
            self.commentView.isHidden = true
            self.editView.yoga.isEnabled = true
            self.editView.isHidden = false
            self.editView.editModle = false
        case .locations_edit:
            self.menuView.yoga.isEnabled = false
            self.commentView.yoga.isEnabled = false
            self.editView.yoga.isEnabled = true
            self.menuView.isHidden = true
            self.commentView.isHidden = true
            self.editView.isHidden = false
        case .playControl:
            self.menuView.yoga.isEnabled = true
            self.commentView.yoga.isEnabled = true
            self.menuView.isHidden = false
            self.commentView.isHidden = false
            self.editView.isHidden = true
            self.editView.yoga.isEnabled = false
            self.menuView.updateInfo()
            if canRotate {
                self.commentView.yoga.height = YGValue(CGFloat(145.auto() + 32.auto()))
            }else {
                self.commentView.yoga.height = YGValue(CGFloat(95.auto() + 32.auto()))
            }
            self.commentView.updateView()
        }
        

    }
    
    private lazy
    var menuView : ADHomeDeviceMenuView = {
        let temp = ADHomeDeviceMenuView()
        self.addSubview(temp)
        temp.protocol = self
        
        temp.yoga.isEnabled = true
        temp.yoga.width = YGValue(value: 100, unit: YGUnit.percent)
        temp.yoga.flexGrow = 1

        return temp
    }()
    

    private lazy
    var commentView : ADHomeDeviceCommandView = {
        let temp = ADHomeDeviceCommandView()
        self.addSubview(temp)
        temp.dragTapProtocol = self
//        temp.rockerProtocol = self
        temp.protocol = self
        
        temp.yoga.isEnabled = true
        temp.yoga.width = YGValue(value: 100, unit: YGUnit.percent)
        temp.yoga.flexGrow = 1
        temp.yoga.marginTop = YGValue(CGFloat(20.auto()))
        return temp
    }()
    
    private lazy
    var editView : HomeVideoDeviceEditView = {
        let temp = HomeVideoDeviceEditView()
        temp.protocol = self
        self.addSubview(temp)
        temp.yoga.isEnabled = true
        temp.yoga.width = YGValue(value: 100, unit: YGUnit.percent)
        temp.yoga.flexGrow = 1
        temp.yoga.marginTop = YGValue(CGFloat(20.auto()))
        return temp
    }()
    
    
    @objc
    func editButtonAction(){
        self.editModle = .edit
//        self.editModleChangeBlock?(.edit)
    }
    
    private func editAction(type : HomeVideoPresetCellType) {
        if case .none = type {
            // v2.3 版不需要改变状态
            //self.speakControlView.isFloow = false
        }
    }
    
    
    static func height(type : ADVideoCellType , forWidth width : CGFloat , alertSupper : Bool , rotateEnable rotate : Bool , whiteLight light : Bool) -> CGFloat {
        let canRtateMinHeight : CGFloat = 280.auto()
        
        switch type {
        case .default:
            fallthrough
        case .split:
            return 0
        case .options_more:
            return max(ADHomeDeviceMenuView.height(forWidth: width , alertSupper : alertSupper, rotateEnable: rotate, whiteLight: light, showMore: true), canRtateMinHeight)
        case .locations:
            return 270.auto()
        case .locations_edit:
            return 270.auto()
        case .playControl:
            let menuHeigt = ADHomeDeviceMenuView.height(forWidth: width  , alertSupper : alertSupper, rotateEnable: rotate, whiteLight: light, showMore: false)
            if rotate {
                return max(menuHeigt + 145.auto() + 32.auto(), canRtateMinHeight)
            }else {
                return max(menuHeigt + 95.auto() + 32.auto(), canRtateMinHeight)
            }
        }
    }
}

extension HomeVideoDeviceControlView : ADRockerViewProtocol {
    // 摇杆开始回调

    func beginRocker(atView view: ADRockerView) {
        self.isRotate = true
        debugPrint("---------> ADRockerView began")
//        self.speakControlView.autoFollowBtnIsEnabled = false
    }
    
    func moveRocker(atView view: ADRockerView, moveToPoint point: CGPoint) {
        // v2.3 版暂废弃 - 2020.12.08 by wjin
        //weakSelf?.speakControlView.isFloow = false
        self.deviceRotateBlock?(point)
    }
    
    func moveEnd(atView view: ADRockerView) {
        self.isRotate = false
    }
    
    func moveEndDelay(atView view: ADRockerView) {
        debugPrint("---------> ADRockerView end")
        // 判断是否在摇杆
        if !(self.isRotate) {
//            self.speakControlView.autoFollowBtnIsEnabled = true
        }
    }
    
}


extension HomeVideoDeviceControlView : HomeVideoDeviceEditViewProtocol {
    func deviceLocationClose(ofView: HomeVideoDeviceEditView) {
//        self.protocol.close
//        self.editModleChangeBlock?(.show)
        self.protocol?.controlType(changeToType: ADHomeVideoPresetTypeModle.none)
    }
    
    func deviceLocationEdit(ofView: HomeVideoDeviceEditView, type: ADHomeVideoPresetTypeModle) {
//        self.editModleChangeBlock?(type)
        self.protocol?.controlType(changeToType: type)

    }
    
    func deviceLocationClick(ofView: HomeVideoDeviceEditView, location: ADPresetModel?, type: HomeVideoPresetCellType) {
//        self.editAction(type: type)
//        self.itemActionBlock?(location,type)
        self.protocol?.controlLocation(clickModle: location, clickType: type)

    }
    
    
}

extension HomeVideoDeviceControlView : AddxCircleControlProtocol {
    func onCircleTapAction(point: CGPoint) {
        self.deviceRotateBlock?(point)
    }
}

extension HomeVideoDeviceControlView : ADHomeDeviceCommandViewProtocol {
    func deviceCommandSpeak(type: ADHomeDeviceSpeakEnum) {
        self.protocol?.controlCommandSpeak(type: type)
    }
    
 
    
    func deviceCommandRotate() -> Bool {
        return self.canRotate
    }
    
}


extension HomeVideoDeviceControlView : ADHomeDeviceMenuViewProtocol {
    func deviceMenuClick(type: ADHomeDeviceMenuType, comple: @escaping (Bool) -> Void) {
        guard let pro = self.protocol else {
            comple(true)
            return
        }
        pro.deviceMenuAction(type: type, comple: comple)
    }
    
    func devcieSupperAlert() -> Bool {
        return supperAlert
    }
    
    func deviceVoiceIsOn() -> Bool {
        return deviceVoiceOn
    }
    
    func deviceRotateEnable() -> Bool {
        return canRotate
    }
    
    func deviceMoveIsHuman() -> Bool {
        return autoFollowBtnIsHumanImg
    }
    
    func deviceLightEnable() -> Bool {
        return lightEnable
    }
    
    func deviceLightisOn() -> Bool {
        return lightisOn
    }
    
    func deviceIsAdmin() -> Bool {
        return self.isFollowAdmin
    }
    
    func deviceIsShowMore() -> Bool {
        return false
    }
    
    func deviceIsAlerting() -> Bool {
        return true
    }
    
    func deviceShowMoreMenu() {
        
    }
    
    func deviceIsFllow() -> Bool {
        return self.isFollow && self.isFollowAdmin
    }
    
}
