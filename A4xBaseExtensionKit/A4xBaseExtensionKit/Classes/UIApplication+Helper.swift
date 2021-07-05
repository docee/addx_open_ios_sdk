//
//  UIApplication+Helper.swift
//  SwiftTemplet
//
//  Created by hsf on 2018/8/24.
//  Copyright © 2018年 BN. All rights reserved.
//

import UIKit

public extension UIApplication{
    
    static var appName: String {
        get {
            let infoDic = Bundle.main.infoDictionary;
            let name:String = infoDic![kCFBundleNameKey as String] != nil ? infoDic![kCFBundleNameKey as String] as! String : infoDic![kCFBundleExecutableKey as String] as! String;
            return name;
        }
    }
    
    static var appIcon: UIImage {
        get {
            let infoDic:AnyObject = Bundle.main.infoDictionary as AnyObject;
            let iconFiles:Array<Any> = infoDic.value(forKeyPath: "CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconFiles") as! Array<Any>;
            let imgName:String = iconFiles.last as! String;
            return  UIImage(named: imgName)!;
        }
    }
    
    static var appVer: String {
        get {
            let infoDic = Bundle.main.infoDictionary;
            return infoDic!["CFBundleShortVersionString"] as! String;
        }
    }
    
    static var appBuild: String {
        get {
            let infoDic = Bundle.main.infoDictionary;
            return infoDic!["CFBundleVersion"] as! String;
        }
    }
    
    static var systemVersion: Float {
        get {
            return UIDevice.current.systemVersion.floatValue();
        }
    }
    
    static var phoneSystemName: String {
        get {
            return UIDevice.current.systemName;
        }
    }
    
    static var phoneName: String {
        get {
            return UIDevice.current.name;
        }
    }
    
    static var mainWindow: UIWindow {
        get {
            if let window = UIApplication.shared.keyWindow {
                window.backgroundColor = UIColor.white
                window.makeKeyAndVisible()
                return window
            } else {
                let window = UIWindow(frame: UIScreen.main.bounds)
                window.backgroundColor = UIColor.white
                window.makeKeyAndVisible()
                return window
            }
        }
    }
    
    static var rootController: UIViewController {
        get {
            return UIApplication.mainWindow.rootViewController!;
        }
        set {
            UIApplication.mainWindow.rootViewController = newValue;
        }
    }
    
    static var tabBarController: UITabBarController? {
        get {
            var tabBarVC = objc_getAssociatedObject(self, RuntimeKeyFromSelector(#function)) as? UITabBarController;
            if tabBarVC == nil {
                if UIApplication.mainWindow.rootViewController is UITabBarController {
                    tabBarVC = (UIApplication.mainWindow.rootViewController as! UITabBarController);
                }
            }
            return tabBarVC;
        }
        set {
            objc_setAssociatedObject(self, RuntimeKeyFromSelector(#function), newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    
    //MARK: func
    static func setupRootController(_ window:inout UIWindow,_ controller:AnyObject,_ isAdjust:Bool) -> Void {
        window = UIApplication.mainWindow;
        UIApplication.setupRootController(controller, isAdjust);
    }
    
    static func setupRootController(_ controller:AnyObject,_ isAdjust:Bool) -> Void {
        var contr = controller;
        if controller is String {
            contr = UICtrFromString(controller as! String);
        }
        
        if !isAdjust {
            UIApplication.rootController = contr as! UIViewController;
            return;
        }
        
        if controller is UINavigationController || controller is UITabBarController {
            UIApplication.rootController = contr as! UIViewController;
        } else {
            UIApplication.rootController = UINavigationController(rootViewController: contr as! UIViewController);
        }
    }
    
    static func setupRootController(_ controller:AnyObject) -> Void {
        return UIApplication.setupRootController(controller, true);
    }
    
    static func setupAppearance() -> Void {
        self.setupAppearanceTabBar();
        self.setupAppearanceNavigationBar();
        
        if iOSVer(version: 11) {
            UITableView.appearance().estimatedRowHeight = 0.0;
            UITableView.appearance().estimatedSectionHeaderHeight = 0.0;
            UITableView.appearance().estimatedSectionFooterHeight = 0.0;
            
//            UIScrollView.appearance().contentInsetAdjustmentBehavior = .never;
            UIScrollView.appearance().keyboardDismissMode = .onDrag;
        }
        UIButton.appearance().isExclusiveTouch = false;
        
        UITabBar.appearance().tintColor = UIColor.theme
        UITabBar.appearance().barTintColor = UIColor.white

    }
    
    static func setupAppearanceNavigationBar() -> Void {
        UINavigationBar.appearance().tintColor =  .white;
        UINavigationBar.appearance().barTintColor = .theme;
        //        UINavigationBar.appearance().barTintColor = .orange;
        
        let attDic = [NSAttributedString.Key.foregroundColor :   UIColor.white,
                      NSAttributedString.Key.font    :   UIFont.boldSystemFont(ofSize:18)];
        UINavigationBar.appearance().titleTextAttributes = attDic;
        
        UINavigationBar.appearance().isTranslucent = true //界面顶部透明
//        UINavigationBar.appearance().shadowImage =  UIImage.lkCreateImage(with:.clear)//阴影颜色
//        UINavigationBar.appearance().setBackgroundImage(UIImage.lkCreateImage(with:.clear), for:UIBarMetrics.default)//背景颜色

//        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffset.init(horizontal: 0, vertical: -60), for: UIBarMetrics.default)//去掉返回图片后面的文
        
        let dicNomal = [NSAttributedString.Key.foregroundColor: UIColor.white,
                        ]
        UIBarButtonItem.appearance().setTitleTextAttributes(dicNomal, for: .normal)
    }
    
    static func setupAppearanceTabBar() -> Void {
        //         设置字体颜色
//        let attDic_N = [NSAttributedString.Key.foregroundColor:.black];
//        let attDic_H = [NSAttributedString.Key.foregroundColor: UIColor.theme];
////        UITabBarItem.appearance().setTitleTextAttributes(attDic_N, for: .normal);
//        UITabBarItem.appearance().setTitleTextAttributes(attDic_H, for: .selected);
        // 设置字体偏移
        UITabBarItem.appearance().titlePositionAdjustment = UIOffset.init(horizontal: 0, vertical: -5.0);
        // 设置图标选中时颜色
//        UITabBar.appearance().tintColor = .red;
    }
    
    static func openURL(_ urlStr:String, _ tips:String) {
        let set = NSCharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]").inverted;
        let str:String = urlStr.addingPercentEncoding(withAllowedCharacters: set)!;
        //        let str:String = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!;
        
        let url:NSURL? = NSURL(string:str);
        if UIApplication.shared.canOpenURL(url! as URL) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url! as URL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url! as URL);
                
            }
        } else {
            print("链接无法打开!!!\n%@",url as Any);
            
        }
    }
    
    
    static func isIPhoneX() -> Bool {
        if #available(iOS 11.0, *) {
            let window: UIWindow? = UIApplication.shared.keyWindow
            if window != nil {
                let bottom :Float = Float(window?.safeAreaInsets.bottom ?? 0)
                if bottom > 20 {
                    return true
                }
            }
        }
        return false
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
