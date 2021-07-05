//
//  ADHomeViewController.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/4/24.
//  Copyright © 2019 addx.ai. All rights reserved.
//  基础类 - 底部标题栏控制器

import UIKit
import ZendeskCoreSDK
import SupportProvidersSDK
import ADVideoMessageManager
import A4xBaseSDK


class ADHomeBaseViewController : A4xBaseViewController {
    
    override var navigationController: UINavigationController? {
        return self.navtion
    }
    private weak var navtion : UINavigationController?
    weak var viewModle : ADHomeViewModel?
    var editModeBlock : ((Bool)->Void)?
    var changeVisableVC : ((ADHomeBottomBarType , A4xDeviceModel?) -> Void)?

    required init(nav : UINavigationController? ,  viewModle : ADHomeViewModel?) {
        super.init(nibName: nil, bundle: nil)
        self.navtion = nav
        self.viewModle = viewModle
    }
    
    func startReloadData() {
        
    }
    
    func tabbarWillShow(){
        A4xLog("\(type(of: self).description()) tabbarWillShow")
    }
    
    func tabbarWillHidden(){
        A4xLog("\(type(of: self).description()) tabbarWillHidden")
    }
    
    private init(){
        super.init(nibName: nil, bundle: nil)
    }
    
    internal convenience required init?(coder aDecoder: NSCoder) {
        self.init(nav: nil , viewModle : nil)
    }
}

class ADHomeViewController: UITabBarController {
    let viewModle : ADHomeViewModel = ADHomeViewModel()
    private var editModle : Bool = false
    private var isHidenBar: Bool = false

    var newFeedBackRecordTimer : TimeInterval? {
        didSet {
            onMainThread { [weak self] in
                if self?.isViewLoaded ?? false {
                    if (A4xUserDataHandle.Handle?.feedBackNewMessageTimer ?? 0) < (self?.newFeedBackRecordTimer ?? 0) {
                        self?.bottomBar.userHasNew = true
                    } else {
                        self?.bottomBar.userHasNew = false
                    }
                }
            }
        }
    }
    
    public var currentType : ADHomeBottomBarType {
          set {
              self.bottomBar.currentType = newValue
          }
          get {
              return bottomBar.currentType ?? .Video
          }
      }
    
    public var currentViewController : UIViewController? {
        return self.viewControllers?.getIndex(self.currentType.rawValue)
    }
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    //MARK:- life cycle
    init(menuIndex : Int) {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        ADVideoMessageManager.shared.config?.enable = false
        A4xLog("-----> ADHomeViewController deinit")
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: LanguageChangeNotificationKey, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)

