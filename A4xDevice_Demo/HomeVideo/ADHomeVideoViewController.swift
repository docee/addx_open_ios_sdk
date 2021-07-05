//
//  ADHomeVideoViewController.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/4/24.
//  Copyright © 2019 addx.ai. All rights reserved.
//


import ADDXWebRTC
import UIKit
import MJRefresh
import A4xBaseSDK
import A4xWebRTCSDK
import A4xBindSDK

enum ADHomeVideoPresetTypeModle: Int {
    case none
    case show
    case edit
    case delete
}

class ADHomeVideoViewController: ADHomeBaseViewController {
    let splitMaxCount: Int = 4
    var currentDialog: ADDialogManager?
    var dialogAdapter: ADDialogAdapterProtocol?
    var fullVideoSelIndexPath: IndexPath?
    var fromLiveVideo: Bool? = false
    var popMenu: A4xBasePopMenuView!
    var homeMoveTrackAlertBGView: UIView!
    var selectedDeviceId: String?
    
    var showImageAnimailRow: Int = -1
    
    var cellTypes: [ADVideoCellType] = []
    
    let presetModle: ADPresetDataModle = ADPresetDataModle()
    
    var dataSource: [A4xDeviceModel]? {
        return A4xUserDataHandle.Handle?.devicesFilter(filter: true)
    }
    
    let gifManager = A4xBaseGifManager(memoryLimit: 60)
    
    //获取 AppDelegate 对象
    //let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    private func reloadData(error: String?) {
        debugPrint("-----------> reloadData error: \(error ?? "nil")")
        guard isTop else {
            debugPrint("-----------> reloadData isTop return")
            return
        }

