//
//  ADLiveVideoControlView.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/3/25.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import Lottie
import A4xBaseSDK
import A4xWebRTCSDK

protocol ADLiveVideoControlProtocol : class {
    func videoBarBackAction()// 视频点击返回
    func videoBarSettingAction() //视频点击设置
    func videoAlarmAction()  //视频点击警告
    func videoSpeakAction(enable : Bool) -> Bool
    func videoVolumeAction(enable : Bool)
    func videoScreenSnap(view : UIView)
    func videoRecordVideo(start : Bool)
    func videoDetailChange(type : A4xVideoSharpType)
    func videoReconnect()
    func videoDisReconnect()
    func videoZoomChange()
    func deviceRotate(point : CGPoint)
    func resetLocationAction(type : LiveVideoPresetCellType , data : ADPresetModel?)
    func presetLocationAction()
    func videoControlWhiteLight(enable : Bool)
    func videoFllowChange(enable : Bool , comple : @escaping (_ isScuess : Bool)-> Void)
    /// 设备唤醒
    func deviceSleepToWakeUp(device : A4xDeviceModel?)
}

extension ADLiveVideoControlProtocol{
    func videoDisReconnect() {
        
    }
    
    func videoControlWhiteLight(enable: Bool){
        
    }
    
    func deviceRotate(point : CGPoint){
        
    }
    func resetLocationAction(type: LiveVideoPresetCellType, data: ADPresetModel?) {
        
    }
    func videoZoomChange() {}
    
    func videoFllowChange(enable : Bool , comple :@escaping (_ isScuess : Bool)-> Void){}
}


/// 按钮状态
///
/// - none:         默认状态
/// - run:          准备中
/// - runing:       运行中
/// - ending:       取消运行,取消运行后none
enum ADButtoneState {
    case none
    case run
    case runing
    case ending
    
}


/// 视频录制状态
///
/// - record: 录制中
/// - end: 结束录制
enum ADRecoredState {
    case none
    case record
}


class ADLiveVideoContentView : UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hidView = super.hitTest(point, with: event)
        if hidView == self {
            return nil
        }
        return hidView
    }
}

class ADLiveVideoControlView: UIView {
    
    let autoHiddenTime : TimeInterval = 6
    private let itemSize : CGSize = CGSize(width: 44.auto(), height: 44.auto())
    private let itemImageSize : CGSize = CGSize(width: 24, height: 24)
    private var recoredTimer : Timer?
    private var recoredTime : Int = 0
    
    private var lastScale : CGFloat = 1
    private var minScale : CGFloat = 1
    private var maxScale : CGFloat = 2
    var isAiPage : Bool = false
    var canRotate : Bool = true{
        didSet {
            self.moreMenuSubLeftView.rotateEnable = canRotate
        }
    }

    var isFllow : Bool = false {
        didSet {
            self.moreMenuSubLeftView.isFllow = isFllow
        }
    }
    
    var isFollowAdmin: Bool = false {
        didSet {
            self.moreMenuSubLeftView.fllowEnable = isFollowAdmin && canRotate
            self.resetLocation.isAdmin = isFollowAdmin
        }
    }
        
    // 追踪按钮替换人形追踪
    var autoFollowBtnIsHumanImg: Bool = true {
        didSet {
            self.moreMenuSubLeftView.isHuman = autoFollowBtnIsHumanImg
        }
    }
    
    
    var supperWhitelight : Bool = false {
        didSet {
            self.moreMenuSubLeftView.lightSupper = supperWhitelight
        }
    }
    
    var canRotating : Bool = false {
        didSet {
            self.moreMenuSubLeftView.rotateEnable = canRotating
            self.resetLocation.isEnabled = canRotating
            self.drawTapView.isUserInteractionEnabled = canRotating
            self.resetLocation.alpha = canRotating ? 1 : 0.7
            self.drawTapView.alpha = canRotating ? 1 : 0.7
        }
    }
    
    var isRotate: Bool = true {
        didSet { }
    }
    
    var whiteLight : Bool = false {
        didSet {
            self.moreMenuSubLeftView.lightEnable = whiteLight
        }
    }
    
    var recordEnable : Bool = true {
         didSet {
            self.recordButton.alpha = recordEnable ? 1 : 0
         }
     }
    
    lazy var doubleRecognier : UITapGestureRecognizer = {
        let rec = UITapGestureRecognizer(target: self, action: #selector(doubleTapVideoAction(sender:)))
        rec.delegate = self
        rec.numberOfTapsRequired = 2
        return rec
    }()
    
    lazy var oneTapRecognier : UITapGestureRecognizer = {
        let rec = UITapGestureRecognizer(target: self, action: #selector(tapVideoAction(sender:)))
        rec.numberOfTapsRequired = 1
        rec.delegate = self

        return rec
    }()
    
    private var recordButtonState : ADButtoneState = .none {
        didSet {
            updateRecoredButtonState();
        }
    }
    
    public var spackVoiceData : [Float] = [] {
        didSet {
            self.spakingView.pointLocation = spackVoiceData
        }
    }
    
    public var recordState : ADRecoredState = .none {
        didSet{
            updataRecoredState();
        }
    }
    
    public var downloadSpeed : String? {
        didSet {
            self.downloadSpeedLable.text = downloadSpeed
        }
    }
    
    /// 视频播放状态
    var videoState : A4xPlayerStateType = .finish {
        didSet {
            if oldValue != videoState {
                self.videoStateUpdate()
            }
            
        }
    }
    var audioEnable : Bool = true {
        didSet {
            self.volumeButton.isSelected = !audioEnable
        }
    }
    
    weak var `protocol` : ADLiveVideoControlProtocol?
    
    var dataSource : A4xDeviceModel? {
        didSet {
            deviceInfoUpdate()
        }
    }
    
    var presetListData : [ADPresetModel]? {
           didSet {
            self.resetLocation.presetListData = presetListData
           }
       }
    
    init(frame: CGRect = .zero , model : A4xDeviceModel = A4xDeviceModel()) {
        self.dataSource = model
        super.init(frame: frame)
        self.videoContentView.isHidden = false
        self.bottomImageV.isHidden = false
        self.topImageV.isHidden = false
        self.liveBgView.isHidden = false
        self.liveText.isHidden = false
        self.loadingView.isHidden = true
        self.errorView.isHidden = true
        self.moreButton.isHidden = false
        self.recordButton.isHidden = false
        self.screenShotButton.isHidden = false
        self.volumeButton.isHidden = false
        self.speakButton.isHidden = false
        self.spakingView.isHidden = true
        self.videoDetailButton.isHidden = false
        self.downloadSpeedLable.isHidden = true
        self.playBtn.isHidden = false
        self.drawTapView.isHidden = true
        self.backButton.isHidden = false
        
        self.moreMenuSubLeftView.isHidden = true
        
        //self.batterButton.isHidden = false || !(dataSource?.supperBatter() ?? false)

        self.resetLocation.isHidden = true
        self.deviceWifiStateImageV.isHidden = true
        self.contentView.addGestureRecognizer(self.doubleRecognier)
        self.contentView.addGestureRecognizer(self.oneTapRecognier)
        self.oneTapRecognier.require(toFail: self.doubleRecognier)
        videoStateUpdate()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    weak var videoView : UIView? {
        didSet {
            videoContentView.playerView = videoView
        }
    }
    
    lazy var videoContentView : ADVideoNewView = {
        let temp = ADVideoNewView()
        temp.clipsToBounds = true
        temp.isUserInteractionEnabled = true
        self.contentView.insertSubview(temp, at: 0)
        weak var weakSelf = self
        temp.snp.makeConstraints({ (make) in
            make.edges.equalTo(self.snp.edges)
        })
        
        return temp
    }()
    
    
    lazy private var contentView : ADLiveVideoContentView =  {
        let temp = ADLiveVideoContentView()
        self.addSubview(temp)
        
        temp.snp.makeConstraints { (make) in
            if #available(iOS 11.0,*) {
                make.edges.equalTo(self.safeAreaLayoutGuide.snp.edges)
            }else {
                make.edges.equalTo(self.snp.edges)
            }
        }
        
        return temp
    }()
    
    lazy var topImageV : ADShareView = {
        let temp = ADShareView()
        temp.isUserInteractionEnabled = false
        temp.setColors(values: (UIColor.hex(0x000000, alpha: 0.5), 0) , (UIColor.hex(0x000000, alpha: 0.0), 1))
        self.videoContentView.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.top.equalTo(self.snp.top)
            make.height.equalTo(self.snp.height).multipliedBy(0.4)
            make.left.equalTo(0)
            make.width.equalTo(self.snp.width)
        })
        
        return temp
    }()
    