        self.removeAlertCommle()
    }
    var shouldReCheck : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ADVideoMessageManager.shared.config?.enable = true

        self.view.backgroundColor = UIColor.white
        DispatchQueue.main.a4xAfter(0.02) {
            self.loadViewControllers()
            self.bottomBar.isHidden = false
        }
        self.automaticallyAdjustsScrollViewInsets = false
        weak var weakSelf = self
        NotificationCenter.default.addObserver(forName: LanguageChangeNotificationKey, object: nil, queue: OperationQueue.main) { (noti) in
            weakSelf?.bottomBar.updateInfo()
            A4xUserDataHandle.Handle?.nodeCountry = nil
        }
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
//        appDelegate?.loadAppInfo(updateAppType: "home_view_controller", comple: {
//            A4xUserDataHandle.Handle?.removeAppInfo.checkRemoveInfo(comple: { [weak self](rmmodle) in
//                self?.shouldReCheck = true
//                if rmmodle.shouldShow ?? false {
//                    DispatchQueue.main.a4xAfter(0.1) {
//                        let vc = ADAppRemoveViewController()
//                        vc.removeModle = rmmodle
//                        self?.navigationController?.pushViewController(vc, animated: true)
//                    }
//                }
//            })
//        })

        
        DispatchQueue.main.a4xAfter(0.1) {
            self.checkGetMember()
            self.initZendesk {
                
            }
        }
    }
    
    var isEnterBack: Bool = false
    @objc
    func didEnterBackground(){
        isEnterBack = true
    }
    
    @objc
    func didBecomeActive(){
        debugPrint("-------------> didBecomeActive homeVC")
        initZendesk {
            
        }
        if isEnterBack {
            isEnterBack = false
//            A4xUserDataHandle.Handle?.restoreMemberShip()
            self.updateFeedNewMessage()
//            A4xUserDataHandle.Handle?.removeAppInfo.checkRemoveInfo(comple: { [weak self](rmmodle) in
//                // 判断是否是绑定模式
//                if A4xUserDataHandle.Handle?.pushType != .addCamera {
//                    self?.checkGetMember()
//                }
//
//                if rmmodle.shouldShow ?? false {
//                    DispatchQueue.main.a4xAfter(0.3) {
//                        let vc = ADAppRemoveViewController()
//                        vc.removeModle = rmmodle
//
//                        self?.navigationController?.pushViewController(vc, animated: true)
//                    }
//                }
//            })
          
        }
    }
      
    // 检查
    private func checkGetMember() {
        weak var weakSelf = self
        A4xUserDataHandle.Handle?.updateMemberShip(showAlert: true) {
            if let vipModel = A4xUserDataHandle.Handle?.userVipModle {
                if let isRecord = vipModel.tierReceive , isRecord == false  {
                    if vipModel.shouldReminder == true {
                        let showNum: String = UserDefaults.standard.string(forKey: "vip_free_show_num") ?? "0"
                        var curShowNum:Int = showNum.intValue()
                        curShowNum += 1
                        UserDefaults.standard.set("\(curShowNum)", forKey: "vip_free_show_num")
                        weakSelf?.showGetMemberAlert()
                    }
                }

            }
        }
    }
    
    // 显示会员
    private func showGetMemberAlert() {
        debugPrint("-----------> showGetMemberAlert homeVC")
//        A4xEventManager.startEvent(eventName:"vip_dialog_show")
//        let alert = ADGetMemberShipAlert(identifier: "ADGetMemberShipAlert")
//        weak var weakSelf = self
//
//        // VIP领取弹窗事件
//        let payEM = A4xPayEventModel()
//        let showNum = UserDefaults.standard.string(forKey: "vip_free_show_num")
//        payEM.show_num = showNum
//
//        alert.onResultAction = { type in
//            switch type {
//            case .close:// 关闭弹窗
//                A4xUserDataHandle.Handle!.showGetMemberAlert = false
//                payEM.end_way = "close_click"
//                A4xEventManager.payEndEvent(event:ADTickerPay.vip_dialog_show(eventModel: payEM))
//            case .open:// 点击开通服务
//                payEM.end_way = "vipServer_introduction_show"
//                A4xEventManager.payEndEvent(event:ADTickerPay.vip_dialog_show(eventModel: payEM))
//                let vc = ADMemberPlanViewController()
//                vc.vipModle = A4xUserDataHandle.Handle?.userVipModle
//                weakSelf?.navigationController?.pushViewController(vc, animated: true)
//            case .get:// 点击免费试用
//                weakSelf?.receiveMemberShip()
//                payEM.end_way = "vip_dialog_free_click"
//                A4xEventManager.payEndEvent(event:ADTickerPay.vip_dialog_show(eventModel: payEM))
//                A4xEventManager.payEndEvent(event:ADTickerPay.vip_dialog_free_click(eventModel: payEM))
//                A4xLog("ADHomeVideoViewController 点击点击领取")
//            }
//        }
//        alert.show()
    }
    
    private func receiveMemberShip(){
        let windown = UIApplication.shared.keyWindow
        windown?.makeToastActivity(title: "loading") { (f) in}
        A4xNetManager.execute(reqMoudelType: A4xNetMoudelType.Devices(.receiveVip), resModelType: A4xNetNormaiModel.self) { (result) in
            windown?.hideToastActivity()
            switch result {
            case .success(_):
                windown?.makeToast(R.string.localizable.receive_scuess())
            case .failure:
                windown?.makeToast(R.string.localizable.receive_fail())
            }
        }
    }
    
    var isInitSDK : Bool = false

    private func initZendesk(comple : @escaping ()-> Void) {
//        if isInitSDK {
//            comple()
//            return
//        }
//        self.isInitSDK = true
//        let appd = (UIApplication.shared.delegate as? AppDelegate)
//        appd?.loadZendesk()
//        weak var weakSelf = self
//        A4xNetManager.execute(reqMoudelType: A4xNetMoudelType.Account(.zendeskToken), resModelType: String.self) { (result) in
//            switch result {
//
//            case .success(let token):
//                if let t = token {
//                    let ident = Identity.createJwt(token: t)
//                    Zendesk.instance?.setIdentity(ident)
//
//                    weakSelf?.isInitSDK = true
//                    weakSelf?.updateFeedNewMessage()
//                    comple()
//                } else {
//                    UIApplication.shared.keyWindow?.hideToastActivity()
//                }
//            case .failure(let code, _):
//                UIApplication.shared.keyWindow?.hideToastActivity()
//                //UIApplication.shared.keyWindow?.makeToast(A4xAppErrorConfig(code: code).message())
//                weakSelf?.isInitSDK = false
//
//            }
//        }
    }
    
    private func updateFeedNewMessage(){
//        if let userVc = self.viewControllers?.last as? ADHomeUserViewController {
//            userVc.loadFeedBack { [weak self] (t) in
//                self?.newFeedBackRecordTimer = t
//            }
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        // 弹窗设置为正常模式
        A4xUserDataHandle.Handle?.pushType = .foreground
        self.checkGetMember()

    }

    // 底部工具栏 - 控制器添加
    private func loadViewControllers() {
//        weak var weakSelf = self
//        let changeBlock: (ADHomeBottomBarType, A4xDeviceModel?) -> Void = { (type , deviceModle)  in
//            A4xLog("ADHomeBottomBarType \(type) deviceModle \(String(describing: deviceModle?.id))")
//            weakSelf?.changeVisableVc(type: type, device: deviceModle)
//        }
//
//        var vcs: [UIViewController] = Array()
//        let videoVc = ADHomeVideoViewController(nav: self.navigationController, viewModle: self.viewModle)
//        videoVc.changeVisableVC = changeBlock
//        vcs.append(videoVc)
//
//        let libaryVc = ADHomeLibaryViewController(nav: self.navigationController, viewModle: self.viewModle)
//        libaryVc.editModeBlock = { editModle in
//            weakSelf?.editModleChange(flag: editModle)
//        }
//        libaryVc.changeVisableVC = changeBlock
//        vcs.append(libaryVc)
//
//        let userVc = ADHomeUserViewController(nav: self.navigationController, viewModle: self.viewModle)
//        userVc.changeVisableVC = changeBlock
//        userVc.feedBackMessageCountChangeBlock = { [weak self] newCount in
//            self?.newFeedBackRecordTimer = newCount
//        }
//        vcs.append(userVc)
//
//        let exploreVc = ADHomeExploreViewController(nav: self.navigationController, viewModle: self.viewModle)
//        exploreVc.changeVisableVC = changeBlock
//        exploreVc.feedBackMessageCountChangeBlock = { [weak self] newCount in
//            self?.newFeedBackRecordTimer = newCount
//        }
//
//        exploreVc.hidenBarChangeBlock = { [weak self] isHidenBar in
//            self?.bottomBar.isHidden = isHidenBar
//            self?.isHidenBar = isHidenBar
//            self?.updateBarView(isHiden: self?.isHidenBar ?? false)
//        }
//
//        vcs.append(exploreVc)
//
//        self.viewControllers = vcs
//        self.tabBar.isHidden = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        self.navigationController?.navigationBar.isHidden = true
        self.updateBarView(isHiden: self.isHidenBar)
    }
    
    private func updateBarView(isHiden: Bool) {
        self.isHidenBar = isHiden
        var barHeight: CGFloat = 0
        if !self.isHidenBar {
            barHeight = UIScreen.bottomBarHeight
        }
        debugPrint("-----------> updateBarView barHeight: \(barHeight)")
        self.view.subviews.forEach { (v) in
            guard !(v is UITabBar) else {
                return
            }
            
            guard !(v is ADHomeBottomBarView) else {
                return
            }
            
            //v.frame = CGRect(x: 0, y: 0, width: UIScreen.width, height: UIScreen.height)
            v.frame = CGRect(x: 0, y: 0, width: self.view.width, height: self.view.height - (self.editModle ? 0 : barHeight))
        }
    }

    //MARK:-  create view
    lazy var bottomBar: ADHomeBottomBarView = {
        weak var weakSelf = self
        let temp: ADHomeBottomBarView = ADHomeBottomBarView()
        self.view.addSubview(temp)
        
        temp.bottomSelectBlock = {state in
            let oldVc: ADHomeBaseViewController? = weakSelf?.selectedViewController as? ADHomeBaseViewController
            switch state {
            case .Video:
                weakSelf?.selectedIndex = 0
            case .Libary:
                weakSelf?.selectedIndex = 1
            case .User:
                weakSelf?.selectedIndex = 2
            case .Web:
                weakSelf?.selectedIndex = 3
            }
            
            let newVc = weakSelf?.selectedViewController as? ADHomeBaseViewController
            if let oc: ADHomeBaseViewController = oldVc, let nv: ADHomeBaseViewController = newVc {
                if (oc.self != nv.self){
                    oc.tabbarWillHidden()
                }
                nv.tabbarWillShow()
            }
            
            weakSelf?.initZendesk {
                
            }

        }
        
        temp.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.height.equalTo(UIScreen.bottomBarHeight)
        }
        
        temp.userHasNew = false
        return temp
    }()

    private func editModleChange(flag: Bool) {
        self.editModle = flag
        self.bottomBar.snp.updateConstraints({ (make) in
            make.bottom.equalTo(self.view.snp.bottom).offset(flag ? UIScreen.bottomBarHeight : 0)
        })
        self.view.layoutIfNeeded()
    }
    
    
    private func changeVisableVc( type : ADHomeBottomBarType, device : A4xDeviceModel?){
//        if case .Libary = type {
//            if device != nil {
//                ADFilterMoodel.clear()
//                if let deviceName = device?.name , let devid = device?.id {
//                    var vc = ADFilterMoodel()
//                    vc.change_select(deviceName: deviceName , deviceId: devid)
//                    vc.save()
//                }
//            }
//        }
//        self.bottomBar.currentType = type
//        if let vc = self.selectedViewController as? ADHomeBaseViewController {
//            vc.startReloadData()
//        }
    }
    
}


extension ADHomeViewController {
    private func getNavigation() -> UINavigationController? {
        var navtions : UINavigationController? = nil
        UIApplication.shared.windows.forEach { (wind) in
            if let nav = wind.rootViewController as? UINavigationController {
                navtions = nav
            }
        }
        return navtions
    }

    private func removeAlertCommle() {
        ADErrorUnit.removeBlock(Tag: type(of: self).description())
    }
}