        if dataSource != nil && dataSource!.count > 0 {
            enteryView.isHidden = true
            collectView.hiddNoDataView()
        } else {
            if error != nil {
                enteryView.isHidden = true
                weak var weakSelf = self
                // 警告不生效
                guard let noDataView = weakSelf?.collectView.showNoDataView(value: ADNoDataValue.error(error: error, comple: {
                    weakSelf?.collectView.mj_header?.beginRefreshing()
                })) else { return }
                //weakSelf?.view.addSubview(noDataView)
                
            } else {
                enteryView.isHidden = false
                collectView.hiddNoDataView()
            }
        }
        debugPrint("-----------> reloadData collectView.reloadData()")
        self.collectView.collectionViewLayout.invalidateLayout()
        self.collectView.reloadData()
    }
    
    // 四分屏自动播放
    private func splitStyleToAutoPlay() {
        // 判断当前状态是否竖屏下的四分屏
        if A4xUserDataHandle.Handle?.videoStyle == .split {
            self.navBar.isUserInteractionEnabled = false
            DispatchQueue.main.a4xAfter(0.3) {
                if self.navigationController?.topViewController is ADHomeViewController {
                    // 设置播放个数为4个
                    A4xPlayerManager.handle.playAll(playNumber: self.splitMaxCount)
                }
                self.navBar.isUserInteractionEnabled = true
                
            }
        }
    }
    
    lazy var collectView: UICollectionView = {
        let temp = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.collectionLayout)
        temp.dataSource = self
        temp.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10.auto(), right: 0)
        temp.delegate = self
        temp.clipsToBounds = false
        temp.backgroundColor = UIColor.clear
        temp.register(HomeVideoCollectCell.self, forCellWithReuseIdentifier: "HomeVideoCollectCell")
        self.view.addSubview(temp)
        
        temp.snp.makeConstraints({ make in
            make.top.equalTo(self.navBar.snp.bottom)
            make.left.equalTo(self.view.snp.left)
            make.width.equalTo(self.view.snp.width)
            make.bottom.equalTo(self.view.snp.bottom)
        })
        return temp
    }()
    
    lazy var noWifiTip: ADHomeNoWifiView = {
        let temp = ADHomeNoWifiView()
        self.view.addSubview(temp)
        weak var weakSelf = self
        temp.colseBlock = {
            weakSelf?.updateWifoTip(noNet: true, isClose: true)
        }
        
        temp.snp.makeConstraints({ make in
            make.top.equalTo(self.navBar.snp.bottom)
            make.width.equalTo(self.view.snp.width)
            make.left.equalTo(0)
            make.height.equalTo(45.auto())
        })
        
        return temp
    }()
    
    lazy var disturbView : ADDisturbAlertView? = {
        let temp = ADDisturbAlertView()
        temp.showSuperView = self.collectView
        
        temp.addTarget(self, action: #selector(closeUserDisturbAction), for: .touchUpInside)
        temp.hiddenActionBlock = { [weak self] in
            self?.hiddenDisturbAlert()
        }
        return temp
    }()
    
    lazy var navBar: ADNewHomeHeaderView = {
        let temp: ADNewHomeHeaderView = ADNewHomeHeaderView()
        temp.menuImage = UIImage(named: "homepage_head_menus")
        temp.addCameraImage = R.image.nav_add_device_right()
        temp.titleType = .Arrow
        temp.backgroundColor = ADTheme.C6
        temp.title = "Kieran.zhi Home"
        weak var weakSelf = self
        temp.headLeftCilckBlock = { show in
            weakSelf?.showTitleDialog(isShow: show)
        }
        temp.headRightCilckBlock = {
            // 四分屏切换点击
            weakSelf?.updateVideoStyle(change: true)
        }
        
        temp.headDisturbClickBlock = { (points) in
            weakSelf?.showDisturbSheet(point: points)
        }
        
        temp.headAddCameraCilckBlock = { [weak temp] in
            guard let temp = temp else {
                return
            }
            weakSelf?.showMenu()
            weakSelf?.rotateArrow(temp.addCameraView, open: true)
        }
        
        self.view.addSubview(temp)
        temp.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.left.equalTo(self.view.snp.left)
            make.right.equalTo(self.view.snp.right)
            make.height.equalTo(UIScreen.newNavHeight.auto())
        }
        return temp
    }()
    
    lazy var collectionLayout: ADHomeVideoCollectLayout = {
        let temp = ADHomeVideoCollectLayout(delegate: self)
        return temp
    }()
    
    lazy var enteryView: ADHomeEnteryView = {
        let temp = ADHomeEnteryView(frame: CGRect.zero)
        temp.backgroundColor = UIColor.clear
        temp.isHidden = true
        self.view.insertSubview(temp, aboveSubview: self.collectView)
        weak var weakSelf = self
        temp.addCameraBlock = {
            weakSelf?.presentAddCamera()
        }
        temp.snp.makeConstraints({ make in
            make.top.equalTo(self.navBar.snp.bottom)
            make.left.equalTo(self.view.snp.left)
            make.width.equalTo(self.view.snp.width)
            make.bottom.equalTo(self.view.snp.bottom)
        })
        return temp
    }()
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        splitStyleToAutoPlay()
        debugPrint("-----------> viewDidAppear func to updateAll")
        A4xPlayerManager.handle.updateAll()
        reloadCellTypes()
        reloadData(error: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func tabbarWillShow() {
        super.tabbarWillShow()
    }
    
    override func tabbarWillHidden() {
        super.tabbarWillHidden()
        // stopAll内部耦合逻辑较多
        A4xPlayerManager.handle.stopAll(troubleDevice: nil, reason: A4xPlayerStopReason.changePage)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ADTheme.C6
        collectView.isHidden = false
        navBar.isHidden = false
        noWifiTip.isHidden = true
        navBar.title = A4xUserDataHandle.Handle?.locationType.name()
        updateVideoStyle()
        viewModle?.getUserLocations { _, _ in }
        
        weak var weakSelf = self
        var shouldUpdateDistan = true
        collectView.mj_header = A4xMJRefreshHeader {
            // 首页下拉列表刷新处理
            weakSelf?.viewModle?.getDevices { (models, err) in
                weakSelf?.collectView.mj_header?.endRefreshing()
                
                debugPrint("-----------> A4xMJRefreshHeader func to updateAll")
                // 清除上报日志按钮状态
                models?.forEach({ (model) in
                    UserDefaults.standard.set("0", forKey: "show_error_report_\(model.id ?? "")")
                    
                })
                
                // 垃圾操作 - 需优化
                // 实例化所有直播对象
                A4xPlayerManager.handle.updateAll()
                
                // 停止所有直播
                A4xPlayerManager.handle.stopAll(troubleDevice: nil, reason: A4xPlayerStopReason.pull)
                
                // 刷新数据
                weakSelf?.reloadData(error: err)
                
                // 更新最新封面图
                A4xPlayerManager.handle.updateAllSnapImage {[weak weakSelf] deviceID in
                    weakSelf?.reloadCellWithDeviceId(deviceID: deviceID)
                }
                
                // 四分屏直播逻辑
                weakSelf?.splitStyleToAutoPlay()
                
                weakSelf?.navBar.showHeadDisturb = A4xUserDataHandle.Handle?.deviceModels?.count ?? 0 > 0
                
                if shouldUpdateDistan {
                    shouldUpdateDistan = false
                    weakSelf?.updateDisturbInfo()
                }
                
                weakSelf?.view.makeToast(err)
                
            }
        }
        collectView.mj_header?.beginRefreshing()
        
        // 切换语言处理
        NotificationCenter.default.addObserver(forName: LanguageChangeNotificationKey, object: nil, queue: OperationQueue.main) { _ in
            weakSelf?.reloadData(error: nil)
            weakSelf?.navBar.title = A4xUserDataHandle.Handle?.locationType.name()
            if weakSelf?.dialogAdapter != nil {
                weakSelf?.showTitleDialog(isShow: false)
            }
            weakSelf?.enteryView.updateInfo()
            weakSelf?.noWifiTip.updateInfo()
            // 更新列表数据 - v3.1 by wjin
            weakSelf?.viewModle?.getDevices { (models, err) in
                // 刷新数据
                weakSelf?.reloadData(error: err)
                weakSelf?.view.makeToast(err)
            }
        }
        
        A4xUserDataHandle.Handle?.addDeviceUpdateListen(targer: self)
        A4xUserDataHandle.Handle?.addAccountChange(targer: self)
        A4xPlayerManager.handle.addHelperStateProtocol(target: self)
        A4xUserDataHandle.Handle?.addWifiChange(targer: self)
        
    }
    
    func reloadCellWithDeviceId(deviceID: String){
        guard !deviceID.isEmpty else {
            return
        }
        
        var reloadindex: Int? = nil
        for index in 0..<(self.dataSource?.count ?? 0) {
            if let deviceModle = self.dataSource?[index]{
                if deviceModle.id == deviceID {
                    reloadindex = index
                }
            }
        }
        
        guard let index = reloadindex else {
            return
        }
        
        showImageAnimailRow = index
        self.reloadData(error: nil)
        // fix attempt to delete item 1 from section 0 which only contains 0 items before the update
        //self.collectView.reloadItems(at: [IndexPath(row: index, section: 0)])
    }
    
    // 更新首页直播风格，四分屏、竖屏
    private func updateVideoStyle(change: Bool = false) {
        var currentStyle = A4xUserDataHandle.Handle?.videoStyle ?? .default
        A4xPlayerManager.handle.stopAll(troubleDevice: nil, reason: A4xPlayerStopReason.changeModle)
        if change {
            currentStyle = currentStyle == .default ? .split : .default
            A4xUserDataHandle.Handle?.videoStyle = currentStyle
        }
        navBar.menuImage = currentStyle.image()
        reloadCellTypes()
        
        reloadData(error: nil)
        splitStyleToAutoPlay()
    }
    
    required init(nav: UINavigationController?, viewModle: ADHomeViewModel?) {
        super.init(nav: nav, viewModle: viewModle)
        
        NotificationCenter.default.addObserver(self, selector: #selector(deviceListChange(noti:)), name: A4xSaveKey.ADDeviceListChangeNotificationKey, object: nil)
    }
    
    internal required convenience init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func deviceListChange(noti: NSNotification) {
        DispatchQueue.main.async {
            self.collectView.mj_header?.beginRefreshing()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        A4xPlayerManager.handle.removeHelperStateProtocol(target: self)
        A4xLog("-----> ADHomeVideoContentView deinit")
    }
}

// MARK: - Dialog

extension ADHomeVideoViewController {
    private func createTitleDialog(ContentType ct: ContentType = .Full, animail: AniDirection = AniDirection.DefautDir()) -> ADDialogManager {
        let temp: ADDialogManager = ADDialogManager(ContentType: ct)
        view.addSubview(temp)
        
        temp.aniDir = animail
        
        temp.snp.makeConstraints { make in
            make.top.equalTo(self.navBar.snp.bottom)
            make.left.equalTo(self.view.snp.left)
            make.right.equalTo(self.view.snp.right)
            make.bottom.equalTo(self.view.snp.bottom)
        }
        return temp
    }
    
    private func showTitleDialog(isShow: Bool) {
//        if isShow && !(dialogAdapter is ADDialogTitleAdapter) {
//            weak var weakSelf = self
//            viewModle?.getLocationsModel(result: { dataList in
//                let tempAdapter: ADDialogTitleAdapter? = weakSelf?.dialogAdapter as? ADDialogTitleAdapter
//                if tempAdapter == nil {
//                    weakSelf?.showCommDialog(AdapterType: ADDialogTitleAdapter.self, dataSource: dataList) {
//                        weakSelf?.navBar.titleInfoShow = false
//                    }
//                } else {
//                    tempAdapter?.dataSources = dataList
//                }
//            })
//
//            dialogAdapter?.didSelectBlock = { model, _ in
//                weakSelf?.navBar.titleInfoShow = false
//                weakSelf?.hiddenCommDialog {
//                }
//                A4xLog("select location \(model)")
//                if let m = model as? ADAddressFilterModle {
//                    A4xUserDataHandle.Handle?.locationType = m.filterType
//                    weakSelf?.navBar.title = m.filterType.name()
//                    weakSelf?.collectView.mj_header?.beginRefreshing()
//                }
//            }
//        } else {
//            hiddenCommDialog {}
//        }
    }
    
    private func showCommDialog<T: ADDialogAdapterProtocol>(AdapterType: T.Type, dataSource: Array<ADDialogModelProtocol>?, ContentType ct: ContentType = .Full, animail: AniDirection = AniDirection.DefautDir(), resultBlock: @escaping (() -> Void)) {
        if dialogAdapter != nil && !(dialogAdapter is T) {
            currentDialog?.adapter = nil
            dialogAdapter = nil
            currentDialog?.removeFromSuperview()
            currentDialog = nil
        }
        
        dialogAdapter = AdapterType.init(dataSource: dataSource)
        dialogAdapter?.selectCellColor = ADTheme.C5.withAlphaComponent(0.5)
        
        if currentDialog == nil {
            currentDialog = createTitleDialog(ContentType: ct)
            currentDialog?.aniDir = animail
            currentDialog?.setRadio(radio: 11.auto(), style: [.bottomRight, .bottomLeft])
        }
        
        currentDialog?.adapter = dialogAdapter
        currentDialog?.showDialog()
        
        weak var weakSelf = self
        
        currentDialog?.autoHiddenBlock = {
            weakSelf?.currentDialog?.adapter = nil
            weakSelf?.dialogAdapter = nil
            weakSelf?.currentDialog?.removeFromSuperview()
            weakSelf?.currentDialog = nil
            resultBlock()
        }
    }
    
    private func hiddenCommDialog(resultBlock: @escaping (() -> Void)) {
        weak var weakSelf = self
        
        currentDialog?.hiddenDialog {
            weakSelf?.currentDialog?.adapter = nil
            weakSelf?.dialogAdapter = nil
            weakSelf?.currentDialog?.removeFromSuperview()
            weakSelf?.currentDialog = nil
        }
    }
    
    private func reloadCellTypes() {
        cellTypes.removeAll()
        
        let count  = self.dataSource?.count ?? 0
        guard count > 0 else {
            return
        }
        
        if A4xUserDataHandle.Handle?.videoStyle == .split {
            cellTypes = Array(repeating: ADVideoCellType.split, count: count)
        } else {
            var types = Array(repeating: ADVideoCellType.default, count: count)
            for index in 0..<count {
                if let device = self.dataSource?.getIndex(index){
                    if case .playing = (A4xPlayerManager.handle.getPlayer(device: device)?.state ?? .none(thumb: nil)) {
                        types[index] = .playControl
                    }
                }
            }
            cellTypes = types
        }
    }
    
    private func updateCellType(type: ADVideoCellType, rowIndex: Int) {
        if self.cellTypes.count != self.dataSource?.count {
            reloadCellTypes()
        }
        
        guard rowIndex < cellTypes.count  else {
            return
        }
        
        cellTypes[rowIndex] = type
    }
    
    
    @objc func showMenu() {
        //数据源（icon可不填）
        let popData = [(icon:"nav_menu_add_device",title:R.string.localizable.add_new_camera()),
                       (icon:"nav_menu_add_friend_device",title:R.string.localizable.join_friend_device())]
        //设置参数
        let parameters:[A4xBasePopMenuViewConfigure] = [
            .PopMenuTextColor(UIColor.black),
            .popMenuItemHeight(53.auto()),
            .PopMenuTextFont(UIFont.regular(15))
        ]
        
        let title1Size = NSString(string: R.string.localizable.add_new_camera()).size(withAttributes: [NSAttributedString.Key.font : UIFont.regular(15)])
        let title2Size = NSString(string: R.string.localizable.join_friend_device()).size(withAttributes: [NSAttributedString.Key.font : UIFont.regular(15)])
        let menuWidth = max(title1Size.width, title2Size.width) + 45 > 182 ? 195 : 182
        popMenu = A4xBasePopMenuView(menuWidth: CGFloat(menuWidth.auto()), arrow: CGPoint(x: navBar.addCameraView.center.x, y: navBar.addCameraView.center.y + 30), datas: popData, configures: parameters)
        
        //click
        popMenu.didSelectMenuBlock = { [weak self](index: Int) -> Void in
            print("block select \(index)")
            self?.popMenu = nil
            self?.rotateArrow((self?.navBar.addCameraView)!, open: false)
            switch index {
            case 0:
                // 打点事件（添加相机）
                let addCamereEM = A4xAddCameraEventModel()
                A4xEventManager.addCameraRecordEvent(event: ADTickerAddCamera.home_addCamera_click(eventModel: addCamereEM))
                let nav = UINavigationController(rootViewController: A4xBindRootViewController())
                nav.isNavigationBarHidden = true
                nav.modalPresentationStyle = .fullScreen
                self?.navigationController?.present(nav, animated: true)
                break
            case 1:
                // 打点事件（添加被分享的相机）
                let addCamereEM = A4xAddCameraEventModel()
                A4xEventManager.addCameraRecordEvent(event: ADTickerAddCamera.home_addSharedCamera_click(eventModel: addCamereEM))
                let vc = A4xBindManager.shared.addFriendDeviceVC() ?? A4xBindRootViewController()
                self?.navigationController?.pushViewController(vc, animated: true)
                break
            default:
                break
            }
        }
        
        popMenu.clicktMenuBlock = { [weak self](dismiss: Int) -> Void in
            print("block select \(dismiss)")
            if dismiss == 1 {
                self?.rotateArrow((self?.navBar.addCameraView)!, open: false)
            }
        }
        
        //show
        popMenu.show()
    }
    
    // 菜单箭头动画
    func rotateArrow(_ btn: UIButton, open: Bool) {
        var rotate = Double.pi * 3 / 4
        if !open {
            rotate = -Double.pi * 3 / 4
        }
        UIView.animate(withDuration: 0.3, animations: { () -> () in
            btn.transform = btn.transform.rotated(by: CGFloat(rotate))
        })
    }
}

// MARK: UICollection delegate

extension ADHomeVideoViewController: ADHomeVideoContentProtocol, UICollectionViewDelegate, UICollectionViewDataSource {
    func getCellHeight(forRow row: Int , itemWidth : CGFloat) -> CGFloat {
        let viewType: ADVideoCellType = self.cellTypes.getIndex(row) ?? .default
        return HomeVideoCollectCell.heightForDevide(type: viewType, itemWidth: itemWidth, deviceModle: self.dataSource?.getIndex(row))
    }
    
    // MARK: ADHomeVideoContentProtocol
    func getDefaultCellType(rowIndex: Int) -> ADVideoCellType {
        var viewType: ADVideoCellType = self.cellTypes.getIndex(rowIndex) ?? .default
        if let deviceModle = dataSource?.getIndex(rowIndex) {
            if let (state, _) = A4xPlayerManager.handle.playinfo(device: deviceModle) {
                if viewType != .split {
                    if state == .playing {
                        if viewType == .default {
                            viewType = .playControl
                        }
                    }else  {
                        viewType = .default
                    }
                    updateCellType(type: viewType, rowIndex: rowIndex)
                }
            }
        }
        return viewType
    }
    
    // MARK: UICollectionViewDelegate,UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (dataSource?.count ?? 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        debugPrint("-----------> collectionView")
        let cell: HomeVideoCollectCell = collectionView.dequeueReusableCell(withReuseIdentifier: "HomeVideoCollectCell", for: indexPath) as! HomeVideoCollectCell
        if self.showImageAnimailRow == indexPath.row {
            cell.showChangeAnilmail = true
            self.showImageAnimailRow = -1
        } else {
            cell.showChangeAnilmail = false
        }
        
        let data = dataSource?.getIndex(indexPath.row)
        cell.indexPath = indexPath
        cell.videoStyle = cellTypes.getIndex(indexPath.row) ?? .default
        cell.protocol = self
        // 竖屏判断是否是人形追踪
        cell.autoFollowBtnIsHumanImg = presetModle.isFollowType(deviceId: data?.id ?? "")
        // 竖屏运动追踪状态图标
        cell.isFllow = presetModle.isFollow(deviceId: data?.id ?? "")
        
        // debugPrint("-------> isAdmin:\(data?.isAdmin())")
        cell.isFollowAdmin = data?.isAdmin() ?? false
        cell.presetListData = presetModle.data(deviceId: data?.id ?? "")
        cell.dataSource = data
        //UserDefaults.standard.set("0", forKey: "show_error_report_\(data?.id ?? "")")
        
        // cell 点击事件处理
        weak var weakSelf = self
        cell.autoFollowBlock = { deviceId, follow, comple in
            weakSelf?.deviceFllowAction(devceid: deviceId, enable: follow, comple: comple)
            A4xLog("HomeVideoCollectCell autoFollowBlock device:\(deviceId ?? "") value \(follow)")
        }
        
        cell.deviceRotateBlock = { deviceId, value in
            weakSelf?.rotateAction(devceid: deviceId, point: value)
            A4xLog("HomeVideoCollectCell deviceRotateBlock device:\(deviceId ?? "") value \(value)")
        }
        //        cell.editModleChangeBlock = { deviceid, edit in
        //            weakSelf?.presetLocationViewTypeChange(deviceId: deviceid, type: edit)
        //            A4xLog("HomeVideoCollectCell editModleChangeBlock device:\(deviceid ?? "") value \(edit)")
        //        }
        cell.itemActionBlock = { deviceid, data, type, img in
            A4xLog("HomeVideoCollectCell itemActionBlock device:\(deviceid ?? "") value \(type)")
            weakSelf?.presetItemAction(deviceId: deviceid, preset: data, type: type, image: img)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        //全屏切半屏后定位到切之前的位置
        if fullVideoSelIndexPath != nil {
            //collectionView.layoutIfNeeded()
            //let offsetY = CGFloat(fullVideoSelIndexPath?.item ?? 0) * collectView.frame.size.height
            //A4xLog("collectionView didEndDisplaying offsetY:\(offsetY)")
            //collectView.contentOffset.y = offsetY
            collectView.scrollToItem(at: fullVideoSelIndexPath ?? IndexPath(row: 0, section: 0), at: .top, animated: true)
            fullVideoSelIndexPath = nil
        }
    }
    
    
    private func deviceFllowAction(devceid: String?, enable: Bool, comple: @escaping (Bool) -> Void) {
        weak var weakSelf = self
        presetModle.updateMotionTrackStatus(deviceId: devceid, enable: enable) { error in
            // 打点事件-
            let playVideoEM = A4xPlayVideoEventModel()
            playVideoEM.live_player_way = "halfscreen"
            playVideoEM.switch_status = "\(enable == true ? "open" : "close")"
            
            if error != nil {
                weakSelf?.view.makeToast(R.string.localizable.request_timeout_and_try())
                playVideoEM.result = "false"
                playVideoEM.error_msg = error
            }
            
            if enable && !(weakSelf?.presetModle.isFollowType(deviceId: devceid ?? "") ?? false) {
                weakSelf?.fristGuideAlert(devceid, type: "move_track")
            }
            
            playVideoEM.track_mode = weakSelf?.presetModle.isFollowType(deviceId: devceid ?? "") == true ? "people_detection" : "move_track"
            A4xEventManager.playRecordEvent(event:ADTickerPlayVideo.live_sportTrack_switch_click(eventModel: playVideoEM))
            comple(error == nil)
        }
    }
    
    private func rotateAction(devceid: String?, point: CGPoint) {
        weak var weakSelf = self
        
        presetModle.rotate(deviceId: devceid, x: Float(point.x), y: Float(point.y)) { error in
            if error != nil {
                weakSelf?.view.makeToast(error)
            }
        }
    }
    
    // 半屏添加预设位置
    private func addPresetAlertLocation(deviceId: String?, image: UIImage?) {
        A4xLog("addPresetAlertLocation ")
        // 打点事件（半屏添加预设位置）
        let playVideoEM = A4xPlayVideoEventModel()
        playVideoEM.live_player_type = "halfscreen"
        let (add, error) = presetModle.canAdd(deviceId: deviceId)
        if !add {
            playVideoEM.result = "\(add)"
            playVideoEM.error_msg = error
            A4xEventManager.endEvent(event:ADTickerPlayVideo.live_remoteControl_savePoint_add(eventModel: playVideoEM))
            view.makeToast(error)
            return
        }
        
        let alert = ADAddPresetLocationAlert(frame: CGRect.zero)
        alert.image = image
        let currKeyWindow = UIApplication.shared.keyWindow
        weak var weakSelf = self
        alert.onEditDone = { str in
            A4xLog("onEditDone onEditDone")
            currKeyWindow?.makeToastActivity(title: R.string.localizable.loading(), completion: { _ in })
            weakSelf?.presetModle.add(deviceId: deviceId, image: image, name: str, comple: { status, tips in
                currKeyWindow?.hideToastActivity()
                weakSelf?.view.makeToast(tips)
                weakSelf?.reloadData(error: nil)
                
                playVideoEM.result = "\(status)"
                if !status {
                    playVideoEM.error_msg = tips
                }
                A4xEventManager.endEvent(event:ADTickerPlayVideo.live_remoteControl_savePoint_add(eventModel: playVideoEM))
            })
        }
        alert.show()
    }
    
    // 首次运动追踪弹窗 & 首次预设位置弹窗
    func fristGuideAlert(_ devceid: String?, type: String) {
        if type == "move_track" {
            self.selectedDeviceId = devceid
            
            if UserDefaults.standard.string(forKey: "\(A4xUserDataHandle.Handle?.loginModel?.id ?? 0)_frist_move_track_alert") != "1" {
                
                UserDefaults.standard.setValue(String(1), forKey:"\(A4xUserDataHandle.Handle?.loginModel?.id ?? 0)_frist_move_track_alert")
                UserDefaults.standard.synchronize()
                
                self.fristAlertView(type: type)
                
            }
        } else {
            if UserDefaults.standard.string(forKey: "\(A4xUserDataHandle.Handle?.loginModel?.id ?? 0)_frist_preset_location_alert") != "1" {
                
                UserDefaults.standard.setValue(String(1), forKey:"\(A4xUserDataHandle.Handle?.loginModel?.id ?? 0)_frist_preset_location_alert")
                UserDefaults.standard.synchronize()
                
                fristAlertView(type: type)
            }
        }
    }
    
    func fristAlertView(type: String) {
        
        homeMoveTrackAlertBGView = UIView()
        homeMoveTrackAlertBGView.backgroundColor = UIColor.colorFromHex("#000000" ,alpha: 0.6)
        UIApplication.shared.keyWindow?.addSubview(homeMoveTrackAlertBGView)
        homeMoveTrackAlertBGView.snp.makeConstraints { (make) in
            make.edges.equalTo(UIApplication.shared.keyWindow!.snp.edges)
        }
        
        let alertView = UIView()
        var alertViewHeight: CGFloat = 15.33.auto()
        homeMoveTrackAlertBGView.addSubview(alertView)
        alertView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
            make.width.equalTo(288.auto())
            make.height.equalTo(280.auto())
        }
        
        let titleIconImgView = UIImageView()
        titleIconImgView.image = type == "move_track" ? R.image.title_move_alert() : R.image.device_preset_location()
        alertView.addSubview(titleIconImgView)
        titleIconImgView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15.3)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 34.5.auto(), height: 34.5.auto()))
        }
        alertViewHeight += 34.5.auto()
        
        let titleLbl = UILabel()
        titleLbl.textColor = ADTheme.C1
        titleLbl.font = ADTheme.H3
        titleLbl.text = type == "move_track" ? R.string.localizable.motion_tracking() : R.string.localizable.preset_location()
        titleLbl.textAlignment = .center
        titleLbl.numberOfLines = 0
        alertView.addSubview(titleLbl)
        titleLbl.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalTo(268.auto())
            make.top.equalTo(titleIconImgView.snp.bottom).offset(14.auto())
        }
        alertViewHeight += (titleLbl.getLabelHeight(titleLbl, width: 268.auto()) + 14.auto())
        
        let msgLbl = UILabel()
        msgLbl.textColor = ADTheme.C1
        msgLbl.font = UIFont.regular(14.67.auto())
        msgLbl.text = type == "move_track" ? R.string.localizable.action_tracing_open() : R.string.localizable.position_tips()
        msgLbl.textAlignment = .center
        msgLbl.numberOfLines = 0
        alertView.addSubview(msgLbl)
        msgLbl.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalTo(268.auto())
            make.top.equalTo(titleLbl.snp.bottom).offset(15.auto())
        }
        alertViewHeight += (msgLbl.getLabelHeight(msgLbl, width: 268.auto()) + 15.auto())
        
        let msg2Lbl = UILabel()