    lazy var bottomImageV : ADShareView = {
        let temp = ADShareView()
        temp.isUserInteractionEnabled = false
        temp.setColors(values: (UIColor.hex(0x000000, alpha: 0), 0) , (UIColor.hex(0x000000, alpha: 0.5), 1))
        self.videoContentView.addSubview(temp)
        temp.snp.makeConstraints({ (make) in
            make.bottom.equalTo(self.snp.bottom)
            make.height.equalTo(self.snp.height).multipliedBy(0.4)
            make.left.equalTo(0)
            make.width.equalTo(self.snp.width)
        })
        
        return temp
    }()
    
    // 录屏计时显示
    lazy var recoredTimeLabel : UILabel = {
        let temp = UILabel()
        temp.textAlignment = .center
        temp.backgroundColor = .red //UIColor(white: 0, alpha: 0.3)
        temp.layer.cornerRadius = 18.25.auto()
        temp.clipsToBounds = true
        temp.font = ADTheme.B2
        temp.textColor = UIColor.white
        temp.isHidden = true
        self.contentView.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.centerY.equalTo(self.backButton.snp.bottom)
            make.centerX.equalTo(self.contentView.snp.centerX)
            make.width.equalTo(75.auto())
            make.height.equalTo(36.5.auto())
        })
        
        return temp
    }()
    
    // 返回按钮
    lazy var backButton : UIButton = {
        let temp = UIButton()
        temp.setImage(R.image.icon_back_write(), for: .normal)
        temp.imageView?.size = itemImageSize
        temp.backgroundColor = .clear
        self.contentView.addSubview(temp)
        
        temp.contentHorizontalAlignment = .center
        temp.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        temp.addTarget(self, action: #selector(videoBarBackAction(sender:)), for: UIControl.Event.touchUpInside)
        let top = UIScreen.horStatusBarHeight
        let itHeight = ItemLandscapeHeight
        let left = 22
        
        temp.snp.makeConstraints({ (make) in
            if #available(iOS 11.0,*) {
                if UIApplication.isIPhoneX() {
                    make.left.equalTo(self.safeAreaLayoutGuide.snp.left).offset(left * 2)
                } else {
                    make.left.equalTo(left)
                }
            } else {
                make.left.equalTo(left)
            }
            make.top.equalTo(top)
            make.size.equalTo(itemSize)
        })
        return temp
    }()
    
    lazy var liveAnimailView : AnimationView = {
        
        let temp = AnimationView(name: "live_play_animail")
        temp.loopMode = .loop

        self.liveBgView.addSubview(temp)
        temp.snp.makeConstraints({ (make) in
            make.width.equalTo(12.auto())
            make.height.equalTo(12.auto())
            make.left.equalTo(3.auto())
            make.centerY.equalTo(self.liveBgView)
        })
        return temp

    }()
    
    lazy var liveBgView : UIView = {
        let temp = UIView()
        temp.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        temp.cornerRadius = 11.auto()
        temp.clipsToBounds = true
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.height.equalTo(22.auto())
            make.left.equalTo(self.backButton.snp.right)
            make.centerY.equalTo(self.backButton.snp.centerY)
        })
        return temp
    }()
    
    lazy var liveText : UILabel = {
        let temp = UILabel()
        self.liveBgView.addSubview(temp)
        temp.font = ADTheme.B3
        temp.textColor = UIColor.white
        temp.setContentHuggingPriority(UILayoutPriority.required, for: NSLayoutConstraint.Axis.horizontal)
        temp.text = R.string.localizable.live()
        let width = temp.sizeThatFits(CGSize(width: 200, height: 16))
        temp.snp.makeConstraints({ (make) in
            make.height.equalTo(22.auto())
            make.left.equalTo(self.liveAnimailView.snp.right).offset(5)
            make.centerY.equalTo(self.liveBgView)
            make.right.equalTo(self.liveBgView.snp.right).offset(-5.auto())
        })
        
        return temp
    }()
    
   
    
    // 更多按钮
    lazy var moreButton : UIButton = {
        let temp = UIButton()
        temp.setImage(R.image.live_video_more(), for: .normal)
        temp.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        temp.contentHorizontalAlignment = .center
        temp.contentMode = .center
        self.contentView.addSubview(temp)
        
        temp.addTarget(self, action: #selector(moreMenuAction(sender:)), for: UIControl.Event.touchUpInside)
        let top = UIScreen.horStatusBarHeight
        let itHeight = ItemLandscapeHeight
        let right = -12
        
        temp.snp.makeConstraints({ (make) in
            if #available(iOS 11.0,*) {
                if UIApplication.isIPhoneX() {
                    make.right.equalTo(self.safeAreaLayoutGuide.snp.right).offset(right * 2 - 12)
                } else {
                    make.right.equalTo(self.contentView.snp.right).offset(right)
                }
            } else {
                make.right.equalTo(self.contentView.snp.right).offset(right)
            }
            make.centerY.equalTo(self.backButton.snp.centerY)
            make.size.equalTo(itemSize)
        })
        return temp
    }()
    
    //
    lazy var moreMenuSubLeftView: ADLiveVideoMoreMenuView = {
        let admin = self.dataSource?.isAdmin() ?? false
        let rotate = self.dataSource?.deviceContrl?.rotate ?? false
        let supperAlert = self.dataSource?.deviceSupport?.deviceSupportAlarm ?? false
        let temp = ADLiveVideoMoreMenuView(supperAlert: supperAlert, rotateEnable: rotate, lightSupper: self.dataSource?.deviceContrl?.whiteLight ?? false , fllowEnable: admin && rotate)
        temp.protocol = self
        self.addSubview(temp)
        temp.quitBlock = { [weak self] in
            self?.moreMenuSubLeftView.isHidden = true
        }
        return temp
    }()
    
    
    // 收藏位置subview
    lazy var resetLocation : ADLiveVideoPresetLocationView = {
        let temp = ADLiveVideoPresetLocationView()
        temp.isEnabled = true
        weak var weakSelf = self
        // 全屏新增预设位置
        temp.itemActionBlock = { (modle ,type) in
            if case .none = type {
                weakSelf?.isFllow = false
            }
            weakSelf?.protocol?.resetLocationAction(type: type, data: modle)
        }
        temp.colseVideoBlock = {
            weakSelf?.resetLocation.frame = CGRect(x:  self.maxX, y: 0, width: 170.auto(), height: self.height)
            weakSelf?.moreMenuSubLeftView.isHidden = false
            weakSelf?.moreMenuSubLeftView.frame = CGRect(x: self.maxX - 222.auto(), y: 0, width: 222.auto(), height: self.height)

        }
        self.addSubview(temp)
        return temp
    }()
    
    lazy var videoDetailListView : ADVideoSharpDialog = {
        let temp = ADVideoSharpDialog()
        temp.selectDataBlock = {[weak self] detail in
            self?.protocol?.videoDetailChange(type: detail)
            self?.visableVideoDetailView(show: false)
        }
        temp.backgroundColor = UIColor.hex(0x1D1C1C, alpha: 0.8)
        temp.isHidden = true
        self.addSubview(temp)
        return temp
    }()
    
    
    // 视频清晰度按钮
    lazy var videoDetailButton : UIButton = {
        let temp = UIButton()
        temp.setTitle(A4xVideoSharpType.hb.name(), for: .normal)
        temp.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        temp.setTitleColor(UIColor.white, for: .normal)
        temp.titleLabel?.font = ADTheme.B2
        temp.contentHorizontalAlignment = .center
        temp.contentMode = .center
        self.contentView.addSubview(temp)

        temp.addTarget(self, action: #selector(videoDetailAction), for: UIControl.Event.touchUpInside)
        let top = UIScreen.horStatusBarHeight
        let itHeight = ItemLandscapeHeight
        let right = -8
        
        temp.snp.makeConstraints({ (make) in
            make.right.equalTo(self.moreButton.snp.left).offset(-right)
            make.centerY.equalTo(self.backButton.snp.centerY)
            make.size.equalTo(CGSize(width: 80, height: 44))
        })
        return temp
    }()
    
    // Wi-Fi信号展示
    lazy var deviceWifiStateImageV : UIImageView = {
        let imageV = UIImageView()
        self.contentView.addSubview(imageV)
        let itemSize : CGSize = CGSize(width: 24, height: 24)
        imageV.snp.makeConstraints({ (make) in
            make.right.equalTo(self.videoDetailButton.snp.left).offset(-57.5.auto())
            make.centerY.equalTo(self.moreButton.snp.centerY)
            make.size.equalTo(itemSize)
        })
        return imageV
    }()
    
    // 直播网速显示
    lazy var downloadSpeedLable : UILabel = {
        let temp = UILabel()
        temp.textAlignment = .right
        temp.textColor = UIColor.white
        temp.font = ADTheme.B3
        self.contentView.addSubview(temp)
        temp.snp.makeConstraints({ (make) in
            make.left.equalTo(self.deviceWifiStateImageV.snp.right)
            make.centerY.equalTo(self.moreButton.snp.centerY)
        })
        return temp
    }()
    
    private lazy
    var drawTapView : AddxCircleControl = {
        let temp = AddxCircleControl()
        temp.visableColors = [UIColor.hex(0x000000, alpha: 0.2) , UIColor.hex(0x000000, alpha: 0.2)]
        temp.lineColor = UIColor.hex(0xFFFFFF, alpha: 0.3)
        temp.borderColor = UIColor.hex(0xFFFFFF, alpha: 0.3)
        temp.onCircleTapBlock = {[weak self] point in
            self?.protocol?.deviceRotate(point: point)
        }
        self.addSubview(temp)
        temp.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.snp.centerY).offset(-20.auto())
            make.right.equalTo(self.moreButton.snp.right).offset(-15.auto())
            make.size.equalTo(CGSize(width: 145.auto(), height: 145.auto()))
        }
        return temp
    }()
    
    // 直播摇杆
