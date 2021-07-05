
//
//  UIScreen+Helper.swift
//  SwiftTemplet
//
//  Created by hsf on 2018/9/7.
//  Copyright © 2018年 BN. All rights reserved.
//

import UIKit


public extension UIScreen {
    
    static var width : CGFloat {
        get {
            return UIScreen.main.bounds.size.width
        }
    }
    
    static var height : CGFloat {
        get {
            return UIScreen.main.bounds.size.height
        }
    }
    
    static var statusBarHeight : CGFloat {
        get {
            if UIApplication.isIPhoneX(){
                return 44.0
            }else {
                return 20.0
            }
        }
    }
    
    
    static var horStatusBarHeight : CGFloat {
        get {
            return 20.0
        }
    }
    
    static var stateHomeSaft : CGFloat {
        get {
            return UIApplication.isIPhoneX() ? 34 : 0
        }
    }
    
    static var newNavHeight : CGFloat {
        get {
            return 74.0 + UIScreen.barNewHeight
        }
    }
    
    static var barNewHeight : CGFloat {
        get {
            let stateHeight : CGFloat
            if UIApplication.isIPhoneX(){
                stateHeight = 42.0
            }else {
                stateHeight = 20.0
            }
            return stateHeight
        }
    }
    
    static var navBarHeight : CGFloat {
        get {
            return UIScreen.statusBarHeight + UIScreen.navtionHeight
        }
    }
    
    
    /// 横屏导航高度
    static var horNavBarHeight : CGFloat {
        get {
            return 20.0 + UIScreen.horNavtionHeight
        }
    }
    
    static var horNavtionHeight : CGFloat {
        get {
            return 30.0
        }
    }
    
    static var navtionHeight : CGFloat {
        get {
            return 44.0
        }
    }
    
    static var barHeight : CGFloat {
        get {
            return (UIScreen.statusBarHeight + UIScreen.navBarHeight)
        }
    }
    
    static var bottomBarHeight : CGFloat {
        get {
            if UIApplication.isIPhoneX(){
                return 51.0 + UIScreen.stateHomeSaft
            }else {
                return 60
            }
        }
    }
    
    static var edges : UIEdgeInsets {
        if #available(iOS 11.0, *) {
            let window: UIWindow? = (UIApplication.shared.keyWindow)!
            if window != nil {
                return window?.safeAreaInsets ?? UIEdgeInsets.zero
            }
        }
        return UIEdgeInsets.zero
    }
}