//        msg2Lbl.textColor = UIColor.colorFromHex("#2F3742")
//        msg2Lbl.font = UIFont.regular(14.67.auto())
//        msg2Lbl.text = R.string.localizable.tracking_guide()
//        msg2Lbl.textAlignment = .center
//        msg2Lbl.numberOfLines = 0
        if type == "move_track" {
            alertView.addSubview(msg2Lbl)
            msg2Lbl.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.width.equalTo(268.auto())
                make.top.equalTo(msgLbl.snp.bottom).offset(15.auto())
            }
//            alertViewHeight += (msg2Lbl.getLabelHeight(msg2Lbl, width: 268.auto()) + 15.auto())
        }
        
        let setMoveTypeLbl = UILabel()
//        setMoveTypeLbl.textColor = UIColor.colorFromHex("#007AFF")
//        setMoveTypeLbl.font = UIFont.regular(14.67.auto())
//        setMoveTypeLbl.text = R.string.localizable.tracking_guide_2()
//        setMoveTypeLbl.textAlignment = .center
//        setMoveTypeLbl.numberOfLines = 0
//        setMoveTypeLbl.isUserInteractionEnabled = true
        if type == "move_track" {
            alertView.addSubview(setMoveTypeLbl)
            setMoveTypeLbl.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.width.equalTo(268.auto())
                make.top.equalTo(msg2Lbl.snp.bottom).offset(15.auto())
            }