//    lazy var rockerView : ADRockerView = {
//        let temp = ADRockerView(frame: CGRect.zero, type: ADRockerType.light)
//        weak var weakSelf = self
//        // 摇杆开始回调
//        temp.beganPockerBlock = {
//            weakSelf?.isRotate = true
//            debugPrint("---------> ADRockerView began")
//        }
//
//        // 摇杆中
//        temp.updatePockerBlock = { point in
//            // v2.3 版暂废弃 - 2020.12.08 by wjin
//            //weakSelf?.isFllow = false
//            weakSelf?.protocol?.deviceRotate(point: point)
//        }
//
//        // 摇杆结束
//        temp.endPockerBlock = {
//            weakSelf?.isRotate = false
//        }
//
//        // 摇杆结束追踪按钮释放
//        temp.endPockerBlockAfter = {
//            debugPrint("---------> ADRockerView end")
//        }
//
//        self.addSubview(temp)
//
//        temp.snp.makeConstraints { (make) in
//            make.centerY.equalTo(self.snp.centerY).offset(-20.auto())
//            make.right.equalTo(self.moreButton.snp.right).offset(-15.auto())
//            make.size.equalTo(CGSize(width: 145.auto(), height: 145.auto()))
//        }
//
//        return temp
//    }()
    
    // 麦克风
    lazy var speakButton : ADLiveSpeakImageView = {
        let temp = ADLiveSpeakImageView()
        temp.setImage(R.image.video_live_speak(), for: UIControl.State.normal)
        temp.contentMode = .center
        self.contentView.addSubview(temp)
        weak var weakSelf = self
        temp.touchAction = { en in
            switch en {
            case .down:
                //weakSelf?.makeToast(R.string.localizable.hold_speak())
                weakSelf?.videoSpeakActiond()
            case .up:
                weakSelf?.videoSpeakAction()
            case .tap:
                weakSelf?.videoSpeakShot()
            }
        }
        temp.snp.makeConstraints({ (make) in
            make.centerX.equalTo(self.drawTapView.snp.centerX)
            //make.bottom.equalTo(self.contentView.snp.bottom).offset(-50.auto())
            make.top.equalTo(self.drawTapView.snp.bottom).offset(16.auto())
            make.size.equalTo(CGSize(width: 64.8.auto(), height: 64.8.auto()))
        })
        return temp
    }()
    
    // 电量展示
