//
// Created by zhi kuiyu on 2019-01-30.
//

import UIKit
import A4xBaseSDK



public enum ADHomeBottomBarType : Int {
    case Video  = 0
    case Libary = 1
    case User   = 2
    case Web   = 3
}

public typealias SelectItemBlock = (ADHomeBottomBarType) -> Void

public class ADHomeBottomBarView: UIView {
    
    var sliceCount: Float = 3.0
    
    // 初始化
    var barTitleArr: [String] = [
                    R.string.localizable.home(),
                    R.string.localizable.library(),
                    R.string.localizable.mine(),
                    R.string.localizable.explore()]
    
    var barImgTuple: [(UIImage?, UIImage?)] = [
                    (R.image.homepage_video(), R.image.homepage_video_select()),
                    (R.image.homepage_libary(), R.image.homepage_libary_select()),
                    (R.image.homepage_user(), R.image.homepage_user_select()),
                    (R.image.homepage_explore(), R.image.homepage_explore_select())]
    
    var barIdentifierArr: [String] = [
                    "home_video",
                    "libary_video",
                    "setting_video",
                    "explore_video"]
    
    
    public var userHasNew: Bool = false {
        didSet {
            if self.getSubViewByTag(tag: 2 + 100).count > 1 {
                let settingIconView = self.getSubViewByTag(tag: 2 + 100)[0] as? ADHomeBarItemView
                settingIconView?.hasNew = userHasNew
            }
        }
    }
    
    public var currentType: ADHomeBottomBarType? = .Video {
        didSet {
            if self.bottomSelectBlock != nil && currentType != oldValue {
                self.bottomSelectBlock?(currentType ?? .Video)
            }
            updateSelect()
        }
    }

    public var bottomSelectBlock: SelectItemBlock? {
        didSet {
            if bottomSelectBlock != nil {
                self.bottomSelectBlock?(currentType ?? .Video)
            }
        }
    }

    public func updateInfo() {
        // 切换语言 监听 by wjin v3.1
//        self.videoIconView.nameTitle = R.string.localizable.home()
//        self.libaryIconView.nameTitle = R.string.localizable.library()
//        self.settingIconView.nameTitle = R.string.localizable.mine()
        
        // 需要重新拿一次赋值给数组 - 拿的过程中就是国际化处理 by wjin
        barTitleArr = [
                        R.string.localizable.home(),
                        R.string.localizable.library(),
                        R.string.localizable.mine(),
                        R.string.localizable.explore()]
        
        for i in 0..<Int(sliceCount) {
            let subView = self.getSubViewByTag(tag: i + 100)[0] as? ADHomeBarItemView
            subView?.nameTitle = barTitleArr[i]
        }
    }
    
//    lazy var videoIconView: ADHomeBarItemView = {
//        let tem: ADHomeBarItemView = ADHomeBarItemView()
//        self.addSubview(tem)
//        tem.accessibilityIdentifier = "home_video"
//        tem.barType = .Video
//        tem.normailImage = R.image.homepage_video()
//        tem.selectImage = R.image.homepage_video_select()
//        tem.selectTitleColor = ADTheme.Theme
//        tem.titleColor = ADTheme.C3
//        tem.nameTitle = R.string.localizable.home()
//        tem.selectBlock = { result in
//            self.currentType = result
//        }
//
//        var proBy: Float = 1.0 / sliceCount
//        tem.snp.makeConstraints { make in
//            make.top.equalTo(self.snp.top)
//            make.height.equalTo(self.snp.height)
//            make.width.equalTo(self.snp.width).multipliedBy(proBy)
//            make.left.equalTo(0)
//        }
//        return tem
//    }()
//
//    lazy var libaryIconView: ADHomeBarItemView = {
//        let tem: ADHomeBarItemView = ADHomeBarItemView()
//        tem.accessibilityIdentifier = "libary_video"
//        tem.barType = .Libary
//        tem.normailImage = R.image.homepage_libary()
//        tem.selectImage = R.image.homepage_libary_select()
//        tem.nameTitle = R.string.localizable.library()
//        tem.selectTitleColor = ADTheme.Theme
//        tem.titleColor = ADTheme.C3
//        tem.selectBlock = { result in
//            self.currentType = result
//        }
//        self.addSubview(tem)
//
//        var proBy:Float = 1.0 / sliceCount
//        tem.snp.makeConstraints { make in
//            make.top.equalTo(self.snp.top)
//            make.height.equalTo(self.snp.height)
//            make.width.equalTo(self.snp.width).multipliedBy(proBy)
//            make.left.equalTo(videoIconView.snp.right)
//        }
//        return tem
//    }()
//
//    lazy var settingIconView: ADHomeBarItemView = {
//        let tem: ADHomeBarItemView = ADHomeBarItemView()
//        tem.accessibilityIdentifier = "setting_video"
//        tem.barType = .User
//        tem.normailImage = R.image.homepage_user()
//        tem.selectImage = R.image.homepage_user_select()
//        tem.selectTitleColor = ADTheme.Theme
//        tem.titleColor = ADTheme.C3
//        tem.nameTitle = R.string.localizable.mine()
//        tem.selectBlock = { (result) in
//            self.currentType = result
//        }
//        self.addSubview(tem)
//
//        var proBy: Float = 1.0 / sliceCount
//        tem.snp.makeConstraints { make in
//            make.top.equalTo(self.snp.top)
//            make.height.equalTo(self.snp.height)
//            make.width.equalTo(self.snp.width).multipliedBy(proBy)
//            make.left.equalTo(libaryIconView.snp.right)
//        }
//        return tem
//    }()
    