//            setMoveTypeLbl.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pushDeviceMotionTrackingSetting)))
//            alertViewHeight += (setMoveTypeLbl.getLabelHeight(setMoveTypeLbl, width: 268.auto()) + 15.auto())
        }
        
        let guideImageView = UIImageView()
        let gifImage = UIImage(gifName: "device_preset_location.gif")
        guideImageView.setGifImage(gifImage, manager: gifManager ,loopCount: -1)
        if type != "move_track" {
            alertView.addSubview(guideImageView)
            guideImageView.snp.makeConstraints { (make) in
                make.top.equalTo(msgLbl.snp.bottom).offset(13.5.auto())
                make.centerX.equalToSuperview()
                make.width.equalTo(164.auto())
                make.height.equalTo(162.auto())
            }
            guideImageView.layoutIfNeeded()
            alertViewHeight += 162.auto() + 13.5.auto()
        }
        
        let doneBtn = UIButton()
        doneBtn.titleLabel?.font = ADTheme.B1
        doneBtn.titleLabel?.numberOfLines = 0
        doneBtn.titleLabel?.textAlignment = .center
        doneBtn.setTitle(type == "move_track" ? R.string.localizable.ok() : R.string.localizable.ok(), for: UIControl.State.normal)
        
        doneBtn.setTitleColor(ADTheme.C4, for: UIControl.State.disabled)
        doneBtn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        doneBtn.setBackgroundImage(UIImage.buttonNormallImage, for: .normal)
        let image = doneBtn.currentBackgroundImage
        let pressColor = image?.multiplyColor(image?.mostColor ?? ADTheme.Theme, by: 0.9)
        doneBtn.setBackgroundImage(UIImage.init(color: pressColor ?? ADTheme.Theme), for: .highlighted)
        doneBtn.setBackgroundImage(UIImage.init(color: ADTheme.C5), for: .disabled)
        doneBtn.layer.cornerRadius = 8.auto()
        doneBtn.clipsToBounds = true
        alertView.addSubview(doneBtn)
        
        doneBtn.snp.makeConstraints { (make) in
            make.centerX.equalTo(alertView.snp.centerX).offset(0)
            make.width.equalTo(alertView.snp.width).offset(-42.auto())
            make.height.equalTo(38.4.auto())
            make.top.equalTo(type == "move_track" ? msg2Lbl.snp.bottom : guideImageView.snp.bottom).offset(29.33.auto())
        }
        doneBtn.addTarget(self, action: #selector(moveTrackAlertDone), for: .touchUpInside)
        
        alertViewHeight += (38.4.auto() + 29.33.auto() + 31.auto())
        
        // 重新计算弹窗的高度
        alertView.snp.updateConstraints { (make) in
            make.centerY.equalTo(self.view)
            make.height.equalTo(alertViewHeight)
        }
        alertView.layoutIfNeeded()
        alertView.backgroundColor = .white
        //设置阴影颜色
        alertView.layer.shadowColor = UIColor.black.cgColor
        //设置透明度
        alertView.layer.shadowOpacity = 0.1
        //设置阴影半径
        alertView.layer.shadowRadius = 6.5
        //设置阴影偏移量
        alertView.layer.shadowOffset = CGSize(width: 0, height: -2)
        alertView.filletedCorner(CGSize(width: 15, height: 15),UIRectCorner(rawValue: (UIRectCorner.topLeft.rawValue) | (UIRectCorner.topRight.rawValue | UIRectCorner.bottomLeft.rawValue) | (UIRectCorner.bottomRight.rawValue)))
    }
    
    // 点击弹窗好的
    @objc func moveTrackAlertDone() {
        homeMoveTrackAlertBGView.removeFromSuperview()
    }
    
    // 点击去设置人形追踪
    @objc private func pushDeviceMotionTrackingSetting() {
        debugPrint("-------------> pushDeviceMotionTrackingSetting")
        // 需要加loading状态
        
        A4xPlayerManager.handle.stopAll(troubleDevice: nil, reason: A4xPlayerStopReason.changePage)
//        // 打点事件（直播设置-半屏）
//        let playVideoEM = A4xPlayVideoEventModel()
//        playVideoEM.live_player_type = "halfscreen"
//        A4xEventManager.endEvent(event:ADTickerPlayVideo.live_camera_setting_click(eventModel: playVideoEM))
//
//        homeMoveTrackAlertBGView.removeFromSuperview()
//        let vc = ADDevicesMotionDetectionViewController(deviceId: self.selectedDeviceId ?? "")
////        vc.fromVCType = .homeVC
//        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func deletePresetLocaion(deviceId: String?, preset: ADPresetModel?) {
        A4xLog("deletePresetLocaion ")
        // 打点事件（半屏添加预设删除）
        let playVideoEM = A4xPlayVideoEventModel()
        playVideoEM.live_player_type = "halfscreen"
        weak var weakSelf = self
        presetModle.remove(deviceId: deviceId, pointId: preset?.id ?? 0) {status, tips in
            playVideoEM.result = "\(status)"
            if status {
                weakSelf?.reloadData(error: nil)
            } else {
                playVideoEM.error_msg = "\(String(describing: tips))"
            }
            A4xEventManager.endEvent(event:ADTickerPlayVideo.live_remoteControl_savePoint_delete(eventModel: playVideoEM))
            weakSelf?.view.makeToast(tips)
        }
    }
    
    private func presetClickAction(deviceId: String?, preset: ADPresetModel?) {
        A4xLog("presetClickAction")
        presetModle.send(deviceId: deviceId, preset: preset) { _ in
        }
    }
    
    private func presetItemAction(deviceId: String?, preset: ADPresetModel?, type: HomeVideoPresetCellType, image: UIImage?) {
        weak var weakSelf = self
        let playVideoEM = A4xPlayVideoEventModel()
        playVideoEM.live_player_type = "halfscreen"
        switch type {
        case .none:// 点击预设位置
            // live_remoteControl_savePoint_rotate
            playVideoEM.save_point_id = deviceId
            A4xEventManager.endEvent(event:ADTickerPlayVideo.live_remoteControl_savePoint_rotate(eventModel: playVideoEM))
            weakSelf?.presetClickAction(deviceId: deviceId, preset: preset)
        case .add:// 新增预设位置
            // live_remoteControl_savePoint_add
            weakSelf?.addPresetAlertLocation(deviceId: deviceId, image: image)
        case .delete:// 删除预设位置
            // live_remoteControl_savePoint_delete
            weakSelf?.deletePresetLocaion(deviceId: deviceId, preset: preset)
        }
    }
    
    //    private
    //    func presetLocationViewTypeChange(deviceId: String?, type: ADHomeVideoPresetTypeModle) {
    //        let (index, _) = deviceAtIndex(deviceId: deviceId)
    //        if index >= 0 {
    //            switch type {
    //            case .none:
    //                updateCellModle(type: ADVideoRowType.runing, editModle: ADHomeVideoPresetTypeModle.none, rowIndex: index)
    //            case .edit:
    //                updateCellModle(type: ADVideoRowType.runing, editModle: .edit, rowIndex: index)
    //            case .delete:
    //                updateCellModle(type: ADVideoRowType.runing, editModle: .delete, rowIndex: index)
    //            case .show:
    //                updateCellModle(type: ADVideoRowType.runing, editModle: .show, rowIndex: index)
    //            }
    //        }
    //    }
    
    private func deviceAtIndex(deviceId: String?) -> (Int, A4xDeviceModel?) {
        if let allSource = dataSource, let devid = deviceId {
            for index in 0 ..< allSource.count {
                let modle = allSource[index]
                if modle.id == devid {
                    return (index, modle)
                }
            }
        }
        
        return (-1, nil)
    }
}