//    lazy var batterButton : A4xBaseBatteryView = {
//        let temp = A4xBaseBatteryView()
//        self.contentView.addSubview(temp)
//        temp.batterStyle = .light
//        let top = UIScreen.horStatusBarHeight
//        let itHeight = ItemLandscapeHeight
//        let right = -12
//
//        temp.snp.makeConstraints({ (make) in
//            make.centerX.equalTo(self.moreButton.snp.centerX)
//            make.top.equalTo(self.snp.top).offset(5)
//            make.size.equalTo(CGSize(width:20.auto(), height: 12.auto()))
//        })
//        return temp
//    }()
    
    // 语音动画
    lazy var spakingView : ADHomeDeviceVoiceWarView = {
        let temp = ADHomeDeviceVoiceWarView()
        temp.backgroundColor = UIColor(white: 0, alpha: 0.3)
        temp.layer.cornerRadius = 36.auto() / 2
        temp.clipsToBounds = true
        self.addSubview(temp)
                
        temp.snp.makeConstraints({ (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.bottom.equalTo(self.snp.bottom).offset(-19.5.auto())
            make.size.equalTo(CGSize(width: 134.5.auto(), height: 36.auto()))
        })
        return temp
    }()
    
    
    // 录像按钮
    lazy var recordButton : UIButton = {
        let temp = UIButton()
        temp.setImage(R.image.live_video_record_normail(), for: .normal)
        temp.setImage(R.image.live_video_record_selected(), for: .selected)
        temp.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        temp.contentHorizontalAlignment = .center
        temp.contentMode = .center
        temp.backgroundColor = UIColor(white: 0, alpha: 0.3)
        temp.layer.cornerRadius = itemSize.height / 2
        temp.clipsToBounds = true
        self.contentView.addSubview(temp)

        temp.addTarget(self, action: #selector(videoRecordVideo(sender:)), for: UIControl.Event.touchUpInside)
        let top = UIScreen.horStatusBarHeight
        let itHeight = ItemLandscapeHeight
        let right = -12

        temp.snp.makeConstraints({ (make) in
            make.bottom.equalTo(self.snp.centerY).offset(-16.auto())
            make.centerX.equalTo(self.backButton.snp.centerX)
            make.size.equalTo(itemSize)
        })
        return temp
    }()
    
    // 截屏按钮
    lazy var screenShotButton : UIButton = {
        let temp = UIButton()
        temp.setImage(R.image.video_live_screen_shot(), for: .normal)
        temp.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        temp.contentHorizontalAlignment = .center
        temp.contentMode = .center
        temp.backgroundColor = UIColor(white: 0, alpha: 0.3)
        temp.layer.cornerRadius = itemSize.height / 2
        temp.clipsToBounds = true

        self.contentView.addSubview(temp)

        temp.addTarget(self, action: #selector(videoScreenSnap(sender:)), for: UIControl.Event.touchUpInside)
        let top = UIScreen.horStatusBarHeight
        let itHeight = ItemLandscapeHeight
        let right = 0

        temp.snp.makeConstraints({ (make) in
            make.top.equalTo(self.snp.centerY).offset(15.5.auto())
            make.centerX.equalTo(self.backButton.snp.centerX)
            make.size.equalTo(itemSize)
        })
        return temp
    }()
    
    // 声音开关
    lazy var volumeButton : UIButton = {
        let temp = UIButton()
        temp.setImage(R.image.video_live_volume(), for: .normal)
        temp.setImage(R.image.video_live_volume_mute(), for: .selected)
        temp.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        temp.contentHorizontalAlignment = .center
        temp.contentMode = .center
        temp.backgroundColor = UIColor(white: 0, alpha: 0.3)
        temp.layer.cornerRadius = itemSize.height / 2
        temp.clipsToBounds = true
        self.contentView.addSubview(temp)
        
        temp.addTarget(self, action: #selector(videoVolumeAction(sender:)), for: UIControl.Event.touchUpInside)
        temp.snp.makeConstraints({ (make) in
            make.top.equalTo(self.screenShotButton.snp.bottom).offset(32.auto())
            make.centerX.equalTo(self.screenShotButton.snp.centerX)
            make.size.equalTo(itemSize)
        })
        return temp
    }()
    
    // 直播播放按钮
    lazy var playBtn : UIButton = {
        let temp = UIButton()
        temp.setImage(UIImage(named: "video_play"), for: UIControl.State.normal)
        temp.setImage(UIImage(named: "video_pause"), for: UIControl.State.selected)
        temp.addTarget(self, action: #selector(playVideoAction), for: .touchUpInside)
        self.addSubview(temp)
        temp.snp.makeConstraints({ (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.centerY.equalTo(self.snp.centerY)
            make.size.equalTo(CGSize(width: 70.auto(), height: 70.auto()))
        })
        return temp
    }()

    //MARK:- view 创建
    lazy var loadingView : HomeVideoLoadingView = {
        let temp = HomeVideoLoadingView()
        temp.loadingImg.image = R.image.live_video_loading()
        self.contentView.addSubview(temp)
        temp.snp.makeConstraints({ (make) in
            make.centerX.equalTo(self.contentView.snp.centerX).offset(8.auto())
            make.centerY.equalTo(self.contentView.snp.centerY)
        })
        return temp
    }()
    
    lazy var errorView : HomeVideoErrorView = {
        let temp = HomeVideoErrorView(frame: .zero, maxWidth: 500)
        self.contentView.insertSubview(temp, belowSubview: self.backButton)
        temp.buttonClickAction = { [weak self] type in
            // 横屏直播错误点击处理
            if case .sleepPlan = type { // 横屏休眠唤醒点击
                self?.protocol?.deviceSleepToWakeUp(device: self?.dataSource)
            } else {
                self?.protocol?.videoReconnect()
            }
        }
        temp.snp.makeConstraints({ (make) in
            make.centerX.equalTo(self.contentView.snp.centerX)
            make.centerY.equalTo(self.contentView.snp.centerY)
            make.width.equalTo(self.contentView.snp.width)
            make.height.equalTo(self.contentView.snp.height)
        })
        return temp
    }()
    
    @objc
    func playVideoAction(){
        if !self.playBtn.isSelected {
            self.protocol?.videoReconnect()
        }else {
            self.protocol?.videoDisReconnect()
        }
    }
    
    deinit {
        A4xLog("ADLiveVideoControlView deinit")
    }
//    func reset () {
//        self.scrollView.setZoomScale(1, animated: true)
//
//    }
}

extension ADLiveVideoControlView {
    
    func free() {
        self.recoredTimer?.invalidate()
        self.recoredTimer = nil
        spakingView.free()
    }
    
    func visableVideoDetailView(show : Bool) {
        videoDetailListView.frame = CGRect(x: self.maxX, y: 0, width: 222.auto(), height: self.height)
        videoDetailListView.dataSouces = A4xVideoSharpType.all()
        if let data = self.dataSource {
            videoDetailListView.selectData = A4xPlayerManager.handle.getVideoDetail(device: data)
        }
        self.videoDetailListView.isHidden = false
        UIView.animate(withDuration: 0.3, animations: {
            self.videoDetailListView.frame = CGRect(x: show ? self.maxX - 170.auto() : self.maxX, y: 0, width: 170.auto(), height: self.height)
        }) { (f) in
        }
    }
    
    @objc
    private func locationButtonAction(){
        self.protocol?.presetLocationAction()
        self.resetLocation.frame = CGRect(x: self.maxX, y: 0, width: 222.auto(), height: self.height)
        self.resetLocation.isHidden = false
        self.resetLocation.frame = CGRect(x: self.maxX - 222.auto(), y: 0, width: 222.auto(), height: self.height)
        // 点击收藏点事件
        let playVideoEM = A4xPlayVideoEventModel()
        playVideoEM.live_player_type = "fullscreen"
        A4xEventManager.endEvent(event:ADTickerPlayVideo.live_remoteControl_savePoint_show(eventModel: playVideoEM))
    }
    
    func visableLocationView(show : Bool) {
        UIView.animate(withDuration: 0.3, animations: {
            self.resetLocation.frame = CGRect(x: show ? self.maxX - 170.auto() : self.maxX, y: 0, width: 170.auto(), height: self.height)
        }) { (f) in
        }
    }
    
    @objc
    private func connectionVideoAction(){
        self.protocol?.videoReconnect()
    }
    
    func updataRecoredState() {
        switch self.recordState {
        case .none:
            self.recordButtonState = .none
        case .record:
            self.changeButtonVisable(toHidden: true)
            self.recordButtonState = .runing
        }
    }
    
    @objc
    private func updateRecoredInfo(){
        self.recoredTime += 1
        self.recoredTimeLabel.text = String(format: "%02d:%02d", self.recoredTime / 60, self.recoredTime % 60);
    }
    
    func updateRecoredButtonState() {
        switch self.recordButtonState {
        case .none:
            self.recordButton.isSelected = false
            self.recoredTimer?.invalidate()
            self.recoredTimer = nil
            self.recoredTimeLabel.isHidden = true
        case .runing:
            self.recoredTimeLabel.isHidden = false
            self.recordButton.isSelected = true
            self.recoredTime = 0
            self.recoredTimer = Timer(timeInterval: 1, target: self, selector: #selector(updateRecoredInfo), userInfo: nil, repeats: true)
            self.updateRecoredInfo()
            RunLoop.current.add(self.recoredTimer!, forMode: .common)
        default:
            return
        }
    }
    
    private func noneStyle() {
        self.liveBgView.isHidden = true
        self.liveAnimailView.stop()
        self.loadingView.isHidden = true
//        self.errorView.isHidden = true
//        self.moreButton.isHidden = true
//        self.errorView.error = ""
//        self.errorView.supportTitle = R.string.localizable.reconnect()

        self.errorView.isHidden = true
        self.errorView.localRemoveGradientLayer()
        self.moreButton.isHidden = true
        // self.locationButton.isHidden = true
        // self.fllowButton.isHidden = true
        self.drawTapView.isHidden = true
        self.downloadSpeedLable.isHidden = true
        self.deviceWifiStateImageV.isHidden = true
        //self.batterButton.isHidden = true
        self.recordButton.isHidden = true
        self.screenShotButton.isHidden = true
        self.volumeButton.isHidden = true
        self.speakButton.isHidden = true
        // self.warningButton.isHidden = true
        // self.lightButton.isHidden = true
        self.videoDetailButton.isHidden = true
        self.hiddenSharpDialog()
        self.playBtn.isSelected = false
        self.playBtn.isHidden = false
        
        self.hiddenMenu()

    }
    
    private func loadingStyle() {
        self.liveBgView.isHidden = true
        self.liveAnimailView.stop()

        self.loadingView.isHidden = false
        self.errorView.isHidden = true
        self.errorView.localRemoveGradientLayer()
        self.moreButton.isHidden = true
        // self.locationButton.isHidden = true
        // self.fllowButton.isHidden = true
        self.drawTapView.isHidden = true
        self.downloadSpeedLable.isHidden = true
        self.deviceWifiStateImageV.isHidden = true
        //self.batterButton.isHidden = true
        self.recordButton.isHidden = true
        self.screenShotButton.isHidden = true
        self.volumeButton.isHidden = true
        self.speakButton.isHidden = true
        // self.warningButton.isHidden = true
        // self.lightButton.isHidden = true
        self.videoDetailButton.isHidden = true
        self.loadingView.startAnimail()
        self.playBtn.isHidden = true

    }
    
    private func aiplayingStyle() {
        self.loadingView.stopAnimail()
        self.topImageV.removeFromSuperview()
        self.bottomImageV.removeFromSuperview()
        self.topImageV.isHidden = true
        self.bottomImageV.isHidden = true
        self.loadingView.isHidden = true
        self.errorView.isHidden = true
        self.errorView.localRemoveGradientLayer()
        self.liveBgView.isHidden = true
        self.liveAnimailView.stop()
        
        self.moreButton.isHidden = false
        // self.locationButton.isHidden = true
        // self.fllowButton.isHidden = true
        
        self.drawTapView.isHidden = true
        self.downloadSpeedLable.isHidden = true
        self.deviceWifiStateImageV.isHidden = true
        //self.batterButton.isHidden = true
        self.recordButton.isHidden = false
        self.screenShotButton.isHidden = true
        self.volumeButton.isHidden = true
        self.speakButton.isHidden = true
        // self.warningButton.isHidden = true
        // self.lightButton.isHidden = true
        self.videoDetailButton.isHidden = true
        weak var weakSelf = self
        // 全屏直播自动隐藏处理
        DispatchQueue.main.a4xAfter(self.autoHiddenTime) {
            if weakSelf != nil && weakSelf?.videoState == .playing && weakSelf?.spakingView.isHidden ?? true  {
                weakSelf?.changeButtonVisable()
            }
        }
    }
    
    private func playingStyle() {
        self.loadingView.stopAnimail()
        self.volumeButton.isSelected = false
        self.loadingView.isHidden = true
        self.errorView.isHidden = true
        self.errorView.localRemoveGradientLayer()
        self.liveBgView.isHidden = false
        self.liveAnimailView.play()
        self.moreButton.isHidden = false
        // self.locationButton.isHidden = !canRotate
        // self.fllowButton.isHidden = !canRotate
        self.drawTapView.isHidden = !canRotate
        self.downloadSpeedLable.isHidden = false
        self.deviceWifiStateImageV.isHidden = false
        //self.batterButton.isHidden = false || !(dataSource?.supperBatter() ?? false)
        self.recordButton.isHidden = false
        self.screenShotButton.isHidden = false
        self.volumeButton.isHidden = false
        self.speakButton.isHidden = false
        if self.canRotate {
            self.speakButton.snp.remakeConstraints({ (make) in
                make.centerX.equalTo(self.drawTapView.snp.centerX)
                //make.bottom.equalTo(self.contentView.snp.bottom).offset(-50.auto())
                make.top.equalTo(self.drawTapView.snp.bottom).offset(16.auto())
                make.size.equalTo(CGSize(width: 64.8.auto(), height: 64.8.auto()))
            })
        }else {
            self.speakButton.snp.remakeConstraints({ (make) in
                make.right.equalTo(self.moreButton.snp.right).offset(-15.auto())
                make.centerY.equalTo(self.snp.centerY)
                make.size.equalTo(CGSize(width: 64.8.auto(), height: 64.8.auto()))
            })
        }
        
        // self.warningButton.isHidden = false
        // self.lightButton.isHidden = !self.supperWhitelight
        self.videoDetailButton.isHidden = false
        weak var weakSelf = self
        DispatchQueue.main.a4xAfter(self.autoHiddenTime) {
            if weakSelf != nil && weakSelf?.videoState == .playing && weakSelf?.spakingView.isHidden ?? true  {
                weakSelf?.changeButtonVisable()
            }
        }
        self.playBtn.isHidden = true
        self.playBtn.isSelected = true
    }
    
    private func pausedStyle() {
        self.liveBgView.isHidden = true
        self.liveAnimailView.stop()
        self.loadingView.isHidden = true
        self.errorView.isHidden = true
        self.errorView.localRemoveGradientLayer()
        self.moreButton.isHidden = true
        // self.locationButton.isHidden = true
        // self.fllowButton.isHidden = true
        self.drawTapView.isHidden = true
        self.downloadSpeedLable.isHidden = true
        self.deviceWifiStateImageV.isHidden = true
        //self.batterButton.isHidden = true
        self.recordButton.isHidden = true
        self.screenShotButton.isHidden = true
        self.volumeButton.isHidden = true
        self.speakButton.isHidden = true
        // self.warningButton.isHidden = true
        // self.lightButton.isHidden = true
        self.videoDetailButton.isHidden = true
        self.playBtn.isHidden = false
        self.playBtn.isSelected = true
        
        self.hiddenMenu()

    }
    private func pausedp2pStyle() {
        self.liveBgView.isHidden = true
        self.liveAnimailView.stop()
        self.loadingView.isHidden = true
        self.errorView.isHidden = true
        self.errorView.localRemoveGradientLayer()
        self.moreButton.isHidden = true
        // self.locationButton.isHidden = true
        self.drawTapView.isHidden = true
        // self.fllowButton.isHidden = true
        self.downloadSpeedLable.isHidden = true
        self.deviceWifiStateImageV.isHidden = true
        //self.batterButton.isHidden = true
        self.recordButton.isHidden = true
        self.screenShotButton.isHidden = true
        self.volumeButton.isHidden = true
        self.speakButton.isHidden = true
        // self.warningButton.isHidden = true
        // self.lightButton.isHidden = true
        self.videoDetailButton.isHidden = true
        self.playBtn.isHidden = false
        self.playBtn.isSelected = false
   
        self.hiddenMenu()

    }
    private func doneStyle() {
        
    }
    
    private func playStateUnuseError(isFock : Bool) {
        self.loadingView.stopAnimail()
        self.errorView.localRemoveGradientLayer()
        let deviceVersion = self.dataSource?.newFirmwareId ?? ""
        if self.dataSource?.isAdmin() ?? false {
            self.errorView.error = R.string.localizable.forck_update(deviceVersion)
//            self.errorView.buttonItems = [HomeVideoItem(style: .theme, action: .upgrade, title: R.string.localizable.go_set())]
            if isFock {
                self.errorView.forceUpgradeButton()
            }else {
                self.errorView.upgradeButton()
            }
            self.errorView.tipIcon = R.image.device_connect_supper()
        }else {
            if !isFock {
                self.errorView.error = R.string.localizable.forck_update_share(deviceVersion)
                self.errorView.buttonItems = [HomeVideoItem(style: .line, action: .video(title:  R.string.localizable.do_not_update(), style: .line))]
            }else {
                self.errorView.error = R.string.localizable.forck_update_share(deviceVersion) + "\n\n" + R.string.localizable.unavailable_before_upgrade()
            }
            self.errorView.tipIcon = R.image.device_connect_supper()
        }
        

        self.liveBgView.isHidden = true
        self.liveAnimailView.stop()

        self.loadingView.isHidden = true
        self.errorView.isHidden = false
        self.moreButton.isHidden = true
        self.downloadSpeedLable.isHidden = true
        self.deviceWifiStateImageV.isHidden = true
        // self.locationButton.isHidden = true
        self.drawTapView.isHidden = true
        // self.fllowButton.isHidden = true
        //self.batterButton.isHidden = true
        self.recordButton.isHidden = true
        self.screenShotButton.isHidden = true
        self.volumeButton.isHidden = true
        self.speakButton.isHidden = true
        // self.warningButton.isHidden = true
        // self.lightButton.isHidden = true
        self.videoDetailButton.isHidden = true
        self.hiddenSharpDialog()
        self.playBtn.isHidden = true

        self.hiddenMenu()
    }
    
    private func errorStyle(error : String , action : A4xVideoAction? ,tipIcon : UIImage?) {
        self.loadingView.stopAnimail()
        self.errorView.error = error
        self.errorView.localRemoveGradientLayer()
        if let action = action  {
            var viewStyle : HomeVideoButtonStyle = .line
            if let style = action.style() {
                switch style {
                case .theme:
                    viewStyle = .theme
                case .line:
                    viewStyle = .line
                case .none:
                    viewStyle = .none
                }
            }
            self.errorView.buttonItems = [HomeVideoItem(style: viewStyle, action: action)]
        }else {
            self.errorView.buttonItems = []
        }
        self.errorView.tipIcon = tipIcon

        self.liveBgView.isHidden = true
        self.liveAnimailView.stop()

        self.loadingView.isHidden = true
        self.errorView.isHidden = false
        self.moreButton.isHidden = true
        self.downloadSpeedLable.isHidden = true
        self.deviceWifiStateImageV.isHidden = true
        // self.locationButton.isHidden = true
        self.drawTapView.isHidden = true
        // self.fllowButton.isHidden = true
        //self.batterButton.isHidden = true
        self.recordButton.isHidden = true
        self.screenShotButton.isHidden = true
        self.volumeButton.isHidden = true
        self.speakButton.isHidden = true
        // self.warningButton.isHidden = true
        // self.lightButton.isHidden = true
        self.videoDetailButton.isHidden = true
        self.hiddenSharpDialog()
        self.playBtn.isHidden = true
        
        if error == R.string.localizable.camera_sleep() {
            self.playStateSleepPlan(sleepPlanIntro: error)
        }

        self.hiddenMenu()
    }
    
    // 横屏直播休眠状态处理UI
    private func playStateSleepPlan(sleepPlanIntro: String) {
        var sleepTips = sleepPlanIntro
        let startColor = UIColor.colorFromHex("#06241C")
        let endColor = UIColor.colorFromHex("#020106")
        self.errorView.gradientColor(CGPoint(x:0, y:0), CGPoint(x:1, y:1), [startColor.cgColor, endColor.cgColor])
        self.errorView.type = .default
        self.errorView.tipIcon = R.image.home_sleep_plan()
        self.errorView.buttonItems = []
        if self.dataSource?.isAdmin() ?? true { // 判断设备是否是非分享设备
            self.errorView.sleepPlanButton()
        } else {
            sleepTips += "\n\n" + R.string.localizable.admin_wakeup_camera()
        }
        self.errorView.error = sleepTips.isBlank ? R.string.localizable.camera_sleep() : sleepTips
    }
    
    func hiddenMenu(){
        self.resetLocation.frame = CGRect(x: self.maxX, y: 0, width: 170.auto(), height: self.height)
        self.resetLocation.isHidden = true
        self.moreMenuSubLeftView.frame = CGRect(x: self.maxX, y: 0, width: 222.auto(), height: self.height)
        self.moreMenuSubLeftView.isHidden = true
        self.videoDetailListView.frame = CGRect(x: self.maxX, y: 0, width: 222.auto(), height: self.height)
        self.videoDetailListView.isHidden = true
        self.spakingView.isHidden = true
        self.spakingView.free()
    }
    
    // 全屏点击屏幕处理
    @objc func doubleTapVideoAction(sender : UITapGestureRecognizer){
//        if self.scrollView.zoomScale > self.scrollView.minimumZoomScale {
//            self.scrollView.setZoomScale(self.scrollView.minimumZoomScale, animated: true)
//        }else {
//            self.scrollView.setZoomScale(self.scrollView.maximumZoomScale, animated: true)
//        }
        self.protocol?.videoZoomChange()
        changeButtonVisable(toHidden: false)
    }
    
    @objc
    func tapVideoAction(sender : UITapGestureRecognizer){
        if !self.resetLocation.isHidden {
            UIView.animate(withDuration: 0.3, animations: {
                self.resetLocation.frame = CGRect(x: self.maxX, y: 0, width: 170.auto(), height: self.height)
            }) { (f) in
             self.resetLocation.isHidden = true
            }
        }
        
        if !self.moreMenuSubLeftView.isHidden {
            UIView.animate(withDuration: 0.3, animations: {
                self.moreMenuSubLeftView.frame = CGRect(x: self.maxX, y: 0, width: 222.auto(), height: self.height)
                self.moreMenuSubLeftView.updateFrame()
            }) { (f) in
             self.moreMenuSubLeftView.isHidden = true
            }
        }
        if !self.videoDetailListView.isHidden {
            UIView.animate(withDuration: 0.3, animations: {
                self.videoDetailListView.frame = CGRect(x: self.maxX, y: 0, width: 222.auto(), height: self.height)
            }) { (f) in
             self.videoDetailListView.isHidden = true
            }
        }
        
        self.changeButtonVisable()
    }
  
    private func changeButtonVisable(toHidden : Bool? = nil){
        let isHidden : Bool = toHidden == nil ? !self.moreButton.isHidden : toHidden!

        UIView.animate(withDuration: 0.2) {
            if self.videoState == .playing {
                self.topImageV.isHidden = isHidden
                self.bottomImageV.isHidden = isHidden
                self.moreButton.isHidden = isHidden
                // self.locationButton.isHidden = isHidden || !self.canRotate
                self.drawTapView.isHidden = isHidden || !self.canRotate
                // self.fllowButton.isHidden = isHidden || !self.canRotate
                self.downloadSpeedLable.isHidden = isHidden
                self.deviceWifiStateImageV.isHidden = isHidden
                //self.batterButton.isHidden = isHidden || !(self.dataSource?.supperBatter() ?? false)
                self.recordButton.isHidden = isHidden
                self.screenShotButton.isHidden = isHidden
                self.volumeButton.isHidden = isHidden
                self.speakButton.isHidden = isHidden
                // self.warningButton.isHidden = isHidden
                // self.lightButton.isHidden = isHidden || !self.supperWhitelight
                self.videoDetailButton.isHidden = isHidden
//                self.playBtn.isHidden = isHidden
            }
        }
    }
}



extension ADLiveVideoControlView {
    
    func videoStateUpdate() {
        self.videoContentView.blueEffectEnable = false
        if case .playing = self.videoState {
            if isAiPage {
                aiplayingStyle()
            }else {
                playingStyle()
            }
            self.videoContentView.image = nil
            return
        }
        var image : UIImage? = nil
        self.speakButton.isUserInteractionEnabled = false
        self.speakButton.isUserInteractionEnabled = true
        self.recordState = .none
        switch self.videoState {
        case .none(let img):
            image = img
            noneStyle()
            self.visableLocationView(show: false)
        case .loading(let img):
            self.videoContentView.blueEffectEnable = true
            image = img
            loadingStyle()
        case .paused(let img):
            self.videoContentView.blueEffectEnable = false
            image = img
            pausedStyle()
            self.visableLocationView(show: false)
        case .pausedp2p(let img):
            self.videoContentView.blueEffectEnable = true
            image = img
            pausedp2pStyle()
            self.visableLocationView(show: false)
        case .finish:
            self.videoContentView.blueEffectEnable = true
            doneStyle()
            self.visableLocationView(show: false)
        case let .error(error , _, img , action , tipIcon, _):
            self.videoContentView.blueEffectEnable = true
            image = img
            errorStyle(error: error, action: action, tipIcon: tipIcon)
            self.visableLocationView(show: false)
        case .unuse(let img , let fork):
            self.videoContentView.blueEffectEnable = true
            image = img
            playStateUnuseError(isFock: fork)
            self.visableLocationView(show: false)
        default:
            break
        }
        self.videoContentView.image = image

    }
    
    func deviceInfoUpdate() {
        guard let dataSouce = self.dataSource else {
            return
        }
        let detailsharp = A4xPlayerManager.handle.getVideoDetail(device: dataSouce)
        
        self.videoDetailButton.setTitle(detailsharp.name(), for: .normal)

        //self.videoDetailButton.title = self.dataSource?.videoSharp().name()
        //self.batterButton.setBatterInfo(leavel: dataSouce.batter ?? 0, isCharging: dataSouce.charging ?? 0, isOnline: dataSouce.online ?? 0 == 1, quantityCharge: dataSource?.quantityCharge ?? false)
        
        if let wifiState = self.dataSource?.wifiStrength() {
            switch wifiState {
            case .offline:
                self.deviceWifiStateImageV.image = R.image.device_live_wifi_none()
            case .none:
                self.deviceWifiStateImageV.image = R.image.device_live_wifi_none()
            case .weak:
                self.deviceWifiStateImageV.image = R.image.device_live_wifi_week()
            case .normail:
                self.deviceWifiStateImageV.image = R.image.device_live_wifi_middle()
            case .strong:
                self.deviceWifiStateImageV.image = R.image.device_live_wifi_strong()
            }
        }
        self.resetLocation.editEnable = self.dataSource?.isAdmin() ?? true
        self.canRotate = self.dataSource?.deviceContrl?.rotate ?? false
        
        // self.locationButton.isHidden = self.moreButton.isHidden || !self.canRotate
        // self.fllowButton.isHidden = self.moreButton.isHidden || !self.canRotate
        self.drawTapView.isHidden = self.moreButton.isHidden || !self.canRotate
    }
    
    @objc
    func videoBarBackAction(sender : UIButton) {
        self.protocol?.videoBarBackAction()
    }
    
    @objc
    func moreMenuAction(sender : UIButton) {
        //self.protocol?.videoBarSettingAction()
        changeButtonVisable(toHidden: true)

        self.moreMenuSubLeftView.frame = CGRect(x: self.maxX, y: 0, width: 222.auto(), height: self.height)
        self.moreMenuSubLeftView.updateFrame()
        self.moreMenuSubLeftView.isHidden = false
        
        UIView.animate(withDuration: 0.3, animations: {
            self.moreMenuSubLeftView.frame = CGRect(x: self.maxX - 222.auto(), y: 0, width: 222.auto(), height: self.height)
        }) { (f) in}
    }
    
    @objc
    func videoSpeakAction() {
        A4xLog("playerhelper speakEnable ========================")
        guard self.protocol?.videoSpeakAction(enable: false) ?? false == true else {
            return
        }
        self.spakingView.isHidden = true
        self.spakingView.free()
    }
    @objc
    func videoSpeakActiond() {
        A4xLog("playerhelper speakEnable ------------------------")
        guard self.protocol?.videoSpeakAction(enable: true) ?? true == true else {
            return
        }
        self.spakingView.isHidden = false
        self.spakingView.load()
        self.hideAllToasts()
    }
    
    @objc
    func videoSpeakShot(){
        var style = ToastStyle()
        style.cornerRadius = 18
        style.messageFont = UIFont.systemFont(ofSize: 13)
        style.maxHeightPercentage = 10
        style.maxWidthPercentage = 18
        style.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        style.imageSize = CGSize(width: 18, height: 18)
        style.horizontalPadding = 7
        self.hideAllToasts()
        self.makeToast(R.string.localizable.hold_speak(), point: self.spakingView.center, title: nil, image: R.image.speak_tip_icon(), style: style , completion: nil)
    }
    
  
    
    @objc
    func videoVolumeAction(sender : UIButton) {
        
        self.protocol?.videoVolumeAction(enable: sender.isSelected)
        sender.isSelected = !sender.isSelected
    }
    
    @objc
    func videoScreenSnap(sender : UIButton) {
        
        self.protocol?.videoScreenSnap(view: sender)
    }
    
    @objc
    func videoDetailAction(sender : UIControl) {
        if self.recordButtonState == .runing {
            self.makeToast(R.string.localizable.cannot_switch())
            return
        }
        changeButtonVisable(toHidden: true)
        videoDetailListView.frame = CGRect(x: self.maxX, y: 0, width: 222.auto(), height: self.height)
        videoDetailListView.dataSouces = A4xVideoSharpType.all()
        if let data = self.dataSource {
            videoDetailListView.selectData = A4xPlayerManager.handle.getVideoDetail(device: data)
        }
//        videoDetailListView.selectData = self.dataSource?.videoSharp()
        self.videoDetailListView.isHidden = false
        UIView.animate(withDuration: 0.3, animations: {
            self.videoDetailListView.frame = CGRect(x: self.maxX - 222.auto(), y: 0, width: 222.auto(), height: self.height)
        }) { (f) in}
    }
    
    @objc
    func videoRecordVideo(sender : UIButton) {
        switch self.recordButtonState {
        case .none:
            self.recordButtonState = .run
            self.protocol?.videoRecordVideo(start: true)
        case .runing:
            self.recordButtonState = .ending
            self.protocol?.videoRecordVideo(start: false)
        default:
            return
        }
    }
}

extension ADLiveVideoControlView : UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view == self.contentView {
            return true
        }else {
            return false
        }
    }
}

extension ADLiveVideoControlView : ADLiveVideoMoreMenuViewProtocol {
    func deviceMenuClick(type: ADLiveDeviceMenuType, compleAction: @escaping (Bool) -> Void) {
        switch type {
        case .track:
            let enable = !self.isFllow
            self.protocol?.videoFllowChange(enable: enable, comple: { [weak self] (scuess) in
                if scuess {
                    self?.isFllow = enable
                }
                compleAction(scuess)
            })
            return
        case .alert:
            self.protocol?.videoAlarmAction()
            compleAction(true)
        case .location:
            self.moreMenuSubLeftView.frame = CGRect(x: self.maxX, y: 0, width: 222.auto(), height: self.height)
            self.moreMenuSubLeftView.updateFrame()
            self.moreMenuSubLeftView.isHidden = true
            self.locationButtonAction()
            compleAction(true)
            return
        case .light:
            self.protocol?.videoControlWhiteLight(enable: !self.whiteLight)
        case .setting:
            self.protocol?.videoBarSettingAction()
            compleAction(true)
        }
        UIView.animate(withDuration: 0.3, animations: {
            self.moreMenuSubLeftView.frame = CGRect(x: self.maxX, y: 0, width: 222.auto(), height: self.height)
            self.moreMenuSubLeftView.updateFrame()
        }) { (f) in
            self.moreMenuSubLeftView.isHidden = true
        }
    }
    
    
}