    lazy var lineView: UIView = {
        let tem: UIView = UIView()
        tem.backgroundColor = ADTheme.C6
        self.addSubview(tem)
        tem.snp.makeConstraints({ (make) in
            make.top.equalTo(0)
            make.height.equalTo(1)
            make.width.equalTo(self.snp.width)
            make.left.equalTo(0)
        })
        return tem
    }()


    init() {
        super.init(frame: CGRect.zero)
        
//        self.videoIconView.isHidden = false
//        self.libaryIconView.isHidden = false
//        self.settingIconView.isHidden = false
        
        createBarView()
        self.lineView.isHidden = false
        
        updateSelect()
    }
    
    private func createBarView() {
        debugPrint("-------------> createBarView: \(self.getAllSubViews())")
        // 移除子视图 - 重新绘制
        _ = self.subviews.map {
            $0.removeFromSuperview()
        }
        
        // 重新拿到 分片数 - 完美方案应该是后端下发 - hardcode by wjin v3.1
        if A4xAppConfigManager.buildInfo().tenantId == "dzees" {
            self.sliceCount = 4.0
        }
        
        for i in 0..<Int(sliceCount) {
            
            let tem: ADHomeBarItemView = ADHomeBarItemView()
            tem.accessibilityIdentifier = self.barIdentifierArr[i]
            tem.barType = ADHomeBottomBarType.init(rawValue: i)
            tem.tag = i + 100
            tem.normailImage = self.barImgTuple[i].0
            tem.selectImage = self.barImgTuple[i].1
            tem.selectTitleColor = ADTheme.Theme
            tem.titleColor = ADTheme.C3
            tem.nameTitle = barTitleArr[i]
            tem.selectBlock = { (result) in
                self.currentType = result
            }
            
            self.addSubview(tem)

            let proBy: Float = 1.0 / sliceCount
            tem.snp.makeConstraints { make in
                make.top.equalTo(self.snp.top)
                make.height.equalTo(self.snp.height)
                make.width.equalTo(self.snp.width).multipliedBy(proBy)
                make.left.equalTo(0 + UIScreen.width * CGFloat(proBy) * CGFloat(i))
            }
        }
        
    }
    
    private func updateSelect() {
//        videoIconView.isSelected   = (videoIconView.barType == currentType)
//        libaryIconView.isSelected  = (libaryIconView.barType == currentType)
//        settingIconView.isSelected = (settingIconView.barType == currentType)
        
        debugPrint("-------------> updateSelect: \(self.getAllSubViews())")
        for i in 0..<Int(sliceCount) {
            let subView = self.getSubViewByTag(tag: i + 100)[0] as? ADHomeBarItemView
            subView?.isSelected = (subView?.barType == currentType)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