extension ADHomeVideoViewController: HomeVideoCollectCellProtocol {
    func deviceAlert(device: A4xDeviceModel?, isAlerting: Bool, comple: @escaping (Bool)->Void) {
        if isAlerting {
            self.view.makeToast(R.string.localizable.alarm_playing())
            comple(false)
        } else {
            weak var weakSelf = self
            self.showDeviceAlert( message: R.string.localizable.do_alarm_tips(), cancelTitle: R.string.localizable.cancel(), doneTitle: R.string.localizable.alarm_on(), image: R.image.device_send_alert(), doneAction: {
                A4xUserDataHandle.Handle?.videoHelper.keepAlive(deviceId: device?.id ?? "", isHeartbeat: false, comple: { (state, flag) in
                    switch state {
                    case .start:
                        break
                    case .done(_):
                        A4xNetManager.execute(reqMoudelType: A4xNetMoudelType.Devices(.alarm(deviceId: device?.id ?? "")), resModelType: A4xNetNormaiModel.self) { (result) in
                            switch result {
                            case .success(_):
                                A4xLog("success")
                                comple(true)
                            case .failure( let code , _):
                                weakSelf?.view.makeToast(A4xAppErrorConfig(code: code).message())
                                A4xLog("failure")
                                comple(false)
                                
                            }
                        }
                    case .error(let errr):
                        weakSelf?.view.makeToast(errr)
                        comple(false)
                        
                        break
                    }
                })
            }) {
                comple(false)
            }
        }
        
    }
    
    func deviceSettingRefresh(device : A4xDeviceModel?) {
        self.collectView.mj_header?.beginRefreshing()
        //        self.viewModle?.getDevices(resultb: { [weak self] (error) in
        //            self?.updateData(error: error)
        //        })
    }
    
    // 设备唤醒处理
    func deviceSleepToWakeUp(device: A4xDeviceModel?) {
        // 开启休眠
        weak var weakSelf = self
        
        UIApplication.shared.keyWindow?.makeToastActivity(title: R.string.localizable.loading()) { (f) in
        }
        
        self.viewModle?.sleepToWakeUP(deviceId: device?.id ?? "", enable: false, comple: { (err) in
            UIApplication.shared.keyWindow?.hideToastActivity()
            if err != nil {
                weakSelf?.view.makeToast(err)
            }
            debugPrint("-----------> deviceSleepToWakeUp func to updateAll")
            A4xPlayerManager.handle.updateAll()
            A4xPlayerManager.handle.stopAll(troubleDevice: nil, reason: A4xPlayerStopReason.pull)
            
            weakSelf?.reloadData(error: err)
            A4xPlayerManager.handle.updateAllSnapImage {[weak weakSelf] deviceID in
                weakSelf?.reloadCellWithDeviceId(deviceID: deviceID)
            }
            weakSelf?.splitStyleToAutoPlay()
            weakSelf?.navBar.showHeadDisturb = A4xUserDataHandle.Handle?.deviceModels?.count ?? 0 > 0
            weakSelf?.collectView.mj_header?.beginRefreshing()
        })
    }
    
    func deviceLoadSpeak(device: A4xDeviceModel?, enable: Bool) -> Bool {
        // 打点事件（双向语音）
        let playVideoEM = A4xPlayVideoEventModel()
        playVideoEM.live_player_type = "halfscreen"
        
        guard let data = device else {
            return false
        }
        
        guard A4xPlayerManager.handle.canSpeak(device: data) else {
            if enable {
                playVideoEM.result = "false"
                playVideoEM.error_msg = R.string.localizable.reject_audio()
                A4xEventManager.endEvent(event:ADTickerPlayVideo.live_voice_calls(eventModel: playVideoEM))
                view.makeToast(R.string.localizable.reject_audio())
            }
            return false
        }
        
        if enable {
            if A4xPlayerManager.handle.speakLoad(device: data) {
                A4xPlayerManager.handle.setAudioEnable(device: data, enable: true)
                playVideoEM.result = "true"
                A4xEventManager.endEvent(event:ADTickerPlayVideo.live_voice_calls(eventModel: playVideoEM))
            } else {
                playVideoEM.result = "false"
                playVideoEM.error_msg = R.string.localizable.voice_talk_failed_and_retry()
                A4xEventManager.endEvent(event:ADTickerPlayVideo.live_voice_calls(eventModel: playVideoEM))
                view.makeToast(R.string.localizable.voice_talk_failed_and_retry())
                return false
            }
        }
        
        A4xPlayerManager.handle.setSpeakEnable(device: data, enable: enable)
        return true
    }
    
    func videoHelpAction() {
        A4xLog("videoHelpAction")
    }
    
    func deviceRecordList(device: A4xDeviceModel?) {
        changeVisableVC?(.Libary, device)
    }
    
    // 设备设置
    func deviceSetting(device: A4xDeviceModel?) {
        A4xPlayerManager.handle.stopAll(troubleDevice: nil, reason: A4xPlayerStopReason.changePage)
        
        // 打点事件（直播设置-半屏）
        let playVideoEM = A4xPlayVideoEventModel()
        playVideoEM.live_player_type = "halfscreen"
        A4xEventManager.endEvent(event:ADTickerPlayVideo.live_camera_setting_click(eventModel: playVideoEM))
        
//        let vc = ADDevicesSettingViewController()
//        vc.deviceId = device?.id
//        navigationController?.pushViewController(vc, animated: true)
    }
    
    // 设备信息设置
    func deviceInfoSetting(device: A4xDeviceModel?, state: String?) {
        A4xPlayerManager.handle.stopAll(troubleDevice: nil, reason: A4xPlayerStopReason.changePage)
        
//        let vc = ADDevicesFirmwareInfoViewController()
//        vc.deviceId = device?.id
//        vc.updateState = state
//        navigationController?.pushViewController(vc, animated: true)
    }
    
    // 设备分享给用户
    func deviceShareUsers(device: A4xDeviceModel?) {
        A4xPlayerManager.handle.stopAll(troubleDevice: nil, reason: A4xPlayerStopReason.changePage)
        guard let dev = device else {
            return
        }
//
//        if dev.isAdmin() {
//            let vc = ADDevicesShareViewController(deviceId: dev.id ?? "")
//            navigationController?.pushViewController(vc, animated: true)
//        } else {
//            let vc = ADDevicesShareByViewController(deviceId: dev.id ?? "")
//            navigationController?.pushViewController(vc, animated: true)
//        }
    }
    
    func videoReportLogAction(device: A4xDeviceModel?) {
        guard let devId = device?.id else {
            return
        }
        
        var config = A4xBaseAlertAnimailConfig()
        config.titleColor = UIColor.hex(0x2F3742)
        config.alertTitleFont = ADTheme.B1
        config.messageColor = UIColor.hex(0x666666)
        config.messageFont = ADTheme.B2
        config.messageAlignment = .left
        config.titleAlignment = .left
        config.leftbtnBgColor = UIColor.clear
        config.leftTitleColor = ADTheme.C1
        config.rightbtnBgColor = UIColor.clear
        config.rightTextColor = ADTheme.Theme
        let alert = A4xBaseAlertView(param: config, identifier: "show send_log")
        alert.title = R.string.localizable.send_log()
        alert.message  = R.string.localizable.send_log_tips()
        alert.leftButtonTitle = R.string.localizable.cancel()
        alert.rightButtonTitle = R.string.localizable.confirm()
        alert.rightButtonBlock = { [weak self] in
//            log.getResultFiles {[weak self] (url, comple) in
//                if let filePath = url {
//                    onMainThread {
//                        UIApplication.shared.keyWindow?.makeToastActivity(title: "", completion: { (f) in})
//                    }
//
//                    A4xNetManager.execute(reqMoudelType: .DeviceControl(.uploadLog(deviceId: devId, logStartTime: Date().timeIntervalSince1970 - 3000, filePath: filePath)), resModelType: A4xNetNormaiModel.self) { [weak self](result) in
//                        onMainThread {
//                            UIApplication.shared.keyWindow?.hideToastActivity()
//                            switch result {
//                            case .success(_):
//                                self?.view.makeToast(R.string.localizable.uploaded_success())
//                            case .failure(code: _, errorMsg: _):
//                                self?.view.makeToast(R.string.localizable.uploaded_fail())
//                            }
//                        }
//                    }
//
//                }
//            }
        }
        alert.show()
    }
    
    // 跳转到全屏直播VC 凸
    func videoControlFull(device: A4xDeviceModel?, indexPath: IndexPath?) {
        if device == nil {
            return
        }
        presentLiveVideo(device: device, currentIndexPath: indexPath)
    }
    
    //
    func deviceCellModleUpdate(device: A4xDeviceModel?, type : ADVideoCellType, indexPath:IndexPath?) {
        if type == .locations {
            fristGuideAlert(device?.id, type: "preset_location")
        }
        self.updateCellType(type: type, rowIndex: indexPath?.row ?? 0)
        self.reloadData(error: nil)
    }
}

// MARK: - UserDevicesChangeProtocol , A4xUserDataHandleWifiProtocol

extension ADHomeVideoViewController: UserDevicesChangeProtocol, A4xUserDataHandleWifiProtocol, A4xUserDataHandleAccountProtocol {
    
    func userLogout() {
        self.disturbView?.free()
    }
    
    private func updateWifoTip(noNet: Bool, isClose: Bool = false) {
        let isHiddenTip = !noNet || isClose
        noWifiTip.isHidden = isHiddenTip
        
        UIView.animate(withDuration: 0.3) {
            self.collectView.snp.updateConstraints { make in
                make.top.equalTo(self.navBar.snp.bottom).offset(isHiddenTip ? 0 : 60.auto())
            }
            self.view.layoutIfNeeded()
        }
        self.reloadData(error: nil)
    }
    
    func wifiInfoUpdate(status: ADReaStatus) {
        updateWifoTip(noNet: status == .nonet)
        if A4xPlayerManager.handle.isPlaying(device: nil) {
            A4xPlayerManager.handle.checkShow4GAlert(device: nil) { f in
                if !f {
                    A4xPlayerManager.handle.stopAll(troubleDevice: nil, reason: A4xPlayerStopReason.none)
                }
            }
        }
    }
    
    func userDevicesChange(status: ADDeviceChange) {
        reloadData(error: nil)
        self.navBar.showHeadDisturb = A4xUserDataHandle.Handle?.deviceModels?.count ?? 0 > 0
        
        switch status {
        case .add:
            collectView.mj_header?.beginRefreshing()
        default:
            return
        }
    }
}

extension ADHomeVideoViewController: A4xUIViewPlayerStateChangeProtocol {
//    func deviceEnableRotating(deviceID: String, enable: Bool) {
//    }
    
    // 直播状态更新ijk
    func helperStateChange(state: A4xPlayerStateType, deviceId: String) {
        
        debugPrint("-----------> ADHomeVideoViewController helperStateChange func state: \(state)")
        
        guard isTop else {
            debugPrint("-----------> helperStateChange isTop return")
            return
        }
        
        let (index, _) = deviceAtIndex(deviceId: deviceId)
        
        // 在当前作用域(并不仅限于函数)结束时执行
        defer {
            reloadData(error: nil)
            if state == .playing {
                if fullVideoSelIndexPath == nil {
                    collectView.scrollToItem(at: IndexPath(row: index, section: 0), at: .top, animated: true)
                }
            }
        }
        
        
        if A4xUserDataHandle.Handle?.videoStyle == .split || index < 0 {
            debugPrint("-----------> helperStateChange index < 0 return")
            return
        }
        
        var currentType = cellTypes.getIndex(index) ?? .default
        weak var weakSelf = self
        if state == .playing {
            if currentType != .playControl {
                currentType = .playControl
            }
            
            presetModle.featch(deviceId: deviceId) { error in
                if let e = error {
                    weakSelf?.view.makeToast(e)
                }
                weakSelf?.reloadData(error: nil)
            }
        } else {
            if currentType != .default {
                currentType = .default
            }
        }
        
        self.updateCellType(type: currentType, rowIndex: index)
    }
}

// MARK: - ViewController handle

extension ADHomeVideoViewController: ADLiveVideoViewControllerDelegate {
    
    @objc private func presentAddCamera() {
        A4xPlayerManager.handle.stopAll(troubleDevice: nil, reason: A4xPlayerStopReason.changePage)
        let nav = UINavigationController(rootViewController: A4xBindRootViewController())
        nav.isNavigationBarHidden = true
        nav.modalPresentationStyle = .fullScreen
        navigationController?.present(nav, animated: true)
        A4xLog("ADHomePageViewController presentAddCamera")
    }
    
    private func presentAddLocation() {
        A4xPlayerManager.handle.stopAll(troubleDevice: nil, reason: A4xPlayerStopReason.changePage)
        let addloc = A4xBindAddLocationViewController(locationModle: nil)
        navigationController?.pushViewController(addloc, animated: true)
    }
    
    private func presentLocationManager() {
        A4xPlayerManager.handle.stopAll(troubleDevice: nil, reason: A4xPlayerStopReason.changePage)
        
//        let addCamera: String = "\(ADUrlPre.nav)://location-manager"
//        Router.push(URL: addCamera)
        A4xLog("ADHomePageViewController presentLocationManager")
    }
    
    // 跳转到全屏直播 凸
    private func presentLiveVideo(device: A4xDeviceModel?, currentIndexPath: IndexPath?) {
        if device == nil {
            return
        }
        A4xPlayerManager.handle.stopAll(troubleDevice: device, reason: A4xPlayerStopReason.changeModle)
        
        let vc = ADLiveVideoViewController()
        vc.delegate = self
        vc.dataSource = device
        vc.presetModle = presetModle
        vc.currentIndexPath = currentIndexPath
        navigationController?.pushViewController(vc, animated: true)
        A4xLog("ADHomePageViewController presendFilterResource")
    }
    
    // 接收 ADLiveVideoViewController 消息处理 凹
    func didFinishViewController(controller: UIViewController, currentIndexPath: IndexPath) {
        debugPrint("-------------> didFinishViewController")
        fromLiveVideo = true
        controller.navigationController?.popViewController(animated: true)
        self.fullVideoSelIndexPath = currentIndexPath
    }
}

//disturbView
extension ADHomeVideoViewController {
    func showDisturbPushOpen() {
        let openBlockblock = { [weak self] in
            UIApplication.shared.keyWindow?.makeToastActivity(title: R.string.localizable.loading()) { (f) in
            }
            self?.viewModle?.openUserDisturbEnable(duration: 15 * 60, resultBlock: { [weak self] (isScuess, error) in
                UIApplication.shared.keyWindow?.hideToastActivity()
                if isScuess {
                    self?.showDisturbView(point: self?.navBar.headerDisturbingPoint ?? .zero)
                    
                }else {
                    UIApplication.shared.keyWindow?.makeToast(error)
                }
            })
        }
        
        if (A4xUserDataHandle.Handle?.noTipDisturbAlerts ?? false) {
            openBlockblock()
            return
        }
        
        let alert = ADOpenDisturbingAlert()
        alert.onRightButtonAction = {  enable in
            A4xUserDataHandle.Handle?.noTipDisturbAlerts = enable
            openBlockblock()
        }
        alert.show()
    }
    
    func updateDisturbInfo() {
        self.viewModle?.getUserDisturbInfo(resultBlock: {[weak self] (f, error) in
            if f {
                let isDone = A4xUserDataHandle.Handle?.disturbModle?.currentTime().idDone ?? true
                if isDone {
                    return
                }
                self?.showDisturbView(point: self?.navBar.headerDisturbingPoint ?? CGPoint.zero)
            }else {
                self?.view.makeToast(error)
            }
        })
    }
    
    func showDisturbSheet(point : CGPoint? = nil) {
        let showPoint : CGPoint = point ?? (self.navBar.headerDisturbingPoint )
        A4xEventManager.event(info: .home_shield_open)
        
        self.showDisturbActionSheet { [weak self] (typ) in
            self?.view.makeToastActivity(title: R.string.localizable.loading()) { (f) in
            }
            A4xEventManager.event(info: .home_shield_time, attr: ["time":"\(typ.intValue())"])
            
            self?.viewModle?.openUserDisturbEnable(duration: typ.intValue(), resultBlock: { [weak self] (isScuess, error) in
                self?.view.hideToastActivity()
                if isScuess {
                    self?.showDisturbView(point: showPoint)
                }else {
                    self?.view.makeToast(error)
                }
            })
        }
    }
    
    func showDisturbView(point : CGPoint) {
        self.navBar.disturbEnable = false
        let resultInsetTop = 10 + 60.auto()
        self.disturbView?.showAnimail(beginPoint: point, insetTop: CGFloat(resultInsetTop)) { [weak self] in
            guard let self = self else {
                return
            }
            
            self.collectView.contentInset = UIEdgeInsets(top: CGFloat(resultInsetTop), left: 0, bottom: 10.auto(), right: 0)
            self.collectView.setContentOffset(CGPoint(x: 0, y: -self.collectView.contentInset.top), animated: true)
            if let resusHeader = self.collectView.mj_header as? A4xMJRefreshHeader {
                resusHeader.ignoredScrollViewContentInsetTop = 60.auto()
            }
        } comple: {
        }
    }
    
    @objc func closeUserDisturbAction(){
        var config = A4xBaseAlertAnimailConfig()
        config.leftbtnBgColor = UIColor.clear
        config.leftTitleColor = ADTheme.C1
        config.rightbtnBgColor = UIColor.clear
        config.rightTextColor = ADTheme.Theme
        
        let alert = A4xBaseAlertView(param: config, identifier: "show Save Alert")
        alert.message  = R.string.localizable.end_do_not_disturb()
        alert.rightButtonTitle = R.string.localizable.end()
        alert.leftButtonTitle = R.string.localizable.cancel()
        alert.leftButtonBlock = { }
        
        alert.rightButtonBlock = { [weak self] in
            A4xEventManager.event(info: .home_shield_close)
            
            self?.view.makeToastActivity(title: R.string.localizable.loading(), completion: { (f) in
            })
            
            self?.viewModle?.closeUserDisturb(resultBlock: { [weak self ](f, error) in
                self?.view.hideToastActivity()
                if f {
                    self?.hiddenDisturbAlert()
                } else {
                    self?.view.makeToast(error)
                }
            })
        }
        alert.show()
    }
    
    @objc func hiddenDisturbAlert() {
        self.disturbView?.hiddenAnimail { [weak self] in
            self?.navBar.disturbEnable = true
            self?.collectView.contentInset = UIEdgeInsets(top: 10 , left: 0, bottom: 10.auto(), right: 0)
            self?.collectView.setContentOffset(CGPoint(x: 0, y: -(self?.collectView.contentInset.top ?? 0)), animated: true)
            if let resusHeader = self?.collectView.mj_header as? A4xMJRefreshHeader {
                resusHeader.ignoredScrollViewContentInsetTop = 10
            }
        } comple: {
            
        }
    }
}
